@ECHO OFF
CLS
rem example execution using passed params
rem D:\IMAPS_DATA\INTERFACES\PROGRAMS\JAVA\FTP_CHK\FTP_CHK.BAT SABRIX D:/IMAPS_DATA/INTERFACES/LOGS/SABRIX/SABRIX_FTP_LOG.TXT 2 "250 Transfer Successful"


set INTERFACE=%1
SET FTP_LOG_FIL=%2
SET PHR_CNT=%3
SET PHRASE=%4

SET APP_HOME=D:\IMAPS_DATA\Interfaces\PROGRAMS\java\
SET APP_LOG_DIR=D:\IMAPS_DATA\Interfaces\LOGS\

REM SET CMN_VAR_BAT=D:\IMAPS_DATA\INTERFACES\PROGRAMS\JAVA\COMMON_VAR.BAT
SET JAVA_DIR=ftp_chk

REM USE FORWARD SLASHES FROM HERE ==> /

REM ************************************************ DO NOT CHANGE BELOW THIS LINE ************************************************

REM JAVA
REM THE ENVIRONMENT VARIABLE IS WRONG ON DEV
REM SET JAVA_HOME=D:\IBMJAVASDK16\BIN

rem CALL %CMN_VAR_BAT%

rem APP
set APP_HOME=%APP_HOME%%JAVA_DIR%
set APP_NAME=com.ibm.imapsstg.%JAVA_DIR%
set APP_LOG_DIR=%APP_LOG_DIR%%INTERFACE%
set APP_LOG_FIL=%JAVA_DIR%.txt

cd /D %APP_HOME%

del /f /q %APP_LOG_DIR%\%APP_LOG_FIL%

rem EVAL A FILE
%JAVA_HOME%\java.exe -Duser.dir=%APP_LOG_DIR% -Dcom.ibm.jsse2.overrideDefaultTLS=true -cp %APP_HOME%\classes;%APP_HOME%\libs\activation.jar;%APP_HOME%\libs\commons-cli-1.0.jar;%APP_HOME%\libs\commons-email-1.1.jar;%APP_HOME%\libs\commons-net-1.4.1.jar;%APP_HOME%\libs\log4j-1.2.9.jar;%APP_HOME%\libs\mail.jar;%APP_HOME%\libs\opencsv-1.8.jar;%APP_HOME%\libs\sqljdbc4.jar; %APP_NAME% %JAVA_DIR% -ftplog %FTP_LOG_FIL% -phrase %PHRASE% -cnt %PHR_CNT% -logfile %APP_LOG_DIR%/%APP_LOG_FIL% -debug 3 
rem %JAVA_HOME%\java.exe -Duser.dir=%APP_LOG_DIR% -cp %APP_HOME%\classes;%APP_HOME%\libs\activation.jar;%APP_HOME%\libs\commons-cli-1.0.jar;%APP_HOME%\libs\commons-email-1.1.jar;%APP_HOME%\libs\commons-net-1.4.1.jar;%APP_HOME%\libs\log4j-1.2.9.jar;%APP_HOME%\libs\mail.jar;%APP_HOME%\libs\opencsv-1.8.jar;%APP_HOME%\libs\sqljdbc4.jar; %APP_NAME% %JAVA_DIR% -ftplog %FTP_LOG_FIL% -phrase %PHRASE% -cnt %PHR_CNT% -logfile %APP_LOG_DIR%/%APP_LOG_FIL% -debug 3 


REM ***************************************************** DOCUMENTATION *************************************************
REM - the following is expanded for ease of reading

REM at some point, we will have to switch to this, or above:
rem D:\sqljdbc_4.2\enu\sqljdbc42.jar

rem "%JAVA_HOME%\bin\java" -Duser.dir=%APP_HOME% -cp 
rem %APP_HOME%\classes;
rem %APP_HOME%\libs\poi.jar; <=== only needed for -serialxref switch
rem %APP_HOME%\libs\activation.jar;
rem %APP_HOME%\libs\commons-cli-1.0.jar;
rem %APP_HOME%\libs\commons-email-1.1.jar;
rem %APP_HOME%\libs\commons-net-1.4.1.jar;
rem %APP_HOME%\libs\log4j-1.2.9.jar;
rem %APP_HOME%\libs\mail.jar;
rem %APP_HOME%\libs\opencsv-1.8.jar;
rem %APP_HOME%\libs\sqljdbc4.jar; <==== this doesn't exist in Clear Case... it is sqljdbc.jar.. Version 4 is needed for Sql Server 2008
rem %APP_NAME% %JAVA_DIR% -ftplog %FTP_LOG_FIL% -phrase "%PHRASE%" -cnt %PHR_CNT% -logfile %APP_LOG%/%LOG_FILE% -debug 0 

