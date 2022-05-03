REM ******************************************************
REM             INTERFACE BATCH START
REM ****************************************************** 

REM APPLICATION CONSTANTS
REM SET JAVA_HOME=%JAVA_HOME%\BIN
SET PROCESS=%DATA_DRIVE%IMAR_DATA\Interfaces\PROCESS\%INTERFACE%
SET PROGRAMS=%DATA_DRIVE%IMAR_DATA\Interfaces\PROGRAMS\%INTERFACE%
SET PROP_DIR=%DATA_DRIVE%IMAR_Data\Interfaces\Programs\%INTERFACE%
SET CRED_DIR=%DATA_DRIVE%IMAR_Data\Props\%INTERFACE%
SET CRED_FILE=sql22.credentials


REM CFF
SET CFF_HOME=%DATA_DRIVE%IMAR_Data\Interfaces\PROGRAMS\java\CFF
SET CFF_LOG_DIR=%DATA_DRIVE%IMAR_Data\Interfaces\Logs\%INTERFACE%
SET CFF_NAME=com.ibm.imapsstg.cff
SET CFF_LOG=CFF_%INTERFACE%_APP_
SET CFF_LOG_FILE=CFF_%INTERFACE%.LOG
rem for validating CFF before interfaces run
SET VAL_LOG=VALIDATE_%INTERFACE%_APP


REM FTP_CHK
SET FTP_CHK_HOME=%DATA_DRIVE%IMAR_Data\Interfaces\PROGRAMS\java\FTP_CHK
SET FTP_CHK_LOG_DIR=%DATA_DRIVE%IMAR_Data\Interfaces\Logs\%INTERFACE%
SET FTP_CHK_NAME=com.ibm.imapsstg.ftp_chk
SET FTP_CHK_LOG=FTP_CHK_%INTERFACE%_APP_LOG.TXT

SET LIBS_HOME=%DATA_DRIVE%IMAR_Data\Interfaces\PROGRAMS\java\LIBS\

REM ******************************************************
REM             INTERFACE BATCH END
REM ****************************************************** 