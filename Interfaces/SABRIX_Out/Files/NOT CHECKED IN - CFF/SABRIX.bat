ECHO ******************************************************
ECHO             SABRIX BATCH START   
ECHO ****************************************************** 

REM USAGE: T:\IMAPS_DATA\Interfaces\PROGRAMS\SABRIX\SABRIX.BAT "sabrix16_hdr,sabrix16_lin,sabrix16_trx"
rem @echo off
set INTERFACE=SABRIX
set PROP=%~1
CALL T:\IMAPS_DATA\Interfaces\PROGRAMS\batch\CFF.BAT

ECHO ******************************************************
ECHO             SABRIX BATCH END
ECHO ****************************************************** 

