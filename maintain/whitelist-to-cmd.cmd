@ECHO OFF
SETLOCAL EnableExtensions
IF CMDEXTVERSION==2 GOTO cmd_ext_ok
ENDLOCAL 
echo Requires Windows 2000 or later.
GOTO EOF
exit 1;
exit 
REM Press Ctrl-C and answer Y to terminate.
COPY CON NUL
command.com
:cmd_ext_ok
ENDLOCAL
SETLOCAL EnableExtensions EnableDelayedExpansion

REM Generates the whitelist (files to keep) code from "..\Whitelist.txt" for
REM use in 'usb_vaccine.cmd'. This script is intended for maintainer only.

REM ---------------------------------------------------------------------------
REM Copyright (C) 2015-2016 Kang-Che Sung <explorer09 @ gmail.com>

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

IF EXIST temp.txt EXIT /B 1

REM 'findstr' has a weird collation sequence, not ASCII as people expect.
REM <http://stackoverflow.com/questions/2635740>

SET alphabet=ABCDEFGHIJKLMNOPQRSTUVWXYZ

REM SYMLINK
TYPE ..\Whitelist.txt | findstr /r "^^[!alphabet!]*L" > temp.txt
SET g_list=
FOR /F "usebackq tokens=2 delims=," %%i IN ("temp.txt") DO (
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
) >> whitelist-cmd.txt

REM HS_ATTRIB
TYPE ..\Whitelist.txt | findstr /r "^^[!alphabet!]*HS" > temp.txt
SET g_list=
FOR /F "usebackq tokens=2 delims=," %%i IN ("temp.txt") DO (
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
) >> whitelist-cmd.txt

REM H_ATTRIB
TYPE ..\Whitelist.txt | findstr /r "^^[!alphabet:S=!]*H[!alphabet:S=!]*," > temp.txt
SET g_list=
FOR /F "usebackq tokens=2 delims=," %%i IN ("temp.txt") DO (
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
) >> whitelist-cmd.txt

REM S_ATTRIB
TYPE ..\Whitelist.txt | findstr /r "^^[!alphabet:H=!]*S[!alphabet:H=!]*," > temp.txt
SET g_list=
FOR /F "usebackq tokens=2 delims=," %%i IN ("temp.txt") DO (
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
) >> whitelist-cmd.txt

REM EXECUTE
TYPE ..\Whitelist.txt | findstr /r "^^[!alphabet!]*," > temp.txt
SET list=
FOR /F "usebackq tokens=1,2 delims=," %%i IN ("temp.txt") DO (
    ECHO.%%i | findstr /r "[\""\.\\]" >NUL
    IF ERRORLEVEL 1 (
        SET list=!list! %%j
    ) ELSE (
        SET list=!list! %%i
    )
)
SET trimmed_list=
SET prev=
FOR %%i IN (!list!) DO (
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
) >> whitelist-cmd.txt

DEL temp.txt
ENDLOCAL
EXIT /B 0

REM ---------------------------------------------------------------------------
REM SUBROUTINES

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
    IF "!g_str_to_count!"=="" GOTO :EOF
    SET /A g_chars_count+=1
    SET "g_str_to_count=!g_str_to_count:~1!"
GOTO :count_chars

:print_wrapped
    SET line=
    SET line_length=0
    SET g_chars_count=0
    IF "!g_list!"=="" GOTO :EOF
    FOR %%i IN (!g_list!) DO (
        SET "g_str_to_count=%%~i"
        CALL :count_chars
        IF "!line!"=="" (
            SET line="%%~i"
            REM Add two quotation marks
            SET /A g_chars_count+=2
        ) ELSE (
            REM Add two quotation marks and a space
            SET /A g_chars_count+=3
            IF !g_chars_count! LSS 80 (
                SET line=!line! "%%~i"
            ) ELSE (
                ECHO.!line!
                SET line="%%~i"
                SET /A g_chars_count=!g_chars_count!-!line_length!-1
            )
        )
        SET /A line_length=!g_chars_count!
    )
    ECHO.!line!
GOTO :EOF

:is_executable
    REM This list includes both executable file types and shortcut types.
    REM No sense to split into two.
    FOR %%e IN (bat cmd com exe scr pif lnk shb url appref-ms glk) DO (
        SET "filename=%~1"
        IF /I "!filename:~-4!"==".%%~e" EXIT /B 0
    )
EXIT /B 1

REM ---------------------------------------------------------------------------
:EOF
