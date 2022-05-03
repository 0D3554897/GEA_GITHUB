UPDATE IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS SET PARAMETER_VALUE = 'T:\IMAPS_DATA\Interfaces\PROGRAMS\batch\FTP_CHK.BAT', MODIFIED_BY = SUSER_SNAME(), MODIFIED_DATE = GETDATE() WHERE PARAMETER_NAME = 'FTP_CHECK_EXE' and INTERFACE_NAME_CD = 'UTIL'
update imapsstg.dbo.XX_PROCESSING_PARAMETERS  set parameter_value = '"250 Transfer completed"' where parameter_name = 'SABRIX_SEARCH_PHRASE' and  interface_name_cd = 'SABRIX'
update imapsstg.dbo.XX_PROCESSING_PARAMETERS  set parameter_value = '"2,2,0"' where parameter_name = 'SQL_TO_EBCDIC' and  interface_name_cd = 'SABRIX'



