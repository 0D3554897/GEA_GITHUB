cls
REM ******************************************************
REM             %~2 VALIDATE FTP BATCH START
REM ****************************************************** 

REM USAGE: %DATA_DRIVE%IMAPS_DATA\Interfaces\PROGRAMS\BATCH\VALFTP.BAT "sabrix16_trx" SABRIX 1 "is logged on"
rem 4 parameters:
rem (1) left side of properties file to be checked
rem (2) standard interface abbreviation
rem (3) number of 
rem (4) success messages from target ftp  (this may vary by server)

set PROP=%~1
set INTERFACE=%~2
set CNT=%~3
set PHRASE=%~4

ECHO PROP IS %PROP
ECHO INTERFACE IS %INTERFACE%
ECHO CNT IS %CNT%
ECHO PHRASE IS %PHRASE%

REM ***************************
REM VALIDATE THE FTP
REM ***************************
del /f /q %DATA_DRIVE%IMAPS_DATA\INTERFACES\LOGS\%INTERFACE%\%INTERFACE%_VALIDATE_FTP_LOG.TXT

CALL %DATA_DRIVE%IMAPS_DATA\INTERFACES\PROGRAMS\BATCH\WINSCP_FTP.BAT %DATA_DRIVE%IMAPS_DATA\INTERFACES\LOGS\%INTERFACE%/%INTERFACE%_VALIDATE_FTP_LOG.TXT %DATA_DRIVE%IMAPS_DATA\Props\%INTERFACE%\v_%INTERFACE%_winscp.txt
REM TIMEOUT 3 NOT SUPPORTED IN SQL SERVER JOB. DO THIS INSTEAD:
PING LOCALHOST 
CALL %DATA_DRIVE%IMAPS_Data\Interfaces\Programs\BATCH\ftp_chk.bat %INTERFACE% %DATA_DRIVE%IMAPS_DATA\Interfaces\LOGS\%INTERFACE%/%INTERFACE%_VALIDATE_FTP_LOG.TXT %CNT% "%PHRASE%"
REM TIMEOUT 3 NOT SUPPORTED IN SQL SERVER JOB. DO THIS INSTEAD:
PING LOCALHOST
REM if the file exists then return 0 and exit:
    if exist %DATA_DRIVE%IMAPS_DATA\Interfaces\LOGS\%INTERFACE%\0.FTP (
        echo Target file exists - FTP PASSED.
	move %DATA_DRIVE%IMAPS_DATA\Interfaces\LOGS\%INTERFACE%\0.FTP %DATA_DRIVE%IMAPS_DATA\Interfaces\LOGS\%INTERFACE%\0_ftp.FTP
        REM exit /B 0
    ) else (
REM if the file doesn't exist, exit with error code 1:    
        echo %PROP% FTP FAILED. - check ?.ftp log for details.
PAUSE
        exit /B 1
    )

ECHO ******************************************************
ECHO             %INTERFACE% VALIDATE FTP BATCH END
ECHO ****************************************************** 

