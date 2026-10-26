# Benchmark the installed app on a device: skip the intros, start an arcade race on Crash Cove,
# run in turbo (no frame pacing) and print the profile lines from the race.
#   pwsh tools/bench.ps1 -Device <device-ip>:5555 [-Options "--scale 1"] [-Frames 4800]
param(
    [Parameter(Mandatory)][string]$Device,
    [string]$Options = "",
    [int]$Frames = 4800,       # the race starts around frame 3900
    [int]$TimeoutSec = 600
)
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$pkg = "io.github.lorenzoalfaro.ctrrecomp"
# Start skips the Naughty Dog intro; the menu appears around frame 2250
$keys = ((0..43 | ForEach-Object { "$(150 + $_ * 40):start" }) -join ",") + ",2300:down,2340:down," +
    ((0..13 | ForEach-Object { "$(2380 + $_ * 60):cross" }) -join ",") + ",3300:cross:5000"
& $adb -s $Device shell am force-stop $pkg
& $adb -s $Device shell "am start -n $pkg/.CTRActivity -e args '--turbo --profile --frames $Frames $Options --keys $keys'" | Out-Null
$t0 = Get-Date
do { Start-Sleep -Seconds 3 } while ((& $adb -s $Device shell pidof $pkg) -and ((Get-Date) - $t0).TotalSeconds -lt $TimeoutSec)
"finished in $([int]((Get-Date) - $t0).TotalSeconds) s ($Options)"
& $adb -s $Device shell cat "/sdcard/Android/data/$pkg/files/ctr.log" |
    Select-String "profile: [0-9]|game renders" | Select-Object -Last 6 | ForEach-Object { $_.Line }
