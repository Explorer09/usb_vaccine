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

REM Generates the whitelist (files to keep) code from "..\Whitelist.txt" for
REM use in 'usb_vaccine.cmd'. This script is intended for maintainer only.

REM ---------------------------------------------------------------------------
REM Copyright (C) 2015-2017 Kang-Che Sung <explorer09 @ gmail.com>

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

REM 'findstr' has a weird collation sequence, not ASCII as people expect.
REM <http://stackoverflow.com/questions/2635740>
REM Avoid character ranges because of this.
SET alphabet=ABCDEFGHIJKLMNOPQRSTUVWXYZ

REM KEEP_SYMLINK_FILES
REM File symlinks only; no directory symlinks or junctions.
SET chars=!alphabet:D=!
SET g_list=
REM 'findstr' bug: If File doesn't end with a newline, 'findstr "x" <File' may
REM hang. Use 'findstr "x" File' instead.
FOR /F "tokens=2 delims=," %%i IN (
    'findstr /r "^^[!chars!]*L[!chars!]*,[^^,\\]*," ..\Whitelist.txt'
) DO (
    SET g_list=!g_list! %%i
)
CALL :trim_list
ECHO KEEP_SYMLINK_FILES=
CALL :print_wrapped
(
    ECHO SET KEEP_SYMLINK_FILES=
    ECHO FOR %%%%i IN ^(
    CALL :print_wrapped
    ECHO ^) DO ^(
    ECHO     SET KEEP_SYMLINK_FILES=^^!KEEP_SYMLINK_FILES^^! %%%%i
    ECHO ^)
) >>whitelist-cmd.txt

REM KEEP_HS_ATTRIB_FILES
REM No symlinks (they can't be processed by 'attrib' without '/L', and '/L' is
REM not available until Windows Vista).
SET chars=!alphabet:L=!
SET g_list=
FOR /F "tokens=2 delims=," %%i IN (
    'findstr /r "^^[!chars!]*HS[!chars!]*," ..\Whitelist.txt'
) DO (
    SET g_list=!g_list! %%i
)
CALL :trim_list
ECHO KEEP_HS_ATTRIB_FILES=
CALL :print_wrapped
(
    ECHO SET KEEP_HS_ATTRIB_FILES=
    ECHO FOR %%%%i IN ^(
    CALL :print_wrapped
    ECHO ^) DO ^(
    ECHO     SET KEEP_HS_ATTRIB_FILES=^^!KEEP_HS_ATTRIB_FILES^^! %%%%i
    ECHO ^)
) >>whitelist-cmd.txt

REM KEEP_H_ATTRIB_FILES
REM No System attribute and no symlinks.
SET chars=!alphabet:S=!
SET chars=!chars:L=!
SET g_list=
FOR /F "tokens=2 delims=," %%i IN (
    'findstr /r "^^[!chars!]*H[!chars!]*," ..\Whitelist.txt'
) DO (
    SET g_list=!g_list! %%i
)
CALL :trim_list
ECHO KEEP_H_ATTRIB_FILES=
CALL :print_wrapped
(
    ECHO SET KEEP_H_ATTRIB_FILES=
    ECHO FOR %%%%i IN ^(
    CALL :print_wrapped
    ECHO ^) DO ^(
    ECHO     SET KEEP_H_ATTRIB_FILES=^^!KEEP_H_ATTRIB_FILES^^! %%%%i
    ECHO ^)
) >>whitelist-cmd.txt

REM KEEP_S_ATTRIB_FILES
REM No Hidden attribute and no symlinks.
SET chars=!alphabet:H=!
SET chars=!chars:L=!
SET g_list=
FOR /F "tokens=2 delims=," %%i IN (
    'findstr /r "^^[!chars!]*S[!chars!]*," ..\Whitelist.txt'
) DO (
    SET g_list=!g_list! %%i
)
CALL :trim_list
ECHO KEEP_S_ATTRIB_FILES=
CALL :print_wrapped
(
    ECHO SET KEEP_S_ATTRIB_FILES=
    ECHO FOR %%%%i IN ^(
    CALL :print_wrapped
    ECHO ^) DO ^(
    ECHO     SET KEEP_S_ATTRIB_FILES=^^!KEEP_S_ATTRIB_FILES^^! %%%%i
    ECHO ^)
) >>whitelist-cmd.txt

REM KEEP_EXECUTE_FILES
SET g_list=
FOR /F "tokens=1,2 delims=," %%i IN (
    'findstr /r "^^[!alphabet!]*,[^^,]*\." ..\Whitelist.txt'
) DO (
    ECHO.%%i | findstr /r "[\""\.\\]" >NUL:
    IF ERRORLEVEL 1 (
        SET g_list=!g_list! %%j
    ) ELSE (
        REM First field empty and "FOR /F" treated second field as first one.
        SET g_list=!g_list! %%i
    )
)
SET trimmed_list=
SET prev=
FOR %%i IN (!g_list!) DO (
    CALL :is_executable "%%~i" && (
        IF NOT !prev!=="%%~i" (
            SET trimmed_list=!trimmed_list! "%%~i"
        )
        SET prev="%%~i"
    )
)
SET g_list=!trimmed_list!
ECHO KEEP_EXECUTE_FILES=
CALL :print_wrapped
(
    ECHO SET KEEP_EXECUTE_FILES=
    ECHO FOR %%%%i IN ^(
    CALL :print_wrapped
    ECHO ^) DO ^(
    ECHO     SET KEEP_EXECUTE_FILES=^^!KEEP_EXECUTE_FILES^^! %%%%i
    ECHO ^)
) >>whitelist-cmd.txt

ENDLOCAL
EXIT /B 0

REM ---------------------------------------------------------------------------
REM SUBROUTINES

REM Removes adjacent, duplicated entries from g_list variable.
:trim_list
    SET trimmed_list=
    SET prev=
    FOR %%i IN (!g_list!) DO (
        IF NOT !prev!=="%%~i" SET trimmed_list=!trimmed_list! "%%~i"
        SET prev="%%~i"
    )
    SET g_list=!trimmed_list!
GOTO :EOF

:count_chars
    SET "str=%~1"
    SET g_chars_count=0
GOTO :count_chars_loop_

:count_chars_loop_
    IF "!str!"=="" GOTO :EOF
    SET /A g_chars_count+=1
    SET "str=!str:~1!"
GOTO :count_chars_loop_

:print_wrapped
    SET line=
    SET line_length=0
    IF "!g_list!"=="" GOTO :EOF
    FOR %%i IN (!g_list!) DO (
        CALL :count_chars "%%~i"
        IF "!line!"=="" (
            SET line="%%~i"
            REM Add two quotation marks
            SET /A line_length=!g_chars_count!+2
        ) ELSE (
            REM Add two quotation marks and a space
            SET /A line_length=!line_length!+!g_chars_count!+3
            IF !line_length! LSS 80 (
                SET line=!line! "%%~i"
            ) ELSE (
                ECHO.!line!
                SET line="%%~i"
                SET /A line_length=!g_chars_count!+2
            )
        )
    )
    ECHO.!line!
GOTO :EOF

:is_executable
    REM This list includes both executable file types and shortcut types.
    REM No sense to split into two.
    REM Not including: .bat, .cmd and .com (See comments in 'usb_vaccine.cmd'
    REM :process_folder_exes for why.)
    FOR %%e IN (exe scr pif lnk shb url appref-ms glk) DO (
        SET "str=%~1\NUL\"
        IF "!str:*.%%e\NUL\=!"=="" EXIT /B 0
    )
EXIT /B 1

REM ---------------------------------------------------------------------------
:EOF
