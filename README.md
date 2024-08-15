## Windows Form window finder
This Powershell script helps to find and count Form window on MS Windows. You can collect statistic fo popped up error window, fire up triggers and, may be, something else.

Actual release 1.0

Tested on:
- Production mode: Windows 10, Powershell 7;

Supported keys:

- _WindowTitle_ - Title of searched Form window;
- _SleepSeconds_ - Idle duration between search attempts;
- _ZabbixServer_ - IP-address or FDQN-name of Zabbix Server;
- _TargetHostName_ - Host name (as shown on the Zabbix UI) which contain $TargetKeyName;
- _TargetKeyName_ - "Zabbix trapper" item key, which stored number of found window instances;
- _Verbose_ - Enable verbose messages;


### How to use standalone

    # Searching every 30 sec for "Error *" (wildcard used) titled Form windows, and sending number of found instances to 172.16.16.172, item "windows.form.count[AllErrorWindows]", linked to "BuggedPC" host.
    "C:\Program Files\PowerShell\7\pwsh.exe" -NoProfile -ExecutionPolicy "RemoteSigned" -File "windows_form_finder.ps1" -WindowTitle "Error *" -SleepSecond 30 -ZabbixServer 172.16.16.172 -TargetHostName "BuggedPC" -TargetKeyName "windows.form.count[AllErrorWindows]"

### How to use with Zabbix

1. Create host _TargetHostName_ on _ZabbixServer_;
2. Create "Zabbix trapper" item inside _TargetHostName_; 
3. Run _Windows Form window finder_ script on PC or Server with _-Verbose_ key, and check result.

**Note**
The _Windows Form window finder_ script must be executed in the User session to be able enumerate Form windows. You can run it minimized from Startup folder of User Menu or use another way.
