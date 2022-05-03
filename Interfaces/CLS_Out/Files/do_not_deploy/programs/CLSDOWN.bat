ECHO ******************************************************
ECHO             CLS BATCH START
ECHO ****************************************************** 

REM USAGE: T:\IMAPS_DATA\Interfaces\PROGRAMS\CLS\CLS.BAT "clsdown,clsdownparm,clsdownsummary"
rem @echo off
set INTERFACE=CLS
set PROP=%~1
CALL T:\IMAPS_DATA\Interfaces\PROGRAMS\batch\CFF.BAT

ECHO ******************************************************
ECHO             CLS BATCH END
ECHO ****************************************************** 