cls
rem @echo off
d:
cd \IMAPS_Data\Interfaces\Logs\GLIM

set LOG_FILE=CFF_CCS_02.TXT
set APP_NAME=com.ibm.imapsstg.cff
set PROP_DIR=D:\IMAPS_Data\Interfaces\Programs\GLIM
set JAVA_HOME=D:\PROGRA~2\ibm\java60\jre\bin
set APP_HOME=D:\IMAPS_Data\Interfaces\Programs\Java\CFF
set APP_LOG_DIR=D:\IMAPS_Data\Interfaces\Logs\GLIM
set CRED_DIR=D:\IMAPS_Data\Props\GLIM
set CRED_FILE=sql16.credentials
set PROC_FOLD=D:\IMAPS_DATA\Interfaces\PROCESS\FDS_CCS\
set OUT_FOLD=D:\IMAPS_Data\Interfaces\PROCESS\FDS_CCS\
set FTP_LOG_FOLD=D:\IMAPS_DATA\Interfaces\Logs\GLIM\
set FTP_LOG_FILE=%FTP_LOG_FOLD%CCS_02_FTP_LOG.TXT


del /f /q %LOG_FILE%

@echo START > %APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%
@echo ******************************************************************************************************************************************************************************** >>%APP_LOG_DIR%\%LOG_FILE%
@echo         BATCH FILE START >>%APP_LOG_DIR%\%LOG_FILE%
@echo ******************************************************************************************************************************************************************************** >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%



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


set PROP_FILE=CCS_0216_dtl.properties
%JAVA_HOME%\java.exe -Duser.dir=%APP_LOG_DIR% -cp %APP_HOME%\classes;%APP_HOME%\libs\activation.jar;%APP_HOME%\libs\commons-cli-1.0.jar;%CERIS_R22_HOME%\libs\commons-email-1.1.jar;%APP_HOME%\libs\commons-net-1.4.1.jar;%APP_HOME%\libs\log4j-1.2.9.jar;%APP_HOME%\libs\mail.jar;%APP_HOME%\libs\opencsv-1.8.jar;%APP_HOME%\libs\sqljdbc4.jar; %APP_NAME%  -readDB -props %PROP_DIR%\%PROP_FILE% -creds %CRED_DIR%\%CRED_FILE% -logfile %LOG_FILE% -debug 0

echo   . >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%
@echo Finished Detail >>%APP_LOG_DIR%\%LOG_FILE%

echo ******************************************************************************************************************************************************************************** >>%APP_LOG_DIR%\%LOG_FILE%
echo        DIV EXECUTION>>%APP_LOG_DIR%\%LOG_FILE%
echo ******************************************************************************************************************************************************************************** >>%APP_LOG_DIR%\%LOG_FILE%

set PROP_FILE=CCS_0216_div.properties
%JAVA_HOME%\java.exe -Duser.dir=%APP_LOG_DIR% -cp %APP_HOME%\classes;%APP_HOME%\libs\activation.jar;%APP_HOME%\libs\commons-cli-1.0.jar;%CERIS_R22_HOME%\libs\commons-email-1.1.jar;%APP_HOME%\libs\commons-net-1.4.1.jar;%APP_HOME%\libs\log4j-1.2.9.jar;%APP_HOME%\libs\mail.jar;%APP_HOME%\libs\opencsv-1.8.jar;%APP_HOME%\libs\sqljdbc4.jar; %APP_NAME%  -readDB -props %PROP_DIR%\%PROP_FILE% -creds %CRED_DIR%\%CRED_FILE% -logfile %LOG_FILE% -debug 0

echo   . >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%
@echo Finished Div >>%APP_LOG_DIR%\%LOG_FILE%

echo ******************************************************************************************************************************************************************************** >>%APP_LOG_DIR%\%LOG_FILE%
echo        FIL EXECUTION>>%APP_LOG_DIR%\%LOG_FILE%
echo ******************************************************************************************************************************************************************************** >>%APP_LOG_DIR%\%LOG_FILE%

set PROP_FILE=CCS_0216_fil.properties
%JAVA_HOME%\java.exe -Duser.dir=%APP_LOG_DIR% -cp %APP_HOME%\classes;%APP_HOME%\libs\activation.jar;%APP_HOME%\libs\commons-cli-1.0.jar;%CERIS_R22_HOME%\libs\commons-email-1.1.jar;%APP_HOME%\libs\commons-net-1.4.1.jar;%APP_HOME%\libs\log4j-1.2.9.jar;%APP_HOME%\libs\mail.jar;%APP_HOME%\libs\opencsv-1.8.jar;%APP_HOME%\libs\sqljdbc4.jar; %APP_NAME%  -readDB -props %PROP_DIR%\%PROP_FILE% -creds %CRED_DIR%\%CRED_FILE% -logfile %LOG_FILE% -debug 0

echo   . >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%
@echo Finished Fil >>%APP_LOG_DIR%\%LOG_FILE%


echo   . >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%
@echo ******************************************************************************************************************************************************************************** >>%APP_LOG_DIR%\%LOG_FILE%
@echo         FILE COPY >>%APP_LOG_DIR%\%LOG_FILE%
@echo ******************************************************************************************************************************************************************************** >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%

REM dir >>%APP_LOG_DIR%\%LOG_FILE%
del /f /q  %PROC_FOLD%ccs_02_out.fil
del /f /q  %PROC_FOLD%ccs_02_out_fil.txt

copy /y /b %OUT_FOLD%ccs_02_dtl.ebc + %OUT_FOLD%ccs_02_div.ebc %OUT_FOLD%ccs_02_middle.ebc >>%APP_LOG_DIR%\%LOG_FILE%
copy /y /b %OUT_FOLD%ccs_02_middle.ebc + %OUT_FOLD%ccs_02_fil.ebc %OUT_FOLD%ccs_02_out.fil >>%APP_LOG_DIR%\%LOG_FILE%
REM copy /y /b %OUT_FOLD%ccs_02_out.fil %PROC_FOLD%ccs_02_out.fil >>%APP_LOG_DIR%\%LOG_FILE%
copy /y %OUT_FOLD%ccs_02_dtl.txt + %OUT_FOLD%ccs_02_div.txt + %OUT_FOLD%ccs_02_fil.txt %PROC_FOLD%ccs_02_out_fil.txt >>%APP_LOG_DIR%\%LOG_FILE%

echo   . >>%APP_LOG_DIR%\%LOG_FILE%
echo   . >>%APP_LOG_DIR%\%LOG_FILE%
@echo ******************************************************************************************************************************************************************************** >>%APP_LOG_DIR%\%LOG_FILE%
@echo         DONE >>%APP_LOG_DIR%\%LOG_FILE%
@echo ******************************************************************************************************************************************************************************** >>%APP_LOG_DIR%\%LOG_FILE%

