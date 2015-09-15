################################################################################
# Rise Vision Player Installer                                                 #
# Copyright (C) 2010 Rise Vision Inc                                           #
#                                                                              #
# This program is free software; you can redistribute it and/or modify         #
# it under the terms of the GNU General Public License as published by         #
# the Free Software Foundation; either version 2 of the License, or            #
# (at your option) any later version.                                          #
#                                                                              #
# This program is distributed in the hope that it will be useful,              #
# but WITHOUT ANY WARRANTY; without even the implied warranty of               #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                #
# GNU General Public License for more details.                                 #
#                                                                              #
# You should have received a copy of the GNU General Public License along      #
# with this program; if not, write to the Free Software Foundation, Inc.,      #
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.                  #
#                                                                              #
# http://www.gnu.org/licenses/gpl-2.0.txt                                      #
################################################################################

; Global Symbols

!define PRODUCTION_VERSION
;!define TEST_VERSION
;!define LOCAL_TEST_VERSION

!ifdef PRODUCTION_VERSION

	!echo "Building production version"
	
	!define CurrentInstallerVersion "2.4.0000win"
	!define CoreURL "https://rvaserver2.appspot.com"
	!define ViewerURL "http://rvashow.appspot.com/Viewer.html"

!else ifdef TEST_VERSION

	!echo "Building test version"
	
	!define CurrentInstallerVersion "2.4.0000win"
	!define CoreURL "https://rvacore-test.appspot.com"
	!define ViewerURL "http://viewer-test.appspot.com/Viewer.html"

!else ifdef LOCAL_TEST_VERSION

	!echo "Building local test version"
	
	!define CurrentInstallerVersion "2.2.00038-local-test"
	!define CoreURL "http://localhost/temp"
	!define ViewerURL "http://viewer-test.appspot.com/Viewer.html"

!endif

!define PlayerUpdatePath "/v2/player/components?os=win" ; &id=displayID        ;(displayId is optional)
!define InstallerDownloadPath_v1 "/player/download?os=win&displayId=" ;code to support rollback to Player 1
!define BaseName "RiseVisionPlayer"
!define ChromiumZIP "chrome-win32.zip"
!define JavaZIP "jre-win32.zip"
!define RiseCacheZIP "RiseCache.zip"
!define RisePlayerZIP "RisePlayer.zip"
!define PlayerMutexName "RiseVisionPlayerInstallerMutex100"

!define DisplayIdFile "RiseDisplayNetworkII.ini"

;!define RiseCachePingURL "http://localhost:9494/ping?callback=test"
!define RiseCacheShutdownURL "http://localhost:9494/shutdown"

;!define RisePlayerPingURL "http://localhost:9449/ping?callback=test"
!define RisePlayerShutdownURL "http://localhost:9449/shutdown"
;!define RisePlayerUpgradeURL "http://localhost:9449/get_upgrade_info"

Name "Rise Vision Player"
Caption "Rise Vision Player"
BrandingText "Rise Vision Player v${CurrentInstallerVersion}"

# MultiUser Symbol Definitions
!define MULTIUSER_EXECUTIONLEVEL Standard
!define MULTIUSER_NOUNINSTALL
!define MULTIUSER_INSTALLMODE_COMMANDLINE
!define MULTIUSER_INSTALLMODE_INSTDIR "RVPlayer"

# MUI Symbol Definitions
!define MUI_FINISHPAGE_NOAUTOCLOSE

!define LOGFILE "$INSTDIR\installer0.log"
!define LOGFILE2 "$INSTDIR\installer1.log"
!define MAXLOGFILESIZE 10240000 ;3K per day, 3Kx30=90K=921600B

# Included files
!include FileFunc.nsh
!include TextFunc.nsh
!include MultiUser.nsh
!include Sections.nsh
!include MUI2.nsh
!include WinVer.nsh
!include zipdll.nsh
!include Utils.nsh
!include Java.nsh
!include RiseCache.nsh
!include RisePlayer.nsh
!include Chromium.nsh

!define MUI_ICON "setup.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "setup.ico"
!define MUI_HEADERIMAGE_RIGHT

# define UI for license page (Page settings apply to a single page and should be set before inserting a page macro.)
!define MUI_PAGE_CUSTOMFUNCTION_PRE LicensePagePre
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE LicensePageLeave
!define MUI_PAGE_HEADER_TEXT "Terms of Service and Privacy"
!define MUI_LICENSEPAGE_TEXT_TOP ""
!define MUI_PAGE_HEADER_SUBTEXT ""
#!define MUI_LICENSEPAGE_HEADER_TEXT "Terms of Service and Privacy"
!define MUI_LICENSEPAGE_TEXT_BOTTOM " "
!define MUI_LICENSEPAGE_CHECKBOX
!define MUI_LICENSEPAGE_CHECKBOX_TEXT "I agree with the Terms of Service and Privacy"

!insertmacro MUI_PAGE_LICENSE "license.rtf"
!insertmacro MUI_PAGE_INSTFILES

!define MUI_TEXT_FINISH_SUBTITLE ""

!define MUI_PAGE_CUSTOMFUNCTION_LEAVE FinishPageLeave
!define MUI_FINISHPAGE_RUN 
!define MUI_FINISHPAGE_RUN_FUNCTION "CreateStartupShortcut"
!define MUI_FINISHPAGE_TITLE ""
!define MUI_FINISHPAGE_TEXT "Rise Vision Player will start automatically when this computer starts, if you want to manually start Rise Vision Player please uncheck Run On Startup.$\n$\nThank you for installing Rise Vision Player!$\n$\n"
!define MUI_FINISHPAGE_RUN_TEXT "Run On Startup"
!insertmacro MUI_PAGE_FINISH

!define MUI_TEXT_ABORT_TITLE "Installation Failed"
!define MUI_TEXT_ABORT_SUBTITLE ""
  
# Installer languages
!insertmacro MUI_LANGUAGE "English"

# Installer attributes
OutFile "rvplayer-installer.exe"
;InstallDir "Rise Vision Player"
CRCCheck on
XPStyle on
ShowInstDetails show
InstallDir "$LOCALAPPDATA\RVPlayer"
Icon "setup.ico"
InstallColors /windows

; Sub Captions
SubCaption 0 " "
SubCaption 1 " "
SubCaption 2 "Installing Rise Vision Player"
SubCaption 3 " "
SubCaption 4 " "

; Pages
#Page instfiles

; Vars
Var Current
Var Revision
Var TempURL
Var TempFile
Var DisplayId
Var ClaimId
Var Hidden
Var MutexHandle

Var InstallerVersion
Var InstallerURL
Var InstallerUpgradeRequired

Var CurrentChromiumVersion
Var ChromiumVersion
Var ChromiumURL

Var CurrentJavaVersion
Var JavaVersion
Var JavaURL

Var CurrentRiseCacheVersion
Var RiseCacheVersion
Var RiseCacheURL

Var CurrentRisePlayerVersion
Var RisePlayerVersion
Var RisePlayerURL

Var UpgradeNeeded
Var InstallerExeName

Var StartupShortcutSelected

Var RightPart

Var FirstRun
var Errors
    
Var ViewerURLLocal
Var CoreURLLocal    

RequestExecutionLevel user
;SilentInstall silent
;AutoCloseWindow true

; Configuration file parameters
Var ForceStable
Var LatestRolloutPercent

Var BrowserVersionStable
Var BrowserURLStable
Var BrowserVersionLatest
Var BrowserURLLatest

Var JavaVersionStable
Var JavaURLStable
Var JavaVersionLatest
Var JavaURLLatest

Var CacheVersionStable
Var CacheURLStable
Var CacheVersionLatest
Var CacheURLLatest

Var PlayerVersionStable
Var PlayerURLStable
Var PlayerVersionLatest
Var PlayerURLLatest

Var BrowserUpgradeable

# Installer sections
Section -Main SEC0000

    ${CheckLogFileSize}

    IfFileExists "$INSTDIR\installer.ver" NotFirstRun 0
    StrCpy $FirstRun "1"
    
    NotFirstRun:
    
    SetDetailsPrint None
    InitPluginsDir
    SetOutPath $INSTDIR
    
    StrCpy $ChromiumVersion "0"
    StrCpy $Hidden "0" 
    
    IfSilent 0 StartInstall
    
    StrCpy $Hidden "1" 
    HideWindow
        
    ;-------------------
    ; Initialization
      
    StartInstall:
        
    ${DetailPrint} "Saving installer version information..."
    ClearErrors
    FileOpen $0 "$INSTDIR\installer.ver" w
    IfErrors SkipWriteInstalerVersion
    FileWrite $0 ${CurrentInstallerVersion}
    FileClose $0

    SkipWriteInstalerVersion:

    ;CheckForUpdates:
    
    ;nsislog::log "$INSTDIR\RiseVisionPlayer.log" "Starting the installation..."
    ${DetailPrint} "Starting the installation..."
 ;   ${ListPrint} "Installing to" $INSTDIR
    
    StrCpy $Revision ""
    StrCpy $Current ""

    ;get DisplayId and ClaimId
    ${ExtractDisplayId}
    
    ;-------------------
    ; Checking for updates

    StrCpy $InstallerUpgradeRequired "0"   

    StrCpy $CurrentChromiumVersion ""
    StrCpy $ChromiumVersion ""
    StrCpy $ChromiumURL ""

    StrCpy $CurrentJavaVersion ""
    StrCpy $JavaVersion ""
    StrCpy $JavaURL ""

    StrCpy $CurrentRiseCacheVersion ""
    StrCpy $RiseCacheVersion ""
    StrCpy $RiseCacheURL ""

    StrCpy $CurrentRisePlayerVersion ""
    StrCpy $RisePlayerVersion ""
    StrCpy $RisePlayerURL ""

    StrCpy $UpgradeNeeded "no"

    ;--------------
    IfFileExists "$INSTDIR\RisePlayer.ver" 0 SkipRisePlayerVersionDetection
    ClearErrors
    FileOpen $0 "$INSTDIR\RisePlayer.ver" r
    IfErrors SkipRisePlayerVersionDetection
    FileRead $0 $CurrentRisePlayerVersion
    FileClose $0
    
    SkipRisePlayerVersionDetection:
    ${ListPrint} "Currently installed RisePlayer version" $CurrentRisePlayerVersion
    
    ;--------------
    IfFileExists "$INSTDIR\RiseCache.ver" 0 SkipRiseCacheVersionDetection
    ClearErrors
    FileOpen $0 "$INSTDIR\RiseCache.ver" r
    IfErrors SkipRiseCacheVersionDetection
    FileRead $0 $CurrentRiseCacheVersion
    FileClose $0
    
    SkipRiseCacheVersionDetection:
    ${ListPrint} "Currently installed RiseCache version" $CurrentRiseCacheVersion
           
    ;--------------
    IfFileExists "$INSTDIR\java.ver" 0 SkipJavaVersionDetection
    ClearErrors
    FileOpen $0 "$INSTDIR\java.ver" r
    IfErrors SkipJavaVersionDetection
    FileRead $0 $CurrentJavaVersion
    FileClose $0
    
    SkipJavaVersionDetection:
    ${ListPrint} "Currently installed Java version" $CurrentJavaVersion

    ;--------------
    IfFileExists "$INSTDIR\chromium.ver" 0 SkipChromiumVersionDetection
    ClearErrors
    FileOpen $0 "$INSTDIR\chromium.ver" r
    IfErrors SkipChromiumVersionDetection
    FileRead $0 $CurrentChromiumVersion
    FileClose $0
   
    SkipChromiumVersionDetection:
    ${ListPrint} "Currently installed Chromium build" $CurrentChromiumVersion

    ;--------------    
    
    ;StrCpy $TempURL "${CoreURL}${PlayerUpdatePath}&id=$DisplayId"
    StrCpy $TempURL "http://install-versions.risevision.com/remote-components-win.cfg"
    ${DetailPrint} "Retrieving update from $TempURL, please wait..."

    ${Download} "silent" "Downloading update..." "$TempURL" "$PLUGINSDIR\${BaseName}.config" "true"
    
    Pop $R0
    StrCmp $R0 "OK" SetVariables

    ${DetailPrint} "Unable to retrieve update at this time."
    StrCpy $Errors "$Errors$\n$\tUnable to retrieve update at this time."
    Goto DeleteConfig
    
    SetVariables:
    ClearErrors
    
    ${ConfigRead} "$PLUGINSDIR\${BaseName}.config" "InstallerVersion=" $InstallerVersion
    ${ConfigRead} "$PLUGINSDIR\${BaseName}.config" "InstallerURL=" $InstallerURL    

    ${ConfigRead} "$PLUGINSDIR\${BaseName}.config" "ForceStable=" $ForceStable
    ${ConfigRead} "$PLUGINSDIR\${BaseName}.config" "LatestRolloutPercent=" $LatestRolloutPercent
    ${ConfigRead} "$PLUGINSDIR\${BaseName}.config" "BrowserVersionStable=" $BrowserVersionStable
    ${ConfigRead} "$PLUGINSDIR\${BaseName}.config" "BrowserVersionLatest=" $BrowserVersionLatest
    ${ConfigRead} "$PLUGINSDIR\${BaseName}.config" "BrowserURLStable=" $BrowserURLStable
    ${ConfigRead} "$PLUGINSDIR\${BaseName}.config" "BrowserURLLatest=" $BrowserURLLatest
    ${ConfigRead} "$PLUGINSDIR\${BaseName}.config" "JavaVersionStable=" $JavaVersionStable
    ${ConfigRead} "$PLUGINSDIR\${BaseName}.config" "JavaVersionLatest=" $JavaVersionLatest
    ${ConfigRead} "$PLUGINSDIR\${BaseName}.config" "JavaURLStable=" $JavaURLStable
    ${ConfigRead} "$PLUGINSDIR\${BaseName}.config" "JavaURLLatest=" $JavaURLLatest
    ${ConfigRead} "$PLUGINSDIR\${BaseName}.config" "PlayerVersionStable=" $PlayerVersionStable
    ${ConfigRead} "$PLUGINSDIR\${BaseName}.config" "PlayerVersionLatest=" $PlayerVersionLatest
    ${ConfigRead} "$PLUGINSDIR\${BaseName}.config" "PlayerURLStable=" $PlayerURLStable
    ${ConfigRead} "$PLUGINSDIR\${BaseName}.config" "PlayerURLLatest=" $PlayerURLLatest
    ${ConfigRead} "$PLUGINSDIR\${BaseName}.config" "CacheVersionStable=" $CacheVersionStable
    ${ConfigRead} "$PLUGINSDIR\${BaseName}.config" "CacheVersionLatest=" $CacheVersionLatest
    ${ConfigRead} "$PLUGINSDIR\${BaseName}.config" "CacheURLStable=" $CacheURLStable
    ${ConfigRead} "$PLUGINSDIR\${BaseName}.config" "CacheURLLatest=" $CacheURLLatest

    ; ForceStable takes precedence over everything else
    StrCmp $ForceStable "true" UseStableChannel
    ; If already on latest, stay on latest
    StrCmp $CurrentRisePlayerVersion $PlayerVersionLatest UseUnstableChannel
    ; Random number to check if installer should use stable or unstable channel
    ${Rnd} $0 0 99
    ; IntComp value1 value2 do_if_equal do_if_value1_lt_value2 do_if_value1_gt_value2
    IntCmp $0 $LatestRolloutPercent 0 UseUnstableChannel UseStableChannel

    UseUnstableChannel:
    StrCpy $ChromiumVersion $BrowserVersionLatest
    StrCpy $ChromiumURL $BrowserURLLatest
    StrCpy $JavaVersion $JavaVersionLatest
    StrCpy $JavaURL $JavaURLLatest
    StrCpy $RisePlayerVersion $PlayerVersionLatest
    StrCpy $RisePlayerURL $PlayerURLLatest
    StrCpy $RiseCacheVersion $CacheVersionLatest
    StrCpy $RiseCacheURL $CacheURLLatest

    Goto ValidateInstalledVersions

    UseStableChannel:
    StrCpy $ChromiumVersion $BrowserVersionStable
    StrCpy $ChromiumURL $BrowserURLStable
    StrCpy $JavaVersion $JavaVersionStable
    StrCpy $JavaURL $JavaURLStable
    StrCpy $RisePlayerVersion $PlayerVersionStable
    StrCpy $RisePlayerURL $PlayerURLStable
    StrCpy $RiseCacheVersion $CacheVersionStable
    StrCpy $RiseCacheURL $CacheURLStable

    ValidateInstalledVersions:

	${DetailPrint} "PlayerURL= $RisePlayerURL"
	${DetailPrint} "CacheURL= $RiseCacheURL"
    StrCmp ${CurrentInstallerVersion} $InstallerVersion InstallerUpgradeIsNotRequired
    StrCpy $InstallerUpgradeRequired "1"
    
    ;--- begin code to support rollback to Player 1
    StrCpy $0 $InstallerVersion 2 # copy first 2 characters
    StrCmp $0 "1." 0 SkipInstallerFix_v1 # check if Installer veresion starts with 1 (i.e. Player 1 installer)
    StrCpy $InstallerExeName "${BaseName}_$DisplayId.exe"
    StrCpy $InstallerURL "${CoreURL}${InstallerDownloadPath_v1}$DisplayId"
    
    ${DetailPrint} "Creating startup shortcut for Player 1..."
    SetOutPath $SMSTARTUP
    CreateShortcut "$SMSTARTUP\Start Rise Vision Player.lnk" "$INSTDIR\$InstallerExeName" "/S"
    
    SkipInstallerFix_v1:
    ;--- end code code to support rollback to Player 1
    
    InstallerUpgradeIsNotRequired:

    ;------------------
    ; patch for Core API not supporting Java, RiseCache, and RisePlayer products.
;    StrCmp $JavaVersion "" 0 +3
;    StrCpy $JavaVersion "7.9"
;    StrCpy $JavaURL "http://ef9507f9e45b5c673653-87f4c042133f43dfb869f7803a2c4f88.r20.cf2.rackcdn.com/jre-7.9-32bit.zip"
; 
;    StrCmp $RisePlayerVersion "" 0 +3
;    StrCpy $RisePlayerVersion "2.0.004"
;    StrCpy $RisePlayerURL "http://3a5d4246319acd95b71f-b1cb9f3373536e241d61b8ebb26f3e79.r61.cf2.rackcdn.com/RisePlayer-2.0.004.zip"
;
;    StrCmp $RiseCacheVersion "" 0 +3
;    StrCpy $RiseCacheVersion "1.0.004"
;    StrCpy $RiseCacheURL "http://81171fc5f892715ca8fe-f4a92021f5079607bd5dfda6d63b7185.r17.cf2.rackcdn.com/RiseCache-1.0.004.zip"
        
    ;${ListPrint} "Restart" $RestartRequired
    ;${ListPrint} "InstallerUpgrade" $InstallerUpgradeRequired
    ;${ListPrint} "ChromiumVersion" $ChromiumVersion
    ;${ListPrint} "ChromiumURL" $ChromiumURL
    ;${ListPrint} "JavaVersion" $JavaVersion
    ;${ListPrint} "JavaURL" $JavaURL
        
    DeleteConfig:
    Delete "$PLUGINSDIR\${BaseName}.config"
           
    ;-------------------
    ; Installer upgrade
    
    ${GetCLIParameterValue} "/update-installer=" "yes"
    pop $R0
    
    StrCmp $R0 "no" SkipInstallerUpdate 0
    
    StrCmp $InstallerUpgradeRequired "1" NewInstaller InstallerUpToDate
       
    NewInstaller:
     
    ClearErrors
    ;StrCpy $TempURL "${CoreURL}${InstallerDownloadPath}"
    ;StrCpy $TempFile "$DisplayId"
    StrCmp $InstallerURL "" SkipInstallerUpdate    

    ${DetailPrint} "Downloading new version of the installer, please wait..."
    
    ${Download} "silent" "Downloading installer..." "$InstallerURL" "$PLUGINSDIR\$InstallerExeName" "true"
    
    Pop $R0
    StrCmp $R0 "OK" CloseInstaller
    
    ${DetailPrint} "Unable to update the installer at this time. $R0"
    StrCpy $Errors "$Errors\n$\tUnable to update the installer at this time. $R0"
    
    Goto SkipInstallerUpdate
        
    InstallerUpToDate:

    ${DetailPrint} "The installer is up-to-date."
    
    StrCmp "$EXEDIR\$EXEFILE" "$INSTDIR\$InstallerExeName" SkipInstallerUpdate
    
    Delete "$INSTDIR\$InstallerExeName"
    ClearErrors
    CopyFiles /SILENT "$EXEDIR\$EXEFILE" "$INSTDIR\$InstallerExeName"
    IfErrors 0 SkipInstallerUpdate
  
    ${DetailPrint} "Error: Unable to copy the installer to the install folder!" 
    StrCpy $Errors "$Errors\n$\tError: Unable to copy the installer to the install folder!" 
        
    SkipInstallerUpdate:
    
    ;-------------------
    ; Java update 
    
    ${JavaUpdate}

    ;-------------------
    ; RiseCache update 

    ${RiseCacheUpdate}

    ;-------------------
    ; RisePlayer update 
        
    ${RisePlayerUpdate}
      
    ;-------------------
    ; Chromium update
    
    ; If displayId is not present, always update
    StrCmp $DisplayId "" UpdateChromium 0

    ${DetailPrint} "Checking if browser is upgradeable..."
    
    StrCpy $TempURL "${CoreURL}/player/isBrowserUpgradeable?displayId=$DisplayId"
    ${Download} "silent" "Checking if browser is upgradeable" "$TempURL" "$PLUGINSDIR\BrowserUpgradeable.config" "true"

    ${LineRead} "$PLUGINSDIR\BrowserUpgradeable.config" "1" $BrowserUpgradeable

    StrCmp $BrowserUpgradeable "true$\n" 0 SkipChromiumUpdateNotUpgradeable

    ${DetailPrint} "Browser is upgradeable."

    UpdateChromium:

    ${ChromiumUpdate}
    Goto ShutdownPlayer

    SkipChromiumUpdateNotUpgradeable:

    ${DetailPrint} "Skipping Chrome update. Browser not upgradeable."

    ShutdownPlayer:
    
    ${DetailPrint} "Shutting down RisePlayer ..."
    
    ${Download} "silent" "Shutting down Rise Vision Player" "${RisePlayerShutdownURL}" "NUL" "false"
    Sleep 2000
    
    ${DetailPrint} "Shutting down RiseCache ..."
    
    ${Download} "silent" "shutting down Rise Cache" "${RiseCacheShutdownURL}" "NUL" "false"
    Sleep 2000

    ;------------------
    ; Wipe browser cache if "/C" parameter specified or "clear_cache" file exists
    ${GetParameters} $R0
    ClearErrors
    ${GetOptions} $R0 "/C" $0
    IfErrors 0 ClearBrowserCache
    IfFileExists "$INSTDIR\clear_cache" 0 SkipClearBrowserCache
    Delete "$INSTDIR\clear_cache"
    
    ClearBrowserCache:
    
    RMDir /r "$INSTDIR\data"
    ${DetailPrint} "browser cache cleared."
    
    SkipClearBrowserCache:
        
    StrCmp $UpgradeNeeded "no" UpdateCompleted        

    StrCmp $Hidden "1" NoJavaInstances

    Processes::FindProcess "chrome" ;without ".exe"

    StrCmp $R0 "1" 0 NoChromeInstances

    MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST "Chrome, Chromium or Java, are running and the installation program will close them to complete the Rise Vision Player setup. Please save any data and press Okay when you are ready to proceed."

    NoChromeInstances:
    
    Processes::FindProcess "javaw" ;without ".exe"
    
    StrCmp $R0 "1" 0 NoJavaInstances

    ;MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST "One or more Java applications are still running. Please save your data, close all Java applications and press OK when you are ready to proceed."
    ${DetailPrint} "Warning: One or more Java applications are still running!" 
    
    NoJavaInstances:
    
    ;--------------------------------
    ; Installing Java
    
    ${JavaInstall}

    ;--------------------------------
    ; Installing RiseCache.jar
    
    ${RiseCacheInstall}

    ;--------------------------------
    ; Installing RisePlayer.jar
    
    ${RisePlayerInstall}
   
    ;--------------------------------
    ; Installing Chromium
    
    ${ChromiumInstall}
            
    ;-------------------

    StrCmp $Hidden "0" 0 UpdateCompleted

    ;${DetailPrint} "Creating startup shortcut, please wait..."
    ;; create shortcut 
    ;SetOutPath $SMSTARTUP
    ;CreateShortcut "$SMSTARTUP\Start Rise Vision Player.lnk" "$INSTDIR\$InstallerExeName" "/S"
    
    UpdateCompleted:
    UpdateFailed:       
    
    ; resetting Chrome preferences to prevent "restore prev session" message from appearing after crash/shutdown and enabling geolocation
    ${DetailPrint} "Resetting to default configuration."
    CreateDirectory "$INSTDIR\data\Default"
    IfErrors SkipSettingsReset
    FileOpen $0 "$INSTDIR\data\Default\Preferences" w
    IfErrors SkipSettingsReset
    FileWrite $0 '{"countryid_at_install":0,"default_search_provider":{"enabled":false},"geolocation":{"default_content_setting":1},"profile":{"content_settings":{"pref_version":1},"default_content_settings":{"geolocation": 1},"exited_cleanly":true}}'
    FileClose $0
            
    SkipSettingsReset:
    
    ;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ; Player 2 - exit installer after installation or auto-update is complete

    ${MutexClose} $MutexHandle

    Goto ExitInstaller

    ;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        
    CloseInstaller:
    
    ${GetParameters} $R0
    
    StrCpy $TempFile '"$PLUGINSDIR\$InstallerExeName" $R0'
    Goto StartInstaller  
   
    StartInstaller:
    
    ${MutexClose} $MutexHandle
    
    Sleep 2000
    
    Exec $TempFile
    Quit
    
    ExitInstaller:
    
    ;StrCmp $FirstRun "1" 0 SkipError
    IfSilent SkipError 0 
    StrCmp $Errors "" SkipError 
    ${MyAbort} "Installation has failed."
   
   SkipError:
   
   StrCmp $Errors "" FinishInstaller
    ${PlayerFailMessage}
    
   FinishInstaller: 
    ;Sleep 1000
    ;Quit

SectionEnd

Function LicensePagePre
    
    abort
    #IfFileExists "$INSTDIR\installer.ver" 0 ExitLicensePagePre
    #abort
    
    #ExitLicensePagePre:

FunctionEnd

Function LicensePageLeave
   ; create "$INSTDIR\terms" file
FunctionEnd

Function CreateStartupShortcut

    ${DetailPrint} "Creating startup shortcut, please wait..."
    ; create shortcut 
    SetOutPath $SMSTARTUP
    CreateShortcut "$SMSTARTUP\Start Rise Vision Player.lnk" "$INSTDIR\$InstallerExeName" "/S"
    StrCpy $StartupShortcutSelected "1"
FunctionEnd

Function FinishPageLeave
    ;this function is called on when IU is visible
    StrCmp $StartupShortcutSelected "1" FinishPageLeave

    ${DetailPrint} "Removing startup shortcut if exists, please wait..."
    ; delete shortcut 
    SetOutPath $SMSTARTUP
    IfFileExists "$SMSTARTUP\Start Rise Vision Player.lnk" 0 FinishPageLeave
    Delete "$SMSTARTUP\Start Rise Vision Player.lnk"
        
    FinishPageLeave:
FunctionEnd

# Installer functions
Function .onInit
    ${MutexCheck} ${PlayerMutexName} $R0 $MutexHandle 
    StrCmp $R0 0 GoAhead
    MessageBox MB_OK "Rise Vision Player installation is already running. Press Okay to close this instance."
    Abort
    
    GoAhead:
    !insertmacro MULTIUSER_INIT
FunctionEnd

Function .onInstSuccess

    ;update shortcut only if silent and shortcut already exists
    StrCmp $Hidden "0" SkipUpdateShortcut
    IfFileExists "$SMSTARTUP\Start Rise Vision Player.lnk" 0 SkipUpdateShortcut
    Call CreateStartUpShortcut
    
    SkipUpdateShortcut:

    ;----------------
    ;start Rise Cache
    
    ${DetailPrint} "Starting RiseCache."
    ClearErrors
    ${LaunchJavaApp} "$INSTDIR\RiseCache\RiseCache.jar"
    IfErrors RiseCacheStartFailed RiseCacheStarted

    RiseCacheStartFailed:
    ${DetailPrint} "Error starting RiseCache."

    RiseCacheStarted:

    ;----------------
    ;start Rise Player

    ${DetailPrint} "Starting Rise Vision Player."
    ClearErrors
    ${LaunchJavaApp} "$INSTDIR\RisePlayer.jar"
    IfErrors RisePlyerStartFailed RisePlayerStarted

    RisePlyerStartFailed:
    ${DetailPrint} "Error starting RisePlayer."
    StrCpy $Errors "$Errors$\n$\tError starting RisePlayer."

    StrCmp $Errors "" RisePlayerStarted 
    ${PlayerFailMessage}
    
    RisePlayerStarted:

    ;----------------
    ;remove from startup if not selected

FunctionEnd

