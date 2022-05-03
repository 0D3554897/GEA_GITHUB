cls
rem the following needed to do math in batch file 
setlocal enableextensions enabledelayedexpansion

REM run common interface batch file or fail
REM if the file exists then run it:
    if exist %DATA_DRIVE%IMAPS_DATA\Interfaces\PROGRAMS\batch\INTERFACE.BAT (
        CALL %DATA_DRIVE%IMAPS_DATA\Interfaces\PROGRAMS\batch\INTERFACE.BAT
        rem exit /B 0
    ) else (
REM if the file doesn't exist, exit with error code 1:    
        echo Common Interface file does not exist - failure
        exit /B 1
    )

del /f /q %CFF_LOG_DIR%\%LOG_FILE%
del /f /q %CFF_LOG_DIR%\%VAL_LOG%*.*


REM del /f /q %PROCESS%\%INTERFACE%_*.txt
REM del /f /q %PROCESS%\%INTERFACE%_*.ebc
DEL /f /q %PROCESS%\*.*


REM START > %CFF_LOG_DIR%\%LOG_FILE%


REM   . >>%CFF_LOG_DIR%\%LOG_FILE%
REM   . >>%CFF_LOG_DIR%\%LOG_FILE%
REM *************************************************************** >>%CFF_LOG_DIR%\%LOG_FILE%
REM         %INTERFACE% BATCH START >>%CFF_LOG_DIR%\%LOG_FILE%
REM *************************************************************** >>%CFF_LOG_DIR%\%LOG_FILE%
REM   . >>%CFF_LOG_DIR%\%LOG_FILE%
REM   . >>%CFF_LOG_DIR%\%LOG_FILE%

T:

FOR %%A IN (%PROP%) DO call :VALIDATE_java %%A
goto :last_part

:VALIDATE_java

set PROP_FILE=%~1.properties
 

REM   . >>%CFF_LOG_DIR%\%LOG_FILE%
REM   . >>%CFF_LOG_DIR%\%LOG_FILE%
REM   . >>%CFF_LOG_DIR%\%LOG_FILE%

REM ****************************************************************************** >>%CFF_LOG_DIR%\%LOG_FILE%
REM    %PROP_FILE% EXECUTION>>%CFF_LOG_DIR%\%LOG_FILE%
REM ****************************************************************************** >>%CFF_LOG_DIR%\%LOG_FILE%


rem jdbc4.2
%JAVA_HOME%\java.exe -Duser.dir=%CFF_LOG_DIR% -Dcom.ibm.jsse2.overrideDefaultTLS=true -cp %CFF_HOME%\classes;%CFF_HOME%\libs\activation.jar;%CFF_HOME%\libs\commons-cli-1.0.jar;%CFF_HOME%\libs\commons-email-1.1.jar;%CFF_HOME%\libs\commons-net-1.4.1.jar;%CFF_HOME%\libs\log4j-1.2.9.jar;%CFF_HOME%\libs\mail.jar;%CFF_HOME%\libs\opencsv-1.8.jar;%CFF_HOME%\libs\sqljdbc42.jar; com.ibm.imapsstg.validate  -readDB -props %PROP_DIR%\%PROP_FILE% -creds %CRED_DIR%\%CRED_FILE% -outfile %PROCESS%\%~1 -logfile %VAL_LOG%%~1.LOG -debug 0

rem jdbc7.4
rem %JAVA_HOME%\bin\java.exe -Duser.dir=%CFF_LOG_DIR% -Dcom.ibm.jsse2.overrideDefaultTLS=true -cp %CFF_HOME%\classes;%CFF_HOME%\libs\activation.jar;%CFF_HOME%\libs\commons-cli-1.0.jar;%CFF_HOME%\libs\commons-email-1.1.jar;%CFF_HOME%\libs\commons-net-1.4.1.jar;%CFF_HOME%\libs\log4j-1.2.9.jar;%CFF_HOME%\libs\mail.jar;%CFF_HOME%\libs\opencsv-1.8.jar;%CFF_HOME%\libs\mssql-jdbc-7.4.1.jre8.jar; com.ibm.imapsstg.validate  -readDB -props %PROP_DIR%\%PROP_FILE% -creds %CRED_DIR%\%CRED_FILE% -logfile %VAL_LOG% -debug 0

REM ****************************************************************************** >>%CFF_LOG_DIR%\%LOG_FILE%
REM    %PROP_FILE% FINISHED>>%CFF_LOG_DIR%\%LOG_FILE%
REM ****************************************************************************** >>%CFF_LOG_DIR%\%LOG_FILE%



:last_part

REM   . >>%CFF_LOG_DIR%\%LOG_FILE%
REM   . >>%CFF_LOG_DIR%\%LOG_FILE%
REM ******************************************************************************************************************************************************************************** >>%CFF_LOG_DIR%\%LOG_FILE%
REM         BATCH FILE COMPLETE >>%CFF_LOG_DIR%\%LOG_FILE%
REM ******************************************************************************************************************************************************************************** >>%CFF_LOG_DIR%\%LOG_FILE%
REM   . >>%CFF_LOG_DIR%\%LOG_FILE%
REM   . >>%CFF_LOG_DIR%\%LOG_FILE%
endlocal


