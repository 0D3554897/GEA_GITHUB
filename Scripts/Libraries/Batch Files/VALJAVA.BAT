cls
REM ******************************************************
REM             %~2 VALIDATE JAVA BATCH START
REM ****************************************************** 

REM USAGE: T:\IMAPS_DATA\Interfaces\PROGRAMS\BATCH\VAL.BAT "sabrix16_trx" SABRIX 
rem 2 parameters:
rem (1) left side of properties file to be checked
rem (2) standard interface abbreviation

set INTERFACE=%~2
set PROP=%~1
REM ***************************
rem VALIDATE THE JAVA
REM ***************************
DEL /F /Q T:\IMAPS_DATA\Interfaces\LOGS\%INTERFACE%\%INTERFACE%*.*
DEL /F /Q T:\IMAPS_DATA\Interfaces\LOGS\%INTERFACE%\*.FTP
DEL /F /Q T:\IMAPS_DATA\Interfaces\LOGS\%INTERFACE%\???_%INTERFACE%.LOG

CALL T:\IMAPS_DATA\Interfaces\PROGRAMS\batch\VALIDATE.BAT
REM TIMEOUT 3 NOT SUPPORTED IN SQL SERVER JOB. DO THIS INSTEAD:
PING LOCALHOST 

CALL T:\IMAPS_Data\Interfaces\Programs\batch\ftp_chk.bat %INTERFACE% T:\IMAPS_DATA\Interfaces\LOGS\%INTERFACE%/VAL_%INTERFACE%.LOG 1 "Execution Finished Successfully" 

REM TIMEOUT 3 NOT SUPPORTED IN SQL SERVER JOB. DO THIS INSTEAD:
PING LOCALHOST 
REM if the file exists then return 0 and exit:
    if exist T:\IMAPS_DATA\Interfaces\LOGS\%INTERFACE%\0.FTP (
        echo Target file exists - Java PASSED
        move  T:\IMAPS_DATA\Interfaces\LOGS\%INTERFACE%\0.FTP  T:\IMAPS_DATA\Interfaces\LOGS\%INTERFACE%\0_java.FTP
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

