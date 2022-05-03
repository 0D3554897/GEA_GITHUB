cls
rem @echo off
d:
cd\apps_to_compile\cff
set APP_LOG_DIR=D:\apps_to_compile\cff
set LOG_FILE=CFF_CCS_02.TXT
set JAVA_LOG=CCS_02_JAVALOG.TXT
del /f /q %APP_LOG_DIR%\%LOG_FILE%
del /f /q *%JAVA_LOG%
@echo START >%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%
@echo ******************************************************************************************************************************************************************************** >>%LOG_FILE%
@echo         BATCH FILE START >>%LOG_FILE%
@echo ******************************************************************************************************************************************************************************** >>%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%

set APP_NAME=com.ibm.imapsstg.cff
set PROP_FILE=CCS_0216_dtl.properties
set JAVA_HOME=D:\IBM_java8_64\bin
set APP_HOME=D:\apps_to_compile\cff
set PROP_DIR=D:\apps_to_compile\cff
set CRED_DIR=D:\apps_to_compile\cff
set CRED_FILE=sql16.credentials
set PROC_FOLD=D:\IMAPS_DATA\Interfaces\PROCESS\FDS_CCS\
set OUT_FOLD=D:\apps_to_compile\cff\OUTPUT\FDS_CCS\
set FTP_LOG_FOLD=D:\IMAPS_DATA\NOTSHARED\


del /f /q %OUT_FOLD%CCS_02*.dtl.txt
del /f /q %OUT_FOLD%CCS_02*_div.txt
del /f /q %OUT_FOLD%CCS_02*_fil.txt

del /f /q %OUT_FOLD%CCS_02*_dtl.ebc
del /f /q %OUT_FOLD%CCS_02*_div.ebc
del /f /q %OUT_FOLD%CCS_02*_fil.ebc
del /f /q %OUT_FOLD%CCS_02*_middle.ebc
del /f /q %OUT_FOLD%CCS_02*_out.fil

del /f /q %PROC_FOLD%CCS_02*.*

cd %APP_HOME%

echo   . >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%

echo ******************************************************************************************************************************************************************************** >>%APP_LOG_DIR%\%LOG_FILE%
echo        DETAIL EXECUTION>>%APP_LOG_DIR%\%LOG_FILE%
echo ******************************************************************************************************************************************************************************** >>%APP_LOG_DIR%\%LOG_FILE%


%JAVA_HOME%\java.exe -Duser.dir=%APP_LOG_DIR% -cp %APP_HOME%\classes;%APP_HOME%\libs\activation.jar;%APP_HOME%\libs\commons-cli-1.0.jar;%CERIS_R22_HOME%\libs\commons-email-1.1.jar;%APP_HOME%\libs\commons-net-1.4.1.jar;%APP_HOME%\libs\log4j-1.2.9.jar;%APP_HOME%\libs\mail.jar;%APP_HOME%\libs\opencsv-1.8.jar;%APP_HOME%\libs\sqljdbc4.jar; %APP_NAME%  -readDB -props %PROP_DIR%\%PROP_FILE% -creds %CRED_DIR%\%CRED_FILE% -logfile HDR_%JAVA_LOG% -debug 3

echo   . >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%
@echo Finished Detail >>%APP_LOG_DIR%\%LOG_FILE%

echo ******************************************************************************************************************************************************************************** >>%APP_LOG_DIR%\%LOG_FILE%
echo        DIV EXECUTION>>%APP_LOG_DIR%\%LOG_FILE%
echo ******************************************************************************************************************************************************************************** >>%APP_LOG_DIR%\%LOG_FILE%

set PROP_FILE=CCS_0216_div.properties
%JAVA_HOME%\java.exe -Duser.dir=%APP_LOG_DIR% -cp %APP_HOME%\classes;%APP_HOME%\libs\activation.jar;%APP_HOME%\libs\commons-cli-1.0.jar;%CERIS_R22_HOME%\libs\commons-email-1.1.jar;%APP_HOME%\libs\commons-net-1.4.1.jar;%APP_HOME%\libs\log4j-1.2.9.jar;%APP_HOME%\libs\mail.jar;%APP_HOME%\libs\opencsv-1.8.jar;%APP_HOME%\libs\sqljdbc4.jar; %APP_NAME%  -readDB -props %PROP_DIR%\%PROP_FILE% -creds %CRED_DIR%\%CRED_FILE% -logfile DTL_%JAVA_LOG% -debug 3

echo   . >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%
@echo Finished Div >>%APP_LOG_DIR%\%LOG_FILE%

echo ******************************************************************************************************************************************************************************** >>%APP_LOG_DIR%\%LOG_FILE%
echo        FIL EXECUTION>>%APP_LOG_DIR%\%LOG_FILE%
echo ******************************************************************************************************************************************************************************** >>%APP_LOG_DIR%\%LOG_FILE%

set PROP_FILE=CCS_0216_fil.properties
%JAVA_HOME%\java.exe -Duser.dir=%APP_LOG_DIR% -cp %APP_HOME%\classes;%APP_HOME%\libs\activation.jar;%APP_HOME%\libs\commons-cli-1.0.jar;%CERIS_R22_HOME%\libs\commons-email-1.1.jar;%APP_HOME%\libs\commons-net-1.4.1.jar;%APP_HOME%\libs\log4j-1.2.9.jar;%APP_HOME%\libs\mail.jar;%APP_HOME%\libs\opencsv-1.8.jar;%APP_HOME%\libs\sqljdbc4.jar; %APP_NAME%  -readDB -props %PROP_DIR%\%PROP_FILE% -creds %CRED_DIR%\%CRED_FILE% -logfile TRX_%JAVA_LOG% -debug 3

echo   . >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%
@echo Finished Fil >>%APP_LOG_DIR%\%LOG_FILE%

echo   . >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%
@echo ******************************************************************************************************************************************************************************** >>%LOG_FILE%
@echo         FILE COPY >>%LOG_FILE%
@echo ******************************************************************************************************************************************************************************** >>%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%

REM dir >>%APP_LOG_DIR%\%LOG_FILE%
del /f /q  %PROC_FOLD%ccs_02_out.fil
del /f /q  %PROC_FOLD%ccs_02_out_fil.txt

copy /y /b %OUT_FOLD%ccs_02_dtl.ebc + %OUT_FOLD%ccs_02_div.ebc %OUT_FOLD%ccs_02_middle.ebc >>%APP_LOG_DIR%\%LOG_FILE%
copy /y /b %OUT_FOLD%ccs_02_middle.ebc + %OUT_FOLD%ccs_02_fil.ebc %OUT_FOLD%ccs_02_out.fil >>%APP_LOG_DIR%\%LOG_FILE%
copy /y /b %OUT_FOLD%ccs_02_out.fil %PROC_FOLD%ccs_02_out.fil >>%APP_LOG_DIR%\%LOG_FILE%
copy /y %OUT_FOLD%ccs_02_dtl.txt + %OUT_FOLD%ccs_02_div.txt + %OUT_FOLD%ccs_02_fil.txt %PROC_FOLD%ccs_02_out_fil.txt >>%APP_LOG_DIR%\%LOG_FILE%

echo   . >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%
@echo ******************************************************************************************************************************************************************************** >>%LOG_FILE%
@echo         DONE >>%APP_LOG_DIR%\%LOG_FILE%
@echo ******************************************************************************************************************************************************************************** >>%LOG_FILE%

