REM **************************************************** START OF FTP_CHK *************************************************
REM @ECHO OFF
CLS
rem example execution using passed params
rem D:\IMAPS_DATA\INTERFACES\PROGRAMS\JAVA\FTP_CHK\FTP_CHK.BAT SABRIX D:/IMAPS_DATA/INTERFACES/LOGS/SABRIX/SABRIX_FTP_LOG.TXT 2 "250 Transfer Successful"

set INTERFACE=%1
SET FTP_LOG_FIL=%2
SET PHR_CNT=%3
SET PHRASE=%4

SET DBG=1

REM *************************** DO NOT CHANGE BELOW THIS LINE ********************************

CALL T:\IMAPS_DATA\Interfaces\PROGRAMS\batch\INTERFACE.BAT
ECHO RETURN FROM INTERFACE.BAT

set LOG4J2_STD=%FTP_CHK_HOME%\classes\log4j2.properties
COPY /Y %LOG4J2_FTP% %LOG4J2_STD%
ECHO COPIED LOG4J
cd /D %FTP_CHK_HOME%

del /f /q %FTP_CHK_LOG_DIR%\%FTP_CHK_LOG%
ECHO DELETED
rem EVAL A FILE
%JAVA_HOME%\java.exe -Duser.dir=%FTP_CHK_LOG_DIR% -Dcom.ibm.jsse2.overrideDefaultTLS=true -cp %FTP_CHK_HOME%\classes;%LIBS_HOME%activation.jar;%LIBS_HOME%commons-cli-1.0.jar;%LIBS_HOME%commons-email-1.1.jar;%LIBS_HOME%commons-net-1.4.1.jar;%LIBS_HOME%log4j-api.jar;%LIBS_HOME%log4j-core.jar;%LIBS_HOME%mail.jar;%LIBS_HOME%opencsv-1.8.jar;%LIBS_HOME%sqljdbc42.jar; %FTP_CHK_NAME% %JAVA_DIR% -ftplog %FTP_LOG_FIL% -phrase %PHRASE% -cnt %PHR_CNT% -logfile %FTP_CHK_LOG_DIR%/%FTP_CHK_LOG% -debug %DBG%

REM ***************************************************** END OF FTP_CHK *************************************************

