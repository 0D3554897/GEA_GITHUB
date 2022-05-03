cls
@echo off

REM TEST WITH THIS COMMAND:
REM D:\IMAPS_DATA\Interfaces\PROGRAMS\FDS\GLIM_FTP.BAT D:\IMAPS_DATA\NOTSHARED\GLIM_FTP_LOG.TXT D:\IMAPS_DATA\PROPS\GLIM\GLIM_WINSCP.TXT

set scp_path=C:\Progra~2\WinSCP\WinSCP.com

@echo ******************************************************************************************
@echo   GLIM FTP BATCH FILE START
@echo ******************************************************************************************

%scp_path% /log="%1" /script="%2"

@echo ******************************************************************************************
@echo  GLIM FTP BATCH FILE COMPLETE
@echo ******************************************************************************************
