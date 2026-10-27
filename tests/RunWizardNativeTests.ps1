param(
    [Parameter(Mandatory = $true)]
    [string] $FpcPath,
    [Parameter(Mandatory = $true)]
    [string] $LazarusDirectory
)

$ErrorActionPreference = 'Stop'
$compiler = (Resolve-Path -LiteralPath $FpcPath).Path
$lazarus = (Resolve-Path -LiteralPath $LazarusDirectory).Path
$targetInfo = ((& $compiler '-iTP' '-iTO') -join ' ').Trim() -split '\s+'
if ($LASTEXITCODE -ne 0 -or $targetInfo.Count -ne 2) {
    throw 'Cannot determine the Free Pascal target CPU and OS.'
}
if ($targetInfo[1] -ne 'win64' -and $targetInfo[1] -ne 'win32') {
    throw 'The private-desktop modal integration test requires Windows.'
}
$target = "$($targetInfo[0])-$($targetInfo[1])"
$runId = (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
$outputDirectory = Join-Path $PSScriptRoot "lib\native-$target\$runId"
$brokerUnits = Join-Path $outputDirectory 'broker-units'
$probeUnits = Join-Path $outputDirectory 'probe-units'
New-Item -ItemType Directory -Path $brokerUnits, $probeUnits -Force | Out-Null
$brokerExecutable = Join-Path $outputDirectory 'PrivateDesktopBroker.exe'
$probeExecutable = Join-Path $outputDirectory 'WizardNativeProbe.exe'
$brokerBuildLog = Join-Path $outputDirectory 'broker-build.log'
$probeBuildLog = Join-Path $outputDirectory 'probe-build.log'
$brokerRunLog = Join-Path $outputDirectory 'broker-run.log'
$probeRunLog = Join-Path $outputDirectory 'modal-transitions.log'

& $compiler '-MDelphi' '-O2' '-gl' "-FU$brokerUnits" "-FE$outputDirectory" `
    "-o$brokerExecutable" "$PSScriptRoot\native\PrivateDesktopBroker.lpr" *> $brokerBuildLog
if ($LASTEXITCODE -ne 0) {
    Get-Content -LiteralPath $brokerBuildLog -Tail 60
    exit $LASTEXITCODE
}
$probeArguments = @(
    '-MDelphi', '-O2', '-gl', '-WG',
    "-Fu$PSScriptRoot\..\src\Sphere10",
    "-Fu$PSScriptRoot\..\src\Generics.Collections",
    "-Fu$PSScriptRoot\..\examples\wizard",
    "-Fu$lazarus\lcl\units\$target",
    "-Fu$lazarus\lcl\units\$target\win32",
    "-Fu$lazarus\components\lazutils\lib\$target",
    "-Fu$lazarus\packager\units\$target",
    "-FU$probeUnits", "-FE$outputDirectory", "-o$probeExecutable",
    "$PSScriptRoot\native\WizardNativeProbe.lpr"
)
& $compiler @probeArguments *> $probeBuildLog
if ($LASTEXITCODE -ne 0) {
    Get-Content -LiteralPath $probeBuildLog -Tail 60
    exit $LASTEXITCODE
}

# The broker never switches desktops and never falls back to the user's desktop.
# It applies a watchdog to its own test process and returns that process's result.
& $brokerExecutable $probeExecutable $probeRunLog *> $brokerRunLog
$nativeTestExitCode = $LASTEXITCODE
if (Test-Path -LiteralPath $probeRunLog) {
    Get-Content -LiteralPath $probeRunLog
}
if ($nativeTestExitCode -ne 0) {
    Get-Content -LiteralPath $brokerRunLog -Tail 40
}
Write-Host "Native modal test evidence: $outputDirectory"
exit $nativeTestExitCode
