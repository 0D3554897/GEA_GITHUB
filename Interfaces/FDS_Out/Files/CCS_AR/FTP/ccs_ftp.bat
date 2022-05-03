cls
rem @echo off
set LOG_FOLD=D:\IMAPS_DATA\Interfaces\logs\FDSCCS\
set LOG_FILE=%LOG_FOLD%CCS_FTP_BAT_LOG.TXT
set scp_path=C:\Progra~2\WinSCP\WinSCP.com
set scp_log=D:\IMAPS_DATA\NOTSHARED\CCS_FTP_LOG.TXT
set scp_script=D:\IMAPS_DATA\NOTSHARED\ccs_winscp.txt

@echo ****************************************************************************************** >%LOG_FILE%
@echo         BATCH FILE >>%LOG_FILE%
@echo ****************************************************************************************** >>%LOG_FILE%
d:
cd\apps_to_compile\fds_ccs


REM CCS TEST using winscp
rem C:\Progra~2\WinSCP\WinSCP.com /log="D:\IMAPS_DATA\NOTSHARED\CCS_FTP_LOG.TXT" /script="d:\apps_to_compile\fds_ccs\ccs_winscp.txt"

%scp_path% /log="%scp_log%" /script="%scp_script%"

@echo ****************************************************************************************** >>%LOG_FILE%
@echo         BATCH FILE COMPLETE >>%LOG_FILE%
@echo ****************************************************************************************** >>%LOG_FILE%
