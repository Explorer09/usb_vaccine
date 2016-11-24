@ECHO OFF
SETLOCAL EnableExtensions
IF CMDEXTVERSION==2 GOTO cmd_ext_ok
ENDLOCAL 
echo Requires Windows 2000 or later.
GOTO EOF
exit 1;
exit 
REM Press Ctrl-C and answer Y to terminate.
COPY CON: NUL:
%0
:cmd_ext_ok
ENDLOCAL
SETLOCAL EnableExtensions EnableDelayedExpansion

REM ---------------------------------------------------------------------------
REM 'usb_vaccine.cmd' version 3 beta (2016-11-24)
REM Copyright (C) 2013-2016 Kang-Che Sung <explorer09 @ gmail.com>

REM This program is free software; you can redistribute it and/or
REM modify it under the terms of the GNU Lesser General Public
REM License as published by the Free Software Foundation; either
REM version 2.1 of the License, or (at your option) any later version.

REM This program is distributed in the hope that it will be useful,
REM but WITHOUT ANY WARRANTY; without even the implied warranty of
REM MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
REM Lesser General Public License for more details.

REM You should have received a copy of the GNU Lesser General Public
REM License along with this program. If not, see
REM <http://www.gnu.org/licenses/>.
REM ---------------------------------------------------------------------------
REM CONSTANTS

REM User's default options for commands. Reset.
SET COPYCMD=
SET DIRCMD=
REM Disable user override.
SET CD=
SET ERRORLEVEL=

SET HKLM_SFT=HKLM\SOFTWARE
SET HKLM_CLS=%HKLM_SFT%\Classes
SET HKLM_SFT_WOW=%HKLM_SFT%\Wow6432Node

SET "CMD_SUBKEY=Microsoft\Command Processor"
SET "INF_MAP_SUBKEY=Microsoft\Windows NT\CurrentVersion\IniFileMapping\autorun.inf"
SET "EXPLORER_SUBKEY=Microsoft\Windows\CurrentVersion\Explorer"
SET "ADVANCED_SUBKEY=%EXPLORER_SUBKEY%\Advanced"
SET "SHELL_ICON_SUBKEY=%EXPLORER_SUBKEY%\Shell Icons"

REM Files to keep. The whitelist.
SET KEEP_SYMLINK_FILES=
FOR %%i IN (
) DO (
    SET KEEP_SYMLINK_FILES=!KEEP_SYMLINK_FILES! %%i
)
SET KEEP_HS_ATTRIB_FILES=
FOR %%i IN (
"ibmbio.com" "ibmdos.com" "IO.SYS" "IO.DOS" "WINBOOT.SYS" "JO.SYS" "MSDOS.SYS"
"MSDOS.DOS" "MSDOS.BAK" "MSDOS.W40" "MSDOS.---" "@oldbios.ui" "@oldbdos.ui"
"COMMAND.COM" "COMMAND.DOS" "AUTOEXEC.DOS" "CONFIG.DOS" "OS2BOOT" "OS2LDR"
"OS2LDR.MSG" "OS2KRNL" "OS2DUMP" "OS2VER" "OS2LOGO" "EA DATA. SF" "WP ROOT. SF"
"Nowhere\" "386SPART.PAR" "pagefile.sys" "swapfile.sys" "hiberfil.sys"
"SSPARTSS.ADD" "STACKER.BIN" "STACKER.INI" "STACVOL.DSK" "DBLSPACE.BIN"
"DRVSPACE.BIN" "DBLSPACE.INI" "DRVSPACE.INI" "DBLSPACE.000" "DRVSPACE.000"
"FAILSAFE.DRV\" "@DLWATCH.DAT" "Recycled\" "RECYCLER\" "$Recycle.Bin\"
"boot.ini" "Boot.BAK" "bootfont.bin" "bootsect.dos" "NTDETECT.COM" "ntldr"
"@oldboot.ui" "SUHDLOG.DAT" "SUHDLOG.---" "arcldr.exe" "arcsetup.exe" "Boot\"
"bootmgr" "BOOTNXT" "BOOTSECT.BAK" "BOOTTGT" "BOOTLOG.TXT" "BOOTLOG.PRV"
"DETLOG.TXT" "DETLOG.OLD" "NETLOG.TXT" "SETUPLOG.TXT" "SETUPLOG.OLD"
"system.1st" "UNINSTAL.INI" "WINLFN.INI" "System Volume Information\"
"cmdcons\" "cmldr" "Recovery\" "SECURITY.BIN" "VIDEOROM.BIN" "EBD.SYS"
) DO (
    SET KEEP_HS_ATTRIB_FILES=!KEEP_HS_ATTRIB_FILES! %%i
)
SET KEEP_H_ATTRIB_FILES=
FOR %%i IN (
"ibmbio.com" "ibmdos.com" "MSDOS.---" "logo.sys" "@command.ui" "autoexec.bat"
"@AUTOEXE.UI" "config.sys" "@CONFIG.UI" "OS2LDR" "OS2KRNL" "SENTRY\" "Boot.BAK"
"SUHDLOG.DAT" "SUHDLOG.---" "BOOTLOG.TXT" "BOOTLOG.PRV" "SETUPLOG.TXT"
"SETUPLOG.OLD" "ASD.LOG" "CLASSES.1ST" "system.1st" "W95UNDO.DAT" "W95UNDO.INI"
"WINUNDO.DAT" "WINUNDO.INI" "W98UNDO.DAT" "W98UNDO.INI" "W9XUNDO.DAT"
"W9XUNDO.INI" "$INPLACE.~TR\" "$WINDOWS.~Q\" "$Windows.~BT\" "_Restore\"
"$WINRE_BACKUP_PARTITION.MARKER" "DOS00I.400" "DOS01L.400" "ProgramData\"
"MSOCache\"
) DO (
    SET KEEP_H_ATTRIB_FILES=!KEEP_H_ATTRIB_FILES! %%i
)
SET KEEP_S_ATTRIB_FILES=
FOR %%i IN (
"PCTRACKR.DEL" "boot.ini" "BOOTSECT.BAK"
) DO (
    SET KEEP_S_ATTRIB_FILES=!KEEP_S_ATTRIB_FILES! %%i
)
SET KEEP_EXECUTE_FILES=
FOR %%i IN (
"ibmbio.com" "ibmdos.com" "COMMAND.COM" "autoexec.bat" "STARTUP.CMD"
"STACKER.EXE" "NTDETECT.COM" "arcldr.exe" "arcsetup.exe"
) DO (
    SET KEEP_EXECUTE_FILES=!KEEP_EXECUTE_FILES! %%i
)

REM ---------------------------------------------------------------------------
REM MAIN

SET g_reg_bak=
SET g_sids=

REM Needed by restart routine. SHIFT will change %*.
SET "args=%*"

:main_parse_options
SET "arg1=%~1"
IF "!arg1!"=="" GOTO main_sanity_test
    IF "!arg1!"=="/?" SET opt_help=1
    IF "!arg1!"=="-?" SET opt_help=1
    IF "!arg1!"=="--help" SET opt_help=1
    IF "!arg1:~0,5!"=="--no-" (
        FOR %%i IN (restart reg_bak inf_mapping mkdir) DO (
            IF "!arg1:-=_!"=="__no_%%i" SET "opt_%%i=SKIP"
        )
    )
    IF "!arg1:~0,7!"=="--skip-" (
        FOR %%i IN (
            cmd_autorun mountpoints known_ext pif_ext scf_icon scrap_ext
        ) DO (
            IF "!arg1:-=_!"=="__skip_%%i" SET "opt_%%i=SKIP"
        )
    )
    IF "!arg1:~0,12!"=="--all-users-" (
        FOR %%i IN (cmd_autorun known_ext reassoc) DO (
            IF "!arg1:-=_!"=="__all_users_%%i" SET "opt_%%i=ALL_USERS"
        )
    )
    IF "!arg1:~0,6!"=="--fix-" (
        FOR %%i IN (exe_ext shortcut_icon file_icon) DO (
            IF "!arg1:-=_!"=="__fix_%%i" SET "opt_%%i=FIX"
        )
    )
    IF "!arg1!"=="--always-exe-ext" SET "opt_exe_ext=ALWAYS"
    IF "!arg1:~0,7!"=="--keep-" (
        FOR %%i IN (
            symlinks attrib shortcuts folder_exe autorun_inf desktop_ini
        ) DO (
            IF "!arg1:-=_!"=="__keep_%%i" SET "opt_%%i=SKIP"
        )
    )
    IF "!arg1:~0,13!"=="--move-subdir" (
        IF "!arg1:~13,1!"=="=" (
            REM User quotes the argument so that '=' is included.
            SET opt_move_subdir=!arg1:~14!
        ) ELSE (
            REM '=' becomes delimiter. Get the next argument.
            SET "opt_move_subdir=%~2"
            SHIFT /1
        )
        SET opt_move_subdir=!opt_move_subdir:^"=!
        SET opt_move_subdir=!opt_move_subdir:/=\!
    )
    REM %0 is needed by restart routine. Don't touch.
    SHIFT /1
GOTO main_parse_options

:main_sanity_test
IF "!opt_help!"=="1" SET opt_restart=SKIP
IF "!opt_reg_bak!"=="SKIP" SET g_reg_bak=FAIL

REM Humbly quit when we get a Unix 'find' utility. We won't bother with
REM 'findstr' or (ported) 'grep'.
find . -prune >NUL: 2>NUL: && GOTO main_find_error
ECHO X | find "X" >NUL: 2>NUL: || GOTO main_find_error

IF "!opt_move_subdir!"=="" SET opt_move_subdir=\MALWARE
IF /I "!opt_move_subdir!"=="NUL:" SET opt_move_subdir=NUL
REM Technically we can't check for every possibility of valid path without
REM actually 'mkdir' with it, but we may filter out common path attacks.
REM Note: There may be false positives with a multi-byte encoded path.
REM (Code point 0xXX5C. GBK, Big5, Shift_JIS, EUC-KR all vulnerable.)
IF "!opt_move_subdir:~0,2!"=="\\" GOTO main_invalid_path
REM Windows 9x allows "\...\", "\....\" and so on for grandparent or any
REM ancestor directory. Thankfully it doesn't work anymore in NT.
ECHO "\!opt_move_subdir!\" | find "\..\" >NUL: && GOTO main_invalid_path
ECHO "!opt_move_subdir!" | find "*" >NUL: && GOTO main_invalid_path
ECHO "!opt_move_subdir!" | find "?" >NUL: && GOTO main_invalid_path
FOR %%c IN (":" "<" ">" "|") DO (
    ECHO "!opt_move_subdir!" | find %%c >NUL: && GOTO main_invalid_path
)

reg query "HKCU" >NUL: 2>NUL: || (
    ECHO.>&2
    ECHO *** ERROR: Can't access Windows registry with reg.exe^^!>&2
    ECHO.>&2
    ECHO If you are using Windows 2000, please install Windows 2000 Support Tools. See>&2
    ECHO ^<https://support.microsoft.com/kb/301423^> for details. You may download the>&2
    ECHO Support Tools from ^<https://www.microsoft.com/download/details.aspx?id=18614^>>&2
    IF "!opt_help!"=="1" GOTO main_help
    ECHO.>&2
    ECHO All registry tasks will be SKIPPED.>&2
    GOTO main_all_drives
)

SET g_is_wow64=0
IF DEFINED PROCESSOR_ARCHITEW6432 (
    IF NOT "!opt_restart!"=="SKIP" GOTO main_restart_native
    SET g_is_wow64=1
    ECHO NOTICE: A WoW64 environment is detected. This script is supposed to be run in a>&2
    ECHO native, 64-bit cmd.exe interpreter.>&2
)
SET has_wow64=0
reg query "%HKLM_SFT_WOW%" >NUL: 2>NUL: && SET has_wow64=1

:main_cmd_autorun
SET has_cmd_autorun=0
FOR %%k IN (%HKLM_SFT_WOW% %HKLM_SFT% HKCU\Software) DO (
    REM "reg query" outputs header lines even if key or value doesn't exist.
    reg query "%%k\%CMD_SUBKEY%" /v "AutoRun" >NUL: 2>NUL: && (
        IF NOT "!opt_restart!"=="SKIP" GOTO main_restart
        SET has_cmd_autorun=1
        REM Show user the AutoRun values along with error message below.
        REM Key name included in "reg query" output.
        IF "!g_is_wow64!!has_wow64!%%k"=="10%HKLM_SFT%" (
            ECHO ^(The key below is a WoW64 redirected key. Its actual name is>&2
            ECHO  "%HKLM_SFT_WOW%\%CMD_SUBKEY%"^)>&2
        )
        IF NOT "!g_is_wow64!!has_wow64!%%k"=="11%HKLM_SFT%" (
            reg query "%%k\%CMD_SUBKEY%" /v "AutoRun" >&2
        )
    )
)
IF "!has_cmd_autorun!"=="1" (
    ECHO *** NOTICE: Your cmd.exe interpreter contains AutoRun commands, which have been>&2
    ECHO     run before this message is displayed and might be malicious.>&2
)
IF "!opt_help!"=="1" GOTO main_help
IF "!opt_cmd_autorun!"=="SKIP" GOTO main_inf_mapping
IF "!has_cmd_autorun!"=="1" (
    IF NOT "!opt_cmd_autorun!"=="ALL_USERS" (
        ECHO [cmd-autorun]
        ECHO For security reasons, we will delete "AutoRun" registry values listed above.
        ECHO ^(Affects machine and current user settings. Cannot be undone. To delete all
        ECHO users' settings, please specify '--all-users-cmd-autorun' option.^)
        CALL :continue_prompt || GOTO main_inf_mapping
    )
    FOR %%k IN (%HKLM_SFT_WOW% %HKLM_SFT% HKCU\Software) DO (
        CALL :delete_reg_value "%%k" "%CMD_SUBKEY%" "AutoRun" "Command Processor /v AutoRun"
    )
)
IF "!opt_cmd_autorun!"=="ALL_USERS" (
    CALL :prepare_sids
    FOR %%i IN (!g_sids!) DO (
        ECHO SID %%~i
        CALL :delete_reg_value "HKU\%%~i\Software" "%CMD_SUBKEY%" "AutoRun" "Command Processor /v AutoRun"
    )
)

:main_inf_mapping
SET has_inf_mapping=1
reg query "%HKLM_SFT%\%INF_MAP_SUBKEY%" /ve 2>NUL: | find /I "@" >NUL: || (
    SET has_inf_mapping=0
    ECHO.>&2
    ECHO *** DANGER: Your computer is vulnerable to the AutoRun malware^^!>&2
)
ECHO.
ECHO This program can help you disable AutoRun, clean the autorun.inf files on your
ECHO disks, remove shortcuts and reveal hidden files. All of these undo the damage
ECHO that might be done by AutoRun malware.
ECHO This DOES NOT remove the malware itself and so is not a substitute for anti-
ECHO virus software. Please install anti-virus software to protect your computer.
ECHO If you are using Windows 2000, XP, Server 2003, Vista, or Server 2008, it is
ECHO strongly recommended that you install KB967715 and KB971029 updates from
ECHO Microsoft. These two updates correct bugs in AutoRun implementations ^(even
ECHO though we will disable AutoRun entirely^).
ECHO Please see ^<https://technet.microsoft.com/library/security/967940.aspx^>

REM Credit to Nick Brown for the solution to disable AutoRun. See:
REM http://archive.today/CpwOH
REM http://www.computerworld.com/article/2481506
REM Works with Windows 7 too, and I believe it's safer to disable ALL AutoRuns
REM in Windows 7 and above, rather than let go some devices.
REM Other references:
REM http://www.kb.cert.org/vuls/id/889747
REM https://www.us-cert.gov/ncas/alerts/TA09-020A
IF "!has_inf_mapping!"=="1" GOTO main_mountpoints
IF "!opt_inf_mapping!"=="SKIP" GOTO main_mountpoints
ECHO.
ECHO [inf-mapping]
ECHO When you insert a disc, or click the icon of a CD-ROM drive, Windows will
ECHO automatically run some programs ^(usually the setup^) by default. Originally
ECHO meant for convenience, this "AutoRun" design is easily exploited by malware,
ECHO which can run automatically without awareness of users.
ECHO We will disable AutoRun entirely, and stop Windows from parsing any autorun.inf
ECHO file. After AutoRun is disabled, if you wish to install or run software from a
ECHO disc, you will have to manually open the Setup.exe inside. This doesn't affect
ECHO the AutoPlay feature of music, video discs, or USB devices.
ECHO ^(This is a machine setting.^)
CALL :continue_prompt || GOTO main_mountpoints
CALL :backup_reg "%HKLM_SFT%" "%INF_MAP_SUBKEY%" /ve
reg add "%HKLM_SFT%\%INF_MAP_SUBKEY%" /ve /t REG_SZ /d "@SYS:DoesNotExist" /f >NUL:
IF ERRORLEVEL 1 (
    CALL :show_reg_write_error "IniFileMapping\autorun.inf"
) ELSE (
    CALL :delete_reg_key "%HKLM_SFT%" "DoesNotExist" "%HKLM_SFT%\DoesNotExist"
)
IF "!has_wow64!"=="1" (
    CALL :backup_reg "%HKLM_SFT_WOW%" "%INF_MAP_SUBKEY%" /ve
    reg add "%HKLM_SFT_WOW%\%INF_MAP_SUBKEY%" /ve /t REG_SZ /d "@SYS:DoesNotExist" /f >NUL:
    IF ERRORLEVEL 1 (
        CALL :show_reg_write_error "(WoW64) IniFileMapping\autorun.inf"
    ) ELSE (
        CALL :delete_reg_key "%HKLM_SFT_WOW%" "DoesNotExist" "(WoW64) %HKLM_SFT%\DoesNotExist"
    )
)

:main_mountpoints
IF "!opt_mountpoints!"=="SKIP" GOTO main_known_ext
REM "MountPoints" for Windows 2000, "MountPoints2" for Windows XP and later.
ECHO.
ECHO [mountpoints]
ECHO The "MountPoints" ^(or "MountPoints2"^) registry keys are the AutoRun cache used
ECHO by Windows Explorer shell. After AutoRun is disabled, clean the registry keys
ECHO in order to prevent AutoRun threats from previous devices.
ECHO ^(Affects all users' settings. Cannot be undone.^)
CALL :continue_prompt || GOTO main_known_ext
CALL :prepare_sids
FOR %%i IN (!g_sids!) DO (
    ECHO SID %%~i
    FOR %%k IN (MountPoints MountPoints2) DO (
        CALL :clean_reg_key "HKU\%%~i\Software" "%EXPLORER_SUBKEY%\%%k" "Explorer\%%k"
    )
)

:main_known_ext
IF "!opt_known_ext!"=="SKIP" GOTO main_exe_ext
REM The value shouldn't exist in HKLM and doesn't work there. Silently delete.
FOR %%k IN (%HKLM_SFT% %HKLM_SFT_WOW%) DO (
    reg delete "%%k\%ADVANCED_SUBKEY%" /v "HideFileExt" /f >NUL: 2>NUL:
)
IF NOT "!opt_known_ext!"=="ALL_USERS" (
    ECHO.
    ECHO [known-ext]
    ECHO Windows will hide extensions for known file types by default, but applications
    ECHO may have custom icons. When the file extensions are hidden, malicious programs
    ECHO may use icons to disguise themselves as regular files or folders, tricking
    ECHO users into opening them.
    ECHO We will disable "Hide extensions for known file types" in "Control Panel" -^>
    ECHO "Folder Options", so that common file extensions ^(except shortcuts^) are always
    ECHO shown. Users may recognize whether a file is executable ^(and suspicious^)
    ECHO through the extensions. The following are executable file types:
    ECHO     .com ^(MS-DOS application^)    .cmd ^(Windows NT command script^)
    ECHO     .exe ^(Application^)           .scr ^(Screen saver^)
    ECHO     .bat ^(Batch file^)
    ECHO ^(Affects current user setting. To change all users' settings, please specify
    ECHO '--all-users-known-ext' option.^)
    CALL :continue_prompt || GOTO main_exe_ext
)
REM "HideFileExt" is enabled (0x1) if value does not exist.
reg add "HKCU\Software\%ADVANCED_SUBKEY%" /v "HideFileExt" /t REG_DWORD /d 0 /f >NUL: || (
    CALL :show_reg_write_error "Explorer\Advanced /v HideFileExt"
)
IF "!opt_known_ext!"=="ALL_USERS" (
    CALL :prepare_sids
    FOR %%i IN (!g_sids!) DO (
        ECHO SID %%~i
        reg add "HKU\%%~i\Software\%ADVANCED_SUBKEY%" /v "HideFileExt" /t REG_DWORD /d 0 /f >NUL: || (
            CALL :show_reg_write_error "Explorer\Advanced /v HideFileExt"
        )
    )
)

:main_exe_ext
IF "!opt_exe_ext!"=="ALWAYS" (
    FOR %%k IN (exefile scrfile) DO (
        reg add "%HKLM_CLS%\%%k" /v "AlwaysShowExt" /t REG_SZ /f >NUL: || (
            CALL :show_reg_write_error "HKCR\%%k /v AlwaysShowExt"
        )
    )
    SET opt_exe_ext=FIX
)
IF NOT "!opt_exe_ext!"=="FIX" GOTO main_pif_ext
FOR %%e IN (com exe bat scr cmd) DO (
    CALL :delete_reg_value "%HKLM_CLS%" "%%efile" "NeverShowExt" "HKCR\%%efile /v NeverShowExt"
)
SET list="com=comfile" "exe=exefile" "bat=batfile" "scr=scrfile" "cmd=cmdfile"
CALL :reassoc_file_types !list!

:main_pif_ext
SET "user_msg=the current user"
IF "!opt_reassoc!"=="ALL_USERS" SET "user_msg=ALL USERS"

IF "!opt_pif_ext!"=="SKIP" GOTO main_scf_icon
reg query "%HKLM_CLS%\piffile" /v "NeverShowExt" >NUL: 2>NUL: || GOTO main_scf_icon
REM Thankfully cmd.exe handles .pif right. Only Explorer has this flaw.
ECHO.
ECHO [pif-ext]
ECHO The .pif files are shortcuts to DOS programs. Windows Explorer will generate a
ECHO .pif file when user requests to create a shortcut to a .com executable.
ECHO However, there's a design flaw in Explorer's handling of this file type. If
ECHO someone renames an executable file to .pif extension, and users opens that .pif
ECHO file, code will be executed. This flaw is exploitable. ^(An executable program
ECHO renamed to a .pif file will show either a generic file icon or an MS-DOS icon
ECHO depending on Windows version.^)
ECHO We will delete the "NeverShowExt" registry value for this file type. Users will
ECHO see the .pif extension if they disable "Hide extensions for known file types".
ECHO This increases awareness.
ECHO ^(This is a machine setting. In addition, the associations for this file type
ECHO for !user_msg! will be reset, which cannot be undone.^)
CALL :continue_prompt || GOTO main_scf_icon
CALL :delete_reg_value "%HKLM_CLS%" "piffile" "NeverShowExt" "HKCR\piffile /v NeverShowExt"
CALL :reassoc_file_types "pif=piffile"

:main_scf_icon
IF "!opt_scf_icon!"=="SKIP" GOTO main_scrap_ext
reg query "%HKLM_CLS%\SHCmdFile" >NUL: 2>NUL: || GOTO main_scrap_ext
reg query "%HKLM_CLS%\SHCmdFile" /v "IsShortcut" >NUL: 2>NUL: && GOTO main_scrap_ext
ECHO.
ECHO [scf-icon]
ECHO The .scf files are directive files that run internal commands of the Windows
ECHO Explorer shell when opened by users. The most common example is "Show Desktop"
ECHO on Quick Launch bar, in Windows versions before Vista. ^(The "Show desktop"
ECHO icons in Vista or later are .lnk files.^) While the format itself doesn't allow
ECHO code, it may still surprise users when a shell command is run accidentally.
ECHO We will add a shortcut arrow icon for this file type, to increase awareness of
ECHO users.
ECHO ^(This is a machine setting. In addition, the associations for this file type
ECHO for !user_msg! will be reset, which cannot be undone.^)
CALL :continue_prompt || GOTO main_scrap_ext
reg add "%HKLM_CLS%\SHCmdFile" /v "IsShortcut" /t REG_SZ /f >NUL: || (
    CALL :show_reg_write_error "HKCR\SHCmdFile /v IsShortcut"
)
CALL :reassoc_file_types "scf=SHCmdFile"

:main_scrap_ext
REM Thanks to PCHelp and others for discovering this security flaw. See:
REM http://www.pc-help.org/security/scrap.htm
REM Other references:
REM http://www.trojanhunter.com/papers/scrapfiles/
REM http://www.giac.org/paper/gsec/614/wrapping-malicious-code-windows-shell-scrap-objects/101444
REM WordPad, Office Word and Excel are all known to support scrap files.
IF "!opt_scrap_ext!"=="SKIP" GOTO main_shortcut_icon
SET scrap_ext_keys=
FOR %%k IN (ShellScrap DocShortcut) DO (
    reg query "%HKLM_CLS%\%%k" /v "NeverShowExt" >NUL: 2>NUL: && (
        SET scrap_ext_keys=!scrap_ext_keys! %%k
    )
)
IF "!scrap_ext_keys!"=="" GOTO main_shortcut_icon
ECHO.
ECHO [scrap-ext]
ECHO The .shs and .shb files are generated when user drags text out of a document
ECHO editor ^(such as WordPad^) and are formats that save document scraps and
ECHO shortcuts respectively. The format allows embedding executable code which can
ECHO get executed when user opens a ^(specially crafted^) file of these types.
ECHO ^(Windows Vista and later have removed support of scrap files.^)
ECHO We will delete the "NeverShowExt" registry value for these file types. Users
ECHO will see the extensions for these if they disable ^"Hide extensions for known
ECHO file types^". This increases awareness.
ECHO ^(This is a machine setting. In addition, the associations for these file types
ECHO for !user_msg! will be reset, which cannot be undone.^)
CALL :continue_prompt || GOTO main_shortcut_icon
FOR %%k IN (!scrap_ext_keys!) DO (
    CALL :delete_reg_value "%HKLM_CLS%" "%%k" "NeverShowExt" "HKCR\%%k /v NeverShowExt"
)
CALL :reassoc_file_types "shs=ShellScrap" "shb=DocShortcut"

:main_shortcut_icon
IF NOT "!opt_shortcut_icon!"=="FIX" GOTO main_file_icon
FOR %%k IN (piffile lnkfile DocShortcut InternetShortcut) DO (
    reg query "%HKLM_CLS%\%%k" >NUL: 2>NUL: && (
        reg add "%HKLM_CLS%\%%k" /v "IsShortcut" /t REG_SZ /f >NUL: || (
            CALL :show_reg_write_error "HKCR\%%k /v IsShortcut"
        )
    )
)
reg query "%HKLM_CLS%\Application.Reference" >NUL: 2>NUL: && (
    reg add "%HKLM_CLS%\Application.Reference" /v "IsShortcut" /t REG_SZ /f >NUL: || (
        CALL :show_reg_write_error "Application.Reference /v IsShortcut"
    )
)
REM The data string "NULL" is in the original entry, in both Groove 2007 and
REM SharePoint Workspace 2010.
reg query "%HKLM_CLS%\GrooveLinkFile" >NUL: 2>NUL: && (
    reg add "%HKLM_CLS%\GrooveLinkFile" /v "IsShortcut" /t REG_SZ /d "NULL" /f >NUL: || (
        CALL :show_reg_write_error "HKCR\GrooveLinkFile /v IsShortcut"
    )
)
CALL :delete_reg_value "%HKLM_SFT%" "%SHELL_ICON_SUBKEY%" "29" "Explorer\Shell Icons /v 29"
IF NOT "!opt_file_icon!"=="FIX" (
    SET list="pif=piffile" "lnk=lnkfile" "shb=DocShortcut" "url=InternetShortcut"
    SET list=!list! "appref-ms=Application.Reference" "glk=GrooveLinkFile"
    CALL :reassoc_file_types !list!
)

:main_file_icon
IF NOT "!opt_file_icon!"=="FIX" GOTO main_all_drives
REM "DefaultIcon" for "Unknown" is configurable since Windows Vista.
reg query "%HKLM_CLS%\Unknown\DefaultIcon" >NUL: 2>NUL: && (
    reg add "%HKLM_CLS%\Unknown\DefaultIcon" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\shell32.dll,0" /f >NUL: || (
        CALL :show_reg_write_error "HKCR\Unknown\DefaultIcon"
    )
)
CALL :delete_reg_key "%HKLM_CLS%" "comfile\shellex\IconHandler" "HKCR\comfile\shellex\IconHandler"
reg add "%HKLM_CLS%\comfile\DefaultIcon" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\shell32.dll,2" /f >NUL: || (
    CALL :delete_reg_key "%HKLM_CLS%" "%%k\DefaultIcon" "HKCR\comfile\DefaultIcon"
)
REM Two vulnerabilities exist in the .lnk and .pif IconHandler:
REM MS10-046 (CVE-2010-2568), MS15-020 (CVE-2015-0096)
REM Windows 2000 has no patch for either. XP has only patch for MS10-046.
REM Expect that user disables the IconHandler as the workaround.
FOR %%k IN (piffile lnkfile) DO (
    reg add "%HKLM_CLS%\%%k\shellex\IconHandler" /ve /t REG_SZ /d "{00021401-0000-0000-C000-000000000046}" /f >NUL: || (
        CALL :show_reg_write_error "HKCR\%%k\shellex\IconHandler"
    )
    CALL :delete_reg_key "%HKLM_CLS%" "%%k\DefaultIcon" "HKCR\%%k\DefaultIcon"
)
REM Scrap file types. Guaranteed to work (and only) in Windows 2000 and XP.
FOR %%k IN (ShellScrap DocShortcut) DO (
    reg query "%HKLM_CLS%\%%k" >NUL: 2>NUL: && (
        reg add "%HKLM_CLS%\%%k\DefaultIcon" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\shscrap.dll,-100" /f >NUL: || (
            CALL :show_reg_write_error "HKCR\%%k\DefaultIcon"
        )
        CALL :delete_reg_key "%HKLM_CLS%" "%%k\shellex\IconHandler" "%%k\shellex\IconHandler"
    )
)
REM The "InternetShortcut" key has "DefaultIcon" subkey whose Default value
REM differs among IE versions.
reg query "%HKLM_CLS%\InternetShortcut" >NUL: 2>NUL: && (
    reg add "%HKLM_CLS%\InternetShortcut\shellex\IconHandler" /ve /t REG_SZ /d "{FBF23B40-E3F0-101B-8488-00AA003E56F8}" /f >NUL: || (
        CALL :show_reg_write_error "InternetShortcut IconHandler"
    )
)
reg query "%HKLM_CLS%\SHCmdFile" >NUL: 2>NUL: && (
    CALL :delete_reg_key "%HKLM_CLS%" "SHCmdFile\DefaultIcon" "HKCR\SHCmdFile\DefaultIcon"
    reg add "%HKLM_CLS%\SHCmdFile\shellex\IconHandler" /ve /t REG_SZ /d "{57651662-CE3E-11D0-8D77-00C04FC99D61}" /f >NUL: || (
        CALL :show_reg_write_error "HKCR\SHCmdFile\shellex\IconHandler"
    )
)
reg query "%HKLM_CLS%\Application.Reference" >NUL: 2>NUL: && (
    CALL :delete_reg_key "%HKLM_CLS%" "Application.Reference\DefaultIcon" "Application.Reference\DefaultIcon"
    reg add "%HKLM_CLS%\Application.Reference\shellex\IconHandler" /ve /t REG_SZ /d "{E37E2028-CE1A-4f42-AF05-6CEABC4E5D75}" /f >NUL: || (
        CALL :show_reg_write_error "Application.Reference IconHandler"
    )
)
REM The "GrooveLinkFile" key has "DefaultIcon" value (data: "%1") and no
REM "DefaultIcon" subkey.
reg query "%HKLM_CLS%\GrooveLinkFile" >NUL: 2>NUL: && (
    reg add "%HKLM_CLS%\GrooveLinkFile\ShellEx\IconHandler" /ve /t REG_SZ /d "{387E725D-DC16-4D76-B310-2C93ED4752A0}" /f >NUL: || (
        CALL :show_reg_write_error "GrooveLinkFile\ShellEx\IconHandler"
    )
)
REM We don't reset associations for .url files because user's favorite browser
REM may have its own settings.
SET list="com=comfile" "pif=piffile" "lnk=lnkfile" "shs=ShellScrap"
SET list=!list! "shb=DocShortcut" "scf=SHCmdFile"
SET list=!list! "appref-ms=Application.Reference" "glk=GrooveLinkFile"
CALL :reassoc_file_types !list!

:main_all_drives
ECHO.
ECHO Now we will process the root directories of all disk drives.
ECHO Please insert all storage devices that are affected by malware, including USB
ECHO flash drives, external hard drives, memory cards, PDAs, smartphones, or digital
ECHO cameras. If you have CD- or DVD-RW discs in your drives, it is recommended that
ECHO you eject them, lest burning actions be triggered accidentally.
IF /I "!opt_move_subdir!"=="NUL" (
    ECHO Files that are found to be suspicious will be DELETED directly, if possible.
) ELSE (
    ECHO Files that are found to be suspicious will be moved to a sub-directory named
    ECHO "!opt_move_subdir!" inside the drive, if possible.
)
ECHO If you type 'skip' here, this program will end.
CALL :continue_prompt || GOTO main_end

REM Symlinks have to be handled first because we can't guarantee that user's
REM 'attrib' utility supports '/L' (don't follow symlinks).
IF NOT "!opt_symlinks!"=="SKIP" (
    ECHO.
    ECHO [symlinks] ^(1 of 7^)
    ECHO In Windows Vista or later, the NTFS file system supports "symbolic links",
    ECHO which are a kind of special files that function like shortcuts, and also have a
    ECHO shortcut arrow icon. But symbolic links are a file system feature, and do not
    ECHO need file name extensions. Some malware will create symbolic links that point
    ECHO to a ^(malicious^) executable file, tricking users into opening them.
    IF /I "!opt_move_subdir!"=="NUL" (
        ECHO We will delete all symbolic links that reside in the root directories and point
        ECHO to files ^(not directories^).
    ) ELSE (
        ECHO We will move away all symbolic links that reside in the root directories and
        ECHO point to files ^(not directories^).
        ECHO NOTICE: Due to a technical limitation, symbolic links with "Hidden" or "System"
        ECHO attribute will be DELETED instead.
    )
    CALL :continue_prompt || SET opt_symlinks=SKIP
)
REM [attrib] must be done before moving anything, or MOVE refuses to move
REM Hidden or System files.
IF NOT "!opt_attrib!"=="SKIP" (
    ECHO.
    ECHO [attrib] ^(2 of 7^)
    ECHO With the "Hidden" or "System" attribute set on files, they will no longer be
    ECHO visible by default in Windows Explorer or 'DIR' command. Some malware will hide
    ECHO the files and generate executable files ^(or shortcuts to executables^) with the
    ECHO same name, tricking users into opening them. ^(No malware will actually delete
    ECHO the files, otherwise the disk space freed through deletion might draw attention
    ECHO of users or anti-virus software.^)
    ECHO Except for real known operating system files, we will clear both "Hidden" and
    ECHO "System" attributes of all files in the root directories. This restores files
    ECHO that are hidden by the malware ^(and might reveal the malware file itself^).
    CALL :continue_prompt || SET opt_attrib=SKIP
)
IF NOT "!opt_shortcuts!"=="SKIP" (
    ECHO.
    ECHO [shortcuts] ^(3 of 7^)
    IF /I "!opt_move_subdir!"=="NUL" (
        ECHO We will delete shortcut files of the following types in the root directories:
        ECHO .pif, .lnk, .shb, .url, .appref-ms and .glk.
    ) ELSE (
        ECHO We will move away shortcut files of the following types in the root
        ECHO directories: .pif, .lnk, .shb, .url, .appref-ms and .glk.
    )
    CALL :continue_prompt || SET opt_shortcuts=SKIP
)
IF NOT "!opt_folder_exe!"=="SKIP" (
    REM COM format does not allow icons and Explorer won't show custom icons
    REM for an NE or PE renamed to .com.
    ECHO.
    ECHO [folder-exe] ^(4 of 7^)
    ECHO Some malware will hide the folders and generate executable files with the same
    ECHO names, usually with also the folder icon, tricking users into opening them.
    IF /I "!opt_move_subdir!"=="NUL" (
        ECHO We will delete executable files that reside in the root directories and carry
        ECHO the same name as an existing folder. File types that will be moved are: .exe
        ECHO and .scr.
    ) ELSE (
        ECHO We will move away executable files that reside in the root directories and
        ECHO carry the same name as an existing folder. File types that will be moved are:
        ECHO .exe and .scr.
    )
    ECHO WARNING: This may affect legitimate applications. When in doubt, skip this.
    CALL :continue_prompt || SET opt_folder_exe=SKIP
)
IF NOT "!opt_autorun_inf!"=="SKIP" (
    ECHO.
    ECHO [autorun-inf] ^(5 of 7^)
    ECHO Some malware will create the autorun.inf file, so that malware itself may be
    ECHO automatically run on computers that didn't have AutoRun disabled. Except for
    ECHO optical drives, no other drives should ever contain a file named "autorun.inf".
    IF /I "!opt_move_subdir!"=="NUL" (
        ECHO We will delete them.
    ) ELSE (
        ECHO We will move and rename them to "!opt_move_subdir!\_autorun.in0".
    )
    CALL :continue_prompt || SET opt_autorun_inf=SKIP
)
REM We won't deal with Folder.htt, because technically it could be any name in
REM any location, as specified in Desktop.ini.
IF NOT "!opt_desktop_ini!"=="SKIP" (
    ECHO.
    ECHO [desktop-ini] ^(6 of 7^)
    ECHO In Windows 98, 2000 or Me ^(or in 95 or NT 4.0 with IE4 installed^), there is a
    ECHO "Customize this folder" feature that allows customizing the root folder of a
    ECHO drive, creating or editing the folder's "Web View" template ^(usually named
    ECHO "Folder.htt"^). The template allows embedding JavaScript or VBScript which will
    ECHO be executed when a user "browses" the folder.
    ECHO If you are using Windows 2000 or XP, it is recommended that you install the
    ECHO latest service pack ^(at least 2000 SP3 or XP SP1^) to fix security risks caused
    ECHO by custom templates. Vista and later versions are safe.
    ECHO The "Desktop.ini" file specifies which template would be used for the folder.
    ECHO However, it's not supposed to exist in the root directories. ^(Not every feature
    ECHO of Desktop.ini works in root folders, and it was not part of design that custom
    ECHO Web View template works there.^)
    IF /I "!opt_move_subdir!"=="NUL" (
        ECHO We will delete the "Desktop.ini" files in the root directories.
    ) ELSE (
        ECHO We will move away and rename the "Desktop.ini" files from the root directories,
        ECHO to "!opt_move_subdir!\_Desktop.in0".
    )
    CALL :continue_prompt || SET opt_desktop_ini=SKIP
)
IF "!opt_autorun_inf!.!opt_desktop_ini!"=="SKIP.SKIP" SET opt_mkdir=SKIP
IF NOT "!opt_mkdir!"=="SKIP" (
    ECHO.
    ECHO [mkdir] ^(7 of 7^)
    ECHO With autorun.inf or Desktop.ini or both files removed, in order to prevent
    ECHO malware from creating either of them again, we will create hidden directories
    ECHO with same names. Users won't see them, but they may interfere with malware.
    ECHO Unless the malware has the ability to delete them, the drive won't be infected
    ECHO by AutoRun any more.
    CALL :continue_prompt || SET opt_mkdir=SKIP
)

SET g_files_moved=0
REM The "Windows - No Disk" error dialog is right on USB drives that are not
REM "safely removed", but is a bug to pop up on floppy drives. Guides on the
REM web mostly refer this to malware, or suggest suppressing it. Both are
REM wrong. Instead we just inform the user about the error dialog here.
ECHO.
ECHO When accessing drives, if an error dialog pops up saying ^"Windows - No Disk.
ECHO Exception Processing Message c0000013^", please press "Cancel". ^(It is normal
ECHO when happening on empty floppy drives.^)
FOR %%d IN (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO (
    IF EXIST %%d:\ (
        CD /D %%d:\
        SET g_move_status=
        ECHO.
        ECHO Drive %%d:
        REM Workaround name collisions caused by forced rename.
        SET g_dont_move_files=_autorun.in0 _Desktop.in0 _README.txt
        IF NOT "!opt_symlinks!"=="SKIP" CALL :process_symlinks
        IF NOT "!opt_attrib!"=="SKIP" CALL :clear_files_attrib
        IF NOT "!opt_shortcuts!"=="SKIP" CALL :process_shortcuts
        IF NOT "!opt_folder_exe!"=="SKIP" CALL :process_folder_exes
        IF NOT "!opt_autorun_inf!"=="SKIP" CALL :file_to_directory autorun.inf
        IF NOT "!opt_desktop_ini!"=="SKIP" CALL :file_to_directory Desktop.ini
        REM Process the locked files last.
        SET g_dont_move_files=
        IF NOT "!opt_symlinks!"=="SKIP" CALL :process_symlinks
        IF "!g_move_status!"=="OK_EMPTY" (
            DEL "!opt_move_subdir!\README.txt" >NUL:
            RMDIR "!opt_move_subdir!"
        )
    )
)
ECHO.
IF "!g_files_moved!"=="0" (
    ECHO All done. Press any key to close this program.
) ELSE (
    ECHO All done. Please examine the "!opt_move_subdir!"
    ECHO sub-directories, which all suspicious files are moved into.
    ECHO Press any key to close this program.
)
PAUSE >NUL:
GOTO main_end

:main_help
ECHO.
ECHO   --help                   show this help
ECHO   --no-restart             don't restart script ^(default will restart when
ECHO                            Command Processor AutoRun is detected^)
ECHO   --no-reg-bak             don't generate registry backup file "Vacc_reg.bak"
ECHO   --skip-cmd-autorun       don't delete Command Processor AutoRun registry
ECHO   --all-users-cmd-autorun  delete ALL USERS' cmd.exe AutoRun ^(default: no^)
ECHO   --no-inf-mapping         don't disable parsing of autorun.inf
ECHO   --skip-mountpoints       don't clean MountPoints registry keys ^(caches^)
ECHO   --skip-known-ext         don't show extensions for known file types
ECHO   --all-users-known-ext    ALL USERS show ext for known types ^(default: no^)
ECHO   --fix-exe-ext            delete NeverShowExt for executables ^(default: no^)
ECHO   --always-exe-ext         always show ext for .exe and .scr ^(default: no^)
ECHO   --skip-pif-ext           don't delete NeverShowExt for .pif files
ECHO   --skip-scf-icon          don't add shortcut arrow icons for .scf files
ECHO   --skip-scrap-ext         don't delete NeverShowExt for .shs and .shb
ECHO   --fix-shortcut-icon      restore shortcut arrow icons ^(default: no^)
ECHO   --fix-file-icon          restore icons for Unknown, com, pif, lnk, shs, shb,
ECHO                            url, scf, appref-ms and glk types ^(default: no^)
ECHO   --all-users-reassoc      when editing file associations, apply to ALL USERS
ECHO                            in addition to machine default and current user
ECHO The following procedures apply to root directories of all drives:
ECHO   --move-subdir=SUBDIR     sub-directory for each drive that suspicious files
ECHO                            will be moved to ^(default: "\MALWARE"^)
ECHO   --keep-symlinks          don't move or delete symbolic links
ECHO   --keep-attrib            keep all files' "Hidden" and "System" attributes
ECHO   --keep-shortcuts         don't move or delete shortcut files
ECHO   --keep-folder-exe        don't move/del executables with same name as folders
ECHO   --keep-autorun-inf       don't move or delete autorun.inf
ECHO   --keep-desktop-ini       don't move or delete Desktop.ini
ECHO   --no-mkdir               don't create placeholder directories
ECHO For security reasons, this script doesn't move suspicious files outside of
ECHO their drives. To delete the files instead, specify '--move-subdir=NUL'.
GOTO main_end

:main_end
ENDLOCAL
EXIT /B 0

:main_find_error
ECHO *** FATAL ERROR: Not a DOS/Windows 'find' command.>&2
ENDLOCAL
EXIT /B 1

:main_invalid_path
ECHO *** FATAL ERROR: Invalid path is specified in '--move-subdir' option.>&2
ENDLOCAL
EXIT /B 1

:main_restart_native
REM KB942589 hotfix brings Sysnative folder support to Windows XP (IA64 and
REM x64) but is never offered in Windows Update.
%WinDir%\Sysnative\cmd /d /c "%0 --no-restart !args!" && EXIT /B 0
SET status=!ERRORLEVEL!
ECHO *** A WoW64 environment is detected. This script is supposed to be run in a>&2
ECHO     native, 64-bit cmd.exe interpreter.>&2
ECHO Please follow these steps:>&2
ECHO 1. Run "%%WinDir%%\explorer.exe" ^(The native, 64-bit Windows Explorer. Note that>&2
ECHO    it is not explorer.exe in System32 or SysWOW64 directory.^)>&2
ECHO 2. In the new Explorer window, navigate to "%%WinDir%%\System32", and then find>&2
ECHO    and right-click on the "cmd.exe".>&2
ECHO 3. Select "Run as administrator".>&2
ECHO 4. In the new Command Prompt window, run the following command:>&2
ECHO    %0 !args!>&2
ECHO.
PAUSE
EXIT /B !status!

:main_restart
cmd /d /c "%0 --no-restart !args!" && EXIT /B 0
SET status=!ERRORLEVEL!
ECHO *** Error occurred when restarting. Please rerun this script using the>&2
ECHO     following command ^(note the '/d' and '--no-restart' options^):>&2
ECHO     cmd /d /c ^"%0 --no-restart !args!^">&2
ECHO.
PAUSE
EXIT /B !status!

REM ---------------------------------------------------------------------------
REM SUBROUTINES

REM Prompts user to continue or skip.
REM @return 0 if user says to continue, or 1 if says to skip
:continue_prompt
    REM Note: If the user answers empty string after a "SET /P", The variable
    REM is kept the previous value and NOT set to the empty string.
    SET prompt=
    SET /P prompt="Press Enter to continue, or type 'skip' to skip this step: "
    IF "!prompt!"=="" EXIT /B 0
    IF /I "!prompt!"=="Y" EXIT /B 0
    IF /I "!prompt!"=="SKIP" EXIT /B 1
GOTO continue_prompt

REM Checks if file exists and creates one if not.
REM @param %1 File name
REM @return 0 if file is created
:create_file
    REM Non-atomic! A race or a TOCTTOU attack may occur.
    IF EXIST %1 EXIT /B 1
    TYPE NUL: >>%1
    IF EXIST %1 EXIT /B 0
EXIT /B 1

REM Creates and initializes "Vacc_reg.bak"
:init_reg_bak
    REM This is not .reg format! So we don't allow user to specify file name.
    CALL :create_file "Vacc_reg.bak" || (
        SET g_reg_bak=FAIL
        ECHO.>&2
        ECHO WARNING: Can't create registry backup file "Vacc_reg.bak" in the directory>&2
        ECHO "!CD!">&2
        ECHO Either a file of same name exists, or the directory is read-only.>&2
        ECHO This program will now continue without registry backup.>&2
        PAUSE
        GOTO :EOF
    )
    SET g_reg_bak=OK
    (
        REM Don't localize.
        ECHO ; Registry backup generated by 'usb_vaccine.cmd'. Project website:
        ECHO ; ^<https://github.com/Explorer09/usb_vaccine^>
    ) >>"Vacc_reg.bak"
    ECHO.
    ECHO Your registry will be backed up in the file named:
    FOR %%i IN (Vacc_reg.bak) DO (
        ECHO "%%~fi".
    )
    PAUSE
GOTO :EOF

REM Logs data of a registry key/value into "Vacc_reg.bak".
REM @param %1 Part of key name up to and including the "Wow6432Node" delimiter
REM @param %2 Sub-key name after "%1\"
REM @param %3 (Without quotes:) "/v", "/ve" (default value) or "" (whole key)
REM @param %4 Value name if "%3"=="/v", empty otherwise
REM @return 0 on success, 1 if key/value doesn't exist, 2 if backup file fails
:backup_reg
    REM With '/ve' option, 'reg' in Windows 2000/XP exits with 1 on a "value
    REM not set" default, while in Vista it exits with 0. We ensures Vista's
    REM behavior by querying the whole key.
    SET "v_opt=%3"
    reg query "%~1\%~2" !v_opt:/ve=! %4 >NUL: 2>NUL: || EXIT /B 1
    IF "!g_reg_bak!"=="" CALL :init_reg_bak
    IF "!g_reg_bak!"=="FAIL" EXIT /B 2
    IF "!g_is_wow64!%~1"=="1%HKLM_SFT%" (
        REM Don't localize.
        ECHO ; WoW64 redirected key. Actual key name is
        ECHO ; "%HKLM_SFT_WOW%\%~2"
    ) >>"Vacc_reg.bak"
    SET s=
    IF "%~3%~4"=="" SET s=/s
    reg query "%~1\%~2" %3 %4 !s! >>"Vacc_reg.bak" 2>NUL:
GOTO :EOF

REM Displays a (generic) error message for any write error in registry.
REM @param %1 Short text about the key or value.
:show_reg_write_error
    ECHO Error occurred when modifying registry: "%~1">&2
    IF "!g_has_error_shown!"=="1" GOTO :EOF
    SET g_has_error_shown=1
    ECHO You may need to re-run this program with administrator privileges.>&2
    PAUSE
GOTO :EOF

REM Deletes a non-default registry value (if it exists).
REM @param %1 Part of key name up to and including the "Wow6432Node" delimiter
REM @param %2 Sub-key name after "%1\"
REM @param %3 Value name
REM @param %4 Short text about the entry, displayed in error messages
REM @return 0 on successful deletion, 1 if key doesn't exist, or 2 on error
:delete_reg_value
    CALL :backup_reg %1 %2 /v %3
    IF "!ERRORLEVEL!"=="1" EXIT /B 1
    reg delete "%~1\%~2" /v "%~3" /f >NUL: && EXIT /B 0
    CALL :show_reg_write_error %4
EXIT /B 2

REM Prepares g_sids global variable (list of all user SIDs on the computer).
:prepare_sids
    IF NOT "!g_sids!"=="" GOTO :EOF
    FOR /F "usebackq eol=\ delims=" %%k IN (`reg query HKU 2^>NUL:`) DO (
        REM 'reg' outputs junk lines, make sure the line truly represents a
        REM user and not a Classes key.
        SET "key=%%~k"
        IF /I "!key:~0,11!"=="HKEY_USERS\" (
            IF /I NOT "!key:~-8!"=="_Classes" (
                SET g_sids=!g_sids! "!key:~11!"
            )
        )
    )
GOTO :EOF

REM Deletes a registry key (if it exists).
REM @param %1 Part of key name up to and including the "Wow6432Node" delimiter
REM @param %2 Sub-key name after "%1\"
REM @param %3 Short text about the key, displayed in error messages
REM @return 0 on successful deletion, 1 if key doesn't exist, or 2 on error
:delete_reg_key
    CALL :backup_reg %1 %2
    IF "!ERRORLEVEL!"=="1" EXIT /B 1
    reg delete "%~1\%~2" /f >NUL: && EXIT /B 0
    CALL :show_reg_write_error %3
EXIT /B 2

REM Cleans a registry key (if it exists).
REM @param %1 Part of key name up to and including the "Wow6432Node" delimiter
REM @param %2 Sub-key name after "%1\"
REM @param %3 Short text about the key, displayed in error messages
REM @return 0 on successful deletion, 1 if key doesn't exist, or 2 on error
:clean_reg_key
    CALL :delete_reg_key %1 %2 %3 || GOTO :EOF
    REM Create a dummy value so that "reg add" won't affect the default value
    REM of the key.
    reg add "%~1\%~2" /v "X" /f >NUL: 2>NUL: || EXIT /B 2
    reg delete "%~1\%~2" /v "X" /f >NUL: 2>NUL: || EXIT /B 2
GOTO :EOF

REM Changes file association for a file type.
REM @param %1 File extension
REM @param %2 ProgID
REM @return 0 on success, 1 if not both .%1 and %2 keys exist, or 2 on error
:safe_assoc
    reg query "%HKLM_CLS%\%~2" >NUL: 2>NUL: || EXIT /B 1
    CALL :backup_reg "%HKLM_CLS%" ".%~1" /ve
    IF "!ERRORLEVEL!"=="1" EXIT /B 1
    reg add "%HKLM_CLS%\.%~1" /ve /t REG_SZ /d "%~2" /f >NUL: && EXIT /B 0
    CALL :show_reg_write_error "%HKLM_CLS%\.%~1"
EXIT /B 2

REM Resets file associations for given file types.
REM @param %* List of extensions in "ext=ProgID" (quoted) data pairs.
:reassoc_file_types
    REM p[air], e[xt], i[d], k[ey]
    SET keys=
    FOR %%p IN (%*) DO (
        FOR /F "tokens=1,2 delims==" %%e IN (%%p) DO (
            CALL :safe_assoc "%%e" "%%f" && SET keys=!keys! ".%%e" "%%f"
        )
    )
    FOR %%k IN (!keys!) DO (
        CALL :delete_reg_key "HKCU\Software\Classes" "%%~k" "HKCU Classes\%%~k"
    )
    IF NOT "!opt_reassoc!"=="ALL_USERS" GOTO :EOF
    CALL :prepare_sids
    FOR %%i IN (!g_sids!) DO (
        ECHO SID %%~i
        FOR %%k IN (!keys!) DO (
            CALL :delete_reg_key "HKU\%%~i\Software\Classes" "%%~k" "HKU Classes\%%~k"
        )
    )
GOTO :EOF

REM Checks if the name matches regex "(?i)WINLFN([1-9A-F][0-9A-F]*)?\.INI"
REM @param %1 File name
REM @return 0 (true) if it matches
:is_winlfn_name
    SET "name=%~1"
    IF /I NOT "!name:~0,6!!name:~-4!"=="WINLFN.INI" EXIT /B 1
    IF "!name:~6,1!"=="0" EXIT /B 1
    SET "name=!name:~6,-4!"
    IF "!name!"=="" EXIT /B 0
    FOR %%c IN (0 1 2 3 4 5 6 7 8 9 A B C D E F a b c d e f) DO (
        SET "name=!name:%%c=!"
        IF "!name!"=="" EXIT /B 0
    )
EXIT /B 1

REM Checks if the file is in one of the list of files to keep.
REM @param %1 Category
REM @param %2 Name of file to check
REM @return 0 (true) if the file is in the list
:is_file_to_keep
    SET list=
    IF "%~1"=="SYMLINK"   SET list=!KEEP_SYMLINK_FILES!
    IF "%~1"=="HS_ATTRIB" SET list=!KEEP_HS_ATTRIB_FILES!
    IF "%~1"=="H_ATTRIB"  SET list=!KEEP_H_ATTRIB_FILES!
    IF "%~1"=="S_ATTRIB"  SET list=!KEEP_S_ATTRIB_FILES!
    IF "%~1"=="EXECUTE"   SET list=!KEEP_EXECUTE_FILES!
    REM Special case for OS/2 "EA DATA. SF" and "WP ROOT. SF", which MUST
    REM contain spaces in their short name form.
    FOR %%i IN ("EA DATA. SF" "WP ROOT. SF") DO (
        IF /I "%~2"==%%i (
            IF /I NOT "%~s2"==%%i EXIT /B 1
        )
    )
    SET attr_d=0
    ECHO.%~a2 | find "d" >NUL: && SET attr_d=1
    FOR %%i IN (!list!) DO (
        IF /I "!attr_d!%~2"=="0%%~i" EXIT /B 0
        IF /I "!attr_d!%~2\"=="1%%~i" EXIT /B 0
    )
    REM Special case for "WINLFN<hex>.INI"
    IF "%~1!attr_d!"=="HS_ATTRIB0" (
        CALL :is_winlfn_name %2 && EXIT /B 0
    )
EXIT /B 1

REM Creates and initializes directory specified by opt_move_subdir.
:init_move_subdir
    IF /I "!opt_move_subdir!"=="NUL" (
        SET g_move_status=DEL
        GOTO :EOF
    )
    MKDIR "!opt_move_subdir!" || (
        REM We default not to touch the files if move_subdir can't be created.
        REM Change this value to DEL if you want to delete files instead.
        SET g_move_status=DONT
        ECHO ERROR: Can't create directory "!opt_move_subdir!" on drive !CD:~0,2!>&2
        ECHO Either a file of same name exists, or the drive is read-only.>&2
        GOTO :EOF
    )
    SET g_move_status=OK_EMPTY
    (
        ECHO All files that are considered suspicious by the script 'usb_vaccine.cmd' are
        ECHO moved to this directory. As 'usb_vaccine.cmd' is not anti-virus software, there
        ECHO may be false positives. Please review every file in this directory to make sure
        ECHO you have no data you wish to keep.
        ECHO.
        ECHO If you want to keep a file, just move it back to the root directory of the
        ECHO drive, where the file originally resides.
        ECHO.
        ECHO When you have finished, delete this directory.
        ECHO.
        ECHO 'usb_vaccine.cmd' project website:
        ECHO ^<https://github.com/Explorer09/usb_vaccine^>
    ) >"!opt_move_subdir!\README.txt"
GOTO :EOF

REM Important notes about commands behaviors:
REM - MOVE command exits with 1 when a move error occurs. There's no way to
REM   specify "don't overwrite" option for MOVE command.
REM - DEL command exits with 1 only when arguments syntax or path is invalid.
REM   It's exit code does not distinguish between deletion success and failure.
REM - Both MOVE and DEL refuse to process files with Hidden or System (or both)
REM   attribute set. (They'll output the "could not find" error.) However since
REM   Windows NT, DEL supports '/A' option that can workaround this.
REM - 'attrib' utility without '/L' option follows symlinks when reading or
REM   changing attributes. '/L' is not available before Windows Vista.
REM - The %~a1 method will retrieve attributes of the link itself, if the file
REM   referenced by %1 is a link (junction or symlink).
REM - If "dirlink" is a directory link (attributes "DL"), "DEL dirlink" deletes
REM   all files in the target directory (DANGEROUS), while "RMDIR dirlink"
REM   (with or without '/S') removes the symlink without touching anything in
REM   the target directory (SAFE). MOVE command on links always processes links
REM   themselves rather than link targets.

REM Decides the file and keeps, moves, or deletes it according to decision.
REM @param %1 Category of list of files to keep
REM @param %2 Type of file, displayed in (localized) messages
REM @param %3 Name of file to process
:process_file
    CALL :is_file_to_keep %1 %3 && (
        ECHO Skip %~2 "%~3" for safety.
        GOTO :EOF
    )
    FOR %%A IN (h s d l) DO (
        SET "attr_%%A=-%%A"
        ECHO.%~a3 | find "%%A" >NUL: && SET "attr_%%A=%%A"
    )
    REM Always Delete Hidden or System symlinks.
    IF NOT "!attr_h!!attr_s!"=="-h-s" (
        IF "!attr_l!!attr_d!"=="l-d" (
            ECHO Delete symbolic link "%~3"
            DEL /F /A:!attr_h!!attr_s!l-d "%~3" >NUL:
            GOTO :EOF
        )
    )
    IF "!g_move_status!"=="" CALL :init_move_subdir
    IF "!g_move_status!"=="DEL" (
        IF "!attr_d!"=="d" GOTO :EOF
        ECHO Delete %~2 "%~3"
        DEL /F /A:!attr_h!!attr_s!!attr_l!-d "%~3" >NUL:
        GOTO :EOF
    )
    IF NOT "!g_move_status:~0,2!"=="OK" (
        ECHO Detected but won't move %~2 "%~3"
        GOTO :EOF
    )
    FOR %%i IN (!g_dont_move_files!) DO (
        IF /I "%~3"=="%%~i" GOTO :EOF
    )
    IF NOT "!attr_h!!attr_s!"=="-h-s" (
        ECHO Can't move %~2 "%~3". ^(Has Hidden or System attribute^)>&2
        GOTO :EOF
    )
    SET "dest=%~3"
    IF /I "%~3"=="autorun.inf" SET dest=_autorun.in0
    IF /I "%~3"=="Desktop.ini" SET dest=_Desktop.in0
    IF /I "%~3"=="README.txt" SET dest=_%~3
    REM Should never exist name collisions except the forced rename above.
    IF EXIST "!opt_move_subdir!\!dest!" (
        ECHO Can't move %~2 "%~3" to "!opt_move_subdir!". ^(Destination file exists^)>&2
        GOTO :EOF
    )
    MOVE /Y "%~3" "!opt_move_subdir!\!dest!" >NUL: || (
        ECHO Can't move %~2 "%~3" to "!opt_move_subdir!".>&2
        GOTO :EOF
    )
    SET g_move_status=OK_MOVED
    SET g_files_moved=1
    ECHO Moved %~2 "%~3" to "!opt_move_subdir!".
GOTO :EOF

REM Moves or deletes all file symlinks in current directory.
:process_symlinks
    REM Directory symlinks/junctions are harmless. Leave them alone.
    REM DIR command in Windows 2000 supports "/A:L", but displays symlinks
    REM (file or directory) as junctions. Undocumented feature.
    FOR /F "usebackq eol=\ delims=" %%f IN (`DIR /A:L-D /B 2^>NUL:`) DO (
        CALL :process_file SYMLINK "symbolic link" "%%~f"
    )
GOTO :EOF

REM Clears hidden and system attributes of all files in current directory.
:clear_files_attrib
    REM 'attrib' refuses to clear either H or S attribute for files with both
    REM attributes set. Must clear both simultaneously.
    REM The exit code of 'attrib' is unreliable.
    FOR /F "usebackq eol=\ delims=" %%f IN (`DIR /A:HS-L /B 2^>NUL:`) DO (
        CALL :is_file_to_keep HS_ATTRIB "%%~f"
        IF ERRORLEVEL 1 (
            ECHO Clear Hidden+System attributes of "%%~f"
            attrib -H -S "%%~f"
        ) ELSE (
            ECHO Skip file "%%~f" ^(Hidden+System attributes^) for safety.
        )
    )
    FOR /F "usebackq eol=\ delims=" %%f IN (`DIR /A:H-S-L /B 2^>NUL:`) DO (
        CALL :is_file_to_keep H_ATTRIB "%%~f"
        IF ERRORLEVEL 1 (
            ECHO Clear Hidden attribute of "%%~f"
            attrib -H "%%~f"
        ) ELSE (
            ECHO Skip file "%%~f" ^(Hidden attribute^) for safety.
        )
    )
    FOR /F "usebackq eol=\ delims=" %%f IN (`DIR /A:S-H-L /B 2^>NUL:`) DO (
        CALL :is_file_to_keep S_ATTRIB "%%~f"
        IF ERRORLEVEL 1 (
            ECHO Clear System attribute of "%%~f"
            attrib -S "%%~f"
        ) ELSE (
            ECHO Skip file "%%~f" ^(System attribute^) for safety.
        )
    )
GOTO :EOF

REM Moves or deletes shortcut files in current directory.
:process_shortcuts
    FOR /F "usebackq eol=\ delims=" %%f IN (
        `DIR /A:-D /B *.pif *.lnk *.shb *.url *.appref-ms *.glk 2^>NUL:`
    ) DO (
        CALL :process_file EXECUTE "shortcut file" "%%~f"
    )
GOTO :EOF

REM Moves or deletes all .exe and .scr files that carry the same name as a
REM folder in current directory.
:process_folder_exes
    REM .bat, .cmd and .com are self-executable, but their icons are static, so
    REM leave them alone.
    FOR /F "usebackq eol=\ delims=" %%d IN (`DIR /A:D /B 2^>NUL:`) DO (
        FOR /F "usebackq eol=\ delims=" %%f IN (
            `DIR /A:-D /B "%%~d.exe" "%%~d.scr" 2^>NUL:`
        ) DO (
            CALL :process_file EXECUTE "file" "%%~f"
        )
    )
GOTO :EOF

REM Removes a file and optionally creates a directory with the same name.
REM @param %1 Name of file to remove or directory to create
REM @return 0 if directory exists or is created successfully, or 1 on error
:file_to_directory
    IF EXIST %1 (
        ECHO.%~a1 | find "d" >NUL: && (
            REM File exists and is a directory. Keep it.
            attrib +R +H +S "%~1"
            EXIT /B 0
        )
        CALL :process_file 0 "file" %1
        IF EXIST %1 EXIT /B 1
    )
    IF "!opt_mkdir!"=="SKIP" EXIT /B 0
    MKDIR "%~1" || (
        ECHO Error occurred when creating directory "%~1">&2
        EXIT /B 1
    )
    (
        REM Should be in ASCII encoding. It is better to keep an English
        REM version as well as localized one.
        ECHO This directory, "%~1", is to protect your disk from injecting a
        ECHO malicious %1 file.
        ECHO Your disk may still carry the USB or AutoRun malware, but it will NOT be
        ECHO executed anymore.
        ECHO Please do not remove this directory. If you do, you'll lose the protection.
        ECHO.
        ECHO This directory is generated by 'usb_vaccine.cmd'. Project website:
        ECHO ^<https://github.com/Explorer09/usb_vaccine^>
    ) >"%~1\DONT_DEL.txt"
    ECHO.>"%~1\dummy"
    attrib +R +H +S "%~1\dummy"
    attrib +R +H +S "%~1"
EXIT /B 0

REM ---------------------------------------------------------------------------
:EOF
