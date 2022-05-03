REM ******************************************************
REM             INTERFACE BATCH START
REM ****************************************************** 

REM APPLICATION CONSTANTS
REM SET JAVA_HOME=%JAVA_HOME%\BIN
SET PROCESS=T:\IMAPS_DATA\Interfaces\PROCESS\%INTERFACE%
SET PROGRAMS=T:\IMAPS_DATA\Interfaces\PROGRAMS\%INTERFACE%
SET PROP_DIR=T:\IMAPS_Data\Interfaces\Programs\%INTERFACE%
SET CRED_DIR=T:\IMAPS_Data\Props\%INTERFACE%
SET CRED_FILE=sql16.credentials

REM CFF
SET CFF_HOME=T:\IMAPS_Data\Interfaces\PROGRAMS\java\CFF
SET CFF_LOG_DIR=T:\IMAPS_Data\Interfaces\Logs\%INTERFACE%
SET CFF_NAME=com.ibm.imapsstg.cff
SET CFF_LOG=CFF_%INTERFACE%_APP_
SET CFF_LOG_FILE=CFF_%INTERFACE%.LOG

REM VALIDATE
rem for validating CFF before interfaces run
rem we will use cff log files and log folders
SET VAL_LOG=VALIDATE_%INTERFACE%_APP
SET VAL_HOME=T:\IMAPS_Data\Interfaces\PROGRAMS\java\VALIDATE
SET VAL_NAME=com.ibm.imapsstg.validate

REM FTP_CHK
SET FTP_CHK_HOME=T:\IMAPS_Data\Interfaces\PROGRAMS\java\FTP_CHK
SET FTP_CHK_LOG_DIR=T:\IMAPS_Data\Interfaces\Logs\%INTERFACE%
SET FTP_CHK_NAME=com.ibm.imapsstg.ftp_chk
SET FTP_CHK_LOG=FTP_CHK_%INTERFACE%_APP_LOG.TXT

REM LOG4J STUFF
SET LIBS_HOME=T:\IMAPS_Data\Interfaces\PROGRAMS\java\LIBS\
set LOG4J2_STD=%CFF_HOME%\classes\log4j2.properties
REM THREE LOGS NEEDED, BECAUSE FILE NAME IS NOW HELD IN PROPERTIES FILES
SET LOG4J2_INT=%CRED_DIR%\%INTERFACE%_log4j2.properties
SET LOG4J2_VAL=%CRED_DIR%\%INTERFACE%_val_log4j2.properties
SET LOG4J2_FTP=%CRED_DIR%\%INTERFACE%_ftp_log4j2.properties

REM ******************************************************
REM             INTERFACE BATCH END
REM ****************************************************** 