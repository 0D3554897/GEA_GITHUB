@echo off
FOR %%A IN (%~1) DO call :chk %%A
goto :EOF

:chk
@echo off
REM check to see if file exists, report failure and exit with bad code
REM usage:  file_check.bat list
rem echo Target file: %1

REM if the file exists then return 0 and exit:
    if exist %1 (
        rem echo SUCCESS! Target file %1 exists
        REM exit /B 0
    ) else (
REM if the file doesn't exist, say so:    
        echo CRITICAL FAILURE! Target file %1 does not exist
        exit /B 1
    )
exit /b



:EOF
