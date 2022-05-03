@ECHO OFF
CLS
rem example execution using passed params
rem %DATA_DRIVE%IMAPS_DATA\INTERFACES\PROGRAMS\JAVA\FTP_CHK\FTP_CHK.BAT SABRIX D:/IMAPS_DATA/INTERFACES/LOGS/SABRIX/SABRIX_FTP_LOG.TXT 2 "250 Transfer Successful"

set INTERFACE=%1
SET FTP_LOG_FIL=%2
SET PHR_CNT=%3
SET PHRASE=%4

REM ************************************************ DO NOT CHANGE BELOW THIS LINE ************************************************

CALL %DATA_DRIVE%IMAPS_DATA\Interfaces\PROGRAMS\batch\INTERFACE.BAT

cd /D %FTP_CHK_HOME%

del /f /q %FTP_CHK_LOG_DIR%\%FTP_CHK_LOG%

rem EVAL A FILE
%JAVA_HOME%\java.exe -Duser.dir=%FTP_CHK_LOG_DIR% -Dcom.ibm.jsse2.overrideDefaultTLS=true -cp %FTP_CHK_HOME%\classes;%FTP_CHK_HOME%\libs\activation.jar;%FTP_CHK_HOME%\libs\commons-cli-1.0.jar;%FTP_CHK_HOME%\libs\commons-email-1.1.jar;%FTP_CHK_HOME%\libs\commons-net-1.4.1.jar;%FTP_CHK_HOME%\libs\log4j-1.2.9.jar;%FTP_CHK_HOME%\libs\mail.jar;%FTP_CHK_HOME%\libs\opencsv-1.8.jar;%FTP_CHK_HOME%\libs\sqljdbc4.jar; %FTP_CHK_NAME% %JAVA_DIR% -ftplog %FTP_LOG_FIL% -phrase %PHRASE% -cnt %PHR_CNT% -logfile %FTP_CHK_LOG_DIR%/%FTP_CHK_LOG% -debug 0 

REM ***************************************************** DOCUMENTATION *************************************************
REM - the following is expanded for ease of reading

REM at some point, we will have to switch to this, or above:
rem %DATA_DRIVE%sqljdbc_4.2\enu\sqljdbc42.jar

rem "%JAVA_HOME%\bin\java" -Duser.dir=%FTP_CHK_HOME% -cp 
rem %FTP_CHK_HOME%\classes;
rem %FTP_CHK_HOME%\libs\poi.jar; <=== only needed for -serialxref switch
rem %FTP_CHK_HOME%\libs\activation.jar;
rem %FTP_CHK_HOME%\libs\commons-cli-1.0.jar;
rem %FTP_CHK_HOME%\libs\commons-email-1.1.jar;
rem %FTP_CHK_HOME%\libs\commons-net-1.4.1.jar;
rem %FTP_CHK_HOME%\libs\log4j-1.2.9.jar;
rem %FTP_CHK_HOME%\libs\mail.jar;
rem %FTP_CHK_HOME%\libs\opencsv-1.8.jar;
rem %FTP_CHK_HOME%\libs\sqljdbc4.jar; <==== this doesn't exist in Clear Case... it is sqljdbc.jar.. Version 4 is needed for Sql Server 2008
rem %FTP_CHK_NAME% %JAVA_DIR% -ftplog %FTP_CHK_LOG_FIL% -phrase "%PHRASE%" -cnt %PHR_CNT% -logfile %FTP_CHK_LOG%/%FTP_CHK_LOG_FILE% -debug 0 

