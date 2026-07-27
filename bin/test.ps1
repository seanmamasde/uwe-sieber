#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.2.0' }
#Requires -Modules @{ ModuleName = 'BuildHelpers'; ModuleVersion = '2.0.1' }

# Scoop's Import-Bucket-Tests.ps1 only schema-validates *changed* manifests when
# $env:CI is set, which it determines by diffing HEAD against its parent. This
# repository is deliberately kept as a single squashed commit, so HEAD^ does not
# exist and that discovery step dies -- silently validating nothing. Clearing CI
# makes it validate every manifest, which is correct here and takes ~3s.
$env:CI = ''

$configuration = New-PesterConfiguration
# Target this bucket's test file explicitly rather than the repository root.
# CI checks Scoop out into a subdirectory of the workspace, and a recursive
# root path would make Pester discover Scoop's own test suite as well.
$configuration.Run.Path = "$PSScriptRoot\..\Scoop-Bucket.Tests.ps1"
$configuration.Run.PassThru = $true
$configuration.Output.Verbosity = 'Detailed'

$result = Invoke-Pester -Configuration $configuration

# A Pester discovery error is NOT counted as a failed test, so the run can
# report success having executed almost nothing. Guard against that false
# green: treat a non-passing container, or an implausibly small number of
# passing tests, as a build failure.
$exitCode = $result.FailedCount

$broken = @($result.Containers | Where-Object { $_.Result -ne 'Passed' })
if ($broken.Count -gt 0) {
    Write-Host "::error::$($broken.Count) test container(s) did not pass - likely a discovery error."
    $exitCode += $broken.Count
}

$manifestCount = @(Get-ChildItem "$PSScriptRoot\..\bucket" -Filter '*.json').Count
if ($result.PassedCount -lt $manifestCount) {
    Write-Host "::error::only $($result.PassedCount) tests passed, but this bucket has $manifestCount manifests - schema validation did not run."
    $exitCode += 1
}

exit $exitCode
