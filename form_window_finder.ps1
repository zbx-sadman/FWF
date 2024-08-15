<#                                          
    .SYNOPSIS  
        Windows Form window finder

    .DESCRIPTION
        Periodically searches specified Windows UI Form window (App / Dialog / Error popup / etc), and send number of found instances to the ZabbixServer.
        Installed zabbix_sender utility, and "Zabbix trapper" item are requred.

    .NOTES  
        Version: 1.0
        Name: Form window finder
        Author: zbx.sadman@gmail.com
        DateCreated: 15AUG2024
        Testing environment: Windows 10

    .LINK  
        https://github.com/zbx-sadman/WFF

    .PARAMETER WindowTitle
        Title of searched Form window.

    .PARAMETER SleepSeconds
        Idle duration between search attempts.

    .PARAMETER ZabbixServer
        IP-address or FDQN-name of Zabbix Server.

    .PARAMETER TargetHostName
        Host name (as shown on the Zabbix UI) which contain $TargetKeyName.

    .PARAMETER TargetKeyName
        "Zabbix trapper" item key, which stored number of found window instances.

    .PARAMETER Verbose
        Enable verbose messages

    .EXAMPLE 
        powershell  -NoProfile -ExecutionPolicy "RemoteSigned" -File "windows_form_finder.ps1" -WindowTitle "Error *" -SleepSecond 30 -ZabbixServer 172.16.16.172 -TargetHostName "BuggedPC" -TargetKeyName "windows.form.count[AllErrorWindows]"

        Description
        -----------  
        Searching every 30 sec for "Error *" (wildcard used) titled Form windows, and sending number of found instances to 172.16.16.172, item "windows.form.count[AllErrorWindows]", linked to "BuggedPC" host.
#>


Param (
   [Parameter(Mandatory = $False)] 
   [String]$WindowTitle,
   [Parameter(Mandatory = $False)]
   [String]$SleepSeconds,
   [Parameter(Mandatory = $True)]
   [String]$ZabbixServer,
   [Parameter(Mandatory = $True)]
   [String]$TargetHostName,
   [Parameter(Mandatory = $True)]
   [String]$TargetKeyName
);


$TypeDef = @"

using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace Api
{

 public class WinStruct
 {
   public string WinTitle {get; set; }
   public int WinHwnd { get; set; }
 }

 public class ApiDef
 {
   private delegate bool CallBackPtr(int hwnd, int lParam);
   private static CallBackPtr callBackPtr = Callback;
   private static List<WinStruct> _WinStructList = new List<WinStruct>();

   [DllImport("User32.dll")]
   [return: MarshalAs(UnmanagedType.Bool)]
   private static extern bool EnumWindows(CallBackPtr lpEnumFunc, IntPtr lParam);

   [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
   static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

   private static bool Callback(int hWnd, int lparam)
   {
       StringBuilder sb = new StringBuilder(256);
       int res = GetWindowText((IntPtr)hWnd, sb, 256);
      _WinStructList.Add(new WinStruct { WinHwnd = hWnd, WinTitle = sb.ToString() });
       return true;
   }   

   public static List<WinStruct> GetWindows()
   {
      _WinStructList = new List<WinStruct>();
      EnumWindows(callBackPtr, IntPtr.Zero);
      return _WinStructList;
   }

 }
}
"@

Add-Type -TypeDefinition $TypeDef -Language CSharp 

$SleepTime = $(if ([String]::IsNullorEmpty($SleepSeconds)) { 10 }  else { $SleepSeconds } ); 
$SearchedWindowTitle = $(if ([String]::IsNullorEmpty($WindowTitle))  { "*" } else { $WindowTitle } ); 

while ($True) 
{

  Write-Verbose "$(Get-Date) Search Form '$SearchedWindowTitle'...";

  $FoundWindowList = [Api.Apidef]::GetWindows() | Where-Object { $_.WinTitle -like $SearchedWindowTitle }
  $FoundWindowCount = @($FoundWindowList).Count;
  if (0 -ne $FoundWindowCount) {
    $Report = "$(Get-Date) Found $FoundWindowCount instances: " + ($FoundWindowList | Select-Object WinTitle,@{Name="Handle"; Expression={"{0:X0}" -f $_.WinHwnd}} | Out-String);
  } else {
    $Report = "$(Get-Date) No Window found";
  }
  Write-Verbose $Report;
 
  Write-Verbose "$(Get-Date) Send '$FoundWindowCount' to $ZabbixServer / $TargetHostName / $TargetKeyName";
  $ArgList = "-z $ZabbixServer -s `"$TargetHostName`" -k `"$TargetKeyName`" -o `"$FoundWindowCount`"";
#  Write-Verbose $ArgList
  Start-Process -NoNewWindow -Wait -FilePath 'C:\Program Files\Zabbix Agent\zabbix_sender.exe' -ArgumentList $ArgList;

  Write-Verbose "$(Get-Date) Sleep for $SleepTime secs";
  Start-Sleep -Seconds $SleepTime;

}
