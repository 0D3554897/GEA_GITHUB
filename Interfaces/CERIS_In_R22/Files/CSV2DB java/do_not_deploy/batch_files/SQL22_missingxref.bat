cls

REM ONLY CHANGES OPS MAY NEED TO MAKE
set DBG=1
set DRV_FLDR=U:\IMAR_DATA


REM NO CHANGES BELOW THIS LINE
set DB=sql
set TASK=missing_xref

ECHO /***************************************/
ECHO *    HERE IN %DB% %TASK%
ECHO /***************************************

set SWITCHES="-email -missingxref"

set APP_NAME=com.ibm.imapsstg.csv2db
set PROP_FILE=sql22_workday.properties
set CRED_FILE=sql22_workday.credentials
set JAVA_HOME=%JAVA_HOME%
set APP_HOME=%DRV_FLDR%\Interfaces\Programs\java\csv2db
set PROP_DIR=%DRV_FLDR%\Props\WorkDay22
set CRED_DIR=%DRV_FLDR%\Props\WorkDay22
set APP_LOG_DIR=%DRV_FLDR%\Interfaces\Logs\WorkDay22
set BATCH_HOME=%DRV_FLDR%\Interfaces\Programs\batch
set JAVA_LOG_FILE=csv2db.txt

set LOG4J2_INT=%PROP_DIR%\log4j2_csv2db.properties
set LOG4J2_STD=%APP_HOME%\classes\log4j2.properties
set LIBS_HOME=%DRV_FLDR%\Interfaces\Programs\java\libs

cd %APP_HOME%
del /f /q %APP_LOG_DIR%\%JAVA_LOG_FILE%
COPY /Y %LOG4J2_INT% %LOG4J2_STD%

CALL %BATCH_HOME%\INT_JAVA.bat %SWITCHES% %DBG%

ECHO /***************************************/
ECHO *    %DB% %TASK% IS FINISHED
ECHO /***************************************

