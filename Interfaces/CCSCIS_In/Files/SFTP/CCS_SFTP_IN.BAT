rem @echo off

REM ********************************************************************************************
REM *                                  MAKE YOUR CHANGES HERE                                  *
REM ********************************************************************************************

rem where SFTP client resides
set v_CLIENT="D:\DEV_SHARE\putty"

rem FTP related 
set v_SFTP_SERVER="fsst@dswax03.div16.ibm.com"
set v_KEYFILE="D:\DEV_SHARE\PuTTY\private\private_rsa_nopw.ppk"
set v_FTPCMD="D:\DEV_SHARE\PuTTY\CCS_SFTP_IN_CMD.DAT"
set v_FTPLOG="D:\DEV_SHARE\PuTTY\CCS_SFTP_LOG.txt"

rem OS related
rem this filename must match the one in the v_FTPCMD file
set v_GETFILE1="D:\DEV_SHARE\PUTTY\CCS.filein"
set v_GETFILE2="D:\DEV_SHARE\PUTTY\CCS.filein2"
set v_GETFILE3="D:\DEV_SHARE\PUTTY\CCS.filein3"
rem this filename is where you want to put it
set v_TARGET1="D:\IMAPS_DATA\inbox\ccis\CCIS_OPEN_BALANCES.TXT"
set v_TARGET2="D:\IMAPS_DATA\inbox\ccis\CCIS_ACTIVITY.TXT"
set v_TARGET3="D:\IMAPS_DATA\inbox\ccis\CCIS_OPEN_REMARKS.TXT"

REM ********************************************************************************************
REM *                                  END OF CHANGES                                          *
REM ********************************************************************************************

rem NAVIGATE TO SFTP CLIENT FOLDER
cd /d %v_CLIENT%

rem RSA SFTP PROTOCOL
psftp %v_SFTP_SERVER% -i %v_KEYFILE% -b %v_FTPCMD% -bc -batch>%v_FTPLOG%

rem D:\DEV_SHARE\putty\psftp fsst@dswax03.div16.ibm.com -i D:\DEV_SHARE\PuTTY\private\private_rsa_nopw.ppk


COPY /Y %v_GETFILE1% %v_TARGET1%
COPY /Y %v_GETFILE2% %v_TARGET2%
COPY /Y %v_GETFILE3% %v_TARGET3%
DEL /F /Q %v_GETFILE1%
DEL /F /Q %v_GETFILE2%
DEL /F /Q %v_GETFILE3%


rem pause






