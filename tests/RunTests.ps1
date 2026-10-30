param(
    [Parameter(Mandatory = $true)]
    [string] $FpcPath,
    [Parameter(Mandatory = $true)]
    [string] $LazarusDirectory,
    [string[]] $TestArguments = @('--all', '--format=plain'),
    [string] $OutputDirectory
)

$ErrorActionPreference = 'Stop'
$compiler = (Resolve-Path -LiteralPath $FpcPath).Path
$lazarus = (Resolve-Path -LiteralPath $LazarusDirectory).Path
$targetInfo = ((& $compiler '-iTP' '-iTO') -join ' ').Trim() -split '\s+'
if ($LASTEXITCODE -ne 0 -or $targetInfo.Count -ne 2) {
    throw 'Cannot determine the Free Pascal target CPU and OS.'
}
$target = "$($targetInfo[0])-$($targetInfo[1])"
if ($targetInfo[1] -ne 'win64' -and $targetInfo[1] -ne 'win32') {
    throw 'This script uses the Lazarus Win32 widgetset. Use the Lazarus project for other platforms.'
}
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $PSScriptRoot "lib\console-$target" }
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$outputDirectory = (Resolve-Path -LiteralPath $OutputDirectory).Path
$buildLog = Join-Path $outputDirectory 'build.log'
$testExecutable = Join-Path $outputDirectory 'FrameworkTestsConsole.exe'
$compilerArguments = @(
    '-B', '-MDelphi', '-gl', '-dUNITTEST',
    "-Fu$PSScriptRoot\..\src\Sphere10",
    "-Fu$PSScriptRoot\..\src\Generics.Collections",
    "-Fu$PSScriptRoot\..\examples\demo",
    "-Fu$lazarus\lcl\units\$target",
    "-Fu$lazarus\lcl\units\$target\win32",
    "-Fu$lazarus\components\lazutils\lib\$target",
    "-Fu$lazarus\packager\units\$target",
    "-FU$outputDirectory", "-FE$outputDirectory",
    "-o$testExecutable", "$PSScriptRoot\FrameworkTestsConsole.lpr"
)

Push-Location $PSScriptRoot
try {
    & $compiler @compilerArguments *> $buildLog
    $compilerExitCode = $LASTEXITCODE
    if ($compilerExitCode -ne 0) {
        Get-Content -LiteralPath $buildLog -Tail 80
        exit $compilerExitCode
    }
    Write-Host "Build succeeded. Compiler log: $buildLog"
    & $testExecutable @TestArguments
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
