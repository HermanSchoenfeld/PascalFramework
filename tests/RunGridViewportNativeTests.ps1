param(
    [string] $FpcPath = 'D:\Pascal\fpc\bin\x86_64-win64\fpc.exe',
    [string] $LazarusDirectory = 'D:\Pascal\lazarus',
    [string] $LibraryDirectory,
    [string] $OutputDirectory
)

$ErrorActionPreference = 'Stop'
$compiler = (Resolve-Path -LiteralPath $FpcPath).Path
$lazarus = (Resolve-Path -LiteralPath $LazarusDirectory).Path
if (-not $LibraryDirectory) { $LibraryDirectory = Join-Path $PSScriptRoot '..\src\Sphere10' }
$library = (Resolve-Path -LiteralPath $LibraryDirectory).Path
foreach ($unit in @('UVisualGrid.pas')) {
    if (-not (Test-Path -LiteralPath (Join-Path $library $unit))) { throw "Missing library unit: $unit" }
}
$targetInfo = ((& $compiler '-iTP' '-iTO') -join ' ').Trim() -split '\s+'
if ($LASTEXITCODE -ne 0 -or $targetInfo.Count -ne 2 -or $targetInfo[1] -notin @('win64','win32')) {
    throw 'The native grid loading probe requires a Windows FPC compiler.'
}
$target = "$($targetInfo[0])-$($targetInfo[1])"
if (-not $OutputDirectory) {
    $runId = (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8)
    $OutputDirectory = Join-Path $PSScriptRoot "lib\grid-native-$target\$runId"
}
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$output = (Resolve-Path -LiteralPath $OutputDirectory).Path
$brokerUnits = Join-Path $output 'broker-units'
$probeUnits = Join-Path $output 'probe-units'
New-Item -ItemType Directory -Path $brokerUnits, $probeUnits -Force | Out-Null
$broker = Join-Path $output 'PrivateDesktopBroker.exe'
$probe = Join-Path $output 'GridViewportProbe.exe'
$brokerBuild = Join-Path $output 'broker-build.log'
$probeBuild = Join-Path $output 'probe-build.log'
$brokerLog = Join-Path $output 'broker-run.log'
$probeLog = Join-Path $output 'grid-viewport.log'

& $compiler '-MDelphi' '-O1' '-gl' "-FU$brokerUnits" "-FE$output" "-o$broker" `
    "$PSScriptRoot\native\PrivateDesktopBroker.lpr" *> $brokerBuild
if ($LASTEXITCODE -ne 0) { Get-Content -LiteralPath $brokerBuild -Tail 40; exit $LASTEXITCODE }
$probeArguments = @(
    '-B', '-MDelphi', '-O1', '-gl', '-WG',
    "-Fu$library", "-Fu$PSScriptRoot", "-Fu$PSScriptRoot\..\src\Generics.Collections",
    "-Fi$PSScriptRoot\..\src\Generics.Collections\inc",
    "-Fu$lazarus\lcl\units\$target", "-Fu$lazarus\lcl\units\$target\win32",
    "-Fu$lazarus\components\lazutils\lib\$target", "-Fu$lazarus\packager\units\$target",
    "-FU$probeUnits", "-FE$output", "-o$probe", "$PSScriptRoot\native\GridViewportProbe.dpr"
)
& $compiler @probeArguments *> $probeBuild
if ($LASTEXITCODE -ne 0) { Get-Content -LiteralPath $probeBuild -Tail 60; exit $LASTEXITCODE }

# The broker creates its own Windows desktop and never switches the input desktop.
& $broker $probe $probeLog *> $brokerLog
$nativeExit = $LASTEXITCODE
if (Test-Path -LiteralPath $probeLog) { Get-Content -LiteralPath $probeLog }
if ($nativeExit -ne 0) { Get-Content -LiteralPath $brokerLog -Tail 30; exit $nativeExit }
if (-not (Select-String -LiteralPath $probeLog -SimpleMatch 'PASS complete native viewport regression matrix')) {
    throw 'The native grid probe exited without explicit completion evidence.'
}
Write-Host "Native grid viewport evidence: $output"
