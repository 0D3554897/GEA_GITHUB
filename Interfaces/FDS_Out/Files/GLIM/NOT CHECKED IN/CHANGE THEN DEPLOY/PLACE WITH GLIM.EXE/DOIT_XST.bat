echo off
REM check to see if file exists, return error if not
echo Target file: %1

REM if the file exists then return 0 and exit:
    if exist %1 (
        echo Target file exists
        exit /B 0
    ) else (
REM if the file doesn't exist, exit with error code 1:    
        echo Target file does not exist
        exit /B 1
    )


