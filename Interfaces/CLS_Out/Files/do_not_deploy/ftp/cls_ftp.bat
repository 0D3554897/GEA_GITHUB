cls
rem @echo off
set LOG_FOLD=D:\IMAPS_DATA\Interfaces\logs\CLS\
set LOG_FILE=%LOG_FOLD%CLS_FTP_BAT_LOG.TXT
set scp_path=C:\Progra~2\WinSCP\WinSCP.com


@echo ****************************************************************************************** >%LOG_FILE%
@echo         BATCH FILE >>%LOG_FILE%
@echo ****************************************************************************************** >>%LOG_FILE%
d:
cd \IMAPS_DATA\Interfaces\PROGRAMS\cls

%scp_path% /log="%1" /script="%2"

@echo ****************************************************************************************** >>%LOG_FILE%
@echo         BATCH FILE COMPLETE >>%LOG_FILE%
@echo ****************************************************************************************** >>%LOG_FILE%
