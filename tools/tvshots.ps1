# Run the reference race script on a device with screenshots every 300 frames, pull them and
# compare them with a reference directory of the PC build (tools/imgdiff.py).
#   & .\tools\tvshots.ps1 -Device <device-ip>:5555 -Options "--renderer gl --scale 1 --no-pgxp" `
#       -Ref ..\CTRStaticRecomp\build\n43 -Out ..\CTRStaticRecomp\build\tv_gl1
param(
    [Parameter(Mandatory)][string]$Device,
    [string]$Options = "",
    [Parameter(Mandatory)][string]$Ref,
    [Parameter(Mandatory)][string]$Out,
    [int]$Frames = 6300,
    [int]$TimeoutSec = 900
)
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$pkg = "io.github.lorenzoalfaro.ctrrecomp"
$dir = "/sdcard/Android/data/$pkg/files"
# the key script of CTRStaticRecomp/tools/verify.ps1 (the references were made with it)
$keys = "2700:down,2740:down," + ((0..13 | ForEach-Object { "$(2780 + $_ * 60):cross" }) -join ",") + ",3700:cross:3000"
& $adb -s $Device shell am force-stop $pkg
& $adb -s $Device shell "rm -f $dir/shot_*.bmp"
& $adb -s $Device shell "am start -n $pkg/.CTRActivity -e args '--turbo --aspect 4:3 --overclock 100 $Options --frames $Frames --shot-every 300 $dir --keys $keys'" | Out-Null
$t0 = Get-Date
do { Start-Sleep -Seconds 3 } while ((& $adb -s $Device shell pidof $pkg) -and ((Get-Date) - $t0).TotalSeconds -lt $TimeoutSec)
"finished in $([int]((Get-Date) - $t0).TotalSeconds) s ($Options)"
New-Item -ItemType Directory -Force $Out | Out-Null
Get-ChildItem $Out -Filter *.bmp | ForEach-Object { [IO.File]::Delete($_.FullName) }
foreach ($f in (& $adb -s $Device shell "ls $dir" | Where-Object { $_ -like "shot_*.bmp" })) {
    & $adb -s $Device pull "$dir/$($f.Trim())" "$Out\$($f.Trim())" | Out-Null
}
& $adb -s $Device shell cat "$dir/ctr.log" | Select-String "GL: |E\]" | ForEach-Object { $_.Line }
& "$env:LOCALAPPDATA\Python\bin\python.exe" -W ignore (Join-Path $PSScriptRoot "..\..\CTRStaticRecomp\tools\imgdiff.py") $Ref $Out
