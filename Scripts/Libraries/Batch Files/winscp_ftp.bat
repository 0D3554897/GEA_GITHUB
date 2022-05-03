cls

@echo *************************************************
@echo         WINSCP_FTP BATCH FILE 
@echo ************************************************* 
T:
cd \IMAPS_DATA\Interfaces\PROGRAMS\

%WINSCP_HOME%\winscp.com /log="%1" /script="%2"

@echo ************************************************* 
@echo    WINSCP_FTP BATCH FILE COMPLETE 
@echo ************************************************** 
