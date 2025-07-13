# TurboTweak
Windows 11 registry tweaks

Recent Folders Tweak
Backup Instructions: Run script's backup or manual: reg export "HKCU\SOFTWARE\Classes\CLSID\{22877a6d-37a1-461a-91b0-dbda5aaebc99}" "C:\backup\recent.reg" /y (same for Wow6432Node, ShellFolder). Restore: reg import. Risks: If no backup, manual recreation needed; no system impact if fails.
.reg File Code Block:
text

Collapse

Wrap

Copy
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\SOFTWARE\Classes\CLSID\{22877a6D-37A1-461A-91B0-DBDA5AAEBC99}]
@="Recent Places"

[HKEY_CURRENT_USER\SOFTWARE\Classes\CLSID\{22877a6D-37A1-461A-91B0-DBDA5AAEBC99}\ShellFolder]
"Attributes"=dword:30040000

[HKEY_CURRENT_USER\SOFTWARE\Classes\Wow6432Node\CLSID\{22877a6D-37A1-461A-91B0-DBDA5AAEBC99}]
@="Recent Places"

[HKEY_CURRENT_USER\SOFTWARE\Classes\Wow6432Node\CLSID\{22877a6D-37A1-461A-91B0-DBDA5AAEBC99}\ShellFolder]
"Attributes"=dword:30040000
Application Steps: Merge .reg as user (no admin for HKCU). Or run script. Open Explorer; pin if prompted.
Reversal Method: Merge removal .reg:
text

Collapse

Wrap

Copy
Windows Registry Editor Version 5.00

[-HKEY_CURRENT_USER\SOFTWARE\Classes\CLSID\{22877a6d-37a1-461a-91b0-dbda5aaebc99}]

[-HKEY_CURRENT_USER\SOFTWARE\Classes\Wow6432Node\CLSID\{22877a6d-37a1-461a-91b0-dbda5aaebc99}]
Or run remove script.
Explanation of Changes: Registers the "Recent Places" virtual folder (CLSID GUID) in Explorer's namespace for 64-bit and 32-bit apps. Sets name and attributes (0x30040000 hides it from certain views but allows pinning/access). Improves navigation by restoring pre-Win11 feature for recent items history. Isolated to UI; no performance hit.
Performance Tweaks
Backup Instructions: reg export "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "C:\backup\perf.reg" /y (and Multimedia). Restore via import. Risks: If not backed, defaults can be manually set; potential boot delay if fails.
.reg File Code Block:
text

Collapse

Wrap

Copy
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize]
"StartupDelayInMSec"=dword:00000000
"WaitforIdleState"=dword:00000000

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile]
"SystemResponsiveness"=dword:0000000a
"NetworkThrottlingIndex"=dword:ffffffff
Application Steps: Merge as admin. Reboot.
Reversal Method: Merge:
text

Collapse

Wrap

Copy
Windows Registry Editor Version 5.00

[-HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize]

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile]
"SystemResponsiveness"=dword:00000014  ; 20
"NetworkThrottlingIndex"=dword:0000000a  ; 10
Explanation of Changes: Reduces startup app delay (0 ms), allocates more CPU to foreground apps (10 from 20%), disables network bandwidth reservation for multimedia (ffffffff from 10). Makes system snappier for power users; may slightly increase background task latency but safe for SSDs/high-spec.
Verbose Boot Tweak
Backup Instructions: reg export "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "C:\backup\verbose.reg" /y. Restore import: via import.
.reg File Code Block:
text

Collapse

Wrap

Copy
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System]
"verbosestatus"=dword:00000001
Application Steps: Merge as admin. Reboot to see effect.
Reversal Method: Merge:
text

Collapse

Wrap

Copy
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System]
"verbosestatus"=dword:00000000
Explanation of Changes: Enables detailed logging messages during boot/shutdown/logon (e.g., "Shutting down service X") instead of generic spinners. Useful for troubleshooting; no impact on normal operation, just more info on screen. Default hides for simplicity.