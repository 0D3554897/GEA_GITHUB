ECHO ******************************************************
ECHO             CCS_02 BATCH START
ECHO ****************************************************** 

REM USAGE: T:\IMAPS_DATA\Interfaces\PROGRAMS\CCS_02\CCS_02.BAT "CCS_0216_det,CCS_0216_div,CCS_0216_fil"
rem @echo off
set INTERFACE=CCS_02
set PROP=%~1
CALL T:\IMAPS_DATA\Interfaces\PROGRAMS\batch\CFF.BAT

ECHO ******************************************************
ECHO             CCS_02 BATCH END
ECHO ****************************************************** 