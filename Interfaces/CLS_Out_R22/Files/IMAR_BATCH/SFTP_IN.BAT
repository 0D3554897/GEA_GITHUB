rem @echo off
REM ***********************************************************************
REM *  ALL PURPOSE GET SFTP FILES FROM SERVER - USE PROCESSING PARAMETERS *
REM *    TO GET AND BUILD VARIABLES FOR YOUR PARTICULAR INBOUND INTERFACE *
REM ***********************************************************************

REM  PUTTY_HOME IS AN ENVIRONMENT VARIABLE, VALUE ON THIS MACHINE: %PUTTY_HOME%

rem FTP related
set v_PROCESS=%~1
set v_SFTP_SERVER=%~2
set v_KEYFILE=%~3
set v_FTPCMD=%~4
set v_FTPLOG=%~5

rem ftp output doesn't echo to log, so will be seen in sql server job log instead

CD /D %v_PROCESS%

rem RSA SFTP PROTOCOL
echo Y|%PUTTY_HOME%psftp %v_SFTP_SERVER% -i %v_KEYFILE% -b %v_FTPCMD% -bc 

