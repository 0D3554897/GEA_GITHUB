ECHO ******************************************************
ECHO             GLIM BATCH START
ECHO ****************************************************** 

REM USAGE: T:\IMAPS_DATA\Interfaces\PROGRAMS\GLIM\GLIM.BAT "glim,glimparm"
rem @echo off
set INTERFACE=GLIM
set PROP=%~1
CALL T:\IMAPS_DATA\Interfaces\PROGRAMS\batch\CFF.BAT

ECHO ******************************************************
ECHO             GLIM BATCH END
ECHO ****************************************************** 