cls
rem @echo off
d:
cd\apps_to_compile\cff
set LOG_FOLD=D:\IMAPS_DATA\Interfaces\logs\
set LOG_FILE=%LOG_FOLD%CCS_02_FTP_BAT_LOG.TXT

@echo START > %LOG_FILE%
echo   . >> %LOG_FILE%
echo   . >> %LOG_FILE%
@echo ******************************************************************************************************************************************************************************** >>%LOG_FILE%
@echo         BATCH FILE START >> %LOG_FILE%
@echo ******************************************************************************************************************************************************************************** >>%LOG_FILE%
echo   . >> %LOG_FILE%
echo   . >> %LOG_FILE%

set APP_NAME=com.ibm.imapsstg.cff
set PROP_FILE=CCS_0216_dtl.properties
set JAVA_HOME=D:\ibmjavasdk16\bin
set APP_HOME=D:\apps_to_compile\cff
set PROP_DIR=D:\apps_to_compile\cff
set APP_LOG_DIR=D:\apps_to_compile\cff
set CRED_DIR=D:\apps_to_compile\cff
set CRED_FILE=sql16.credentials
set PROC_FOLD=D:\IMAPS_DATA\Interfaces\PROCESS\FDS_CCS\
set OUT_FOLD=D:\apps_to_compile\cff\OUTPUT\FDS_CCS\
set FTP_LOG_FOLD=D:\IMAPS_DATA\NOTSHARED\
set FTP_LOG_FILE=%FTP_LOG_FOLD%CCS_02_FTP_LOG.TXT


echo   . >> %LOG_FILE%
echo   . >> %LOG_FILE%
ECHO ******************************************************************************************************************************************************************************** >> %LOG_FILE%
ECHO         FTP EXECUTION>> %LOG_FILE%
ECHO ******************************************************************************************************************************************************************************** >> %LOG_FILE%
echo   . >> %LOG_FILE%
echo   . >> %LOG_FILE%


REM WAIT
ping 127.0.0.1 -n 6 > nul

rem dEAN
REM ftp -n -s:FTPCCS.TXT STFMVS1.POK.IBM.COM > %FTP_LOG_FILE%
rem ftp -n -s:FTPCCS.TXT > %FTP_LOG_FILE%
REM cristiane @ ccs
rem test ftp -n -s:FTPCCS_TEST.TXT SBRYS61.POK.IBM.COM >> %LOG_FILE%
REM CCS DEV ftp -n -s:FTPCCS_TEST.TXT SBRYS32.POK.IBM.COM >> %LOG_FILE%

REM CCS TEST using winscp
C:\Progra~2\WinSCP\WinSCP.com /log="D:\IMAPS_DATA\NOTSHARED\CCS_02_FTP_LOG.TXT" /script="d:\apps_to_compile\cff\winscp.txt"


rem @ECHO  . >>%LOG_FILE%
rem @echo FTP Finished >>%LOG_FILE%

echo   . >> %LOG_FILE%
echo   . >> %LOG_FILE%
@echo ******************************************************************************************************************************************************************************** >>%LOG_FILE%
@echo         BATCH FILE COMPLETE >>%LOG_FILE%
@echo ******************************************************************************************************************************************************************************** >>%LOG_FILE%
