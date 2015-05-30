@ECHO OFF
SETLOCAL EnableExtensions
IF CMDEXTVERSION 2 GOTO cmd_ext_ok
ENDLOCAL
ECHO Requires Windows 2000 or later.
GOTO EOF
EXIT
:cmd_ext_ok
ENDLOCAL
SETLOCAL EnableExtensions EnableDelayedExpansion

REM ---------------------------------------------------------------------------
REM Copyright (C) 2013-2015 Kang-Che Sung <explorer09 @ gmail.com>

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

REM User's default options for DIR command. Reset.
SET DIRCMD=

SET CMD_REG_SUBKEY=Software\Microsoft\Command Processor
SET INF_MAPPING_REG_KEY="HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\IniFileMapping\autorun.inf"
SET MOUNT2_REG_SUBKEY=Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2
SET ADVANCED_REG_SUBKEY=Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced
SET SHELL_ICON_REG_KEY="HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons"

REM Files to keep - these are REAL system files and it's best to leave these
REM untouched. (Last updated for Windows 10 Insider Preview build 10074)

SET KEEP_SYMLINK_FILES=
FOR %%i IN (
) DO (
    SET KEEP_SYMLINK_FILES=!KEEP_SYMLINK_FILES! %%i
)
SET KEEP_HS_ATTRIB_FILES=
FOR %%i IN (
    "System Volume Information\"

    "autoexec.bat"
    "config.sys"
    "IO.SYS"
    "MSDOS.SYS"

    "BOOT.BAK"
    "boot.ini"
    "bootfont.bin"
    "NTDETECT.COM"
    "ntldr"

    "RECYCLER\"
    "$Recycle.Bin\"

    "Boot\"
    "bootmgr"
    "BOOTSECT.BAK"
    "BOOTNXT"

    "hiberfil.sys"
    "pagefile.sys"
    "swapfile.sys"

    "cmdcons\"
    "cmldr"

    "Recovery\"
) DO (
    SET KEEP_HS_ATTRIB_FILES=!KEEP_HS_ATTRIB_FILES! %%i
)
SET KEEP_H_ATTRIB_FILES=
FOR %%i IN (
    "ProgramData\"
    "MSOCache\"
) DO (
    SET KEEP_H_ATTRIB_FILES=!KEEP_H_ATTRIB_FILES! %%i
)
SET KEEP_S_ATTRIB_FILES=
FOR %%i IN (
) DO (
    SET KEEP_S_ATTRIB_FILES=!KEEP_S_ATTRIB_FILES! %%i
)
SET KEEP_EXECUTE_FILES=
FOR %%i IN (
    "autoexec.bat"
    "NTDETECT.COM"
) DO (
    SET KEEP_EXECUTE_FILES=!KEEP_EXECUTE_FILES! %%i
)

REM ---------------------------------------------------------------------------
REM MAIN

SET g_sids=

REM Needed by restart routine. SHIFT will change %*.
SET "args=%*"

:main_parse_options
IF NOT "X%~1"=="X" (
    SET "arg1=%~1"
    IF "X!arg1!"=="X/?" (
        SET opt_help=1
        SET opt_restart=SKIP
    )
    IF "X!arg1!"=="X-?" (
        SET opt_help=1
        SET opt_restart=SKIP
    )
    IF "X!arg1!"=="X--help" (
        SET opt_help=1
        SET opt_restart=SKIP
    )
    IF "X!arg1!"=="X--default-shortcut-icon" (
        SET "opt_shortcut_icon=DEFAULT"
    )
    IF "X!arg1:~0,5!"=="X--no-" (
        FOR %%i IN (restart inf_mapping mkdir) DO (
            IF "X!arg1:-=_!"=="X__no_%%i" (
                SET "opt_%%i=SKIP"
            )
        )
    )
    IF "X!arg1:~0,7!"=="X--skip-" (
        FOR %%i IN (cmd_autorun mountpoints2 known_ext shortcut_icon) DO (
            IF "X!arg1:-=_!"=="X__skip_%%i" (
                SET "opt_%%i=SKIP"
            )
        )
    )
    IF "X!arg1:~0,7!"=="X--keep-" (
        FOR %%i IN (symlinks attrib shortcuts folder-exe files) DO (
            IF "X!arg1:-=_!"=="X__keep_%%i" (
                SET "opt_%%i=SKIP"
            )
        )
    )
    IF "X!arg1:~0,12!"=="X--all-users-" (
        FOR %%i IN (cmd-autorun known-ext) DO (
            IF "X!arg1:-=_!"=="X__all_users_%%i" (
                SET "opt_%%i=ALL_USERS"
            )
        )
    )
    REM %0 is needed by restart routine. Don't touch.
    SHIFT /1
    GOTO main_parse_options
)

:main_sanity_test
reg query "HKCU" >nul 2>nul || (
    ECHO.
    ECHO *** ERROR: Can't access Windows registry with reg.exe^^!>&2
    ECHO.
    ECHO If you are using Windows 2000, please install reg.exe from Windows 2000 Support
    ECHO Tools. For details, see ^<https://support.microsoft.com/kb/301423^>
    ECHO You may download the Support Tools from
    ECHO ^<https://www.microsoft.com/download/details.aspx?id=18614^>
    IF "X!opt_help!"=="X1" GOTO main_help
    ECHO.
    ECHO All registry tasks will be SKIPPED.
    GOTO main_all_drives
)

:main_cmd_autorun
SET has_cmd_autorun=0
FOR %%k IN (HKLM HKCU) DO (
    REM "reg query" always output blank lines. Suppress them.
    reg query "%%k\%CMD_REG_SUBKEY%" /v "AutoRun" >nul 2>nul && (
        SET has_cmd_autorun=1
        IF NOT "X!opt_restart!"=="XSKIP" GOTO main_restart
        REM Show user the AutoRun values along with error message below.
        REM Key name included in "reg query" output.
        reg query "%%k\%CMD_REG_SUBKEY%" /v "AutoRun" >&2
    )
)
IF "!has_cmd_autorun!"=="1" (
    ECHO *** NOTICE: Your cmd.exe interpreter contains AutoRun commands, which have been>&2
    ECHO     run before this message is displayed and might be malicious.>&2
)
IF "X!opt_help!"=="X1" GOTO main_help
IF "X!opt_cmd_autorun!"=="XSKIP" GOTO main_inf_mapping
IF "!has_cmd_autorun!"=="1" (
    IF NOT "X!opt_cmd_autorun!"=="XALL_USERS" (
        ECHO.
        ECHO [cmd-autorun]
        ECHO For security reasons, the registry value "AutoRun" in two keys
        ECHO "{HKLM,HKCU}\%CMD_REG_SUBKEY%" will be deleted.
        ECHO ^(Affects machine and current user settings. To also delete other users'
        ECHO settings, please specify '--all-users-cmd-autorun' option. This action cannot
        ECHO be undone.^)
        CALL :continue_prompt || GOTO main_inf_mapping
    )
    FOR %%k IN (HKLM HKCU) DO (
        CALL :delete_reg_value "%%k\%CMD_REG_SUBKEY%" "AutoRun" "Command Processor /v AutoRun"
    )
)
IF "X!opt_cmd_autorun!"=="XALL_USERS" (
    CALL :prepare_sids
    FOR %%i IN (!g_sids!) DO (
        ECHO SID %%i
        CALL :delete_reg_value "HKU\%%i\%CMD_REG_SUBKEY%" "AutoRun" "Command Processor /v AutoRun"
    )
)

:main_inf_mapping
SET has_reg_inf_mapping=1
reg query %INF_MAPPING_REG_KEY% /ve 2>nul | find "@SYS:" /I >nul || (
    SET has_reg_inf_mapping=0
    ECHO.
    ECHO *** DANGER: Your computer is vulnerable to the AutoRun malware^^!>&2
)
ECHO.
ECHO This program can help you disable AutoRun, clean the autorun.inf files on your
ECHO disks, delete shortcuts and reveal hidden files. All of these undo the damage
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
REM in Windows 7, rather than let go some devices.
REM Other references:
REM http://www.kb.cert.org/vuls/id/889747
REM https://www.us-cert.gov/ncas/alerts/TA09-020A
IF "!has_reg_inf_mapping!"=="1" GOTO main_mountpoints2
IF "X!opt_inf_mapping!"=="XSKIP" GOTO main_mountpoints2
ECHO.
ECHO [inf-mapping]
ECHO When you insert a disc, or click the icon of a CD-ROM drive, Windows will
ECHO automatically run some ^(setup^) programs by default. Originally meant for
ECHO convenience, this AutoRun design is easily misused by malware, running
ECHO automatically without awareness of users.
ECHO We will disable AutoRun entirely, and stop Windows from parsing any autorun.inf
ECHO file. After AutoRun is disabled, if you wish to install or run software from a
ECHO disc, you will have to manually click the Setup.exe inside. This doesn't affect
ECHO the AutoPlay feature of music, video discs, or USB devices.
ECHO ^(This is a machine setting.^)
CALL :continue_prompt || GOTO main_mountpoints2
reg add %INF_MAPPING_REG_KEY% /ve /t REG_SZ /d "@SYS:DoesNotExist" /f >nul || (
    CALL :show_reg_write_error "IniFileMapping\autorun.inf"
    GOTO main_mountpoints2
)
CALL :delete_reg_key "HKLM\SOFTWARE\DoesNotExist" "HKLM\SOFTWARE\DoesNotExist"

:main_mountpoints2
IF "X!opt_mountpoints2!"=="XSKIP" GOTO main_known_ext
ECHO.
ECHO [mountpoints2]
ECHO The MountPoints2 registry keys are the AutoRun cache used by the OS. After
ECHO AutoRun is disabled, clean the registry keys in order to prevents AutoRun
ECHO threats from previous devices.
ECHO ^(Affects all users' settings. This action cannot be undone.^)
CALL :continue_prompt || GOTO main_known_ext
CALL :prepare_sids
FOR %%i IN (!g_sids!) DO (
    ECHO SID %%i
    CALL :clean_reg_key "HKU\!sid!\%MOUNT2_REG_SUBKEY%" "Explorer\MountPoints2"
)

:main_known_ext
REM The value shouldn't exist in HKLM and doesn't work there. Silently delete.
reg delete "HKLM\%ADVANCED_REG_SUBKEY%" /v "HideFileExt" /f >nul 2>nul

IF "X!opt_known_ext!"=="XSKIP" GOTO main_shortcut_icon
REM We include PIF because it's executable in Windows!
REM It's possible to rename a PE .exe to .pif and run when user clicks it.
ECHO.
ECHO [known-ext]
ECHO Windows will hide extensions for known file types by default. However, as
ECHO applications may have custom icons, with the file extensions hidden, it is
ECHO possible for malicious programs to use icons to disguise themselves as regular
ECHO files, tricking users into clicking them.
ECHO We will disable "Hide extensions for known file types" in "Control Panel" -^>
ECHO "Folder Options", so that common file extensions ^(except shortcuts^) are always
ECHO shown. Users may recognize whether a file is executable ^(and malicious^) through
ECHO the extensions. The following are executable:
ECHO     .exe ^(Application^)           .bat ^(Batch file^)
ECHO     .com ^(MS-DOS application^)    .cmd ^(Windows NT command script^)
ECHO     .scr ^(Screen saver^)          .pif ^(Shortcut to MS-DOS program^)
ECHO We will also delete the "NeverShowExt" registry value for the file types above.
ECHO The value always hides the extension for that file type. Unless it is a
ECHO shortcut file, the value should not exist.
ECHO ^(Affects machine and current user settings. To also change other users'
ECHO settings, please specify '--all-users-known-ext' option.^)
CALL :continue_prompt || GOTO main_shortcut_icon
REM "HideFileExt" is enabled (0x1) if value does not exist.
reg add "HKCU\%ADVANCED_REG_SUBKEY%" /v "HideFileExt" /t REG_DWORD /d 0 /f >nul || (
    CALL :show_reg_write_error "Explorer\Advanced /v HideFileExt"
)
REM "NeverShowExt"
FOR %%i IN (exe com scr bat cmd pif) DO (
    CALL :delete_reg_key "HKCU\Software\Classes\.%%i" "HKCU\Software\Classes\.%%i"
    CALL :delete_reg_key "HKCU\Software\Classes\%%ifile" "HKCU\Software\Classes\.%%ifile"
    reg add "HKLM\SOFTWARE\Classes\.%%i" /ve /t REG_SZ /d "%%ifile" /f >nul || (
        CALL :show_reg_write_error "HKLM\SOFTWARE\Classes\%%i"
    )
    CALL :delete_reg_value "HKLM\SOFTWARE\Classes\%%ifile" "NeverShowExt" "HKCR\%%ifile /v NeverShowExt"
)
IF "X!opt_known_ext!"=="XALL_USERS" (
    CALL :prepare_sids
    FOR %%i IN (!g_sids!) DO (
        ECHO SID %%i
        reg add "HKU\%%i\%ADVANCED_REG_SUBKEY%" /v "HideFileExt" /t REG_DWORD /d 0 /f >nul || (
            CALL :show_reg_write_error "Explorer\Advanced /v HideFileExt"
        )
        CALL :delete_reg_key "HKU\%%i\Software\Classes\.%%i" "HKU\*\Software\Classes\.%%i"
        CALL :delete_reg_key "HKU\%%i\Software\Classes\%%ifile" "HKU\*\Software\Classes\.%%ifile"
    )
)

:main_shortcut_icon
IF "X!opt_shortcut_icon!"=="XSKIP" GOTO main_all_drives
ECHO.
ECHO [shortcut-icon]
ECHO All shortcut files should have a small arrow icon on them, especially shortcuts
ECHO pointing to executable files. As the extensions of shortcut files are usually
ECHO hidden, users may only recognize shortcut files through its arrow icon.
ECHO We will restore arrow icons of common shortcut types, .lnk and .pif, which may
ECHO be pointing to executables. If you have customized the shortcut arrow icon, the
ECHO custom icon will be used here.
ECHO ^(This is a machine setting.^)
CALL :continue_prompt || GOTO main_all_drives
FOR %%i IN (lnk pif) DO (
    CALL :delete_reg_key "HKCU\Software\Classes\.%%i" "HKCU\Software\Classes\.%%i"
    CALL :delete_reg_key "HKCU\Software\Classes\%%ifile" "HKCU\Software\Classes\.%%ifile"
    reg add "HKLM\SOFTWARE\Classes\.%%i" /ve /t REG_SZ /d "%%ifile" /f >nul || (
        CALL :show_reg_write_error "HKLM\SOFTWARE\Classes\%%i"
    )
    reg add "HKLM\SOFTWARE\Classes\%%ifile" /v "IsShortcut" /t REG_SZ /f >nul || (
        CALL :show_reg_write_error "HKCR\%%ifile /v IsShortcut"
    )
)
IF "X!opt_shortcut_icon!"=="XDEFAULT" (
    CALL :delete_reg_value %SHELL_ICON_REG_KEY% "29" "Explorer\Shell Icons /v 29"
)

:main_all_drives
ECHO.
ECHO Now we are processing the root directories of all disk drives.
ECHO Please insert all storage devices that are affected by malware, including USB
ECHO flash drives, external hard drives, memory cards, PDAs, smartphones, or digital
ECHO cameras. If you have CD- or DVD-RW discs in your drives, it is recommended that
ECHO you eject them, lest burning actions be triggered accidentally.
PAUSE

IF NOT "X!opt_symlinks!"=="XSKIP" (
    ECHO.
    ECHO [symlinks]
    ECHO In Windows Vista or later, the NTFS file system supports "symbolic links",
    ECHO which are a kind of special files that function like shortcuts, and also have a
    ECHO shortcut arrow icon. But symbolic links are a file system feature, and do not
    ECHO need file extensions. Some malware will create symbolic links that point to a
    ECHO ^(malicious^) executable file, tricking users into clicking them.
    ECHO In the root directories, we will delete all symbolic links that point to files
    ECHO ^(not directories^).
    CALL :continue_prompt || SET opt_symlinks=SKIP
)
IF NOT "X!opt_attrib!"=="XSKIP" (
    ECHO.
    ECHO [attrib]
    ECHO With the "Hidden" or "System" attribute set on files, they will no longer be
    ECHO visible by default in Windows Explorer or 'DIR' command. Some malware will hide
    ECHO the files and generate executable files ^(or shortcuts to executables^) with the
    ECHO same name, tricking users into clicking them. ^(No malware will actually delete
    ECHO the files, otherwise the disk space freed through deletion might draw attention
    ECHO of users or anti-virus software.^)
    ECHO Except for real known operating system files, we will clear both "Hidden" and
    ECHO "System" attributes of all files in the root directories. This restores files
    ECHO that are hidden by the malware ^(and might reveal the malware file itself^).
    CALL :continue_prompt || SET opt_attrib=SKIP
)
IF NOT "X!opt_shortcuts!"=="XSKIP" (
    ECHO.
    ECHO [shortcuts]
    ECHO We will delete all shortcuts of .lnk or .pif file type in the root directories.
    CALL :continue_prompt || SET opt_shortcuts=SKIP
)
IF NOT "X!opt_folder_exe!"=="XSKIP" (
    ECHO.
    ECHO [folder-exe]
    ECHO Some malware will hide the folders and generate executable files with the same
    ECHO names, usually with also the folder icon, tricking users into clicking them.
    ECHO In the root directories, we will delete all executable files that carry the
    ECHO same name as a folder. File types that will be deleted are .com, .exe and .scr.
    ECHO WARNING: This may delete legitimate applications. When in doubt, skip this.
    CALL :continue_prompt || SET opt_folder_exe=SKIP
)
IF NOT "X!opt_files!"=="XSKIP" (
    ECHO.
    ECHO [files]
    ECHO Some malware will create the autorun.inf file, so that malware itself may be
    ECHO automatically run on computers that didn't have AutoRun disabled. Except for
    ECHO optical drives, no other drives should ever contain a file named "autorun.inf".
    ECHO We will delete them.
    CALL :continue_prompt || SET opt_files=SKIP
)
IF "X!opt_files!"=="XSKIP" (
    SET opt_mkdir=SKIP
)
IF NOT "X!opt_mkdir!"=="XSKIP" (
    ECHO.
    ECHO [mkdir]
    ECHO With the autorun.inf file deleted, in order to prevent malware from creating it
    ECHO again, we will create a folder with the same name. This folder will be hidden -
    ECHO users won't see it, but can interfere with the malware. Unless it has the
    ECHO ability to delete the folder, the drive won't be infected by AutoRun any more.
    CALL :continue_prompt || SET opt_mkdir=SKIP
)

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
        ECHO Drive %%d:
        REM Symlinks have to be handled first because we can't guarantee that
        REM user's 'attrib' utility supports '/L' (don't follow symlinks).
        IF NOT "X!opt_symlinks!"=="XSKIP" CALL :delete_symlinks
        REM :clear_files_attrib must be done before deleting anything, or DEL
        REM refuses to delete files with certain attributes.
        IF NOT "X!opt_attrib!"=="XSKIP" CALL :clear_files_attrib
        IF NOT "X!opt_shortcuts!"=="XSKIP" CALL :delete_shortcuts
        IF NOT "X!opt_folder_exe!"=="XSKIP" CALL :delete_folder_exes
        IF NOT "X!opt_files!"=="XSKIP" (
            FOR %%f IN (autorun.inf) DO (
                CALL :file_to_directory %%f
            )
        )
    )
)
ECHO.
ECHO All done. Press any key to close this program.
PAUSE >nul
GOTO main_end

:main_help
ECHO.
ECHO   --help                   show this help
ECHO   --no-restart             don't restart script ^(default will restart when
ECHO                            Command Processor AutoRun is detected^)
ECHO   --skip-cmd-autorun       don't delete Command Processor AutoRun registry
ECHO   --all-users-cmd-autorun  delete ALL USERS' cmd.exe AutoRun ^(default: no^)
ECHO   --no-inf-mapping         don't stop parsing of autorun.inf
ECHO   --skip-mountpoints2      don't clean MountPoints2 registry keys ^(caches^)
ECHO   --skip-known-ext         don't show extensions of known file types
ECHO   --all-users-known-ext    ALL USERS show extensions of known file types
ECHO                            ^(default: no^)
ECHO   --skip-shortcut-icon     don't restore arrow icons of shortcut files
ECHO   --default-shortcut-icon  unset custom shortcut icon and use system default
ECHO The following procedures apply to root directories of all drives:
ECHO   --keep-symlinks          don't delete symbolic links
ECHO   --keep-attrib            keep all files' Hidden or System attributes
ECHO   --keep-shortcuts         don't delete shortcut files ^(.lnk and .pif^)
ECHO   --keep-folder-exe        don't delete executables with same name as folders
ECHO   --keep-files             don't delete autorun.inf or other malicious files
ECHO   --no-mkdir               don't create directories after deleting files
GOTO main_end

:main_restart
ECHO Restarting this program without cmd.exe AutoRun commands...
cmd /d /c "%0 --no-restart !args!"
GOTO main_end

:main_end
ENDLOCAL
GOTO :EOF

REM ---------------------------------------------------------------------------
REM SUBROUTINES

REM Prompt user to continue or skip.
REM @return 0 if user says to continue, or 1 if says to skip
:continue_prompt
    REM Note: If the user answers empty string after a "SET /P", The variable
    REM is kept the previous value and NOT set to the empty string.
    SET prompt=
    SET /P prompt="Press Enter to continue, or type 'skip' to skip this step: "
    IF "X!prompt!"=="X" EXIT /B 0
    IF /I "X!prompt!"=="XY" EXIT /B 0
    IF /I "X!prompt!"=="XSKIP" EXIT /B 1
    GOTO continue_prompt
GOTO :EOF

REM Displays a (generic) error message for any write error in registry.
REM (add key, delete key, add value, etc.)
REM @param %1 Short name about the registry key or value.
:show_reg_write_error
    ECHO Error occurred when modifying registry: "%~1">&2
    IF NOT "X!g_has_error_displayed!"=="X1" (
        SET g_has_error_displayed=1
        ECHO You may need to re-run this program with administrator privileges.>&2
        PAUSE
    )
GOTO :EOF

REM Prepare g_sids global variable (list of all user SIDs on the computer.)
:prepare_sids
    IF NOT "X!g_sids!"=="X" GOTO :EOF
    FOR /F "usebackq delims=" %%k IN (`reg query HKU 2^>nul`) DO (
        REM 'reg' outputs junk lines, make sure the line truly represents a
        REM user and not a Classes key.
        SET "key=%%~k"
        IF /I "!key:~0,11!"=="HKEY_USERS\" (
            IF /I NOT "!key:~-8!"=="_Classes" (
                SET g_sids=!g_sids! !key:~11!
            )
        )
    )
GOTO :EOF

REM Delete a registry key (if it exists).
REM @param %1 Key name, including root key
REM @param %2 Short hint of the key, displayed in error messages
REM @return 0 if key doesn't exist or is deleted successfully, or 1 on error
:delete_reg_key
    REM Must query the whole key. 'reg' in Windows 2000/XP returns failure on a
    REM "value not set" default with '/ve', while in Vista it returns success.
    reg query "%~1" >nul 2>nul || EXIT /B 0
    reg delete "%~1" /f >nul && EXIT /B 0
    CALL :show_reg_write_error %2
    EXIT /B 1
GOTO :EOF

REM Clean a registry key (if it exists).
REM @param %1 Key name, including root key
REM @param %2 Short hint of the key, displayed in error messages
REM @return 0 if key doesn't exist or is cleaned successfully, or 1 on error
:clean_reg_key
    CALL :delete_reg_key %1 %2 || EXIT /B 1
    REM Create a dummy value so that "reg add" won't affect the default value
    REM of the key.
    reg add "%~1" /v "dummyValue" /f >nul 2>nul || EXIT /B 1
    reg delete "%~1" /v "dummyValue" /f >nul 2>nul
GOTO :EOF

REM Delete a non-default registry value (if it exists).
REM @param %1 Key name, including root key
REM @param %2 Value name
REM @param %3 Short hint of the entry, displayed in error messages
REM @return 0 if value doesn't exist or is deleted, or 1 on error
:delete_reg_value
    reg query "%~1" /v "%~2" >nul 2>nul || EXIT /B 0
    reg delete "%~1" /v "%~2" /f >nul && EXIT /B 0
    CALL :show_reg_write_error %3
    EXIT /B 1
GOTO :EOF

REM Check if the file is in one of the list of files to keep.
REM @param %1 Category
REM @param %2 File to check
REM @return 0 (true) if the file is in the list
:is_file_to_keep
    SET list=
    IF "X%1"=="XSYMLINK"   SET list=!KEEP_SYMLINK_FILES!
    IF "X%1"=="XHS_ATTRIB" SET list=!KEEP_HS_ATTRIB_FILES!
    IF "X%1"=="XH_ATTRIB"  SET list=!KEEP_H_ATTRIB_FILES!
    IF "X%1"=="XS_ATTRIB"  SET list=!KEEP_S_ATTRIB_FILES!
    IF "X%1"=="XEXECUTE"   SET list=!KEEP_EXECUTE_FILES!
    FOR %%i IN (%list%) DO (
        IF /I "X%~2"=="X%%~i" EXIT /B 0
        IF /I "X%~2\"=="X%%~i" (
            ECHO.%~a2 | find "d" >nul 2>nul && EXIT /B 0
        )
    )
    EXIT /B 1
GOTO :EOF

REM Delete a specified symlink.
REM @param %1 Symlink name
REM @return 0 on success
:delete_symlink
    REM 'attrib' without '/L' follows symlinks so can't be used here, but
    REM "DEL /F /A:<attrib>" could do.
    SET attr=
    ECHO.%~a1 | find "h" >nul 2>nul && SET attr=h
    ECHO.%~a1 | find "s" >nul 2>nul && SET attr=!attr!s
    DEL /F /A:!attr! "%~1"
GOTO :EOF

REM Delete all file symlinks in current directory.
REM Note that this function will have problems with files with newlines ('\n')
REM in their filenames.
:delete_symlinks
    REM Directory symlinks/junctions are harmless. Leave them alone.
    REM DIR command in Windows 2000 supports "/A:L", but displays symlinks
    REM (file or directory) as junctions. Undocumented feature.
    REM The "2^>nul" is to suppress the "File not found" output by DIR command.
    FOR /F "usebackq delims=" %%f IN (`DIR /A:L-D /B /O:N 2^>nul`) DO (
        CALL :is_file_to_keep SYMLINK "%%~f" && (
            ECHO Symbolic link "%%~f" skipped for safety.
        ) || (
            ECHO Delete symbolic link "%%~f"
            CALL :delete_symlink "%%~f"
        )
    )
    REM Note when handling directory links/junctions:
    REM If "dirlink" is a directory link, "DEL dirlink" removes all files in
    REM the target directory (DANGEROUS), "RMDIR dirlink" (with or without
    REM '/S') removes the symlink without touching anything in the target
    REM directory (SAFE).
GOTO :EOF

REM Clear hidden and system attributes of all files in current directory.
REM Note that this function will have problems with files with newlines ('\n')
REM in their filenames.
:clear_files_attrib
    REM 'attrib' refuses to clear either H or S attribute for files with both
    REM attributes set. Must clear both simultaneously.
    REM The exit code of 'attrib' is unreliable.
    REM The "2^>nul" is to suppress the "File not found" output by DIR command.
    FOR /F "usebackq delims=" %%f IN (`DIR /A:HS /B /O:N 2^>nul`) DO (
        CALL :is_file_to_keep HS_ATTRIB "%%~f" && (
            ECHO File "%%~f" ^(Hidden+System attributes^) skipped for safety.
        ) || (
            ECHO Clear Hidden+System attributes of "%%~f"
            attrib -H -S "%%~f"
        )
    )
    FOR /F "usebackq delims=" %%f IN (`DIR /A:H-S /B /O:N 2^>nul`) DO (
        CALL :is_file_to_keep H_ATTRIB "%%~f" && (
            ECHO File "%%~f" ^(Hidden attribute^) skipped for safety.
        ) || (
            ECHO Clear Hidden attribute of "%%~f"
            attrib -H "%%~f"
        )
    )
    FOR /F "usebackq delims=" %%f IN (`DIR /A:S-H /B /O:N 2^>nul`) DO (
        CALL :is_file_to_keep S_ATTRIB "%%~f" && (
            ECHO File "%%~f" ^(System attribute^) skipped for safety.
        ) || (
            ECHO Clear System attribute of "%%~f"
            attrib -S "%%~f"
        )
    )
GOTO :EOF

REM Delete .lnk and .pif shortcut files in current directory.
:delete_shortcuts
    ECHO Deleting .lnk and .pif shortcuts...
    DEL /F *.lnk
    DEL /F *.pif
GOTO :EOF

REM Delete all executable files (.com, .exe and .scr) that carry the same name
REM as a folder in current directory.
:delete_folder_exes
    REM Note: .bat and .cmd are self-executable, but their icons are static, so
    REM leave them alone.
    REM The exit code of DEL command is unreliable.
    FOR /F "usebackq delims=" %%d IN (`DIR /A:D /B /O:N 2^>nul`) DO (
        FOR /F "usebackq delims=" %%e IN (
            `DIR /A:-D /B /O:N "%%~d.com" "%%~d.exe" "%%~d.scr" 2^>nul`
        ) DO (
            CALL :is_file_to_keep EXECUTE "%%~e" && (
                ECHO File "%%~e" skipped for safety.
            ) || (
                ECHO Delete "%%~e"
                DEL /F "%%~e"
            )
        )
    )
GOTO :EOF

REM Force delete a file and create a directory with the same name.
REM @param %1 File name to be converted into a directory
:file_to_directory
    IF EXIST %1 (
        ECHO.%~a1 | find "d" >nul 2>nul && (
            REM If file exists and is a directory, keep it.
            attrib +R +H +S "%~1"
            EXIT /B 0
        )
        ECHO Delete "%~1"
        DEL /F "%~1"
        IF EXIST %1 EXIT /B 1
    )
    IF NOT "X!opt_mkdir!"=="XSKIP" CALL :make_directory %1
GOTO :EOF

REM Create a directory and write a file named DO_NOT_DELETE.txt inside it.
REM @param %1 Directory name
:make_directory
    MKDIR %1 || (
        ECHO Error occurred when creating directory: "%~1">&2
        EXIT /B 1
    )
    REM Don't localize the text below. I want this file to be readable despite
    REM the encoding the user's system is in, and it's difficult to convert
    REM character encodings in shell.
    (
        ECHO This folder, "%~1", is to protect your disk from injecting a
        ECHO malicious %1 file.
        ECHO Your disk may still carry the USB or AutoRun malware, but it will NOT be
        ECHO executed anymore.
        ECHO Please do not delete this folder. If you do, you'll lose the protection.
        ECHO.
        ECHO This folder is generated by 'usb_vaccine.cmd'. Project website:
        ECHO ^<https://github.com/Explorer09/usb_vaccine^>
    ) >"%~1\DO_NOT_DELETE.txt"
    attrib +R +H +S "%~1"
    EXIT /B 0
GOTO :EOF

REM ---------------------------------------------------------------------------
:EOF
