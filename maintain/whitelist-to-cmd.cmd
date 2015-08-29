@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

REM Generates the whitelist (files to keep) code from "..\Whitelist.txt" for
REM use in 'usb_vaccine.cmd'. This script is intended for maintainer only.

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

IF EXIST temp.txt EXIT /B 1

REM 'findstr' has a weird collation sequence, not ASCII as people expect.
REM <http://stackoverflow.com/questions/2635740>

SET alphabet=ABCDEFGHIJKLMNOPQRSTUVWXYZ

REM SYMLINK
TYPE ..\Whitelist.txt | findstr /r "^^[!alphabet!]*L" > temp.txt
SET list=
FOR /F "usebackq tokens=2 delims=," %%i IN ("temp.txt") DO (
    SET list=!list! %%i
)
SET trimmed_list=
SET prev=
FOR %%i IN (!list!) DO (
    IF NOT !prev!=="%%~i" (
        SET trimmed_list=!trimmed_list! "%%~i"
    )
    SET prev="%%~i"
)
ECHO KEEP_SYMLINK_FILES=
ECHO.!trimmed_list!
(
    ECHO SET KEEP_SYMLINK_FILES=
    ECHO FOR %%%%i IN ^(
    ECHO.!trimmed_list!
    ECHO ^) DO ^(
    ECHO     SET KEEP_SYMLINK_FILES=^^!KEEP_SYMLINK_FILES^^! %%%%i
    ECHO ^)
) >> whitelist-cmd.txt

REM HS_ATTRIB
TYPE ..\Whitelist.txt | findstr /r "^^[!alphabet!]*HS" > temp.txt
SET list=
FOR /F "usebackq tokens=2 delims=," %%i IN ("temp.txt") DO (
    SET list=!list! %%i
)
SET trimmed_list=
SET prev=
FOR %%i IN (!list!) DO (
    IF NOT !prev!=="%%~i" (
        SET trimmed_list=!trimmed_list! "%%~i"
    )
    SET prev="%%~i"
)
ECHO KEEP_HS_ATTRIB_FILES=
ECHO.!trimmed_list!
(
    ECHO SET KEEP_HS_ATTRIB_FILES=
    ECHO FOR %%%%i IN ^(
    ECHO.!trimmed_list!
    ECHO ^) DO ^(
    ECHO     SET KEEP_HS_ATTRIB_FILES=^^!KEEP_HS_ATTRIB_FILES^^! %%%%i
    ECHO ^)
) >> whitelist-cmd.txt

REM H_ATTRIB
TYPE ..\Whitelist.txt | findstr /r "^^[!alphabet:S=!]*H[!alphabet:S=!]*," > temp.txt
SET list=
FOR /F "usebackq tokens=2 delims=," %%i IN ("temp.txt") DO (
    SET list=!list! %%i
)
SET trimmed_list=
SET prev=
FOR %%i IN (!list!) DO (
    IF NOT !prev!=="%%~i" (
        SET trimmed_list=!trimmed_list! "%%~i"
    )
    SET prev="%%~i"
)
ECHO KEEP_H_ATTRIB_FILES=
ECHO.!trimmed_list!
(
    ECHO SET KEEP_H_ATTRIB_FILES=
    ECHO FOR %%%%i IN ^(
    ECHO.!trimmed_list!
    ECHO ^) DO ^(
    ECHO     SET KEEP_H_ATTRIB_FILES=^^!KEEP_H_ATTRIB_FILES^^! %%%%i
    ECHO ^)
) >> whitelist-cmd.txt

REM S_ATTRIB
TYPE ..\Whitelist.txt | findstr /r "^^[!alphabet:H=!]*S[!alphabet:H=!]*," > temp.txt
SET list=
FOR /F "usebackq tokens=2 delims=," %%i IN ("temp.txt") DO (
    SET list=!list! %%i
)
SET trimmed_list=
SET prev=
FOR %%i IN (!list!) DO (
    IF NOT !prev!=="%%~i" (
        SET trimmed_list=!trimmed_list! "%%~i"
    )
    SET prev="%%~i"
)
ECHO KEEP_S_ATTRIB_FILES=
ECHO.!trimmed_list!
(
    ECHO SET KEEP_S_ATTRIB_FILES=
    ECHO FOR %%%%i IN ^(
    ECHO.!trimmed_list!
    ECHO ^) DO ^(
    ECHO     SET KEEP_S_ATTRIB_FILES=^^!KEEP_S_ATTRIB_FILES^^! %%%%i
    ECHO ^)
) >> whitelist-cmd.txt

REM EXECUTE
TYPE ..\Whitelist.txt | findstr /r "^^[!alphabet!]*," > temp.txt
SET list=
FOR /F "usebackq tokens=2 delims=," %%i IN ("temp.txt") DO (
    SET list=!list! %%i
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
ECHO KEEP_EXECUTE_FILES=
ECHO.!trimmed_list!
(
    ECHO SET KEEP_EXECUTE_FILES=
    ECHO FOR %%%%i IN ^(
    ECHO.!trimmed_list!
    ECHO ^) DO ^(
    ECHO     SET KEEP_EXECUTE_FILES=^^!KEEP_EXECUTE_FILES^^! %%%%i
    ECHO ^)
) >> whitelist-cmd.txt

DEL temp.txt
EXIT /B 0

:is_executable
    FOR %%e IN (bat cmd com exe scr pif) DO (
        SET "filename=%~1"
        IF /I "!filename:~-4!"==".%%~e" EXIT /B 0
    )
    EXIT /B 1
GOTO :EOF
