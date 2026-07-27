if (!$env:SCOOP_HOME) { $env:SCOOP_HOME = Convert-Path (scoop prefix scoop) }
& "$env:SCOOP_HOME\bin\checkhashes.ps1" -Dir "$PSScriptRoot\..\bucket" @Args
