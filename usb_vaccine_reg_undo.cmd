@ECHO () { exit 1; } # >nul
@ECHO OFF
SETLOCAL EnableExtensions
IF CMDEXTVERSION 2 GOTO cmd_ext_ok
ENDLOCAL 
echo Requires Windows 2000 or later.
GOTO EOF
exit 1;
exit 
:cmd_ext_ok
ENDLOCAL
SETLOCAL EnableExtensions EnableDelayedExpansion

REM ---------------------------------------------------------------------------
REM 'usb_vaccine_reg_undo.cmd' version 3 beta (2016-09-21)
REM Copyright (C) 2015 Kang-Che Sung <explorer09 @ gmail.com>

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

SET HKLM_SFT=HKLM\SOFTWARE
SET HKLM_CLS=%HKLM_SFT%\Classes
SET HKLM_SFT_WOW=%HKLM_SFT%\Wow6432Node

SET "INF_MAP_SUBKEY=Microsoft\Windows NT\CurrentVersion\IniFileMapping\autorun.inf"
SET "ADVANCED_SUBKEY=Microsoft\Windows\CurrentVersion\Explorer\Advanced"

REM ---------------------------------------------------------------------------
REM MAIN

:main_sanity_test
reg query "HKCU" >nul 2>nul || (
    ECHO.
    ECHO *** ERROR: Can't access Windows registry with reg.exe^^!>&2
    GOTO main_undone
)

ECHO.
ECHO Note: 'usb_vaccine.cmd' should have made a registry backup "Vacc_reg.bak"
ECHO before modifying any part of registry of your system.

:main_undo_inf_mapping
ECHO.
ECHO Undo [inf-mapping]
ECHO We will remove the "autorun.inf" entry from the IniFileMapping list. This re-
ECHO enables AutoRun.
CALL :confirm_prompt || GOTO main_undo_known_ext
FOR %%k IN (%HKLM_SFT% %HKLM_SFT_WOW%) DO (
    reg delete "%%k\%INF_MAP_SUBKEY%" /f >nul
)

:main_undo_known_ext
ECHO.
ECHO Undo [known-ext]
ECHO We will re-enable "Hide extensions for known file types" option for current
ECHO user.
CALL :confirm_prompt || GOTO main_undo_exe_ext
reg delete "HKCU\Software\%ADVANCED_SUBKEY%" /v "HideFileExt" /f >nul

:main_undo_exe_ext
ECHO.
ECHO Undo [exe-ext]
ECHO We will delete the "AlwaysShowExt" values for .exe and .scr file types.
CALL :confirm_prompt || GOTO main_undo_pif_ext
FOR %%e IN (exe scr) DO (
    reg delete "%HKLM_CLS%\%%efile" /v "AlwaysShowExt" /f >nul
)

:main_undo_pif_ext
ECHO.
ECHO Undo [pif-ext]
ECHO We will restore the "NeverShowExt" value for .pif files. This hides the .pif
ECHO extension.
CALL :confirm_prompt || GOTO main_undo_scf_icon
reg query "%HKLM_CLS%\piffile" >nul 2>nul && (
    reg add "%HKLM_CLS%\piffile" /v "NeverShowExt" /t REG_SZ /f >nul
)

:main_undo_scf_icon
ECHO.
ECHO Undo [scf-icon]
ECHO We will remove the shortcut arrow icon for .scf files.
CALL :confirm_prompt || GOTO main_undo_scrap_ext
reg delete "%HKLM_CLS%\SHCmdFile" /v "IsShortcut" /f >nul

:main_undo_scrap_ext
ECHO.
ECHO Undo [scrap-ext]
ECHO We will restore the "NeverShowExt" value for .shs and .shb file types. This
ECHO hides the extensions for them.
CALL :confirm_prompt || GOTO main_undone
FOR %%k IN (ShellScrap DocShortcut) DO (
    reg query "%HKLM_CLS%\%%k" >nul 2>nul && (
        reg add "%HKLM_CLS%\%%k" /v "NeverShowExt" /t REG_SZ /f >nul
    )
)

:main_undone
ECHO.
ECHO Press any key to close this program.
PAUSE >nul
ENDLOCAL
EXIT /B 0

REM ---------------------------------------------------------------------------
REM SUBROUTINES

REM Prompts user to confirm or not.
REM @return 0 if user says YES, or 1 if says NO
:confirm_prompt
    SET prompt=
    SET /P prompt="Confirm [Y/n]? "
    IF "!prompt!"=="" EXIT /B 0
    IF /I "!prompt!"=="Y" EXIT /B 0
    IF /I "!prompt!"=="YES" EXIT /B 0
    IF /I "!prompt!"=="N" EXIT /B 1
    IF /I "!prompt!"=="NO" EXIT /B 1
    GOTO confirm_prompt
GOTO :EOF

REM ---------------------------------------------------------------------------
:EOF
