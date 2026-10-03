# Verification commands

All commands ran from repository root in PowerShell. Baseline commands and exits
are in baseline/commands.md. Each batch directory contains its command output,
summary and scenario results.

```powershell
./TEST_ROOM_SCALE_POC46.ps1 -Mode Repeatability -OutputDirectory verification/poc46/repeatability
./TEST_ROOM_SCALE_POC45.ps1 -Mode Fast -OutputDirectory verification/poc46/regression-poc45
./TEST_ROOM_SCALE_POC4.ps1 -Mode Fast -OutputDirectory verification/poc46/regression-poc4
./TEST_ROOM_SCALE_POC46.ps1 -Mode Fast -OutputDirectory verification/poc46/final-fast
./TEST_ROOM_SCALE_POC46.ps1 -Mode Scenario -CaptureVisuals -OutputDirectory verification/poc46/final-visuals
& '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --path . --script scripts/poc46_camera_visual_test.gd
```

Normal and fishbowl PowerShell launchers were also run in real GUI processes;
startup output and receipts are in launcher/. Owned smoke processes were stopped
after startup verification. Final fast and visual batch exit codes are zero.
Intermediate fast/render runs were used to diagnose presentation issues; the final
report identifies corrections rather than treating intermediate images as final.
