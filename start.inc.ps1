<#
.SYNOPSIS
    A universal script that defines 'Start-UniversalApps' for:
    - Browser (Edge, Chrome, Firefox, Brave, PaleMoon, Vivaldi, Opera) + Tabs
    - (Optional) Microsoft Teams
    - (Optional) Outlook

.DESCRIPTION
    - Stops existing processes for each requested app (browser, Teams, Outlook).
    - Starts each app.
    - Positions each app on a specific monitor (by index) and coordinates (X,Y).
    - Allows optional Zoom-Out for the browser using Ctrl + '-'.
    - Has default values for all parameters so the caller script only needs to override what's desired.

.NOTES
    - Nothing runs automatically. This script only defines the function.
    - Call from another script via dot-sourcing or Import-Module.
#>

function Start-UniversalApps {
    param(
        # ------------------------------------------------------
        # Browser / Tabs
        # ------------------------------------------------------
        [Parameter(Mandatory=$false)]
        [ValidateSet("Edge","Chrome","Firefox","Brave","PaleMoon","Vivaldi","Opera")]
        [string]$BrowserName = "Edge",

        [Parameter(Mandatory=$false)]
        [string[]]$TabURLs = @("https://www.bing.com"),

        [int]$BrowserMonitorIndex = 0,
        [int]$BrowserX = 100,
        [int]$BrowserY = 100,
        [int]$BrowserWidth = 1200,
        [int]$BrowserHeight = 800,
        [int]$BrowserZoomOutCount = 0,

        # ------------------------------------------------------
        # Teams
        # ------------------------------------------------------
        [bool]$StartTeams = $false,
        [string[]]$TeamsProcessNames = @("Teams","ms-teams"),
        [string[]]$TeamsExecutablePaths = @(
            "$env:LOCALAPPDATA\Microsoft\WindowsApps\ms-teams.exe",
            "$env:LOCALAPPDATA\Microsoft\Teams\current\Teams.exe"
        ),
        [int]$TeamsMonitorIndex = 0,
        [int]$TeamsX = 50,
        [int]$TeamsY = 50,
        [int]$TeamsWidth = 1000,
        [int]$TeamsHeight = 700,

        # ------------------------------------------------------
        # Outlook
        # ------------------------------------------------------
        [bool]$StartOutlook = $false,
        # The process name is consistent on most systems as "OUTLOOK"
        # (not mandatory to override).
        [string]$OutlookExe = "OUTLOOK.EXE",
        [int]$OutlookMonitorIndex = 0,
        [int]$OutlookX = 100,
        [int]$OutlookY = 100,
        [int]$OutlookWidth = 900,
        [int]$OutlookHeight = 700
    )

    # This is the default process name we see in Get-Process.  
    # We'll keep it internal so the caller doesn't need to set it.
    $OutlookProcessName = "OUTLOOK"

    # ----------------------------------------------------------
    #                      Helper Functions
    # ----------------------------------------------------------

    # region Get-BrowserDefinition
    function Get-BrowserDefinition {
        param ([string]$BrowserName)
        switch ($BrowserName.ToLower()) {
            'firefox' {
                return [PSCustomObject]@{
                    DisplayName = 'Firefox'
                    ProcessName = 'firefox'
                    ExePath     = 'firefox.exe'
                }
            }
            'chrome' {
                return [PSCustomObject]@{
                    DisplayName = 'Chrome'
                    ProcessName = 'chrome'
                    ExePath     = 'chrome.exe'
                }
            }
            'edge' {
                return [PSCustomObject]@{
                    DisplayName = 'Edge'
                    ProcessName = 'msedge'
                    ExePath     = 'msedge.exe'
                }
            }
            'brave' {
                return [PSCustomObject]@{
                    DisplayName = 'Brave'
                    ProcessName = 'brave'
                    ExePath     = 'brave.exe'
                }
            }
            'palemoon' {
                return [PSCustomObject]@{
                    DisplayName = 'Pale Moon'
                    ProcessName = 'palemoon'
                    ExePath     = 'C:\Program Files\Pale Moon\palemoon.exe'
                }
            }
            'vivaldi' {
                return [PSCustomObject]@{
                    DisplayName = 'Vivaldi'
                    ProcessName = 'vivaldi'
                    # Adjust if your path is different
                    ExePath     = 'C:\Users\info\AppData\Local\Vivaldi\Application\vivaldi.exe'
                }
            }
            'opera' {
                return [PSCustomObject]@{
                    DisplayName = 'Opera'
                    ProcessName = 'opera'
                    ExePath     = 'c:\Users\info\AppData\Local\programs\Opera\opera.exe'
                }
            }
            default {
                Write-Warning "Browser '$BrowserName' not recognized. Using 'Chrome' by default."
                return [PSCustomObject]@{
                    DisplayName = 'Chrome'
                    ProcessName = 'chrome'
                    ExePath     = 'chrome.exe'
                }
            }
        }
    }
    # endregion

    # region Stop-ProcessesByName
    function Stop-ProcessesByName {
        param ([string[]]$ProcessNames)
        foreach ($procName in $ProcessNames) {
            $processes = Get-Process -Name $procName -ErrorAction SilentlyContinue
            if ($processes) {
                Write-Host "Stopping process(es) named '$procName'..."
                try {
                    $processes | Stop-Process -Force -ErrorAction Stop
                    Write-Host "  Successfully stopped '$procName'."
                }
                catch {
                    Write-Warning "  Failed to stop '$procName'. Permissions?"
                }
                Start-Sleep -Seconds 1
            }
            else {
                Write-Host "No running processes found named '$procName'."
            }
        }
    }
    # endregion

    # region Start-Browser
    function Start-Browser {
        param (
            [string]$ExePath,
            [string[]]$TabURLs
        )
        Write-Host "Starting browser ($ExePath)..."
        try {
            $urls = $TabURLs -join " "
            Start-Process $ExePath -ArgumentList $urls
            Write-Host "  $ExePath started with tabs."
        }
        catch {
            Write-Error "Failed to start $ExePath. Check installation/PATH."
        }
    }
    # endregion

    # region Start-Teams
    function Start-Teams {
        param([string[]]$TeamsExecutablePaths)
        Write-Host "Starting Microsoft Teams..."
        foreach ($path in $TeamsExecutablePaths) {
            if (Test-Path $path) {
                try {
                    Start-Process $path
                    Write-Host "  Teams started from '$path'."
                    return
                }
                catch {
                    Write-Warning "  Failed to start Teams from '$path'. Trying next..."
                }
            }
            else {
                Write-Host "  Teams not found at '$path'."
            }
        }
        Write-Error "Failed to start Teams. No valid path found."
    }
    # endregion

    # region Start-Outlook
    function Start-Outlook {
        param([string]$OutlookExe)
        Write-Host "Starting Outlook..."
        try {
            Start-Process $OutlookExe -ErrorAction Stop
            Write-Host "  Outlook started successfully."
        }
        catch {
            Write-Error "Failed to start Outlook. Ensure Outlook is installed and '$OutlookExe' is in PATH."
        }
    }
    # endregion

    # region Wait-ForProcess
    function Wait-ForProcess {
        param ([string]$ProcessName, [int]$TimeoutSeconds = 60)
        $elapsed = 0
        while (-not (Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)) {
            Write-Host "Waiting for process '$ProcessName'... ($elapsed s)"
            Start-Sleep -Seconds 1
            $elapsed++
            if ($elapsed -ge $TimeoutSeconds) {
                Write-Warning "Timed out waiting for '$ProcessName'. Continuing..."
                return
            }
        }
        Write-Host "Process '$ProcessName' is now running."
    }
    # endregion

    # region Get/Wait-ForWindowHandle
    function Get-WindowHandleByProcessName {
        param ([string]$ProcessName)

        $processes = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
        if (!$processes) {
            return [IntPtr]::Zero
        }

        Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WindowFinder {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    public static IntPtr FindWindowFromProcessId(int processId) {
        IntPtr found = IntPtr.Zero;
        EnumWindows(delegate(IntPtr hWnd, IntPtr lParam) {
            uint pid;
            GetWindowThreadProcessId(hWnd, out pid);
            if (pid == (uint)lParam.ToInt32()) {
                if (IsWindowVisible(hWnd)) {
                    found = hWnd;
                    return false; // found
                }
            }
            return true;
        }, new IntPtr(processId));
        return found;
    }
}
"@ -ErrorAction SilentlyContinue

        foreach ($p in $processes) {
            $handle = [WindowFinder]::FindWindowFromProcessId($p.Id)
            if ($handle -ne [IntPtr]::Zero) {
                return $handle
            }
        }
        return [IntPtr]::Zero
    }

    function Wait-ForWindowHandle {
        param (
            [string]$ProcessName,
            [int]$TimeoutSeconds = 60
        )
        $elapsed = 0
        $handle = [IntPtr]::Zero
        while ($handle -eq [IntPtr]::Zero -and $elapsed -lt $TimeoutSeconds) {
            $handle = Get-WindowHandleByProcessName -ProcessName $ProcessName
            if ($handle -eq [IntPtr]::Zero) {
                Start-Sleep 1
                $elapsed++
            }
        }
        return $handle
    }
    # endregion

    # region Send-ZoomOut
    function Send-ZoomOut {
        param ([IntPtr]$WindowHandle, [int]$Count = 3)

        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        Add-Type -Namespace Util -Name User32 -MemberDefinition @"
using System;
using System.Runtime.InteropServices;
public class User32 {
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
}
"@

        [Util.User32]::SetForegroundWindow($WindowHandle) | Out-Null

        for ($i = 1; $i -le $Count; $i++) {
            [System.Windows.Forms.SendKeys]::SendWait("^-")
            Start-Sleep -Milliseconds 300
        }
    }
    # endregion

    # region Move-Window
    function Move-Window {
        param ([IntPtr]$WindowHandle, [int]$X, [int]$Y, [int]$Width, [int]$Height)
        Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@ -ErrorAction SilentlyContinue

        $SW_RESTORE = 9
        [Win32]::ShowWindow($WindowHandle, $SW_RESTORE) | Out-Null
        [Win32]::MoveWindow($WindowHandle, $X, $Y, $Width, $Height, $true) | Out-Null
    }
    # endregion

    # region Get-MonitorOffset
    function Get-MonitorOffset {
        param([int]$MonitorIndex)
        Add-Type -AssemblyName System.Windows.Forms

        $allScreens = [System.Windows.Forms.Screen]::AllScreens
        if ($MonitorIndex -ge $allScreens.Count) {
            throw "Monitor #$MonitorIndex not found. Found $($allScreens.Count) monitor(s)."
        }
        return $allScreens[$MonitorIndex].Bounds
    }
    # endregion

    # ----------------------------------------------------------
    #                 Main Execution Flow
    # ----------------------------------------------------------
    Write-Host "`n=== [Start-UniversalApps] Browser=$BrowserName, StartTeams=$StartTeams, StartOutlook=$StartOutlook ==="

    # 1) Gather browser info
    $browserInfo = Get-BrowserDefinition -BrowserName $BrowserName

    # 2) Stop processes for Browser, Teams, Outlook
    Stop-ProcessesByName -ProcessNames @($browserInfo.ProcessName)

    if ($StartTeams) {
        Stop-ProcessesByName -ProcessNames $TeamsProcessNames
    }

    if ($StartOutlook) {
        # Our default Outlook process name is "OUTLOOK"
        Stop-ProcessesByName -ProcessNames @("OUTLOOK")
    }

    # 3) Start the apps
    Start-Browser -ExePath $browserInfo.ExePath -TabURLs $TabURLs

    if ($StartTeams) {
        Start-Teams -TeamsExecutablePaths $TeamsExecutablePaths
    }

    if ($StartOutlook) {
        Start-Outlook -OutlookExe $OutlookExe
    }

    # 4) Wait for processes
    Wait-ForProcess -ProcessName $browserInfo.ProcessName -TimeoutSeconds 60

    if ($StartTeams) {
        foreach ($pName in $TeamsProcessNames) {
            Wait-ForProcess -ProcessName $pName -TimeoutSeconds 60
        }
    }

    if ($StartOutlook) {
        Wait-ForProcess -ProcessName "OUTLOOK" -TimeoutSeconds 60
    }

    # 5) Get window handles
    $browserHandle = Wait-ForWindowHandle -ProcessName $browserInfo.ProcessName -TimeoutSeconds 60

    $teamsHandle = [IntPtr]::Zero
    if ($StartTeams) {
        foreach ($pName in $TeamsProcessNames) {
            $teamsHandle = Wait-ForWindowHandle -ProcessName $pName -TimeoutSeconds 60
            if ($teamsHandle -ne [IntPtr]::Zero) { break }
        }
    }

    $outlookHandle = [IntPtr]::Zero
    if ($StartOutlook) {
        $outlookHandle = Wait-ForWindowHandle -ProcessName "OUTLOOK" -TimeoutSeconds 60
    }

    # 6) Position Browser
    if ($browserHandle -ne [IntPtr]::Zero) {
        $bMonitor = Get-MonitorOffset -MonitorIndex $BrowserMonitorIndex
        $finalBX = $bMonitor.X + $BrowserX
        $finalBY = $bMonitor.Y + $BrowserY

        Move-Window -WindowHandle $browserHandle `
                    -X $finalBX `
                    -Y $finalBY `
                    -Width $BrowserWidth `
                    -Height $BrowserHeight

        if ($BrowserZoomOutCount -gt 0) {
            Send-ZoomOut -WindowHandle $browserHandle -Count $BrowserZoomOutCount
        }
    }

    # 7) Position Teams
    if ($StartTeams -and $teamsHandle -ne [IntPtr]::Zero) {
        $tMonitor = Get-MonitorOffset -MonitorIndex $TeamsMonitorIndex
        $finalTX = $tMonitor.X + $TeamsX
        $finalTY = $tMonitor.Y + $TeamsY

        Move-Window -WindowHandle $teamsHandle `
                    -X $finalTX `
                    -Y $finalTY `
                    -Width $TeamsWidth `
                    -Height $TeamsHeight
    }

    # 8) Position Outlook
    if ($StartOutlook -and $outlookHandle -ne [IntPtr]::Zero) {
        $oMonitor = Get-MonitorOffset -MonitorIndex $OutlookMonitorIndex
        $finalOX = $oMonitor.X + $OutlookX
        $finalOY = $oMonitor.Y + $OutlookY

        Move-Window -WindowHandle $outlookHandle `
                    -X $finalOX `
                    -Y $finalOY `
                    -Width $OutlookWidth `
                    -Height $OutlookHeight
    }

    Write-Host "`n[Done] Start-UniversalApps finished!"
}
