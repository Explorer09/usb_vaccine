@ECHO OFF
SETLOCAL EnableExtensions
IF CMDEXTVERSION==2 GOTO cmd_ext_ok
ENDLOCAL ;
echo Requires Windows 2000 or later.
GOTO EOF
exit 1;
REM Press Ctrl-C and answer Y to terminate.
COPY CON: NUL:
%0
:cmd_ext_ok
ENDLOCAL
SETLOCAL EnableExtensions EnableDelayedExpansion

REM ---------------------------------------------------------------------------
REM 'usb_vaccine.cmd' version 3 beta zh-TW (2018-07-28)
REM Copyright (C) 2013-2018 Kang-Che Sung <explorer09 @ gmail.com>

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
SET HKLM_CLS=!HKLM_SFT!\Classes
SET HKLM_SFT_WOW=!HKLM_SFT!\Wow6432Node

SET "CMD_SUBKEY=Microsoft\Command Processor"
SET "INF_MAP_SUBKEY=Microsoft\Windows NT\CurrentVersion\IniFileMapping\autorun.inf"
SET "EXPLORER_SUBKEY=Microsoft\Windows\CurrentVersion\Explorer"
SET "ADVANCED_SUBKEY=!EXPLORER_SUBKEY!\Advanced"
SET "SHELL_ICON_SUBKEY=!EXPLORER_SUBKEY!\Shell Icons"

REM BIG5 許蓋功問題 workaround
SET "BIG5_A15E=）"
SET "BIG5_A65E=回"
SET "BIG5_AE7C=徑"
SET "BIG5_B77C=會"

REM Files to keep. The whitelist.
SET KEEP_SYMLINK_FILES=
FOR %%i IN (
"vmlinux" "vmlinuz"
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
"@oldboot.ui" "SUHDLOG.DAT" "SUHDLOG.---" "ldlinux.sys" "ldlinux.c32"
"arcldr.exe" "arcsetup.exe" "Boot\" "bootmgr" "BOOTNXT" "BOOTSECT.BAK"
"BOOTTGT" "BOOTLOG.TXT" "BOOTLOG.PRV" "DETLOG.TXT" "DETLOG.OLD" "NETLOG.TXT"
"SETUPLOG.TXT" "SETUPLOG.OLD" "system.1st" "UNINSTAL.INI" "WINLFN.INI"
"System Volume Information\" "cmdcons\" "cmldr" "Recovery\" "SECURITY.BIN"
"VIDEOROM.BIN" "EBD.SYS"
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
"W9XUNDO.INI" "$INPLACE.~TR\" "$WINDOWS.~Q\" "$Windows.~BT\" "$Windows.~WS\"
"_Restore\" "$WINRE_BACKUP_PARTITION.MARKER" "DOS00I.400" "DOS01L.400"
"ProgramData\" "MSOCache\"
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
"STACKER.EXE" "arcldr.exe" "arcsetup.exe"
) DO (
    SET KEEP_EXECUTE_FILES=!KEEP_EXECUTE_FILES! %%i
)

REM ---------------------------------------------------------------------------
REM MAIN

SET g_reg_bak=
SET g_sids=
IF "!opt_move_subdir!"=="" SET opt_move_subdir=\MALWARE

REM Needed by restart routine. SHIFT will change %%*.
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
            symlink_ext
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
    )
    REM %%0 is needed by restart routine. Don't touch.
    SHIFT /1
GOTO main_parse_options

:main_sanity_test
IF "!opt_help!"=="1" SET opt_restart=SKIP
IF "!opt_reg_bak!"=="SKIP" SET g_reg_bak=FAIL

REM Humbly quit when we get a Unix 'find' utility. We won't bother with
REM 'findstr' or (ported) 'grep'.
find . -prune >NUL: 2>NUL: && GOTO main_find_error
ECHO X | find "X" >NUL: 2>NUL: || GOTO main_find_error

IF "!opt_move_subdir!"=="" GOTO main_invalid_path
SET opt_move_subdir=!opt_move_subdir:^"=!
REM ^"
IF "!opt_move_subdir!"=="" GOTO main_invalid_path
SET opt_move_subdir=!opt_move_subdir:/=\!
IF /I "!opt_move_subdir!"=="NUL:" SET opt_move_subdir=NUL
REM Technically we can't check for every possibility of valid path without
REM actually 'mkdir' with it, but we may filter out common path attacks.
IF "!opt_move_subdir:~0,2!"=="\\" GOTO main_invalid_path
REM Windows 9x allows "\...\", "\....\" and so on for grandparent or any
REM ancestor directory. Thankfully it doesn't work anymore in NT.
SET "name=\!opt_move_subdir!\"
IF NOT "!name!"=="!name:*\..\=!" GOTO main_invalid_path
CALL :has_path_char ":*?<>|" && GOTO main_invalid_path

REM Check if "FOR /F" supports unquoted options and 'eol' being null.
REM Check this in a subshell because (a) it won't halt our script in case of
REM unsupported syntax, and (b) we need to disable Command Processor AutoRun.
SET g_cmdfor_unquoted_opts=0
SET "a=FOR /F tokens^=1-2^ delims^=^"
SET b="^ eol^= %%i IN (" ;""x") DO IF NOT "%%i.%%j"==" ;.x^" EXIT /B 1
REM ^"
!ComSpec! /q /d /e:on /c "!a!!b!" >NUL: 2>NUL: && SET g_cmdfor_unquoted_opts=1
REM Delayed expansion is not performed in FOR options field.
IF "!g_cmdfor_unquoted_opts!"=="1" (
    SET "FOR_OPTS_FOR_DIR_B=/F delims^=^ eol^="
) ELSE (
    SET FOR_OPTS_FOR_DIR_B=/F "eol=/ delims="
    ECHO 警告：此命令直譯器（cmd.exe!BIG5_A15E!不支援無引號的 "FOR /F" 選項字串。>&2
)

SET g_is_wow64=0
IF DEFINED PROCESSOR_ARCHITEW6432 (
    IF NOT "!opt_restart!"=="SKIP" GOTO main_restart_native
    SET g_is_wow64=1
    ECHO 注意：偵測到 WoW64 的執行環境。本腳本應該要在作業系統預設的 64 位元的命令直譯器>&2
    ECHO （cmd.exe!BIG5_A15E!下執行。>&2
)

reg query "HKCU" >NUL: 2>NUL: || (
    REM Without 'reg', we cannot detect Command Processor AutoRun, so always
    REM try restarting without it before going further.
    IF NOT "!opt_restart!"=="SKIP" GOTO main_restart
    ECHO.>&2
    ECHO *** 錯誤：無法使用 reg.exe 來存取 Windows 登錄！>&2
    ECHO.>&2
    ECHO 如果您使用 Windows 2000，請安裝 Windows 2000 支援工具。>&2
    ECHO 詳情請見 ^<https://support.microsoft.com/kb/301423^>，您可以從此下載支援工具：>&2
    ECHO ^<https://www.microsoft.com/download/details.aspx?id=18614^>>&2
    IF "!opt_help!"=="1" GOTO main_help
    ECHO.>&2
    ECHO 所有登錄檔工作將!BIG5_B77C!被跳過。>&2
    GOTO main_all_drives
)

SET has_wow64=0
reg query "!HKLM_SFT_WOW!" >NUL: 2>NUL: && SET has_wow64=1

:main_cmd_autorun
REM The Command Processor AutoRun will execute every time we do command
REM substitution (via "FOR /F") and may pollute output of our every command.
SET has_cmd_autorun=0
FOR %%k IN (!HKLM_SFT_WOW! !HKLM_SFT! HKCU\Software) DO (
    REM "reg query" outputs header lines even if key or value doesn't exist.
    reg query "%%k\!CMD_SUBKEY!" /v "AutoRun" >NUL: 2>NUL: && (
        IF NOT "!opt_restart!"=="SKIP" GOTO main_restart
        SET has_cmd_autorun=1
        REM Show user the AutoRun values along with error message below.
        REM Key name included in "reg query" output.
        IF "!g_is_wow64!!has_wow64!%%k"=="10!HKLM_SFT!" (
            ECHO （底下的機碼為 WoW64 重定向的機碼，它的實際名稱為>&2
            ECHO   "!HKLM_SFT_WOW!\!CMD_SUBKEY!"!BIG5_A15E!>&2
        )
        IF NOT "!g_is_wow64!!has_wow64!%%k"=="11!HKLM_SFT!" (
            reg query "%%k\!CMD_SUBKEY!" /v "AutoRun" >&2
        )
    )
)
IF "!has_cmd_autorun!"=="1" (
    ECHO *** 注意：在此訊息顯示之前，您的命令直譯器（cmd.exe!BIG5_A15E!已經自動執行了一些命令，這>&2
    ECHO     些命令可能為惡意程式。>&2
)
IF "!opt_help!"=="1" GOTO main_help
IF "!opt_cmd_autorun!"=="SKIP" GOTO main_inf_mapping
IF "!has_cmd_autorun!"=="1" (
    IF NOT "!opt_cmd_autorun!"=="ALL_USERS" (
        ECHO [cmd-autorun]
        ECHO 為了安全性的原因，我們將刪除上面列出的 "AutoRun" 登錄值。
        ECHO （影響全機與目前使用者的設定。此無法被復原。若要刪除所有使用者的設定，請指定
        ECHO '--all-users-cmd-autorun' 選項。!BIG5_A15E!
        CALL :continue_prompt || GOTO main_inf_mapping
    )
    FOR %%k IN (!HKLM_SFT_WOW! !HKLM_SFT! HKCU\Software) DO (
        CALL :delete_reg_value "%%k" "!CMD_SUBKEY!" "AutoRun" "Command Processor /v AutoRun"
    )
)
IF "!opt_cmd_autorun!"=="ALL_USERS" (
    CALL :prepare_sids
    FOR %%i IN (!g_sids!) DO (
        ECHO SID %%~i
        CALL :delete_reg_value "HKU\%%~i\Software" "!CMD_SUBKEY!" "AutoRun" "Command Processor /v AutoRun"
    )
)

:main_inf_mapping
SET has_inf_mapping=1
reg query "!HKLM_SFT!\!INF_MAP_SUBKEY!" /ve 2>NUL: | find /I "@" >NUL: || (
    SET has_inf_mapping=0
    ECHO.>&2
    ECHO *** 注意：您的電腦易受 AutoRun 惡意軟體的攻擊！>&2
)
ECHO.
ECHO 本程式可以幫助您關閉自動執行（AutoRun!BIG5_A15E!、清理您磁碟裡的 autorun.inf 檔案、移除
ECHO 捷!BIG5_AE7C!並顯示被隱藏的檔案。這些動作復原 AutoRun 惡意軟體做造成的傷害。
ECHO 本程式「並不!BIG5_B77C!」移除惡意軟體本身，所以不能用來取代防毒軟體。請安裝一套防毒軟體
ECHO 來保護您的電腦。
ECHO 如果您使用 Windows 2000、XP、Server 2003、Vista 或 Server 2008，我們強烈建議您
ECHO 安裝微軟的 KB967715 與 KB971029 更新，此二更新修正了 AutoRun 實作的臭蟲（即使我
ECHO 們!BIG5_B77C!停止所有的 AutoRun!BIG5_A15E!。
ECHO 請見 ^<https://technet.microsoft.com/library/security/967940.aspx^>

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
ECHO 當您放入光碟，或滑鼠點擊光碟機圖示時，Windows 在預設下!BIG5_B77C!自動執行某些程式（通常
ECHO 是安裝程式!BIG5_A15E!。原本是提供方便，但這個「自動執行」（AutoRun!BIG5_A15E!設計卻容易被惡意軟體
ECHO 利用，在使用者未查覺的情況下自動執行。
ECHO 我們將關閉所有自動執行（AutoRun!BIG5_A15E!，並停止 Windows 剖析任何 autorun.inf 檔案。關
ECHO 閉 AutoRun 之後，如果您要從光碟裡面安裝或執行軟體，您必須手動開啟裡面的
ECHO Setup.exe。這並不影響音樂，電影光碟，或 USB 裝置的自動播放（AutoPlay!BIG5_A15E!功能。
ECHO （這是全機設定。!BIG5_A15E!
CALL :continue_prompt || GOTO main_mountpoints
CALL :backup_reg "!HKLM_SFT!" "!INF_MAP_SUBKEY!" /ve
reg add "!HKLM_SFT!\!INF_MAP_SUBKEY!" /ve /t REG_SZ /d "@SYS:DoesNotExist" /f >NUL:
IF ERRORLEVEL 1 (
    CALL :show_reg_write_error "IniFileMapping\autorun.inf"
) ELSE (
    CALL :delete_reg_key "!HKLM_SFT!" "DoesNotExist" "!HKLM_SFT!\DoesNotExist"
)
IF "!has_wow64!"=="1" (
    CALL :backup_reg "!HKLM_SFT_WOW!" "!INF_MAP_SUBKEY!" /ve
    reg add "!HKLM_SFT_WOW!\!INF_MAP_SUBKEY!" /ve /t REG_SZ /d "@SYS:DoesNotExist" /f >NUL:
    IF ERRORLEVEL 1 (
        CALL :show_reg_write_error "(WoW64) IniFileMapping\autorun.inf"
    ) ELSE (
        CALL :delete_reg_key "!HKLM_SFT_WOW!" "DoesNotExist" "(WoW64) !HKLM_SFT!\DoesNotExist"
    )
)

:main_mountpoints
IF "!opt_mountpoints!"=="SKIP" GOTO main_known_ext
REM "MountPoints" for Windows 2000, "MountPoints2" for Windows XP and later.
ECHO.
ECHO [mountpoints]
ECHO "MountPoints"（或 "MountPoints2"!BIG5_A15E!登錄機碼為 Windows 檔案總管的 AutoRun 快取資
ECHO 料，在 AutoRun 關閉之後，清理機碼以避免之前裝置的 AutoRun 威脅。
ECHO （影響所有使用者的設定。此無法被復原。!BIG5_A15E!
CALL :continue_prompt || GOTO main_known_ext
CALL :prepare_sids
FOR %%i IN (!g_sids!) DO (
    ECHO SID %%~i
    FOR %%k IN (MountPoints MountPoints2) DO (
        CALL :clean_reg_key "HKU\%%~i\Software" "!EXPLORER_SUBKEY!\%%k" "Explorer\%%k"
    )
)

:main_known_ext
IF "!opt_known_ext!"=="SKIP" GOTO main_exe_ext
REM The value shouldn't exist in HKLM and doesn't work there. Silently delete.
FOR %%k IN (!HKLM_SFT! !HKLM_SFT_WOW!) DO (
    reg delete "%%k\!ADVANCED_SUBKEY!" /v "HideFileExt" /f >NUL: 2>NUL:
)
IF NOT "!opt_known_ext!"=="ALL_USERS" (
    ECHO.
    ECHO [known-ext]
    ECHO Windows 預設!BIG5_B77C!隱藏已知檔案類型的副檔名，但是應用程式可以有自訂的圖示，在副檔名
    ECHO 被隱藏的時候，惡意程式可以利用圖示來偽裝成普通檔案或資料夾，以誘騙使用者去開啟
    ECHO 它們。
    ECHO 我們將取消「控制台」→「資料夾選項」的「隱藏已知檔案類型的副檔名」，使得常用的
    ECHO 副檔名（除捷!BIG5_AE7C!外!BIG5_A15E!永遠被顯示。使用者可以透過副檔名來辨認檔案是否為執行檔（而且
    ECHO 可疑!BIG5_A15E!，以下為可執行的檔案類型：
    ECHO     .com（MS-DOS 應用程式!BIG5_A15E!    .cmd（Windows NT 命令腳本!BIG5_A15E!
    ECHO     .exe（應用程式!BIG5_A15E!           .scr（螢幕保護程式!BIG5_A15E!
    ECHO     .bat（批次檔案!BIG5_A15E!
    ECHO （影響目前使用者的設定，若要更改所有使用者的設定，請指定
    ECHO '--all-users-known-ext' 選項。!BIG5_A15E!
    CALL :continue_prompt || GOTO main_exe_ext
)
REM "HideFileExt" is enabled (0x1) if value does not exist.
reg add "HKCU\Software\!ADVANCED_SUBKEY!" /v "HideFileExt" /t REG_DWORD /d 0 /f >NUL: || (
    CALL :show_reg_write_error "Explorer\Advanced /v HideFileExt"
)
IF "!opt_known_ext!"=="ALL_USERS" (
    CALL :prepare_sids
    FOR %%i IN (!g_sids!) DO (
        ECHO SID %%~i
        reg add "HKU\%%~i\Software\!ADVANCED_SUBKEY!" /v "HideFileExt" /t REG_DWORD /d 0 /f >NUL: || (
            CALL :show_reg_write_error "Explorer\Advanced /v HideFileExt"
        )
    )
)

:main_exe_ext
IF "!opt_exe_ext!"=="ALWAYS" (
    FOR %%k IN (exefile scrfile) DO (
        reg add "!HKLM_CLS!\%%k" /v "AlwaysShowExt" /t REG_SZ /f >NUL: || (
            CALL :show_reg_write_error "HKCR\%%k /v AlwaysShowExt"
        )
    )
    SET opt_exe_ext=FIX
)
IF NOT "!opt_exe_ext!"=="FIX" GOTO main_pif_ext
FOR %%e IN (com exe bat scr cmd) DO (
    CALL :delete_reg_value "!HKLM_CLS!" "%%efile" "NeverShowExt" "HKCR\%%efile /v NeverShowExt"
)
SET list="com=comfile" "exe=exefile" "bat=batfile" "scr=scrfile" "cmd=cmdfile"
CALL :reassoc_file_types !list!

:main_pif_ext
SET "user_msg=目前使用者"
IF "!opt_reassoc!"=="ALL_USERS" SET "user_msg=所有使用者"

IF "!opt_pif_ext!"=="SKIP" GOTO main_scf_icon
REM .pif files already have shortcut arrows; no need to suggest AlwaysShowExt.
reg query "!HKLM_CLS!\piffile" /v "NeverShowExt" >NUL: 2>NUL: || (
    GOTO main_scf_icon
)
REM Thankfully cmd.exe handles .pif right. Only Windows Explorer has this flaw.
ECHO.
ECHO [pif-ext]
ECHO .pif 檔案為 DOS 程式的捷!BIG5_AE7C!。Windows 檔案總管!BIG5_B77C!在使用者請求建立 .com 執行檔的捷
ECHO !BIG5_AE7C!時產生 .pif 檔。然而，檔案總管在處理此檔案類型時有個設計缺陷，如果有人把執行
ECHO 檔重新命名為 .pif 副檔名，而使用者開啟該 .pif 檔案，程式碼就!BIG5_B77C!被執行。此缺陷可
ECHO 以被利用。（執行檔被重新命名為 .pif 檔案後，!BIG5_B77C!取決於 Windows 版本，顯示一般檔案
ECHO 的圖示或是 MS-DOS 圖示。!BIG5_A15E!
ECHO 我們將刪除此檔案類型的 "NeverShowExt" 登錄值，若使用者取消了「隱藏已知檔案類型
ECHO 的副檔名」，他們將!BIG5_B77C!看見 .pif 的副檔名。這可提高警覺。
ECHO （這是全機設定。同時!user_msg!對於此檔案類型的關聯!BIG5_B77C!被重設，而此無法被復原。!BIG5_A15E!
CALL :continue_prompt || GOTO main_scf_icon
CALL :delete_reg_value "!HKLM_CLS!" "piffile" "NeverShowExt" "HKCR\piffile /v NeverShowExt"
CALL :reassoc_file_types "pif=piffile"

:main_scf_icon
IF "!opt_scf_icon!"=="SKIP" GOTO main_scrap_ext
reg query "!HKLM_CLS!\SHCmdFile" >NUL: 2>NUL: || GOTO main_scrap_ext
reg query "!HKLM_CLS!\SHCmdFile" /v "IsShortcut" >NUL: 2>NUL: && (
    GOTO main_scrap_ext
)
ECHO.
ECHO [scf-icon]
ECHO .scf 檔案為 Windows 檔案總管殼層（shell!BIG5_A15E!的指令檔。它們!BIG5_B77C!在使用者開啟的時候執行
ECHO 殼層的內部命令。最常見的例子為 Windows Vista 之前版本的快速啟動列上面的「顯示桌
ECHO 面」。（Vista 或之後的「顯示桌面」圖示為 .lnk 檔案。!BIG5_A15E!即使格式本身不允許程式
ECHO 碼，當殼層的命令被無意間執行時，仍然有可能嚇到使用者。
ECHO 我們將為此檔案類型添加捷!BIG5_AE7C!箭頭圖示，以提高使用者的警覺。
ECHO （這是全機設定。同時!user_msg!對於此檔案類型的關聯!BIG5_B77C!被重設，而此無法被復原。!BIG5_A15E!
CALL :continue_prompt || GOTO main_scrap_ext
reg add "!HKLM_CLS!\SHCmdFile" /v "IsShortcut" /t REG_SZ /f >NUL: || (
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
IF "!opt_scrap_ext!"=="SKIP" GOTO main_symlink_ext
REM Scrap files already have static icon; no need to suggest AlwaysShowExt.
SET scrap_ext_keys=
FOR %%k IN (ShellScrap DocShortcut) DO (
    reg query "!HKLM_CLS!\%%k" /v "NeverShowExt" >NUL: 2>NUL: && (
        SET scrap_ext_keys=!scrap_ext_keys! %%k
    )
)
IF "!scrap_ext_keys!"=="" GOTO main_symlink_ext
ECHO.
ECHO [scrap-ext]
ECHO .shs 與 .shb 檔案分別為儲存文件剪輯資料（scrap!BIG5_A15E!與文件捷!BIG5_AE7C!的格式。它們!BIG5_B77C!在使用
ECHO 者從文件編輯器（例如 WordPad!BIG5_A15E!中拖曳文字出去時產生。此格式允許嵌入可執行的程式
ECHO 碼，當使用者開啟一個（特別製作的!BIG5_A15E!此類型的檔案，程式碼就!BIG5_B77C!被執行。（Windows
ECHO Vista 與之後已經移除剪輯資料檔案的支援。!BIG5_A15E!
ECHO 我們將刪除這些檔案類型的 "NeverShowExt" 登錄值，若使用者取消了「隱藏已知檔案類
ECHO 型的副檔名」，他們將!BIG5_B77C!看見 .shs 與 .shb 的副檔名。這可提高警覺。
ECHO （這是全機設定。同時!user_msg!對於此檔案類型的關聯!BIG5_B77C!被重設，而此無法被復原。!BIG5_A15E!
CALL :continue_prompt || GOTO main_symlink_ext
FOR %%k IN (!scrap_ext_keys!) DO (
    CALL :delete_reg_value "!HKLM_CLS!" "%%k" "NeverShowExt" "HKCR\%%k /v NeverShowExt"
)
CALL :reassoc_file_types "shs=ShellScrap" "shb=DocShortcut"

:main_symlink_ext
REM The ".symlink" association only applies to Windows 8.1 or later, or
REM Windows 7 SP1 with KB3009980 hotfix. This requires shell32.dll's support.
IF "!opt_symlink_ext!"=="SKIP" GOTO main_shortcut_icon
REM If symlinks are not "known" (i.e. there's no "HKCR\.symlink" entry), then
REM the extensions will be always shown. Don't bother then.
reg query "!HKLM_CLS!\.symlink" >NUL: 2>NUL: || GOTO main_shortcut_icon
reg query "!HKLM_CLS!\.symlink" /v "AlwaysShowExt" >NUL: 2>NUL: && (
    reg query "!HKLM_CLS!\.symlink" /v "NeverShowExt" >NUL: 2>NUL: || (
        GOTO main_shortcut_icon
    )
)
ECHO.
ECHO [symlink-ext]
ECHO 符號連結（symbolic link!BIG5_A15E!是 NTFS 檔案系統中的一種特殊檔案。它類似於捷!BIG5_AE7C!，根據
ECHO 路!BIG5_AE7C!與檔名來連結到另一個檔案。符號連結!BIG5_B77C!顯示捷!BIG5_AE7C!的箭頭圖示來辨別。符號連結的不
ECHO 同之處在於它可以是任意的副檔名或不帶副檔名。Windows 檔案總管!BIG5_B77C!預設隱藏符號連結
ECHO 的副檔名（例如 ".txt" 或 ".exe"，它不像捷!BIG5_AE7C!的 ".lnk" 能標記自己為連結!BIG5_A15E!。隱藏
ECHO 符號連結的副檔名並不像隱藏捷!BIG5_AE7C!的 ".lnk" 有意義。
ECHO 我們將強制檔案符號連結永遠顯示其副檔名。這無論使用者是否使用「隱藏已知檔案類型
ECHO 的副檔名」的選項。
ECHO （這是全機設定。同時!user_msg!對於此檔案類型的關聯!BIG5_B77C!被重設，而此無法被復原。!BIG5_A15E!
CALL :continue_prompt || GOTO main_shortcut_icon
reg add "!HKLM_CLS!\.symlink" /v "AlwaysShowExt" /t REG_SZ /f >NUL: || (
    CALL :show_reg_write_error "HKCR\.symlink /v AlwaysShowExt"
)
CALL :delete_reg_value "!HKLM_CLS!" ".symlink" "NeverShowExt" "HKCR\.symlink /v NeverShowExt"
CALL :reassoc_file_types "symlink=.symlink"

:main_shortcut_icon
IF NOT "!opt_shortcut_icon!"=="FIX" GOTO main_file_icon
FOR %%k IN (piffile lnkfile DocShortcut InternetShortcut) DO (
    reg query "!HKLM_CLS!\%%k" >NUL: 2>NUL: && (
        reg add "!HKLM_CLS!\%%k" /v "IsShortcut" /t REG_SZ /f >NUL: || (
            CALL :show_reg_write_error "HKCR\%%k /v IsShortcut"
        )
    )
)
reg query "!HKLM_CLS!\Application.Reference" >NUL: 2>NUL: && (
    reg add "!HKLM_CLS!\Application.Reference" /v "IsShortcut" /t REG_SZ /f >NUL: || (
        CALL :show_reg_write_error "Application.Reference /v IsShortcut"
    )
)
REM The data string "NULL" is in the original entry, in both Groove 2007 and
REM SharePoint Workspace 2010.
reg query "!HKLM_CLS!\GrooveLinkFile" >NUL: 2>NUL: && (
    reg add "!HKLM_CLS!\GrooveLinkFile" /v "IsShortcut" /t REG_SZ /d "NULL" /f >NUL: || (
        CALL :show_reg_write_error "HKCR\GrooveLinkFile /v IsShortcut"
    )
)
CALL :delete_reg_value "!HKLM_SFT!" "!SHELL_ICON_SUBKEY!" "29" "Explorer\Shell Icons /v 29"
IF NOT "!opt_file_icon!"=="FIX" (
    SET list="pif=piffile" "lnk=lnkfile" "shb=DocShortcut" "url=InternetShortcut"
    SET list=!list! "appref-ms=Application.Reference" "glk=GrooveLinkFile"
    CALL :reassoc_file_types !list!
)

:main_file_icon
IF NOT "!opt_file_icon!"=="FIX" GOTO main_all_drives
REM "DefaultIcon" for "Unknown" is configurable since Windows Vista.
SET key=Unknown\DefaultIcon
CALL :backup_reg "!HKLM_CLS!" "!key!" /ve
IF NOT "!ERRORLEVEL!"=="1" (
    reg add "!HKLM_CLS!\!key!" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\shell32.dll,0" /f >NUL: || (
        CALL :show_reg_write_error "HKCR\!key!"
    )
)
SET key=comfile\DefaultIcon
CALL :backup_reg "!HKLM_CLS!" "!key!" /ve
reg add "!HKLM_CLS!\!key!" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\shell32.dll,2" /f >NUL: || (
    CALL :show_reg_write_error "HKCR\!key!"
)
SET key=comfile\shellex\IconHandler
CALL :delete_reg_key "!HKLM_CLS!" "!key!" "HKCR\!key!"
REM Two vulnerabilities exist in the .lnk and .pif IconHandler:
REM MS10-046 (CVE-2010-2568), MS15-020 (CVE-2015-0096)
REM Windows 2000 has no patch for either. XP has only patch for MS10-046.
REM Expect that user disables the IconHandler as the workaround.
FOR %%k IN (piffile lnkfile) DO (
    CALL :delete_reg_key "!HKLM_CLS!" "%%k\DefaultIcon" "HKCR\%%k\DefaultIcon"
    SET key=%%k\shellex\IconHandler
    CALL :backup_reg "!HKLM_CLS!" "!key!" /ve
    reg add "!HKLM_CLS!\!key!" /ve /t REG_SZ /d "{00021401-0000-0000-C000-000000000046}" /f >NUL: || (
        CALL :show_reg_write_error "HKCR\!key!"
    )
)
REM Scrap file types. Guaranteed to work (and only) in Windows 2000 and XP.
FOR %%k IN (ShellScrap DocShortcut) DO (
    reg query "!HKLM_CLS!\%%k" >NUL: 2>NUL: && (
        CALL :backup_reg "!HKLM_CLS!" "%%k\DefaultIcon" /ve
        reg add "!HKLM_CLS!\%%k\DefaultIcon" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\shscrap.dll,-100" /f >NUL: || (
            CALL :show_reg_write_error "HKCR\%%k\DefaultIcon"
        )
        CALL :delete_reg_key "!HKLM_CLS!" "%%k\shellex\IconHandler" "%%k\shellex\IconHandler"
    )
)
REM The "InternetShortcut" key has "DefaultIcon" subkey whose Default value
REM differs among IE versions.
reg query "!HKLM_CLS!\InternetShortcut" >NUL: 2>NUL: && (
    SET key=InternetShortcut\shellex\IconHandler
    CALL :backup_reg "!HKLM_CLS!" "!key!" /ve
    reg add "!HKLM_CLS!\!key!" /ve /t REG_SZ /d "{FBF23B40-E3F0-101B-8488-00AA003E56F8}" /f >NUL: || (
        CALL :show_reg_write_error "InternetShortcut IconHandler"
    )
)
reg query "!HKLM_CLS!\SHCmdFile" >NUL: 2>NUL: && (
    CALL :delete_reg_key "!HKLM_CLS!" "SHCmdFile\DefaultIcon" "HKCR\SHCmdFile\DefaultIcon"
    SET key=SHCmdFile\shellex\IconHandler
    CALL :backup_reg "!HKLM_CLS!" "!key!" /ve
    reg add "!HKLM_CLS!\!key!" /ve /t REG_SZ /d "{57651662-CE3E-11D0-8D77-00C04FC99D61}" /f >NUL: || (
        CALL :show_reg_write_error "HKCR\!key!"
    )
)
reg query "!HKLM_CLS!\Application.Reference" >NUL: 2>NUL: && (
    SET key=Application.Reference\DefaultIcon
    CALL :delete_reg_key "!HKLM_CLS!" "!key!" "!key!"
    SET key=Application.Reference\shellex\IconHandler
    CALL :backup_reg "!HKLM_CLS!" "!key!" /ve
    reg add "!HKLM_CLS!\!key!" /ve /t REG_SZ /d "{E37E2028-CE1A-4f42-AF05-6CEABC4E5D75}" /f >NUL: || (
        CALL :show_reg_write_error "Application.Reference IconHandler"
    )
)
REM The "GrooveLinkFile" key has "DefaultIcon" value (data: "%1") and no
REM "DefaultIcon" subkey.
reg query "!HKLM_CLS!\GrooveLinkFile" >NUL: 2>NUL: && (
    SET key=GrooveLinkFile\ShellEx\IconHandler
    CALL :backup_reg "!HKLM_CLS!" "!key!" /ve
    reg add "!HKLM_CLS!\!key!" /ve /t REG_SZ /d "{387E725D-DC16-4D76-B310-2C93ED4752A0}" /f >NUL: || (
        CALL :show_reg_write_error "!key!"
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
ECHO 現在我們將處理所有磁碟機的根目錄。
ECHO 請插入所有受惡意軟體影響的儲存裝置，包括 USB 隨身碟、外接硬碟、記憶卡、PDA、智
ECHO 慧型手機與數位相機。如果您有 CD- 或 DVD-RW 光碟在光碟機裡，建議您退出它們，以免
ECHO 誤啟動燒錄的動作。
IF /I "!opt_move_subdir!"=="NUL" (
    ECHO 假如可行的話，被發現為可疑的檔案將!BIG5_B77C!被直接刪除。
) ELSE (
    ECHO 假如可行的話，被發現為可疑的檔案將!BIG5_B77C!被移動到磁碟裡名為
    ECHO "!opt_move_subdir!" 的子目錄。
)
ECHO 如果您在此輸入 'skip'，則本程式!BIG5_B77C!結束。
CALL :continue_prompt || GOTO main_end

REM Symlinks have to be handled first because we can't guarantee that user's
REM 'attrib' utility supports '/L' (don't follow symlinks).
IF NOT "!opt_symlinks!"=="SKIP" (
    ECHO.
    ECHO [symlinks] ^(1 / 7^)
    ECHO 從 Windows Vista 開始，NTFS 檔案系統支援「符號連結」（symbolic link!BIG5_A15E!。符號連結
    ECHO 是一種特殊的檔案，功能類似捷!BIG5_AE7C!檔，也帶有捷!BIG5_AE7C!的箭頭圖示，但是符號連結屬於檔案系
    ECHO 統的功能，並且不需帶有副檔名。有些惡意軟體!BIG5_B77C!建立指向（惡意!BIG5_A15E!執行檔的符號連結，
    ECHO 以誘騙使用者去開啟它們。
    IF /I "!opt_move_subdir!"=="NUL" (
        ECHO 我們將刪除存放在根目錄中所有指向檔案（非目錄!BIG5_A15E!的符號連結。
    ) ELSE (
        ECHO 我們將移走存放在根目錄中所有指向檔案（非目錄!BIG5_A15E!的符號連結。
        ECHO 注意：由於技術限制，帶有「隱藏」或「系統」屬性的符號連結反而!BIG5_B77C!被直接刪除。
    )
    CALL :continue_prompt || SET opt_symlinks=SKIP
)
REM [attrib] must be done before moving anything, or MOVE refuses to move
REM Hidden or System files.
IF NOT "!opt_attrib!"=="SKIP" (
    ECHO.
    ECHO [attrib] ^(2 / 7^)
    ECHO 當檔案有設定「隱藏」或「系統」屬性，它們就預設不!BIG5_B77C!在 Windows 檔案總管或 DIR 命
    ECHO 令中顯示。有些惡意軟體!BIG5_B77C!隱藏檔案，並產生相同名稱的執行檔（或是指向執行檔的捷
    ECHO !BIG5_AE7C!!BIG5_A15E!，以誘騙使用者去開啟它們。（惡意軟體並不!BIG5_B77C!真正刪除掉檔案，不然刪除檔案時空
    ECHO 出的磁碟空間很容易引起使用者或防毒軟體的注意。!BIG5_A15E!
    ECHO 除了已知真正的作業系統檔案，我們將解除根目錄中所有檔案與資料夾的「隱藏」與「系
    ECHO 統」屬性。這復原所有被惡意軟體隱藏的檔案（可能也!BIG5_B77C!顯示惡意軟體檔案本身!BIG5_A15E!。
    CALL :continue_prompt || SET opt_attrib=SKIP
)
IF NOT "!opt_shortcuts!"=="SKIP" (
    ECHO.
    ECHO [shortcuts] ^(3 / 7^)
    IF /I "!opt_move_subdir!"=="NUL" (
        ECHO 我們將刪除根目錄中以下類型的捷!BIG5_AE7C!檔案：.pif、.lnk、.shb、.url、.appref-ms 與
        ECHO .glk.
    ) ELSE (
        ECHO 我們將移走根目錄中以下類型的捷!BIG5_AE7C!檔案：.pif、.lnk、.shb、.url、.appref-ms 與
        ECHO .glk.
    )
    CALL :continue_prompt || SET opt_shortcuts=SKIP
)
IF NOT "!opt_folder_exe!"=="SKIP" (
    REM COM format does not allow icons and Explorer won't show custom icons
    REM for an NE or PE renamed to .com.
    ECHO.
    ECHO [folder-exe] ^(4 / 7^)
    ECHO 有些惡意軟體!BIG5_B77C!隱藏資料夾，並產生相同名稱的執行檔，通常同時帶著資料夾圖示，以誘
    ECHO 騙使用者去開啟它們。
    IF /I "!opt_move_subdir!"=="NUL" (
        ECHO 我們將刪除存放在根目錄中且與現存資料夾相同名稱的執行檔。!BIG5_B77C!被刪除的檔案類型為
        ECHO .exe 與 .scr。
    ) ELSE (
        ECHO 我們將移走存放在根目錄中且與現存資料夾相同名稱的執行檔。!BIG5_B77C!被移動的檔案類型為
        ECHO .exe 與 .scr。
    )
    ECHO 警告：這可能!BIG5_B77C!影響到合法的應用程式，若有疑慮，請跳過此步驟。
    CALL :continue_prompt || SET opt_folder_exe=SKIP
)
IF NOT "!opt_autorun_inf!"=="SKIP" (
    ECHO.
    ECHO [autorun-inf] ^(5 / 7^)
    ECHO 有些惡意軟體!BIG5_B77C!建立 autorun.inf 檔案，使自己能在沒有關閉 AutoRun 的電腦裡被自動
    ECHO 執行。除了光碟機以外，其它磁碟機都不應該含有名為 autorun.inf 的檔案。
    IF /I "!opt_move_subdir!"=="NUL" (
        ECHO 我們將刪除它們。
    ) ELSE (
        ECHO 我們將移動並把它們重新命名為 "!opt_move_subdir!\_autorun.in0"。
    )
    IF NOT "!opt_attrib!"=="SKIP" (
        ECHO 同時，對於在根目錄中名為 "autorun.inf" 的資料夾，我們將保留其「隱藏」或「系統」
        ECHO 屬性（如果有設定的話!BIG5_A15E!。如果您選擇跳過，則資料夾!BIG5_B77C!被解除隱藏而顯示出來。
    )
    CALL :continue_prompt || SET opt_autorun_inf=SKIP
)
REM We won't deal with Folder.htt, because technically it could be any name in
REM any location, as specified in Desktop.ini.
IF NOT "!opt_desktop_ini!"=="SKIP" (
    ECHO.
    ECHO [desktop-ini] ^(6 / 7^)
    ECHO 在 Windows 98、2000 或 Me（或是安裝了 IE4 的 95 或 NT 4.0!BIG5_A15E!裡，有個「自訂此資料
    ECHO 夾」的功能，它允許自訂磁碟的根資料夾、建立或編輯資料夾的「Web 畫面」範本（通常
    ECHO 名為 "Folder.htt"!BIG5_A15E!。該範本允許嵌入 JavaScript 或 VBScript，而這些指令碼!BIG5_A65E!在使
    ECHO 用者「瀏覽」資料夾的時候被執行。
    ECHO 如果您使用 Windows 2000 或 XP，我們建議您安裝最新的 Service Pack（至少 2000 SP3
    ECHO 或 XP SP1!BIG5_A15E!以修補允許自訂範本所造成的安全風險。Vista 與之後版本是安全的。
    ECHO "Desktop.ini" 檔案指定了資料夾要使用哪份範本，然而在根目錄裡面，不應該存在
    ECHO Desktop.ini 檔案。（不是每個 Desktop.ini 功能都在根資料夾裡有效，而自訂的 Web
    ECHO 畫面範本可用在根資料夾中並不是當初設計的一部分。!BIG5_A15E!
    IF /I "!opt_move_subdir!"=="NUL" (
        ECHO 我們將刪除根目錄中的 "Desktop.ini" 檔案。
    ) ELSE (
        ECHO 我們將從根目錄中移走 "Desktop.ini" 檔案，並把它們重新命名為
        ECHO "!opt_move_subdir!\_Desktop.in0"。
    )
    IF NOT "!opt_attrib!"=="SKIP" (
        ECHO 同時，對於在根目錄中名為 "Desktop.ini" 的資料夾，我們將保留其「隱藏」或「系統」
        ECHO 屬性（如果有設定的話!BIG5_A15E!。如果您選擇跳過，則資料夾!BIG5_B77C!被解除隱藏而顯示出來。
    )
    CALL :continue_prompt || SET opt_desktop_ini=SKIP
)
IF "!opt_autorun_inf!.!opt_desktop_ini!"=="SKIP.SKIP" SET opt_mkdir=SKIP
IF NOT "!opt_mkdir!"=="SKIP" (
    ECHO.
    ECHO [mkdir] ^(7 / 7^)
    ECHO 移除 autorun.inf 或 Desktop.ini 檔案後，為了避免惡意軟體重新建立其中任一檔案，
    ECHO 我們將建立相同名稱的隱藏目錄，這些目錄使用者看不到，但可干擾惡意軟體，除非惡意
    ECHO 軟體有能力刪除它們，否則磁碟機將不!BIG5_B77C!再受 AutoRun 感染。
    CALL :continue_prompt || SET opt_mkdir=SKIP
)

SET g_files_moved=0
REM In Windows NT versions before Vista, when accessing A:\ or B:\ without a
REM floppy inserted into the respective drive, a graphical (!) error dialog
REM "Windows - No Disk" will pop up, blocking script execution.
REM Only DIR command (in NT 4 or later) on A: or B: shows non-blocking and no-
REM pop-up behavior.
REM The text of this dialog is usually:
REM "There is no disk in the drive. Please insert a disk into drive A:."
REM "[>Cancel<] [&Try Again] [&Continue]"
REM But due to a bug in Windows XP, it may instead show:
REM "Exception Processing Message c0000013 Parameters <address> 4 <address>
REM <address>" (<address> varied among OS language releases)
REM Beware that it's a really bad idea to supress such error dialogs! Don't
REM follow what the Web suggests and set the "ErrorMode" value in
REM "HKLM\SYSTEM\CurrentControlSet\Control\Windows" to 2! It could make real
REM serious errors to go unnoticed in your system.
FOR %%d IN (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO (
    DIR /B %%d:\ >NUL: 2>NUL: && (
        CD /D %%d:\
        SET g_move_status=
        ECHO.
        ECHO 磁碟 %%d：
        IF NOT "!opt_attrib!"=="SKIP" CALL :clear_files_attrib
        IF NOT "!opt_shortcuts!"=="SKIP" CALL :process_shortcuts
        IF NOT "!opt_folder_exe!"=="SKIP" CALL :process_folder_exes
        SET name=autorun.inf
        IF NOT "!opt_autorun_inf!"=="SKIP" CALL :make_dummy_dir
        SET name=Desktop.ini
        IF NOT "!opt_desktop_ini!"=="SKIP" CALL :make_dummy_dir
        IF NOT "!opt_symlinks!"=="SKIP" CALL :process_symlinks
        IF "!g_move_status!"=="OK_EMPTY" (
            DEL "!opt_move_subdir!\README.txt" >NUL:
            RMDIR "!opt_move_subdir!"
        )
    )
)
ECHO.
IF "!g_files_moved!"=="0" (
    ECHO 全部完成。按任意鍵關閉本程式。
) ELSE (
    ECHO 全部完成。請檢查各個 "!opt_move_subdir!"
    ECHO 子目錄，所有可疑檔案皆被移動到那裡了。按任意鍵關閉本程式。
)
PAUSE >NUL:
GOTO main_end

:main_help
ECHO.
ECHO   --help                   顯示此說明
ECHO   --no-restart             不重新啟動腳本（預設!BIG5_B77C!在偵測到命令處裡程式的 AutoRun
ECHO                            時重新啟動!BIG5_A15E!
ECHO   --no-reg-bak             不產生登錄備份檔案 "Vacc_reg.bak"
ECHO   --skip-cmd-autorun       不要刪除命令處裡程式的 AutoRun 登錄值
ECHO   --all-users-cmd-autorun  刪除*所有使用者*的 cmd.exe AutoRun（預設不進行!BIG5_A15E!
ECHO   --no-inf-mapping         不要關閉 autorun.inf 的剖析
ECHO   --skip-mountpoints       不要清理 MountPoints 登錄機碼（快取!BIG5_A15E!
ECHO   --skip-known-ext         不要顯示已知檔案類型的副檔名
ECHO   --all-users-known-ext    *所有使用者*皆顯示已知檔案類型的副檔名（預設不進行!BIG5_A15E!
ECHO   --fix-exe-ext            刪除執行檔類型的 NeverShowExt 登錄值（預設不進行!BIG5_A15E!
ECHO   --always-exe-ext         永遠顯示 .exe 與 .scr 檔案類型的副檔名（預設不進行!BIG5_A15E!
ECHO   --skip-pif-ext           不要刪除 .pif 檔案的 NeverShowExt 登錄值
ECHO   --skip-scf-icon          不要為 .scf 檔案添加捷!BIG5_AE7C!箭頭圖示
ECHO   --skip-scrap-ext         不要刪除 .shs 與 .shb 檔案的 NeverShowExt 登錄值
ECHO   --skip-symlink-ext       不要永遠顯示符號連結（symbolic link!BIG5_A15E!的副檔名
ECHO   --fix-shortcut-icon      復原捷!BIG5_AE7C!檔案的箭頭圖示（預設不進行!BIG5_A15E!
ECHO   --fix-file-icon          復原未知類型、com、pif、lnk、shs、shb、url、scf、
ECHO                            appref-ms 與 glk 檔案類型的圖示（預設不進行!BIG5_A15E!
ECHO   --all-users-reassoc      當編輯檔案關聯時，除了編輯全機預設與目前使用者的設定
ECHO                            外，一併套用到*所有使用者*
ECHO 以下程序是套用在所有磁碟機的根目錄：
ECHO   --move-subdir=子目錄     各磁碟的可疑檔案!BIG5_B77C!被移動到的子目錄
ECHO                            （預設："\MALWARE"!BIG5_A15E!
ECHO   --keep-symlinks          不移動或刪除符號連結（symbolic link!BIG5_A15E!
ECHO   --keep-attrib            保留所有檔案的「隱藏」與「系統」屬性
ECHO   --keep-shortcuts         不移動或刪除捷!BIG5_AE7C!檔案
ECHO   --keep-folder-exe        不移動或刪除與資料夾相同名稱的執行檔
ECHO   --keep-autorun-inf       不移動或刪除 autorun.inf
ECHO   --keep-desktop-ini       不移動或刪除 Desktop.ini
ECHO   --no-mkdir               不建立佔位的目錄
ECHO 為了安全性的原因，此腳本並不!BIG5_B77C!將可疑的檔案移出磁碟機外。要刪除檔案而不是移動的
ECHO 話，請指定 '--move-subdir=NUL'。
GOTO main_end

:main_end
ENDLOCAL
EXIT /B 0

:main_find_error
ECHO *** 嚴重錯誤：不是 DOS/Windows 的 'find' 命令。>&2
ENDLOCAL
EXIT /B 1

:main_invalid_path
ECHO *** 嚴重錯誤：指定在 '--move-subdir' 選項裡的路!BIG5_AE7C!無效。>&2
ENDLOCAL
EXIT /B 1

:main_restart_native
REM KB942589 hotfix brings Sysnative folder support to Windows 2003 SP1+ (IA64
REM and x64) and XP x64 but is never offered in Windows Update.
SET status=1
REM Even with file system redirection in WoW64, the "IF EXIST" construct and
REM 'attrib' command do not redirect and can be used to check the existence of
REM real file names on disk. (Better not run cmd.exe inside if we're unsure
REM that "Sysnative" is a redirected pseudo-directory.)
FOR %%I IN ("!WinDir!\Sysnative") DO (
    REM "%%~aI" redirects.
    CALL :has_ci_substr "%%~aI" "d" && (
        CALL :has_ci_substr "%%~aI" "h" || (
            IF NOT EXIST %%I (
                %%I\cmd /d /c "%0 --no-restart !args!" && GOTO :main_end
                SET status=!ERRORLEVEL!
            )
        )
    )
)
ECHO *** 偵測到 WoW64 的執行環境。本腳本應該要在作業系統預設的 64 位元命令直譯器>&2
ECHO     （cmd.exe!BIG5_A15E!下執行。>&2
ECHO 請按照下列步驟操作：>&2
ECHO 1. 執行 "%%WinDir%%\explorer.exe"（預設、64 位元的 Windows 檔案總管。注意不是>&2
ECHO    System32 或 SysWOW64 目錄底下的 explorer.exe。!BIG5_A15E!>&2
ECHO 2. 在新的檔案總管視窗，瀏覽到 "%%WinDir%%\System32"，然後尋找 "cmd.exe" 並在上面>&2
ECHO    按滑鼠右鍵。>&2
ECHO 3. 選取「以系統管理員身分執行」。>&2
ECHO 4. 在新的命令提示字元視窗，執行下列命令：>&2
ECHO    %0 !args!>&2
ECHO.
PAUSE
ENDLOCAL & EXIT /B %status%

:main_restart
cmd /d /c "%0 --no-restart !args!" && GOTO :main_end
SET status=!ERRORLEVEL!
ECHO *** 重新啟動時發生錯誤。請以下列命令來重新執行此腳本（注意 '/d' 與>&2
ECHO     '--no-restart' 選項!BIG5_A15E!：>&2
ECHO     cmd /d /c ^"%0 --no-restart !args!^">&2
ECHO.
PAUSE
ENDLOCAL & EXIT /B %status%

REM ---------------------------------------------------------------------------
REM SUBROUTINES

REM Checks if string contains any of the substrings, ignoring case.
REM @param %1 String, which must be quoted
REM @param %2... Substrings, each must be quoted and not contain "!" or "="
REM @return 0 (true) if any of the substrings is found in string
:has_ci_substr
    SET "str=%~1"
    REM cmd.exe bug: "SET v=&ECHO.!v:s=r!x" outputs "s=rx" instead of "x".
    REM Must return early lest the bug break the condtional below.
    IF "%~1"=="" EXIT /B 1
    SHIFT /1
    REM Can't use FOR because it expands "*" and "?" that we don't want.
GOTO has_ci_substr_loop_

:has_ci_substr_loop_
    IF "%~1"=="" EXIT /B 1
    REM The first "*" in "!v:*s=r!" syntax is special (read "SET /?" page);
    REM the rest is matched literally even if it contains "*".
    REM Undocumented: String substitution is case insensitive.
    REM Undocumented: On a multi-byte code page, string substitution operates
    REM on characters, not bytes. E.g. !v:s=! won't match the character 0xE073.
    IF NOT "!str!"=="!str:*%~1=!" EXIT /B 0
    SHIFT /1
GOTO has_ci_substr_loop_

REM Checks if path or file name contains any character in the set.
REM @param %1 Quoted string containing set of characters to be checked.
REM @param name Unquoted file name
REM @return 0 (true) if names contain any of the characters in %1
:has_path_char
    FOR /F "tokens=2 eol=/ delims=%~1" %%t IN ("x!name!x") DO (
        REM It won't enter loop body if token 2 is empty, but for safety...
        SETLOCAL DisableDelayedExpansion
        IF NOT "%%t"=="" (
            ENDLOCAL & EXIT /B 0
        )
        ENDLOCAL
    )
EXIT /B 1

REM Prompts user to continue or skip.
REM @return 0 if user says to continue, or 1 if says to skip
:continue_prompt
    REM Note: If the user answers empty string after a "SET /P", The variable
    REM is kept the previous value and NOT set to the empty string.
    SET reply=
    SET /P reply="請按 Enter 鍵繼續，或是輸入 'skip' 跳過此步驟："
    IF "!reply!"=="" EXIT /B 0
    IF /I "!reply!"=="Y" EXIT /B 0
    IF /I "!reply!"=="SKIP" EXIT /B 1
GOTO continue_prompt

REM Creates a file.
REM @param name Unquoted, valid file name
REM @return 0 if file is created
:create_file
    REM There's no atomic "create file if not exist" command in Batch, so we
    REM can't avoid a TOCTTOU attack completely.
    REM "IF EXIST" doesn't detect the existence of file with Hidden attribute.
    REM "%%~aI" outputs empty string for files with (hacked) Device attribute.
    REM Neither of them are more reliable than MKDIR for checking file's
    REM existence (or availability of the file name).
    MKDIR "!name!" || EXIT /B 1
    RMDIR "!name!" & TYPE NUL: >>"!name!"
    IF NOT EXIST "!name!" EXIT /B 1
    FOR %%I IN ("!name!") DO (
        CALL :has_ci_substr "%%~aI" "d" && EXIT /B 1
    )
EXIT /B 0

REM Creates and initializes "Vacc_reg.bak"
:init_reg_bak
    REM This is not .reg format! So we don't allow user to specify file name.
    SET name=Vacc_reg.bak
    CALL :create_file || (
        SET g_reg_bak=FAIL
        ECHO.>&2
        ECHO 警告：無法在此目錄裡建立登錄備份檔 "Vacc_reg.bak">&2
        ECHO "!CD!"!BIG5_A15E!>&2
        ECHO 可能已經存在相同名稱的檔案，或是此目錄是唯讀的。>&2
        ECHO 本程式將!BIG5_B77C!在沒有登錄備份的情況下繼續。>&2
        PAUSE
        GOTO :EOF
    )
    SET g_reg_bak=OK
    (
        REM Don't localize.
        ECHO ; Registry backup generated by 'usb_vaccine.cmd'. Project website:
        ECHO ; ^<https://gitlab.com/Explorer09/usb_vaccine^>
    ) >>"Vacc_reg.bak"
    ECHO.
    ECHO 您的登錄將!BIG5_B77C!備份在此檔案裡：
    FOR %%i IN (Vacc_reg.bak) DO (
        SETLOCAL DisableDelayedExpansion
        ECHO "%%~fi"
        ENDLOCAL
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
    REM With '/ve' option, 'reg' in Windows 2000 or XP exits with 1 on a "value
    REM not set" default, while in 2003 or later it exits with 0. We ensures
    REM Windows 2003's behavior by querying the whole key.
    SET "v=%3"
    IF "%3"=="/ve" SET v=
    reg query "%~1\%~2" !v! %4 >NUL: 2>NUL: || EXIT /B 1
    IF "!g_reg_bak!"=="" CALL :init_reg_bak
    IF "!g_reg_bak!"=="FAIL" EXIT /B 2
    IF "!g_is_wow64!%~1"=="1!HKLM_SFT!" (
        REM Don't localize.
        ECHO ; WoW64 redirected key. Actual key name is
        ECHO ; "!HKLM_SFT_WOW!\%~2"
    ) >>"Vacc_reg.bak"
    SET s=
    IF "%~3%~4"=="" SET s=/s
    reg query "%~1\%~2" %3 %4 !s! >>"Vacc_reg.bak" 2>NUL:
GOTO :EOF

REM Displays a (generic) error message for any write error in registry.
REM @param %1 Short text about the key or value.
:show_reg_write_error
    ECHO 修改登錄時發生錯誤："%~1">&2
    IF "!g_has_error_shown!"=="1" GOTO :EOF
    SET g_has_error_shown=1
    ECHO 您可能需要用系統管理員的權限重新執行此程式。>&2
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
    FOR /F "eol=\ delims=" %%k IN ('reg query HKU 2^>NUL:') DO (
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
REM @param %1 File extension with "." prefix
REM @param %2 ProgID
REM @return 0 on success, 1 if not both %1 and %2 keys exist, or 2 on error
:safe_assoc
    reg query "!HKLM_CLS!\%~2" >NUL: 2>NUL: || EXIT /B 1
    CALL :backup_reg "!HKLM_CLS!" "%~1" /ve
    IF "!ERRORLEVEL!"=="1" EXIT /B 1
    reg add "!HKLM_CLS!\%~1" /ve /t REG_SZ /d "%~2" /f >NUL: && EXIT /B 0
    CALL :show_reg_write_error "!HKLM_CLS!\%~1"
EXIT /B 2

REM Resets file associations for given file types.
REM @param %* List of extensions in "ext=ProgID" (quoted) data pairs.
:reassoc_file_types
    REM p[air], e[xt], i[d], k[ey]
    SET keys=
    FOR %%p IN (%*) DO (
        FOR /F "tokens=1,2 delims==" %%e IN (%%p) DO (
            CALL :safe_assoc ".%%e" "%%f" && (
                SET keys=!keys! ".%%e"
                IF /I NOT ".%%e"=="%%f" SET keys=!keys! "%%f"
            )
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

REM Checks and displays warning message for invalid characters in file name.
REM @param name Unquoted file name
REM @return 0 (true) if file name contains all valid characters
:is_valid_file_name
    REM We check this only because some characters are unsafe to process in
    REM cmd.exe environment. This function isn't meant to catch all invalid
    REM file names. Specifically, checking reserved file names and checking
    REM validity of "short names" are out of this function's scope.
    REM "FOR /F" should have skipped empty lines, but for safety...
    IF "!name!"=="" EXIT /B 1
    REM Token 1 (%%s) is to ensure loop body is always entered.
    SET "FOR_OPTS=/F tokens^=1-2^ eol^=/^ delims^=\/:*?^<^>^|^"
    SET FOR_OPTS=!FOR_OPTS!^"
    REM ^"
    IF "!g_cmdfor_unquoted_opts!"=="1" (
        FOR %FOR_OPTS% %%s IN ("x!name!x") DO (
            SETLOCAL DisableDelayedExpansion
            IF "%%t"=="" (
                ENDLOCAL & EXIT /B 0
            )
            ENDLOCAL
        )
    )
    IF NOT "!name!"==^"!name:*^"=!^" (
        REM ^"
        ECHO 警告："!name!">&2
        ECHO 包含無效的檔案名稱字元。檔案系統可能已損壞。>&2
        EXIT /B 1
    )
    IF "!g_cmdfor_unquoted_opts!"=="0" (
        CALL :has_path_char "\/:*?<>|" || EXIT /B 0
    )
    CALL :has_path_char "/:*" && (
        REM TODO: We might handle NTFS alternate data stream in the future so
        REM ":" might be significant.
        ECHO 警告："!name!">&2
        ECHO 包含無效的檔案名稱字元。檔案系統可能已損壞。>&2
        EXIT /B 1
    )
    CALL :has_path_char "<>" && (
        ECHO 警告："!name!">&2
        ECHO 包含無效的檔案名稱字元「^<」或「^>」。檔案系統已損壞或與 DOS 2 或更新版本或>&2
        ECHO Windows 不相容。>&2
        EXIT /B 1
    )
    CALL :has_path_char "?" && (
        ECHO 警告："!name!">&2
        ECHO 包含無效的檔案名稱字元「?」。此檔案名稱可能使用了與您目前系統地區設定不相容的>&2
        ECHO 字元編碼。>&2
        EXIT /B 1
    )
    ECHO 警告："!name!">&2
    ECHO 包含無效的檔案名稱字元「\」或「^|」。此檔案名稱可能使用了與您目前系統地區設定不>&2
    ECHO 相容的字元編碼，或是檔案系統與 DOS 2 或更新版本或 Windows 不相容。>&2
EXIT /B 1

:is_valid_file_name_NDE
    SETLOCAL EnableDelayedExpansion
    CALL :is_valid_file_name
ENDLOCAL & EXIT /B %ERRORLEVEL%

REM Checks if the name matches regex "(?i)WINLFN([1-9a-f][0-9a-f]*)?\.INI"
REM @param name Unquoted, valid file name
REM @return 0 (true) if it matches
:is_winlfn_name
    IF /I NOT "!name:~0,6!!name:~-4!"=="WINLFN.INI" EXIT /B 1
    IF "!name:~6,1!"=="0" EXIT /B 1
    SET "name=!name:~6,-4!"
    IF "!name!"=="" EXIT /B 0
    FOR %%c IN (0 1 2 3 4 5 6 7 8 9 a b c d e f) DO (
        REM Undocumented: String substitution is case insensitive.
        SET "name=!name:%%c=!"
        IF "!name!"=="" EXIT /B 0
    )
EXIT /B 1

REM Checks if the file should be skipped.
REM @param %1 "Files to keep" list category
REM @param name Unquoted name of file to check
REM @return 0 (true) if the file should be skipped
:is_file_to_skip
    CALL :is_valid_file_name || EXIT /B 0
    REM Special case for OS/2 "EA DATA. SF" and "WP ROOT. SF", which MUST
    REM contain spaces in their short name form.
    FOR %%I IN ("EA DATA. SF" "WP ROOT. SF") DO (
        IF /I %%I=="!name!" (
            SETLOCAL DisableDelayedExpansion
            IF %%I=="%%~nxsI" (
                ENDLOCAL & EXIT /B 1
            )
            ENDLOCAL
        )
    )
    SET attr_d=0
    FOR %%I IN ("!name!") DO (
        CALL :has_ci_substr "%%~aI" "d" && SET attr_d=1
    )
    REM "Files to keep" list
    FOR %%i IN (!KEEP_%~1_FILES!) DO (
        IF /I "!attr_d!!name!"=="0%%~i" EXIT /B 0
        IF /I "!attr_d!!name!\"=="1%%~i" EXIT /B 0
    )
    REM Special case for "WINLFN<hex>.INI"
    IF "%~1!attr_d!"=="HS_ATTRIB0" (
        CALL :is_winlfn_name && EXIT /B 0
    )
    REM Don't clear attributes of what :make_dummy_dir creates.
    IF /I "!attr_d!!name!"=="1autorun.inf" (
        IF NOT "!opt_autorun_inf!"=="SKIP" EXIT /B 0
    )
    IF /I "!attr_d!!name!"=="1Desktop.ini" (
        IF NOT "!opt_desktop_ini!"=="SKIP" EXIT /B 0
    )
EXIT /B 1

:is_file_to_skip_NDE
    SETLOCAL EnableDelayedExpansion
    CALL :is_file_to_skip %1
ENDLOCAL & EXIT /B %ERRORLEVEL%

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
        ECHO 錯誤：無法在磁碟機 !CD:~0,2! 上建立目錄 "!opt_move_subdir!"。>&2
        ECHO 磁碟中可能已經存在相同名稱的檔案，或是磁碟機是唯讀的。>&2
        GOTO :EOF
    )
    SET g_move_status=OK_EMPTY
    (
        ECHO ^(zh-TW.Big5^)
        ECHO.
        ECHO 所有被腳本 'usb_vaccine.cmd' 判定為可疑的檔案皆被移動到此目錄裡了，但是由於
        ECHO 'usb_vaccine.cmd' 並不是防毒軟體，它可能!BIG5_B77C!有錯誤的判斷。請檢查此目錄裡的每個檔
        ECHO 案，確認其中您沒有想要保留的資料。
        ECHO.
        ECHO 如果您要保留檔案，直接將它移!BIG5_A65E!磁碟的根目錄即可。這裡的檔案原本都存放在根目錄。
        ECHO.
        ECHO 當您完成了之後，請刪除此目錄。
        ECHO.
        ECHO 'usb_vaccine.cmd' 專案網站：
        ECHO ^<https://gitlab.com/Explorer09/usb_vaccine^>
    ) >"!opt_move_subdir!\README.txt"
GOTO :EOF

REM Important notes about commands behaviors:
REM - 'attrib' utility refuses to change attributes for Hidden or System files
REM   if the respective '+H'/'-H' or '+S'/'-S' option are not also specified on
REM   the command line. For files with both Hidden and System attributes set,
REM   'attrib' would require both H and S options specified.
REM - 'attrib' without '/L' option follows symlinks when reading or changing
REM   attributes. '/L' is not available before Windows Vista.
REM - 'attrib' seems to always exit with status 0 despite any error, and it
REM   seems to output every message, including error messages, to stdout.
REM - The %~a1 method will retrieve attributes of the link itself, if the file
REM   referenced by %1 is a link (junction or symlink).
REM - DEL command exits with 1 only when arguments syntax or path is invalid.
REM   It's exit code does not distinguish between deletion success and failure.
REM - MOVE command exits with 1 when a move error occurs. There's no way to
REM   specify "don't overwrite" option for MOVE command.
REM - Both DEL and MOVE refuse to process files with Hidden or System (or both)
REM   attribute set. (They'll output the "could not find" error.) However since
REM   Windows NT, DEL supports '/A' option that can workaround this.
REM - If "dirlink" is a directory link (attributes "DL"), "DEL dirlink" deletes
REM   all files in the target directory (DANGEROUS), while "RMDIR dirlink"
REM   (with or without '/S') removes the symlink without touching anything in
REM   the target directory (SAFE). MOVE command on links always processes links
REM   themselves rather than link targets.

REM Clears hidden and system attributes of all files in current directory.
:clear_files_attrib
    SETLOCAL DisableDelayedExpansion
    FOR %FOR_OPTS_FOR_DIR_B% %%f IN ('DIR /A:HS-L /B 2^>NUL:') DO (
        SET "name=%%f"
        CALL :is_file_to_skip_NDE HS_ATTRIB
        IF ERRORLEVEL 1 (
            ECHO 解除隱藏+系統屬性 "%%f"
            attrib -H -S "%%f"
        ) ELSE (
            ECHO 為了安全原因，跳過檔案 "%%f"（隱藏+系統屬性!BIG5_A15E!
        )
    )
    FOR %FOR_OPTS_FOR_DIR_B% %%f IN ('DIR /A:H-S-L /B 2^>NUL:') DO (
        SET "name=%%f"
        CALL :is_file_to_skip_NDE H_ATTRIB
        IF ERRORLEVEL 1 (
            ECHO 解除隱藏屬性 "%%f"
            attrib -H "%%f"
        ) ELSE (
            ECHO 為了安全原因，跳過檔案 "%%f"（隱藏屬性!BIG5_A15E!
        )
    )
    FOR %FOR_OPTS_FOR_DIR_B% %%f IN ('DIR /A:S-H-L /B 2^>NUL:') DO (
        SET "name=%%f"
        CALL :is_file_to_skip_NDE S_ATTRIB
        IF ERRORLEVEL 1 (
            ECHO 解除系統屬性 "%%f"
            attrib -S "%%f"
        ) ELSE (
            ECHO 為了安全原因，跳過檔案 "%%f"（系統屬性!BIG5_A15E!
        )
    )
    ENDLOCAL
GOTO :EOF

REM Moves or deletes the file if it's safe to do so.
REM @param %1 "Files to keep" list category
REM @param %2 Type of file, displayed in (localized) messages
REM @param name Unquoted name of file to process
:process_file
    REM Wrap around and delay-expand to guard against embedded 0x5E "^" or
    REM 0x7C "|" byte in localized strings.
    SET "type=%~2"
    CALL :is_file_to_skip %1 && (
        ECHO 為了安全原因，跳過!type! "!name!"
        GOTO :EOF
    )
    FOR %%I IN ("!name!") DO (
        FOR %%A IN (h s d l) DO (
            SET "attr_%%A=-%%A"
            CALL :has_ci_substr "%%~aI" "%%A" && SET "attr_%%A=%%A"
        )
    )
    REM Always Delete Hidden or System symlinks.
    IF NOT "!attr_h!!attr_s!"=="-h-s" (
        IF "!attr_l!!attr_d!"=="l-d" (
            DEL /F /A:!attr_h:h=H!!attr_s:s=S!L-D "!name!" >NUL:
            DIR /A:!attr_h:h=H!!attr_s:s=S!L-D /B "!name!" >NUL: 2>NUL:
            IF ERRORLEVEL 1 (
                ECHO 已刪除符號連結 "!name!"
            ) ELSE (
                ECHO 無法刪除符號連結 "!name!">&2
            )
            GOTO :EOF
        )
    )
    IF "!g_move_status!"=="" CALL :init_move_subdir
    IF "!g_move_status!"=="DEL" (
        IF "!attr_d!"=="d" GOTO :EOF
        DEL /F /A:!attr_h:h=H!!attr_s:s=S!!attr_l:l=L!-D "!name!" >NUL:
        DIR /A:!attr_h:h=H!!attr_s:s=S!!attr_l:l=L!-D /B "!name!" >NUL: 2>NUL:
        IF ERRORLEVEL 1 (
            ECHO 已刪除!type! "!name!"
        ) ELSE (
            ECHO 無法刪除!type! "!name!">&2
        )
        GOTO :EOF
    )
    IF NOT "!g_move_status:~0,2!"=="OK" (
        ECHO 偵測到但不!BIG5_B77C!移動!type! "!name!"
        GOTO :EOF
    )
    IF NOT "!attr_h!!attr_s!"=="-h-s" (
        ECHO 無法移動!type! "!name!"。（有隱藏或系統屬性!BIG5_A15E!>&2
        GOTO :EOF
    )
    SET "dest=!name!"
    IF /I "!name!"=="autorun.inf" SET dest=_!name:~0,10!0
    IF /I "!name!"=="Desktop.ini" SET dest=_!name:~0,10!0
    IF /I "!name!"=="README.txt" SET dest=_!name!
    REM Should never exist name collisions except the forced rename above.
    IF EXIST "!opt_move_subdir!\!dest!" (
        ECHO 無法移動!type! "!name!" 到 "!opt_move_subdir!"。（目的地檔案已存在!BIG5_A15E!>&2
        GOTO :EOF
    )
    MOVE /Y "!name!" "!opt_move_subdir!\!dest!" >NUL: || (
        ECHO 無法移動!type! "!name!" 到 "!opt_move_subdir!"。>&2
        GOTO :EOF
    )
    SET g_move_status=OK_MOVED
    SET g_files_moved=1
    ECHO 已移動!type! "!name!" 到 "!opt_move_subdir!"。
GOTO :EOF

:process_file_NDE
    SETLOCAL EnableDelayedExpansion
    CALL :process_file %1 %2
    ENDLOCAL & (
        SET g_move_status=%g_move_status%
        SET g_files_moved=%g_files_moved%
EXIT /B %ERRORLEVEL% )

REM Moves or deletes shortcut files in current directory.
:process_shortcuts
    SETLOCAL DisableDelayedExpansion
    FOR %FOR_OPTS_FOR_DIR_B% %%f IN (
        'DIR /A:-D /B *.pif *.lnk *.shb *.url *.appref-ms *.glk 2^>NUL:'
    ) DO (
        SET "name=%%f"
        CALL :process_file_NDE EXECUTE "捷!BIG5_AE7C!檔案"
    )
    ENDLOCAL & (
        SET g_move_status=%g_move_status%
        SET g_files_moved=%g_files_moved%
    )
GOTO :EOF

REM Moves or deletes all .exe and .scr files that carry the same name as a
REM folder in current directory.
:process_folder_exes
    REM .bat, .cmd and .com are self-executable, but their icons are static, so
    REM leave them alone.
    SETLOCAL DisableDelayedExpansion
    FOR %FOR_OPTS_FOR_DIR_B% %%d IN ('DIR /A:D /B 2^>NUL:') DO (
        SET "name=%%d"
        CALL :is_valid_file_name_NDE && (
            FOR %FOR_OPTS_FOR_DIR_B% %%f IN (
                'DIR /A:-D /B "%%d.exe" "%%d.scr" 2^>NUL:'
            ) DO (
                SET "name=%%f"
                CALL :process_file_NDE EXECUTE "檔案"
            )
        )
    )
    ENDLOCAL & (
        SET g_move_status=%g_move_status%
        SET g_files_moved=%g_files_moved%
    )
GOTO :EOF

REM Removes a file and optionally creates a directory with the same name.
REM @param %1 "LFN" if LFN entry should be preserved, empty otherwise
REM @param name Unquoted, valid name of file to remove or directory to create
REM @return 0 if directory exists or is created successfully, or 1 on error
:make_dummy_dir
    FOR %%I IN ("!name!") DO (
        CALL :has_ci_substr "%%~aI" "d" && (
            ECHO 目錄 "!name!" 已存在。
            EXIT /B 0
        )
    )
    DIR /A:-D /B "!name!" >NUL: 2>NUL: && (
        CALL :process_file EXECUTE "檔案"
    )
    IF "!opt_mkdir!"=="SKIP" EXIT /B 0
    MKDIR "!name!" || (
        ECHO 建立目錄 "!name!" 時發生錯誤。>&2
        EXIT /B 1
    )
    REM Rename to short name, if possible, so that we don't store two names for
    REM this directory in file system.
    IF NOT "%~1"=="LFN" (
        FOR %%I IN ("!name!") DO (
            SETLOCAL DisableDelayedExpansion
            IF NOT %%I=="%%~nxsI" (
                REM Use REN because MOVE cannot rename a directory if the new
                REM name differs from old name only in letter case.
                REN %%I "%%~nxsI"
            )
            ENDLOCAL
        )
    )
    ECHO 已建立目錄 "!name!"
    (
        REM Should be in ASCII encoding. It is better to keep an English
        REM version as well as localized one.
        ECHO This directory, "!name!", is to protect your disk from injecting a
        ECHO malicious !name! file.
        ECHO Your disk may still carry the USB or AutoRun malware, but it will NOT be
        ECHO executed anymore.
        ECHO Please do not remove this directory. If you do, you'll lose the protection.
        ECHO.
        ECHO This directory is generated by 'usb_vaccine.cmd'. Project website:
        ECHO ^<https://gitlab.com/Explorer09/usb_vaccine^>
    ) >"!name!\DONT_DEL.txt"
    ECHO.>"!name!\dummy"
    attrib +R +H +S "!name!\dummy"
    attrib +R +H +S "!name!"
EXIT /B 0

REM Moves or deletes all file symlinks in current directory.
:process_symlinks
    REM Directory symlinks/junctions are harmless. Leave them alone.
    SETLOCAL DisableDelayedExpansion
    REM DIR command in Windows 2000 supports "/A:L", but displays symlinks
    REM (file or directory) as junctions. Undocumented feature.
    FOR %FOR_OPTS_FOR_DIR_B% %%f IN ('DIR /A:L-D /B README.txt 2^>NUL:') DO (
        SET "name=%%f"
        CALL :process_file_NDE SYMLINK "符號連結"
    )
    FOR %FOR_OPTS_FOR_DIR_B% %%f IN ('DIR /A:L-D /B 2^>NUL:') DO (
        SET "name=%%f"
        CALL :process_file_NDE SYMLINK "符號連結"
    )
    ENDLOCAL & (
        SET g_move_status=%g_move_status%
        SET g_files_moved=%g_files_moved%
    )
GOTO :EOF

REM ---------------------------------------------------------------------------
:EOF
