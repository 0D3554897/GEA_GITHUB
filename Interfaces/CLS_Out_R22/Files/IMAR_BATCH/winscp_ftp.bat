cls

@echo *************************************************
@echo         WINSCP_FTP BATCH FILE 
@echo ************************************************* 

cd /d %DATA_DRIVE%IMAPS_DATA\Interfaces\PROGRAMS\BATCH

%WINSCP_HOME%\winscp.com /log="%1" /script="%2"

@echo ************************************************* 
@echo    WINSCP_FTP BATCH FILE COMPLETE 
@echo ************************************************* 
