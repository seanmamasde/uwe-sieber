<#
.SYNOPSIS
    Sole updater for this bucket. Derives every manifest version from the
    packaged executable, not from the author's product page.

.DESCRIPTION
    uwe-sieber.de serves each tool from a stable filename and its product pages
    carry a hand-maintained version that is often stale or simply wrong, so the
    page is not a usable source of truth. This script instead:

      1. HEADs every download and compares ETag / Last-Modified / Content-Length
         against cache/downloads.csv. Unchanged entries cost one HEAD.
      2. Downloads only what moved, hashes it, extracts it, and reads the
         executable's FileVersion resource once per architecture.
      3. Writes the normalised FileVersion, the new SHA-256 and, where the
         download URL encodes the version, the new URL.

    Everything an app touches is staged as a candidate and committed only when
    that whole app validates, so a failure leaves the manifest and the cache
    exactly as they were. Without -Apply nothing on disk is modified at all.

    Where an executable carries no FileVersion resource the version falls back
    to the product page, flagged <pageVersion>+web.<revision>. The fallback
    never moves backwards: a page version that would order lower than what is
    already published is reported instead of written.

    Exceptions live in config/sync.json. Manifests carry no checkver and no
    autoupdate.

.PARAMETER Apply
    Write the changes. Without it the script only reports and touches nothing.

.PARAMETER App
    Restrict the run to a single manifest.

.PARAMETER Force
    Ignore the cache and re-download everything.
#>
#Requires -Version 7.0
[CmdletBinding()]
param(
    [switch] $Apply,
    [string] $App,
    [switch] $Force
)

$ErrorActionPreference = 'Stop'

$repo       = Split-Path $PSScriptRoot -Parent
$bucketDir  = Join-Path $repo 'bucket'
$cacheFile  = Join-Path $repo 'cache\downloads.csv'
$configFile = Join-Path $repo 'config\sync.json'
$ua         = 'Scoop uwe-sieber sync'

New-Item -ItemType Directory -Force -Path (Split-Path $cacheFile) | Out-Null

$config = if (Test-Path $configFile) { Get-Content $configFile -Raw | ConvertFrom-Json } else { [pscustomobject]@{} }

$cache = @{}
if (Test-Path $cacheFile) {
    foreach ($r in (Import-Csv $cacheFile)) { $cache[$r.url] = $r }
}

# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------

# Write a file only after it is fully materialised, so an interrupted run can
# never leave a half-written manifest or cache behind.
function Set-FileAtomic {
    param([string] $Path, [string] $Content)
    $tmp = "$Path.tmp"
    [IO.File]::WriteAllText($tmp, $Content, (New-Object Text.UTF8Encoding $false))
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}

# Normalise a raw FileVersion resource into a manifest version.
#   "3, 4, 8, 0" -> 3.4.8      trailing zero segments dropped while >3 remain
#   "0.3.0.1"    -> 0.3.0.1    a significant 4th segment is kept
#   "0.04.0027"  -> 0.04.0027  the author's zero padding is preserved verbatim
# Returns $null when the resource is not plain dotted-numeric, which is treated
# as an error rather than silently coerced.
function ConvertTo-ManifestVersion {
    param([string] $Raw)

    if ([string]::IsNullOrWhiteSpace($Raw)) { return $null }
    $v = ($Raw.Trim() -replace '[,\s]+', '.')
    if ($v -notmatch '^\d+(?:\.\d+)*$') { return $null }

    $seg = [System.Collections.Generic.List[string]]::new()
    foreach ($s in $v.Split('.')) { $seg.Add($s) }
    while ($seg.Count -gt 3 -and [int]$seg[$seg.Count - 1] -eq 0) { $seg.RemoveAt($seg.Count - 1) }
    return ($seg -join '.')
}

# Numeric, segment-wise comparison. Scoop's own comparer returns $null for some
# zero-padded pairs (0.04 vs 0.4), so ordering decisions are made here instead.
function Compare-NumericVersion {
    param([string] $A, [string] $B)
    $sa = @(($A -split '\.') | ForEach-Object { [int]$_ })
    $sb = @(($B -split '\.') | ForEach-Object { [int]$_ })
    $n = [Math]::Max($sa.Count, $sb.Count)
    for ($i = 0; $i -lt $n; $i++) {
        $x = if ($i -lt $sa.Count) { $sa[$i] } else { 0 }
        $y = if ($i -lt $sb.Count) { $sb[$i] } else { 0 }
        if ($x -gt $y) { return 1 }
        if ($x -lt $y) { return -1 }
    }
    return 0
}

# <pageVersion>+web.<revision>. The revision increments when the bytes moved
# under an unchanged page version. A page version that is not >= the currently
# published base is refused, so the fallback can never regress.
function Get-FallbackVersion {
    param([string] $PageVersion, [string] $CurrentManifestVersion, [bool] $BytesChanged)

    if ($PageVersion -notmatch '^\d+(?:\.\d+)*$') {
        return [pscustomobject]@{ Ok = $false; Detail = "page version '$PageVersion' is not dotted-numeric" }
    }

    $rev = 0
    if ($CurrentManifestVersion -match '^(?<base>\d+(?:\.\d+)*)\+web\.(?<rev>\d+)$') {
        $base = $Matches.base
        $cmp = Compare-NumericVersion $PageVersion $base
        if ($cmp -lt 0) {
            return [pscustomobject]@{ Ok = $false; Detail = "page version '$PageVersion' is older than the published '$base'" }
        }
        if ($cmp -eq 0) {
            $rev = [int]$Matches.rev
            if ($BytesChanged) { $rev++ }
        }
    }
    return [pscustomobject]@{ Ok = $true; Version = "$PageVersion+web.$rev" }
}

function Get-PageVersion {
    param([string] $Url, [string] $Regex)
    try {
        $html = (Invoke-WebRequest -Uri $Url -UserAgent $ua -TimeoutSec 60 -UseBasicParsing).Content
    } catch {
        return $null
    }
    if ($html -match $Regex) { return $Matches[1] }
    return $null
}

# --------------------------------------------------------------------------
# Archive inspection
# --------------------------------------------------------------------------

# Extracts once and reads the executable under EVERY architecture directory the
# archive serves, so a shared ZIP whose x64 and Win32 builds disagree is caught
# instead of silently publishing whichever path sorted first.
# Returns one result per target:
#   Found           -> Version populated
#   MissingResource -> executable located, FileVersion empty
#   Error           -> anything else
function Get-ArchiveVersions {
    param([string] $Zip, [string] $ExeName, [object[]] $Targets)

    $dest = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
    try {
        try {
            Expand-Archive -LiteralPath $Zip -DestinationPath $dest -Force -ErrorAction Stop
        } catch {
            return $Targets | ForEach-Object {
                [pscustomobject]@{ arch = $_.arch; State = 'Error'; Detail = "extraction failed - $($_.Exception.Message)" }
            }
        }

        $out = @()
        foreach ($t in $Targets) {
            $root = if ($t.extractDir) { Join-Path $dest $t.extractDir } else { $dest }
            if (-not (Test-Path $root)) {
                $out += [pscustomobject]@{ arch = $t.arch; State = 'Error'; Detail = "extract_dir '$($t.extractDir)' not present in archive" }
                continue
            }
            # Shallowest match under this architecture root.
            $hit = Get-ChildItem $root -Recurse -Filter $ExeName -File -ErrorAction SilentlyContinue |
                Sort-Object { $_.FullName.Length } | Select-Object -First 1
            if (-not $hit) {
                $out += [pscustomobject]@{ arch = $t.arch; State = 'Error'; Detail = "executable '$ExeName' not found under '$($t.extractDir)'" }
                continue
            }
            $raw = $hit.VersionInfo.FileVersion
            if ([string]::IsNullOrWhiteSpace($raw)) {
                $out += [pscustomobject]@{ arch = $t.arch; State = 'MissingResource'; Detail = 'no FileVersion resource' }
                continue
            }
            $norm = ConvertTo-ManifestVersion $raw
            if (-not $norm) {
                $out += [pscustomobject]@{ arch = $t.arch; State = 'Error'; Detail = "unparsable FileVersion '$raw'" }
                continue
            }
            $out += [pscustomobject]@{ arch = $t.arch; State = 'Found'; Raw = $raw.Trim(); Version = $norm }
        }
        return $out
    } finally {
        Remove-Item -Recurse -Force $dest -ErrorAction SilentlyContinue
    }
}

# Groups a manifest into one record per distinct download URL, carrying every
# architecture that URL serves together with that architecture's effective
# extract_dir.
function Get-Downloads {
    param($Manifest, $Name, [hashtable] $UrlOverride)

    $b = @($Manifest.bin)[0]
    $exe = if ($b -is [string]) { $b } else { $b[0] }
    $exe = if ($exe) { Split-Path $exe -Leaf } else { $null }

    $topDir = if ($Manifest.extract_dir) { $Manifest.extract_dir } else { '' }

    $byUrl = [ordered]@{}
    function Add-Target {
        param($Url, $Hash, $Arch, $Dir)
        if (-not $Url) { return }
        if (-not $byUrl.Contains($Url)) {
            $byUrl[$Url] = [pscustomobject]@{ url = $Url; hash = $Hash; targets = @() }
        }
        $byUrl[$Url].targets += [pscustomobject]@{ arch = $Arch; extractDir = $Dir }
    }

    if ($Manifest.architecture) {
        foreach ($a in '64bit', '32bit', 'arm64') {
            $n = $Manifest.architecture.$a
            if (-not $n) { continue }
            $dir = if ($n.extract_dir) { $n.extract_dir } else { $topDir }
            if ($n.url) {
                $u = if ($UrlOverride -and $UrlOverride.ContainsKey($a)) { $UrlOverride[$a] } else { $n.url }
                Add-Target -Url $u -Hash $n.hash -Arch $a -Dir $dir
            } elseif ($Manifest.url) {
                Add-Target -Url $Manifest.url -Hash $Manifest.hash -Arch $a -Dir $dir
            }
        }
    }
    if ($Manifest.url -and -not $byUrl.Contains($Manifest.url)) {
        Add-Target -Url $Manifest.url -Hash $Manifest.hash -Arch '' -Dir $topDir
    }

    return @($byUrl.Values | ForEach-Object {
            [pscustomobject]@{ app = $Name; url = $_.url; hash = $_.hash; exe = $exe; targets = $_.targets }
        })
}

# Rewrites the version, the hashes and any moved URLs, leaving formatting and
# key order untouched. Every substitution is counted and the result is parsed
# before it is written, so a bad edit fails loudly instead of shipping.
function Update-Manifest {
    param(
        [string] $Path,
        [string] $OldVersion,
        [string] $NewVersion,
        [hashtable] $HashMap,
        [hashtable] $UrlMap
    )

    $raw = [IO.File]::ReadAllText($Path)

    if ($NewVersion -and $NewVersion -ne $OldVersion) {
        # NOTE: the 4th argument of the STATIC [regex]::Replace is RegexOptions,
        # not a replace count. An instance regex is required to bound the count.
        $re = [regex]::new('("version"\s*:\s*")' + [regex]::Escape($OldVersion) + '(")')
        $n = $re.Matches($raw).Count
        if ($n -ne 1) { throw "expected exactly 1 version field, found $n" }
        $raw = $re.Replace($raw, "`${1}$NewVersion`${2}", 1)
    }

    foreach ($k in $UrlMap.Keys) {
        if (-not $raw.Contains($k)) { throw "url '$k' not found in manifest" }
        $raw = $raw.Replace($k, $UrlMap[$k])
    }
    foreach ($k in $HashMap.Keys) {
        if (-not $raw.Contains($k)) { throw "hash '$k' not found in manifest" }
        $raw = $raw.Replace($k, $HashMap[$k])
    }

    # Fail before writing rather than leaving an unparsable manifest.
    $null = $raw | ConvertFrom-Json

    Set-FileAtomic -Path $Path -Content $raw
}

# --------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------

$allManifests = Get-ChildItem $bucketDir -Filter *.json | Sort-Object BaseName

# Every URL the bucket references, regardless of any -App filter, so a partial
# run keeps unrelated cache rows while still pruning URLs nothing points at.
$knownUrls = [System.Collections.Generic.HashSet[string]]::new()
foreach ($f in $allManifests) {
    $m = Get-Content $f.FullName -Raw | ConvertFrom-Json
    foreach ($d in (Get-Downloads -Manifest $m -Name $f.BaseName)) { [void]$knownUrls.Add($d.url) }
}

$manifests = $allManifests
if ($App) { $manifests = @($manifests | Where-Object BaseName -eq $App) }
if (-not $manifests) { throw "no manifests matched" }

"Syncing $($manifests.Count) manifest(s)..."
''

$changed   = @()
$errors    = @()
$flagged   = @()
$unchanged = 0
$committedCache = @{}
# URLs superseded by discovery, so their stale cache rows can be pruned.
$retiredUrls = [System.Collections.Generic.HashSet[string]]::new()

foreach ($f in $manifests) {
    $name = $f.BaseName
    $m = Get-Content $f.FullName -Raw | ConvertFrom-Json
    $cfg = $config.$name

    # Everything this app would change is staged here and only merged once the
    # whole app validates.
    $appErrors    = @()
    $candCache    = @{}
    $hashMap      = @{}
    $urlMap       = @{}
    $urlOverride  = @{}
    $bytesChanged = $false
    $appUnchanged = 0

    # A version-encoded filename needs the page to discover the next URL. The
    # discovered URL becomes the actual download target.
    if ($cfg -and $cfg.discovery) {
        $pv = Get-PageVersion -Url $cfg.discovery.url -Regex $cfg.discovery.regex
        if (-not $pv -or $pv -notmatch '^\d+(?:\.\d+)*$') {
            $appErrors += "$name : discovery failed, could not read a usable page version"
        } else {
            $clean = $pv -replace '\.', ''
            foreach ($a in $cfg.discovery.architecture.PSObject.Properties.Name) {
                $want = $cfg.discovery.architecture.$a -replace '\$pageCleanVersion', $clean
                $have = $m.architecture.$a.url
                if ($want -ne $have) {
                    $urlOverride[$a] = $want
                    $urlMap[$have] = $want
                }
            }
        }
    }

    if ($appErrors) {
        $errors += $appErrors
        $errors += "$name : left unchanged"
        continue
    }

    $downloads = Get-Downloads -Manifest $m -Name $name -UrlOverride $urlOverride
    $results = @()

    foreach ($d in $downloads) {
        $isNewUrl = $urlMap.Values -contains $d.url

        try {
            $head = Invoke-WebRequest -Uri $d.url -Method Head -UserAgent $ua -TimeoutSec 60
        } catch {
            $appErrors += "$name : HEAD failed for $($d.url) - $($_.Exception.Message)"
            $results += [pscustomobject]@{ State = 'Error' }
            continue
        }

        $etag = ($head.Headers['ETag'] -join '')
        $lm   = ($head.Headers['Last-Modified'] -join '')
        $len  = ($head.Headers['Content-Length'] -join '')
        $prev = $cache[$d.url]

        # A row written by an older cache format lacks 'state', so it is
        # refreshed once and the format upgrade heals itself. A rediscovered URL
        # is always fetched.
        $cacheUsable = -not $Force -and -not $isNewUrl -and $prev -and
            $prev.PSObject.Properties.Name -contains 'state' -and
            $prev.state -in @('Found', 'MissingResource') -and
            ($prev.state -eq 'MissingResource' -or $prev.version) -and
            $prev.etag -ceq $etag -and $prev.last_modified -ceq $lm -and
            $prev.length -eq $len -and $prev.sha256 -ceq $d.hash

        if ($cacheUsable) {
            $appUnchanged++
            $candCache[$d.url] = $prev
            foreach ($t in $d.targets) {
                $results += [pscustomobject]@{ arch = $t.arch; State = $prev.state; Version = $prev.version; Raw = $prev.raw_version }
            }
            continue
        }

        $tmp = Join-Path ([IO.Path]::GetTempPath()) (([IO.Path]::GetRandomFileName()) + '.zip')
        $infos = $null
        try {
            Invoke-WebRequest -Uri $d.url -OutFile $tmp -UserAgent $ua -TimeoutSec 300
            $sha = (Get-FileHash $tmp -Algorithm SHA256).Hash.ToLower()
            $infos = Get-ArchiveVersions -Zip $tmp -ExeName $d.exe -Targets $d.targets
        } catch {
            $appErrors += "$name : download failed for $($d.url) - $($_.Exception.Message)"
            $results += [pscustomobject]@{ State = 'Error' }
            continue
        } finally {
            if (Test-Path $tmp) { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
        }

        if ($sha -ne $d.hash) {
            $bytesChanged = $true
            if (-not $isNewUrl) { $hashMap[$d.hash] = $sha }
        }
        if ($isNewUrl) { $hashMap[$d.hash] = $sha }

        foreach ($i in $infos) {
            if ($i.State -eq 'Error') { $appErrors += "$name [$($i.arch)] : $($i.Detail)" }
        }
        $results += $infos

        $first = @($infos)[0]
        $candCache[$d.url] = [pscustomobject]@{
            url = $d.url; etag = $etag; last_modified = $lm; length = $len; sha256 = $sha
            state = $first.State; version = $first.Version; raw_version = $first.Raw
        }
    }

    if (-not $results) { continue }

    # Any error anywhere in an app leaves that app, and its cache rows,
    # completely untouched.
    if ($appErrors -or ($results.State -contains 'Error')) {
        $errors += $appErrors
        $errors += "$name : left unchanged"
        continue
    }

    # Architectures must agree. A mismatch is an error, not something to guess.
    $found = @($results | Where-Object State -eq 'Found')
    $missing = @($results | Where-Object State -eq 'MissingResource')
    if ($found.Count -gt 0 -and $missing.Count -gt 0) {
        $errors += "$name : some architectures report a FileVersion and others do not, left unchanged"
        continue
    }
    $distinct = @($found.Version | Sort-Object -Unique)
    if ($distinct.Count -gt 1) {
        $errors += "$name : architectures disagree on FileVersion ($($distinct -join ' vs ')), left unchanged"
        continue
    }

    $newVersion = $null
    if ($distinct.Count -eq 1) {
        $newVersion = $distinct[0]
    } else {
        # Every architecture reported MissingResource, so fall back to the page.
        $fb = $cfg.fallback
        if (-not $fb) {
            $errors += "$name : no FileVersion resource and no fallback configured in config/sync.json"
            continue
        }
        $pageVersion = if ($fb.version) { $fb.version } else { Get-PageVersion -Url $fb.url -Regex $fb.regex }
        if (-not $pageVersion) {
            $errors += "$name : no FileVersion resource and the page version could not be read"
            continue
        }
        $fbr = Get-FallbackVersion -PageVersion $pageVersion -CurrentManifestVersion $m.version -BytesChanged $bytesChanged
        if (-not $fbr.Ok) {
            $errors += "$name : $($fbr.Detail), left unchanged"
            continue
        }
        $newVersion = $fbr.Version
        $flagged += "$name -> $newVersion"
    }

    $unchanged += $appUnchanged

    if ($newVersion -eq $m.version -and $hashMap.Count -eq 0 -and $urlMap.Count -eq 0) {
        foreach ($k in $candCache.Keys) { $committedCache[$k] = $candCache[$k] }
        continue
    }

    $note = @()
    if ($newVersion -ne $m.version) { $note += "version $($m.version) -> $newVersion" }
    if ($urlMap.Count -gt 0)  { $note += "$($urlMap.Count) url(s)" }
    if ($hashMap.Count -gt 0) { $note += "$($hashMap.Count) hash(es)" }
    $changed += "$name : $($note -join ', ')"

    if ($Apply) {
        try {
            Update-Manifest -Path $f.FullName -OldVersion $m.version -NewVersion $newVersion -HashMap $hashMap -UrlMap $urlMap
        } catch {
            $errors += "$name : manifest write failed - $($_.Exception.Message), left unchanged"
            continue
        }
    }

    # Only now is this app's cache state considered good.
    foreach ($k in $candCache.Keys) { $committedCache[$k] = $candCache[$k] }
    foreach ($k in $urlMap.Keys) { [void]$retiredUrls.Add($k) }
}

# The cache is state, so it is only persisted on an applying run. A report-only
# run must leave the working tree byte-for-byte untouched.
if ($Apply) {
    $finalCache = @{}
    foreach ($u in $knownUrls) {
        if ($retiredUrls.Contains($u)) { continue }
        if ($cache[$u]) { $finalCache[$u] = $cache[$u] }
    }
    foreach ($k in $committedCache.Keys) { $finalCache[$k] = $committedCache[$k] }

    $csv = $finalCache.Values |
        Select-Object url, etag, last_modified, length, sha256, state, version, raw_version |
        Sort-Object url |
        ConvertTo-Csv -NoTypeInformation
    Set-FileAtomic -Path $cacheFile -Content (($csv -join "`r`n") + "`r`n")
}

"cached/unchanged : $unchanged"
"changed          : $($changed.Count)"
"flagged (+web)   : $($flagged.Count)"
"errors           : $($errors.Count)"

if ($changed) { ''; 'CHANGED:'; $changed | ForEach-Object { "  $_" } }
if ($flagged) { ''; 'FLAGGED - no FileVersion resource, using the page version:'; $flagged | ForEach-Object { "  $_" } }
if ($errors)  { ''; 'ERRORS:';  $errors  | ForEach-Object { "  $_" } }

if (-not $Apply -and $changed) { ''; 'Re-run with -Apply to write these changes.' }

exit $errors.Count
