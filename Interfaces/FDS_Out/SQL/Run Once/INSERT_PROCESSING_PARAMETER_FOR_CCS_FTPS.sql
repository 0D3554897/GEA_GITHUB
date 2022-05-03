insert imapsstg.dbo.xx_processing_parameters (interface_name_id, interface_name_cd, parameter_name, parameter_value, created_by, created_date)
values (12,'FDS/CCS','CCS_FTP_CMD','D:\IMAPS_Data\Interfaces\PROGRAMS\FDS\ccs_ftp.bat',SUSER_SNAME(),GETDATE())
