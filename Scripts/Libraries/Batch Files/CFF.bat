cls
rem the following needed to do math in batch file  
setlocal enableextensions enabledelayedexpansion

REM run common interface batch file or fail
REM if the file exists then run it:
    if exist T:\IMAPS_DATA\Interfaces\PROGRAMS\batch\INTERFACE.BAT (
        CALL T:\IMAPS_DATA\Interfaces\PROGRAMS\batch\INTERFACE.BAT
        rem exit /B 0
    ) else (
REM if the file doesn't exist, exit with error code 1:    
        echo Common Interface file does not exist - failure
        exit /B 1
    )

del /f /q %CFF_LOG_DIR%\%LOG_FILE%
del /f /q %CFF_LOG_DIR%\%CFF_LOG%*.*

REM del /f /q %PROCESS%\%INTERFACE%_*.txt
REM del /f /q %PROCESS%\%INTERFACE%_*.ebc
DEL /f /q %PROCESS%\*.*

SET DBG=1
COPY /Y %LOG4J2_INT% %LOG4J2_STD%

REM START > %CFF_LOG_DIR%\%LOG_FILE%


REM   . >>%CFF_LOG_DIR%\%LOG_FILE%
REM   . >>%CFF_LOG_DIR%\%LOG_FILE%
REM *************************************************************** >>%CFF_LOG_DIR%\%LOG_FILE%
REM         %INTERFACE% BATCH START >>%CFF_LOG_DIR%\%LOG_FILE%
REM *************************************************************** >>%CFF_LOG_DIR%\%LOG_FILE%
REM   . >>%CFF_LOG_DIR%\%LOG_FILE%
REM   . >>%CFF_LOG_DIR%\%LOG_FILE%

T:

FOR %%A IN (%PROP%) DO call :cff_java %%A
goto :last_part

:cff_java

set PROP_FILE=%~1.properties
 

REM   . >>%CFF_LOG_DIR%\%LOG_FILE%
REM   . >>%CFF_LOG_DIR%\%LOG_FILE%
REM   . >>%CFF_LOG_DIR%\%LOG_FILE%

REM ****************************************************************************** >>%CFF_LOG_DIR%\%LOG_FILE%
REM    %PROP_FILE% EXECUTION>>%CFF_LOG_DIR%\%LOG_FILE%
REM ****************************************************************************** >>%CFF_LOG_DIR%\%LOG_FILE%


rem jdbc4.2
%JAVA_HOME%\java.exe -Duser.dir=%CFF_LOG_DIR% -Dcom.ibm.jsse2.overrideDefaultTLS=true -cp %CFF_HOME%\classes;%LIBS_HOME%activation.jar;%LIBS_HOME%commons-cli-1.0.jar;%LIBS_HOME%commons-email-1.1.jar;%LIBS_HOME%commons-net-1.4.1.jar;%LIBS_HOME%log4j-api.jar;%LIBS_HOME%log4j-core.jar;%LIBS_HOME%mail.jar;%LIBS_HOME%opencsv-1.8.jar;%LIBS_HOME%sqljdbc42.jar; %CFF_NAME%  -readDB -props %PROP_DIR%\%PROP_FILE% -creds %CRED_DIR%\%CRED_FILE% -outfile %PROCESS%\%~1 -logfile %CFF_LOG%%~1.LOG -debug %DBG%

rem jdbc7.4
rem %JAVA_HOME%\bin\java.exe -Duser.dir=%CFF_LOG_DIR% -Dcom.ibm.jsse2.overrideDefaultTLS=true -cp %CFF_HOME%\classes;%LIBS_HOME%activation.jar;%LIBS_HOME%commons-cli-1.0.jar;%LIBS_HOME%commons-email-1.1.jar;%LIBS_HOME%commons-net-1.4.1.jar;%LIBS_HOME%log4j-1.2.9.jar;%LIBS_HOME%mail.jar;%LIBS_HOME%opencsv-1.8.jar;%LIBS_HOME%mssql-jdbc-7.4.1.jre8.jar; %CFF_NAME%  -readDB -props %PROP_DIR%\%PROP_FILE% -creds %CRED_DIR%\%CRED_FILE% -logfile %CFF_LOG% -debug 0


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


