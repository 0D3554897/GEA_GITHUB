cls
REM ******************************************************
REM             %~2 VALIDATE JAVA BATCH START
REM ****************************************************** 

REM USAGE: %DATA_DRIVE%IMAPS_DATA\Interfaces\PROGRAMS\BATCH\VAL.BAT "sabrix16_trx" SABRIX 
rem 2 parameters:
rem (1) left side of properties file to be checked
rem (2) standard interface abbreviation

set INTERFACE=%~2
set PROP=%~1
REM ***************************
rem VALIDATE THE JAVA
REM ***************************
DEL /F /Q %DATA_DRIVE%IMAPS_DATA\Interfaces\LOGS\%INTERFACE%\VALIDATE_%INTERFACE%*.*
DEL /F /Q %DATA_DRIVE%IMAPS_DATA\Interfaces\LOGS\%INTERFACE%\*.FTP
DEL /F /Q %DATA_DRIVE%IMAPS_DATA\Interfaces\LOGS\%INTERFACE%\FTP_CHK.TXT
CALL %DATA_DRIVE%IMAPS_DATA\Interfaces\PROGRAMS\batch\VALIDATE.BAT
REM TIMEOUT 3 NOT SUPPORTED IN SQL SERVER JOB. DO THIS INSTEAD:
PING LOCALHOST 
CALL %DATA_DRIVE%IMAPS_Data\Interfaces\Programs\batch\ftp_chk.bat %INTERFACE% %DATA_DRIVE%IMAPS_DATA\Interfaces\LOGS\%INTERFACE%/VALIDATE_%INTERFACE%_APP%~1.LOG 1 "Execution Finished Successfully" 
REM TIMEOUT 3 NOT SUPPORTED IN SQL SERVER JOB. DO THIS INSTEAD:
PING LOCALHOST 
REM if the file exists then return 0 and exit:
    if exist %DATA_DRIVE%IMAPS_DATA\Interfaces\LOGS\%INTERFACE%\0.FTP (
        echo Target file exists - Java PASSED
        move  %DATA_DRIVE%IMAPS_DATA\Interfaces\LOGS\%INTERFACE%\0.FTP  %DATA_DRIVE%IMAPS_DATA\Interfaces\LOGS\%INTERFACE%\0_java.FTP
        REM exit /B 0
    ) else (
REM if the file doesn't exist, exit with error code 1:    
        echo Target file does not exist - JAVA FAILED.
PAUSE
        exit /B 1
    )

ECHO ******************************************************
ECHO             %INTERFACE% VALIDATE JAVA BATCH END
ECHO ****************************************************** 

