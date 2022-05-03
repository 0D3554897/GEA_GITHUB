cls
set DB=ora
set TASK=load
set DBG=1

ECHO /***************************************/
ECHO *    HERE IN %DB% %TASK%
ECHO /***************************************

set APP_NAME=com.ibm.imapsstg.csv2db
rem set APP_HOME=T:\IMAPS_Data\Interfaces\Programs\WorkDay16
set APP_HOME=T:\IMAPS_DATA\Interfaces\PROGRAMS\java\csv2db
set APP_LOG_DIR=T:\IMAPS_Data\Interfaces\Logs\WorkDay16
set CRED_DIR=T:\IMAPS_Data\Props\WorkDay16
set CRED_FILE=%DB%16workday.credentials
set LIBS_HOME=T:\IMAPS_Data\Interfaces\Programs\java\LIBS\
set PROP_DIR=T:\IMAPS_Data\Props\WorkDay16
set PROP_FILE=%DB%16_workday.properties

set LOG4J2_INT=%PROP_DIR%\log4j2_csv2db.properties
set LOG4J2_STD=%APP_HOME%\classes\log4j2.properties

cd %APP_HOME%

del /f /q %APP_LOG_DIR%\csv2db_*.log
COPY /Y %LOG4J2_INT% %LOG4J2_STD%

rem truncate and load only
%JAVA_HOME%\java.exe -Dcom.ibm.jsse2.overrideDefaultTLS=true -Duser.dir=%APP_LOG_DIR% -cp %APP_HOME%\classes;%LIBS_HOME%activation.jar;%LIBS_HOME%commons-cli-1.0.jar;%LIBS_HOME%commons-email-1.1.jar;%LIBS_HOME%commons-net-1.4.1.jar;%LIBS_HOME%log4j-api.jar;%LIBS_HOME%log4j-core.jar;%LIBS_HOME%mail.jar;%LIBS_HOME%opencsv-1.8.jar;%LIBS_HOME%ojdbc6.jar; %APP_NAME% -truncate -loaddb -props %PROP_DIR%\%PROP_FILE%  -creds %CRED_DIR%\%CRED_FILE% -debug %DBG%


