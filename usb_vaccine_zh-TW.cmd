@ECHO OFF
SETLOCAL EnableExtensions
IF CMDEXTVERSION 2 GOTO cmd_ext_ok
ENDLOCAL
echo Requires Windows 2000 or later.
GOTO EOF
exit
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

REM BIG5 許蓋功問題 workaround
SET "BIG5_A15E=）"
SET "BIG5_AE7C=徑"
SET "BIG5_B77C=會"

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
            IF "!arg1:-=_!"=="__no_%%i" (
                SET "opt_%%i=SKIP"
            )
        )
    )
    IF "X!arg1:~0,7!"=="X--skip-" (
        FOR %%i IN (cmd_autorun mountpoints2 known_ext shortcut_icon) DO (
            IF "!arg1:-=_!"=="__skip_%%i" (
                SET "opt_%%i=SKIP"
            )
        )
    )
    IF "X!arg1:~0,7!"=="X--keep-" (
        FOR %%i IN (symlinks attrib shortcuts folder_exe files) DO (
            IF "!arg1:-=_!"=="__keep_%%i" (
                SET "opt_%%i=SKIP"
            )
        )
    )
    IF "X!arg1:~0,12!"=="X--all-users-" (
        FOR %%i IN (cmd_autorun known_ext) DO (
            IF "!arg1:-=_!"=="__all_users_%%i" (
                SET "opt_%%i=ALL_USERS"
            )
        )
    )
    REM %0 is needed by restart routine. Don't touch.
    SHIFT /1
    GOTO main_parse_options
)

:main_sanity_test
REM Humbly quit when we get a Unix 'find' utility. We won't bother with 'grep'.
find . -prune >nul 2>nul && (
    ECHO *** 嚴重錯誤：不是 DOS/Windows 的 'find' 命令。>&2
    ENDLOCAL
    EXIT /B 1
)
reg query "HKCU" >nul 2>nul || (
    ECHO.
    ECHO *** 錯誤：無法使用 reg.exe 來存取 Windows 登錄！>&2
    ECHO.
    ECHO 如果您使用 Windows 2000，請安裝 Windows 2000 支援工具。
    ECHO 詳情請見 ^<https://support.microsoft.com/kb/301423^>，您可以從此下載支援工具：
    ECHO ^<https://www.microsoft.com/download/details.aspx?id=18614^>
    IF "X!opt_help!"=="X1" GOTO main_help
    ECHO.
    ECHO 所有登錄檔工作將!BIG5_B77C!被跳過。
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
    ECHO *** 警告：在此訊息顯示之前，您的命令直譯器 ^(cmd.exe^) 已經自動執行了一些命令，這>&2
    ECHO     些命令可能為惡意程式。>&2
)
IF "X!opt_help!"=="X1" GOTO main_help
IF "X!opt_cmd_autorun!"=="XSKIP" GOTO main_inf_mapping
IF "!has_cmd_autorun!"=="1" (
    IF NOT "X!opt_cmd_autorun!"=="XALL_USERS" (
        ECHO.
        ECHO [cmd-autorun]
        ECHO 為了安全性的原因，在 "{HKLM,HKCU}\%CMD_REG_SUBKEY%" 兩個機
        ECHO 碼裡面的 "AutoRun" 登錄值將!BIG5_B77C!被刪除。
        ECHO （影響全機與目前使用者的設定，若要同時刪除其它使用者的設定，請指定
        ECHO '--all-users-cmd-autorun' 選項。此動作無法復原。!BIG5_A15E!
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
reg query %INF_MAPPING_REG_KEY% /ve 2>nul | find /I "@SYS:" >nul || (
    SET has_reg_inf_mapping=0
    ECHO.
    ECHO *** 警告：您的電腦易受 AutoRun 惡意軟體的攻擊！>&2
)
ECHO.
ECHO 本程式可以幫助您關閉自動執行 ^(AutoRun^)、清理您磁碟裡的 autorun.inf 檔案、刪除捷
ECHO !BIG5_AE7C!並顯示被隱藏的檔案。這些動作復原 AutoRun 惡意軟體做造成的傷害。
ECHO 本程式「並不!BIG5_B77C!」移除惡意軟體本身，所以不能用來取代防毒軟體。請安裝一套防毒軟體
ECHO 來保護您的電腦。
ECHO 如果您使用 Windows 2000, XP, Server 2003, Vista 或 Server 2008，我們強烈建議您
ECHO 安裝微軟的 KB967715 與 KB971029 更新，此二更新修正了 AutoRun 實作的臭蟲（即使我
ECHO 們!BIG5_B77C!停止所有的 AutoRun!BIG5_A15E!。
ECHO 請見 ^<https://technet.microsoft.com/library/security/967940.aspx^>

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
ECHO Windows 在預設情況下!BIG5_B77C!在您放入光碟，或滑鼠點擊光碟機圖示時，自動執行某些（安
ECHO 裝!BIG5_A15E!程式。原本是提供方便，但此設計卻容易被惡意軟體利用，在使用者未查覺的情況下
ECHO 自動執行。
ECHO 我們將關閉所有自動執行 ^(AutoRun^)，並停止 Windows 剖析任何 autorun.inf 檔案，包
ECHO 括光碟機。關閉 AutoRun 後，如果您要從光碟裡面安裝或執行軟體，您必須手動點擊裡面
ECHO 的 Setup.exe。這不影響音樂，電影光碟，或 USB 裝置的自動播放 ^(AutoPlay^) 功能。
ECHO （這是全機設定。!BIG5_A15E!
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
ECHO MountPoints2 登錄機碼為作業系統 AutoRun 的快取資料，在 AutoRun 關閉之後，清理機
ECHO 碼以避免之前裝置的 AutoRun 威脅。
ECHO （影響所有使用者的設定。此動作無法復原。!BIG5_A15E!
CALL :continue_prompt || GOTO main_known_ext
CALL :prepare_sids
FOR %%i IN (!g_sids!) DO (
    ECHO SID %%i
    CALL :clean_reg_key "HKU\%%i\%MOUNT2_REG_SUBKEY%" "Explorer\MountPoints2"
)

:main_known_ext
REM The value shouldn't exist in HKLM and doesn't work there. Silently delete.
reg delete "HKLM\%ADVANCED_REG_SUBKEY%" /v "HideFileExt" /f >nul 2>nul

IF "X!opt_known_ext!"=="XSKIP" GOTO main_shortcut_icon
REM We include PIF because it's executable in Windows!
REM It's possible to rename a PE .exe to .pif and run when user clicks it.
IF NOT "X!opt_known_ext!"=="XALL_USERS" (
    ECHO.
    ECHO [known-ext]
    ECHO Windows 預設將已知檔案類型的副檔名隱藏起來。但是，由於應用程式有自訂的圖示，在
    ECHO 副檔名隱藏的時候，惡意程式可以使用圖示來偽裝成一般檔案，誘騙使用者去點擊它們。
    ECHO 我們將取消「控制台」→「資料夾選項」的「隱藏已知檔案類型的副檔名」，使得常用的
    ECHO 副檔名（除捷!BIG5_AE7C!外!BIG5_A15E!永遠被顯示。使用者可以透過副檔名來辨認檔案是否為（惡意!BIG5_A15E!執行
    ECHO 檔，以下副檔名為可執行檔：
    ECHO     .exe（應用程式!BIG5_A15E!           .bat（批次檔案!BIG5_A15E!
    ECHO     .com（MS-DOS 應用程式!BIG5_A15E!    .cmd（Windows NT 命令腳本!BIG5_A15E!
    ECHO     .scr（螢幕保護程式!BIG5_A15E!       .pif（MS-DOS 程式捷!BIG5_AE7C!!BIG5_A15E!
    ECHO 我們!BIG5_B77C!同時刪除以上檔案類型的 "NeverShowExt" 登錄值，該登錄值!BIG5_B77C!永遠隱藏該檔案類
    ECHO 型的副檔名，除了捷!BIG5_AE7C!檔以外不應存在該登錄值。
    ECHO （影響全機與目前使用者的設定，若要同時更改其它使用者的設定，請指定
    ECHO '--all-users-known-ext' 選項。!BIG5_A15E!
    CALL :continue_prompt || GOTO main_shortcut_icon
)
REM "HideFileExt" is enabled (0x1) if value does not exist.
reg add "HKCU\%ADVANCED_REG_SUBKEY%" /v "HideFileExt" /t REG_DWORD /d 0 /f >nul || (
    CALL :show_reg_write_error "Explorer\Advanced /v HideFileExt"
)
REM "NeverShowExt"
FOR %%e IN (exe com scr bat cmd pif) DO (
    CALL :delete_reg_key "HKCU\Software\Classes\.%%e" "HKCU\Software\Classes\.%%e"
    CALL :delete_reg_key "HKCU\Software\Classes\%%efile" "HKCU\Software\Classes\%%efile"
    reg add "HKLM\SOFTWARE\Classes\.%%e" /ve /t REG_SZ /d "%%efile" /f >nul || (
        CALL :show_reg_write_error "HKLM\SOFTWARE\Classes\.%%e"
    )
    CALL :delete_reg_value "HKLM\SOFTWARE\Classes\%%efile" "NeverShowExt" "HKCR\%%efile /v NeverShowExt"
)
IF "X!opt_known_ext!"=="XALL_USERS" (
    CALL :prepare_sids
    FOR %%i IN (!g_sids!) DO (
        ECHO SID %%i
        reg add "HKU\%%i\%ADVANCED_REG_SUBKEY%" /v "HideFileExt" /t REG_DWORD /d 0 /f >nul || (
            CALL :show_reg_write_error "Explorer\Advanced /v HideFileExt"
        )
        FOR %%e IN (exe com scr bat cmd pif) DO (
            CALL :delete_reg_key "HKU\%%i\Software\Classes\.%%e" "HKU\*\Software\Classes\.%%e"
            CALL :delete_reg_key "HKU\%%i\Software\Classes\%%efile" "HKU\*\Software\Classes\%%efile"
        )
    )
)

:main_shortcut_icon
IF "X!opt_shortcut_icon!"=="XSKIP" GOTO main_all_drives
IF NOT "X!opt_shortcut_icon!"=="XDEFAULT" (
    ECHO.
    ECHO [shortcut-icon]
    ECHO 所有的捷!BIG5_AE7C!檔案都應有箭頭的小圖示，尤其是指向執行檔的捷!BIG5_AE7C!。由於捷!BIG5_AE7C!的副檔名常被
    ECHO 隱藏起來，使用者只能透過箭頭的圖示來辨認捷!BIG5_AE7C!檔。
    ECHO 我們將復原常見的捷!BIG5_AE7C!檔案類型 .lnk 與 .pif 的箭頭圖示。此二類型是可以指向執行檔
    ECHO 的。如果您有自訂的捷!BIG5_AE7C!箭頭圖示，在此!BIG5_B77C!使用自訂的圖示。
    ECHO （這是全機設定。!BIG5_A15E!
    CALL :continue_prompt || GOTO main_all_drives
)
FOR %%e IN (lnk pif) DO (
    CALL :delete_reg_key "HKCU\Software\Classes\.%%e" "HKCU\Software\Classes\.%%e"
    CALL :delete_reg_key "HKCU\Software\Classes\%%efile" "HKCU\Software\Classes\%%efile"
    reg add "HKLM\SOFTWARE\Classes\.%%e" /ve /t REG_SZ /d "%%efile" /f >nul || (
        CALL :show_reg_write_error "HKLM\SOFTWARE\Classes\%%e"
    )
    reg add "HKLM\SOFTWARE\Classes\%%efile" /v "IsShortcut" /t REG_SZ /f >nul || (
        CALL :show_reg_write_error "HKCR\%%efile /v IsShortcut"
    )
)
IF "X!opt_shortcut_icon!"=="XDEFAULT" (
    CALL :delete_reg_value %SHELL_ICON_REG_KEY% "29" "Explorer\Shell Icons /v 29"
)

:main_all_drives
ECHO.
ECHO 現在我們將處理所有磁碟機的根目錄。
ECHO 請插入所有受惡意軟體影響的儲存裝置，包括 USB 隨身碟、外接硬碟、記憶卡、PDA、智
ECHO 慧型手機與數位相機。如果您有 CD- 或 DVD-RW 光碟在光碟機裡，建議您退出它們，以免
ECHO 誤啟動燒錄的動作。
PAUSE

IF NOT "X!opt_symlinks!"=="XSKIP" (
    ECHO.
    ECHO [symlinks]
    ECHO 在 Windows Vista 之後，NTFS 檔案系統支援「符號連結」^(Symbolic link^)。符號連結是
    ECHO 一種特殊的檔案，功能類似捷!BIG5_AE7C!檔，也帶有捷!BIG5_AE7C!的箭頭圖示，但是符號連結屬於檔案系統
    ECHO 的功能，而且不需帶有副檔名。有些惡意軟體!BIG5_B77C!建立指向（惡意!BIG5_A15E!執行檔的符號連結，以
    ECHO 誘騙使用者去點擊它們。
    ECHO 我們將刪除根目錄中所有指向檔案（非目錄!BIG5_A15E!的符號連結。
    CALL :continue_prompt || SET opt_symlinks=SKIP
)
IF NOT "X!opt_attrib!"=="XSKIP" (
    ECHO.
    ECHO [attrib]
    ECHO 當檔案有設定「隱藏」或「系統」屬性，它們就預設不!BIG5_B77C!在 Windows 檔案總管或 DIR 命
    ECHO 令中顯示。有些惡意軟體!BIG5_B77C!隱藏檔案，並產生相同名稱的執行檔（或是指向執行檔的捷
    ECHO !BIG5_AE7C!!BIG5_A15E!，以誘騙使用者去點擊它們。（惡意軟體並不!BIG5_B77C!真正刪除掉檔案，不然刪除檔案時空
    ECHO 出的磁碟空間很容易引起使用者或防毒軟體的注意。!BIG5_A15E!
    ECHO 除了已知真正的作業系統檔案，我們將解除根目錄中所有檔案的「隱藏」與「系統」屬
    ECHO 性。這復原所有被惡意軟體給隱藏的檔案（同時有可能顯示惡意軟體檔案本身!BIG5_A15E!。
    CALL :continue_prompt || SET opt_attrib=SKIP
)
IF NOT "X!opt_shortcuts!"=="XSKIP" (
    ECHO.
    ECHO [shortcuts]
    ECHO 我們將刪除根目錄中所有 .lnk 與 .pif 檔案類型的捷!BIG5_AE7C!。
    CALL :continue_prompt || SET opt_shortcuts=SKIP
)
IF NOT "X!opt_folder_exe!"=="XSKIP" (
    ECHO.
    ECHO [folder-exe]
    ECHO 有些惡意軟體!BIG5_B77C!隱藏資料夾，並產生相同名稱的執行檔，通常同時帶著資料夾圖
    ECHO 示，以誘騙使用者去點擊它們。
    ECHO 我們將刪除根目錄中所有與資料夾相同名稱的執行檔。!BIG5_B77C!刪除的檔案類型有 .com, .exe
    ECHO 與 .scr。
    ECHO 警告：這可能!BIG5_B77C!刪除到合法的應用程式，若有疑慮，請跳過此步驟。
    CALL :continue_prompt || SET opt_folder_exe=SKIP
)
IF NOT "X!opt_files!"=="XSKIP" (
    ECHO.
    ECHO [files]
    ECHO 有些惡意軟體!BIG5_B77C!建立 autorun.inf 檔案，使自己在尚未關閉 AutoRun 的電腦裡自動被執
    ECHO 行。除了光碟機以外，其它磁碟機都不應該含有名為 autorun.inf 的檔案。
    ECHO 我們將刪除它們。
    CALL :continue_prompt || SET opt_files=SKIP
)
IF "X!opt_files!"=="XSKIP" (
    SET opt_mkdir=SKIP
)
IF NOT "X!opt_mkdir!"=="XSKIP" (
    ECHO.
    ECHO [mkdir]
    ECHO 刪除 autorun.inf 檔案後，為了避免惡意軟體重新建立它，我們將建立相同名稱的隱藏目
    ECHO 錄，此目錄使用者看不到，但可干擾惡意軟體，除非惡意軟體有能力刪除它，否則磁碟機
    ECHO 將不!BIG5_B77C!再受 AutoRun 感染。
    CALL :continue_prompt || SET opt_mkdir=SKIP
)

REM The "Windows - No Disk" error dialog is right on USB drives that are not
REM "safely removed", but is a bug to pop up on floppy drives. Guides on the
REM web mostly refer this to malware, or suggest suppressing it. Both are
REM wrong. Instead we just inform the user about the error dialog here.
ECHO.
ECHO 如果在存取磁碟機代號時，出現錯誤交談窗「Windows - 沒有磁片。Exception
ECHO Processing Message c0000013」，請按「取消」。（這在空軟碟機上發生時是正常的!BIG5_A15E!
FOR %%d IN (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO (
    IF EXIST %%d:\ (
        CD /D %%d:\
        ECHO 磁碟 %%d：
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
ECHO 全部完成。請按任意鍵關閉本程式。
PAUSE >nul
GOTO main_end

:main_help
ECHO.
ECHO   --help                   顯示此說明
ECHO   --no-restart             不重新啟動腳本（預設!BIG5_B77C!在偵測到命令處裡程式的 AutoRun
ECHO                            時重新啟動!BIG5_A15E!
ECHO   --skip-cmd-autorun       不刪除命令處裡程式的 AutoRun 登錄值
ECHO   --all-users-cmd-autorun  刪除*所有使用者*的 cmd.exe AutoRun（預設不進行!BIG5_A15E!
ECHO   --no-inf-mapping         不停止 autorun.inf 的剖析
ECHO   --skip-mountpoints2      不清理 MountPoints2 登錄機碼（快取!BIG5_A15E!
ECHO   --skip-known-ext         不顯示已知檔案類型的副檔名
ECHO   --all-users-known-ext    *所有使用者*皆顯示已知檔案類型的副檔名（預設不進行!BIG5_A15E!
ECHO   --skip-shortcut-icon     不復原捷!BIG5_AE7C!檔案的箭頭圖示
ECHO   --default-shortcut-icon  取消自訂的捷!BIG5_AE7C!圖示並使用系統預設圖示
ECHO 以下程序是套用在所有磁碟機的根目錄：
ECHO   --keep-symlinks          不刪除符號連結 ^(symbolic link^)
ECHO   --keep-attrib            保留所有檔案的「隱藏」、「系統」屬性
ECHO   --keep-shortcuts         不刪除捷!BIG5_AE7C!檔案（.lnk 與 .pif!BIG5_A15E!
ECHO   --keep-folder-exe        不刪除與資料夾相同名稱的執行檔
ECHO   --keep-files             不刪除 autorun.inf 或其它可能惡意的檔案
ECHO   --no-mkdir               不在刪除檔案後建立目錄
GOTO main_end

:main_restart
ECHO 在停止 cmd.exe 的自動執行 ^(AutoRun^) 命令下，重新啟動本程式...
cmd /d /c "%0 --no-restart !args!" && GOTO main_end
ECHO 重新啟動時發生錯誤。請以下列命令來重新執行本腳本（注意 '/d' 與 '--no-restart'>&2
ECHO 選項!BIG5_A15E!：>&2
ECHO cmd /d /c ^"%0 --no-restart !args!^">&2
PAUSE
GOTO :EOF

:main_end
ENDLOCAL
EXIT /B 0

REM ---------------------------------------------------------------------------
REM SUBROUTINES

REM Prompts user to continue or skip.
REM @return 0 if user says to continue, or 1 if says to skip
:continue_prompt
    REM Note: If the user answers empty string after a "SET /P", The variable
    REM is kept the previous value and NOT set to the empty string.
    SET prompt=
    SET /P prompt="請按 Enter 鍵繼續，或是輸入 'skip' 跳過此步驟："
    IF "X!prompt!"=="X" EXIT /B 0
    IF /I "X!prompt!"=="XY" EXIT /B 0
    IF /I "X!prompt!"=="XSKIP" EXIT /B 1
    GOTO continue_prompt
GOTO :EOF

REM Displays a (generic) error message for any write error in registry.
REM (add key, delete key, add value, etc.)
REM @param %1 Short name about the registry key or value.
:show_reg_write_error
    ECHO 修改登錄時發生錯誤："%~1">&2
    IF NOT "X!g_has_error_displayed!"=="X1" (
        SET g_has_error_displayed=1
        ECHO 您可能需要用系統管理員的權限重新執行此程式。>&2
        PAUSE
    )
GOTO :EOF

REM Prepares g_sids global variable (list of all user SIDs on the computer).
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

REM Deletes a registry key (if it exists).
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

REM Cleans a registry key (if it exists).
REM @param %1 Key name, including root key
REM @param %2 Short hint of the key, displayed in error messages
REM @return 0 if key doesn't exist or is cleaned successfully, or 1 on error
:clean_reg_key
    CALL :delete_reg_key %1 %2 || EXIT /B 1
    REM Create a dummy value so that "reg add" won't affect the default value
    REM of the key.
    reg add "%~1" /v "dummy" /f >nul 2>nul || EXIT /B 1
    reg delete "%~1" /v "dummy" /f >nul 2>nul
GOTO :EOF

REM Deletes a non-default registry value (if it exists).
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

REM Checks if the file is in one of the list of files to keep.
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

REM Deletes a specified symlink.
REM @param %1 Symlink name
:delete_symlink
    REM 'attrib' without '/L' follows symlinks so can't be used here, but
    REM "DEL /F /A:<attrib>" can.
    REM The exit code of DEL command is unreliable.
    SET attr=
    ECHO.%~a1 | find "h" >nul 2>nul && SET attr=h
    ECHO.%~a1 | find "s" >nul 2>nul && SET attr=!attr!s
    DEL /F /A:!attr! "%~1"
GOTO :EOF

REM Deletes all file symlinks in current directory.
REM Note that this function will have problems with files with newlines ('\n')
REM in their filenames.
:delete_symlinks
    REM Directory symlinks/junctions are harmless. Leave them alone.
    REM DIR command in Windows 2000 supports "/A:L", but displays symlinks
    REM (file or directory) as junctions. Undocumented feature.
    REM The "2^>nul" is to suppress the "File not found" output by DIR command.
    FOR /F "usebackq delims=" %%f IN (`DIR /A:L-D /B /O:N 2^>nul`) DO (
        CALL :is_file_to_keep SYMLINK "%%~f" && (
            ECHO 為了安全因素，跳過符號連結 "%%~f"
        ) || (
            ECHO 刪除符號連結 "%%~f"
            CALL :delete_symlink "%%~f"
        )
    )
    REM Note when handling directory links/junctions:
    REM If "dirlink" is a directory link, "DEL dirlink" removes all files in
    REM the target directory (DANGEROUS), "RMDIR dirlink" (with or without
    REM '/S') removes the symlink without touching anything in the target
    REM directory (SAFE).
GOTO :EOF

REM Clears hidden and system attributes of all files in current directory.
REM Note that this function will have problems with files with newlines ('\n')
REM in their filenames.
:clear_files_attrib
    REM 'attrib' refuses to clear either H or S attribute for files with both
    REM attributes set. Must clear both simultaneously.
    REM The exit code of 'attrib' is unreliable.
    REM The "2^>nul" is to suppress the "File not found" output by DIR command.
    FOR /F "usebackq delims=" %%f IN (`DIR /A:HS /B /O:N 2^>nul`) DO (
        CALL :is_file_to_keep HS_ATTRIB "%%~f" && (
            ECHO 為了安全因素，跳過檔案 "%%~f"（隱藏+系統屬性!BIG5_A15E!
        ) || (
            ECHO 解除隱藏+系統屬性 "%%~f"
            attrib -H -S "%%~f"
        )
    )
    FOR /F "usebackq delims=" %%f IN (`DIR /A:H-S /B /O:N 2^>nul`) DO (
        CALL :is_file_to_keep H_ATTRIB "%%~f" && (
            ECHO 為了安全因素，跳過檔案 "%%~f"（隱藏屬性!BIG5_A15E!
        ) || (
            ECHO 解除隱藏屬性 "%%~f"
            attrib -H "%%~f"
        )
    )
    FOR /F "usebackq delims=" %%f IN (`DIR /A:S-H /B /O:N 2^>nul`) DO (
        CALL :is_file_to_keep S_ATTRIB "%%~f" && (
            ECHO 為了安全因素，跳過檔案 "%%~f"（系統屬性!BIG5_A15E!
        ) || (
            ECHO 解除系統屬性 "%%~f"
            attrib -S "%%~f"
        )
    )
GOTO :EOF

REM Deletes .lnk and .pif shortcut files in current directory.
:delete_shortcuts
    ECHO 正在刪除 .lnk 與 .pif 捷!BIG5_AE7C!...
    DEL /F *.lnk
    DEL /F *.pif
GOTO :EOF

REM Deletes all executable files (.com, .exe and .scr) that carry the same name
REM as a folder in current directory.
:delete_folder_exes
    REM Note: .bat and .cmd are self-executable, but their icons are static, so
    REM leave them alone.
    FOR /F "usebackq delims=" %%d IN (`DIR /A:D /B /O:N 2^>nul`) DO (
        FOR /F "usebackq delims=" %%e IN (
            `DIR /A:-D /B /O:N "%%~d.com" "%%~d.exe" "%%~d.scr" 2^>nul`
        ) DO (
            CALL :is_file_to_keep EXECUTE "%%~e" && (
                ECHO 為了安全因素，跳過檔案 "%%~e"
            ) || (
                ECHO 刪除 "%%~e"
                DEL /F "%%~e"
            )
        )
    )
GOTO :EOF

REM Force deletes a file and creates a directory with the same name.
REM @param %1 File name to be converted into a directory
REM @return 0 if directory exists or is created successfully, or 1 on error
:file_to_directory
    IF EXIST %1 (
        ECHO.%~a1 | find "d" >nul 2>nul && (
            REM File exists and is a directory. Keep it.
            attrib +R +H +S "%~1"
            EXIT /B 0
        )
        ECHO 刪除 "%~1"
        DEL /F "%~1"
        IF EXIST %1 EXIT /B 1
    )
    IF "X!opt_mkdir!"=="XSKIP" EXIT /B 0
    CALL :make_directory %1
GOTO :EOF

REM Creates a directory and writes a file named DONT_DEL.txt inside it.
REM @param %1 Directory name
REM @return 0 if directory is created successfully (despite the file within)
:make_directory
    MKDIR "%~1" || (
        ECHO 建立目錄時發生錯誤："%~1">&2
        EXIT /B 1
    )
    REM Don't localize the text below. I want this file to be readable despite
    REM the encoding the user's system is in, and it's difficult to convert
    REM character encodings in shell.
    (
        ECHO This directory, "%~1", is to protect your disk from injecting a
        ECHO malicious %1 file.
        ECHO Your disk may still carry the USB or AutoRun malware, but it will NOT be
        ECHO executed anymore.
        ECHO Please do not remove this directory. If you do, you'll lose the protection.
        ECHO.
        ECHO This directory is generated by 'usb_vaccine.cmd'. Project website:
        ECHO ^<https://github.com/Explorer09/usb_vaccine^>
    ) >"%~1\DONT_DEL.txt"
    attrib +R +H +S "%~1"
    EXIT /B 0
GOTO :EOF

REM ---------------------------------------------------------------------------
:EOF
