$wixFolder = if ($env:WIX) { Join-Path $env:WIX -ChildPath "bin" } else { "C:\Program Files (x86)\WiX Toolset v3.11\bin" }
$candleToolPath = Join-Path $wixFolder -ChildPath candle.exe
$lightToolPath = Join-Path $wixFolder -ChildPath light.exe

try
{
    Push-Location $PSScriptRoot

    $wxsFileName = "Product.wxs"
    $wixobjFileName = "Product.wixobj"
    $msiFileName = "Product.msi"

    # compiling wxs file into wixobj
    & "$candleToolPath" $wxsFileName -v -wx -out $wixobjFileName
    if($LASTEXITCODE -ne 0)
    {
        throw "Compilation of $wxsFileName failed with exit code $LASTEXITCODE"
    }

    # linking wixobj into msi
    & "$lightToolPath" $wixobjFileName -v -sw1076 -ext WixUtilExtension.dll -out $msiFileName
    if($LASTEXITCODE -ne 0)
    {
        throw "Linking of $wixobjFileName failed with exit code $LASTEXITCODE"
    }
}
catch
{
    Write-Error $_
    exit 1
}
finally
{
    Pop-Location
}