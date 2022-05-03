ECHO /***************************************/
ECHO *    HERE IN INT_JAVA.BAT
ECHO /***************************************

rem LAUNCHES JAVA CODE
%JAVA_HOME%\java.exe -Dcom.ibm.jsse2.overrideDefaultTLS=true -Duser.dir=%APP_LOG_DIR% -cp %APP_HOME%\classes;%LIBS_HOME%\activation.jar;%LIBS_HOME%\commons-cli-1.0.jar;%LIBS_HOME%\commons-email-1.1.jar;%LIBS_HOME%\commons-net-1.4.1.jar;%LIBS_HOME%\log4j-api.jar;%LIBS_HOME%\log4j-core.jar;%LIBS_HOME%\mail.jar;%LIBS_HOME%\opencsv-1.8.jar;%LIBS_HOME%\ojdbc6.jar;;%LIBS_HOME%\poi.jar;%LIBS_HOME%\sqljdbc42.jar; %APP_NAME% %~1 -props %PROP_DIR%\%PROP_FILE% -creds %CRED_DIR%\%CRED_FILE% -debug %2

ECHO /***************************************/
ECHO *    INT_JAVA.BAT IS FINISHED
ECHO /***************************************