if (!$env:SCOOP_HOME) { $env:SCOOP_HOME = Convert-Path (scoop prefix scoop) }
& "$env:SCOOP_HOME\bin\checkurls.ps1" -Dir "$PSScriptRoot\..\bucket" @Args
