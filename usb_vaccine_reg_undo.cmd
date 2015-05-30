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

SET INF_MAPPING_REG_KEY="HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\IniFileMapping\autorun.inf"
SET ADVANCED_REG_SUBKEY=Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced

REM ---------------------------------------------------------------------------
REM MAIN

:main_sanity_test
reg query "HKCU" >nul 2>nul || (
    ECHO.
    ECHO *** ERROR: Can't access Windows registry with reg.exe^^!>&2
    GOTO main_undone
)

:main_undo_inf_mapping
ECHO.
ECHO Undo [inf-mapping]
ECHO We will remove autorun.inf file from IniFileMapping list. This re-enables
ECHO AutoRun.
CALL :confirm_prompt || GOTO main_undo_known_ext
reg delete %INF_MAPPING_REG_KEY% /f >nul

:main_undo_known_ext
ECHO.
ECHO Undo [known-ext]
ECHO We will re-enable "Hide extensions for known file types" option, and also
ECHO restore the "NeverShowExt" value for .pif shortcuts. 
CALL :confirm_prompt || GOTO main_undone
reg delete "HKCU\%ADVANCED_REG_SUBKEY%" /v "HideFileExt" /f >nul
reg add "HKLM\SOFTWARE\Classes\piffile" /v "NeverShowExt" /t REG_SZ /f >nul

:main_undone
ECHO.
ECHO Press any key to close this program.
PAUSE >nul
ENDLOCAL
GOTO :EOF

REM ---------------------------------------------------------------------------
REM SUBROUTINES

:confirm_prompt
    SET prompt=
    SET /P prompt="Confirm [Y/n]? "
    IF "X!prompt!"=="X" EXIT /B 0
    IF /I "X!prompt!"=="XY" EXIT /B 0
    IF /I "X!prompt!"=="XYES" EXIT /B 0
    IF /I "X!prompt!"=="XN" EXIT /B 1
    IF /I "X!prompt!"=="XNO" EXIT /B 1
    GOTO confirm_prompt
GOTO :EOF

REM ---------------------------------------------------------------------------
:EOF
