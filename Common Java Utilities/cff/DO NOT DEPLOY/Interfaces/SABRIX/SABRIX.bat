cls
echo off
d:
cd\apps_to_compile\cff

set LOG_FILE=CFF_SABRIX.TXT
del /f /q %LOG_FILE%
@echo START > %LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%
@echo ******************************************************************************************************************************************************************************** >>%LOG_FILE%
@echo         BATCH FILE START >>%LOG_FILE%
@echo ******************************************************************************************************************************************************************************** >>%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%




del /f /q sabrix*.trx.txt
del /f /q sabrix*_hdr.txt
del /f /q sabrix*_hdr.ebc
del /f /q sabrix*_dtl.txt
del /f /q sabrix*_dtl.ebc
del /f /q sabrix*_out.fil
del /f /q D:\IMAPS_DATA\Interfaces\PROCESS\SABRIX\sabrix*.*

set APP_NAME=com.ibm.imapsstg.cff
set PROP_FILE=sabrix16_hdr.properties
set JAVA_HOME=D:\IBM_java8_64\bin
set APP_HOME=D:\apps_to_compile\cff
set PROP_DIR=D:\apps_to_compile\cff
set APP_LOG_DIR=D:\apps_to_compile\cff
set CRED_DIR=D:\apps_to_compile\cff
set CRED_FILE=sql16.credentials


cd %APP_HOME%

echo   . >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%

echo ******************************************************************************************************************************************************************************** >>%APP_LOG_DIR%\%LOG_FILE%
echo         HEADER EXECUTION>>%APP_LOG_DIR%\%LOG_FILE%
echo ******************************************************************************************************************************************************************************** >>%APP_LOG_DIR%\%LOG_FILE%
rem call cff_header.bat

%JAVA_HOME%\java.exe -Duser.dir=%APP_LOG_DIR% -cp %APP_HOME%\classes;%APP_HOME%\libs\activation.jar;%APP_HOME%\libs\commons-cli-1.0.jar;%CERIS_R22_HOME%\libs\commons-email-1.1.jar;%APP_HOME%\libs\commons-net-1.4.1.jar;%APP_HOME%\libs\log4j-1.2.9.jar;%APP_HOME%\libs\mail.jar;%APP_HOME%\libs\opencsv-1.8.jar;%APP_HOME%\libs\sqljdbc4.jar; %APP_NAME%  -readDB -props %PROP_DIR%\%PROP_FILE% -creds %CRED_DIR%\%CRED_FILE% -logfile %LOG_FILE% -debug 0

echo   . >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%
@echo Header Finished >>%LOG_FILE%


echo   . >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%
ECHO ******************************************************************************************************************************************************************************** >> %APP_LOG_DIR%\%LOG_FILE%
ECHO         DETAIL EXECUTION>> %APP_LOG_DIR%\%LOG_FILE%
ECHO ******************************************************************************************************************************************************************************** >> %APP_LOG_DIR%\%LOG_FILE%
set PROP_FILE=sabrix16_dtl.properties

rem call cff_detail.bat
%JAVA_HOME%\java.exe -Duser.dir=%APP_LOG_DIR% -cp %APP_HOME%\classes;%APP_HOME%\libs\activation.jar;%APP_HOME%\libs\commons-cli-1.0.jar;%CERIS_R22_HOME%\libs\commons-email-1.1.jar;%APP_HOME%\libs\commons-net-1.4.1.jar;%APP_HOME%\libs\log4j-1.2.9.jar;%APP_HOME%\libs\mail.jar;%APP_HOME%\libs\opencsv-1.8.jar;%APP_HOME%\libs\sqljdbc4.jar; %APP_NAME%  -readDB -props %PROP_DIR%\%PROP_FILE% -creds %CRED_DIR%\%CRED_FILE% -logfile %LOG_FILE% -debug 0

echo   . >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%
@echo Detail Finished >>%APP_LOG_DIR%\%LOG_FILE%


echo   . >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%
ECHO ******************************************************************************************************************************************************************************** >> %APP_LOG_DIR%\%LOG_FILE%
ECHO         TRX FILE EXECUTION>> %APP_LOG_DIR%\%LOG_FILE%
ECHO ******************************************************************************************************************************************************************************** >> %APP_LOG_DIR%\%LOG_FILE%
set PROP_FILE=sabrix16_trx.properties

rem call cff_detail.bat
%JAVA_HOME%\java.exe -Duser.dir=%APP_LOG_DIR% -cp %APP_HOME%\classes;%APP_HOME%\libs\activation.jar;%APP_HOME%\libs\commons-cli-1.0.jar;%CERIS_R22_HOME%\libs\commons-email-1.1.jar;%APP_HOME%\libs\commons-net-1.4.1.jar;%APP_HOME%\libs\log4j-1.2.9.jar;%APP_HOME%\libs\mail.jar;%APP_HOME%\libs\opencsv-1.8.jar;%APP_HOME%\libs\sqljdbc4.jar; %APP_NAME%  -readDB -props %PROP_DIR%\%PROP_FILE% -creds %CRED_DIR%\%CRED_FILE% -logfile %LOG_FILE% -debug 0

echo   . >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%
@echo ******************************************************************************************************************************************************************************** >>%LOG_FILE%
@echo         FILE COPY >>%LOG_FILE%
@echo ******************************************************************************************************************************************************************************** >>%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%

del /f /q sabrix_trx.ebc
copy /b sabrix_hdr.ebc + sabrix_dtl.ebc D:\IMAPS_DATA\Interfaces\PROCESS\SABRIX\sabrix_out.fil >>%APP_LOG_DIR%\%LOG_FILE%
copy sabrix_hdr.txt + sabrix_dtl.txt D:\IMAPS_DATA\Interfaces\PROCESS\SABRIX\sabrix_out_fil.txt >>%APP_LOG_DIR%\%LOG_FILE%
copy sabrix_trx.txt D:\IMAPS_DATA\Interfaces\PROCESS\SABRIX\sabrix_trx.txt>>%APP_LOG_DIR%\%LOG_FILE%


echo   . >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%
@echo ******************************************************************************************************************************************************************************** >>%LOG_FILE%
@echo         BATCH FILE COMPLETE >>%LOG_FILE%
@echo ******************************************************************************************************************************************************************************** >>%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%

rem call sendfile.bat
rem @ECHO  . >>%APP_LOG_DIR%\%LOG_FILE%
rem @echo FTP Finished >>%APP_LOG_DIR%\%LOG_FILE%
