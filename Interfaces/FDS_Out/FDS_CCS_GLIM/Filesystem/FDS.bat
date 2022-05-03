ECHO OFF
REM usage: T:\IMAPS_DATA\Interfaces\PROGRAMS\FDS\FDS.BAT T:\IMAPS_DATA\interfaces\PROGRAMS\java\FDS\exe\CreateFlatFiles.jar "T:\IMAPS_DATA\Props\FDS\jdbc_connection.properties" no "T:\IMAPS_DATA\INTERFACES\PROCESS\FDS\FDS\"

CALL T:\IMAPS_DATA\Interfaces\PROGRAMS\batch\interface.bat

%JAVA_HOME%\JAVA.EXE -Dcom.ibm.jsse2.overrideDefaultTLS=true -jar %~1 %~2 %~3 %~4

REM %JAVA_HOME%\JAVA.EXE -jar T:\IMAPS_DATA\interfaces\PROGRAMS\java\FDS_CCS\exe\CreateFlatFiles.jar "T:\IMAPS_DATA\NotShared\jdbc_connection.properties" no "T:\IMAPS_DATA\Interfaces\PROCESS\FDS\FDS\"
