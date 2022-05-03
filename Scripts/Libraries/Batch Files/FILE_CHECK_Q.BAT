@echo off
FOR %%A IN (%~1) DO call :chk %%A
goto :EOF

:chk
@echo off
REM check to see if file exists, report either way
REM usage:  file_check.bat list
rem echo Target file: %1
REM if the file exists then return 0 and exit:
    if exist %1 (
        echo SUCCESS! Target file %1 exists
        REM exit /B 0
    ) else (
REM if the file doesn't exist, say so:    
        echo FAILURE! Target file %1 does not exist
        exit 9
    )




:EOF
