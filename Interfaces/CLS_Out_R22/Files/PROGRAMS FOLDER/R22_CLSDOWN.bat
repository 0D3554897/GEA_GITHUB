ECHO ******************************************************
ECHO             R22_CLS BATCH START
ECHO ****************************************************** 

REM USAGE: T:\IMAPS_DATA\Interfaces\PROGRAMS\CLS_R22\R22_CLSDOWN.BAT "R22_clsdown,R22_clsdownparm,R22_clsdownsummary"
rem @echo off
set debug=0
set INTERFACE=CLS_R22
set PROP=%~1
CALL %DATA_DRIVE%IMAPS_DATA\Interfaces\PROGRAMS\batch\CFF.BAT

ECHO ******************************************************
ECHO             R22_CLS BATCH END
ECHO ****************************************************** 