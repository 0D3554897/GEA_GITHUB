
update imapsstg.dbo.XX_PROCESSING_PARAMETERS
set parameter_value =  REPLACE(parameter_value,'D:\','T:\')
where interface_name_cd = 'CLS'
and charindex('D:\',parameter_value) > 0

update imapsstg.dbo.XX_PROCESSING_PARAMETERS
set parameter_value =  'T:\IMAPS_DATA\Interfaces\Process\CLS\'
where interface_name_cd = 'CLS'
and parameter_name = 'FIL_DIR'

update imapsstg.dbo.XX_PROCESSING_PARAMETERS
set parameter_value =  'T:\IMAPS_DATA\INTERFACES\PROGRAMS\BATCH\WINSCP_FTP.BAT'
where interface_name_cd = 'CLS'
and parameter_name = 'FTP_COMMAND_EXE'

update imapsstg.dbo.XX_PROCESSING_PARAMETERS
set parameter_value =  'T:\IMAPS_DATA\INTERFACES\PROCESS\CLS\CLSDOWN.EBC'
where interface_name_cd = 'CLS'
and parameter_name = 'CURRENT_FILE'

update imapsstg.dbo.XX_PROCESSING_PARAMETERS
set parameter_value =  'T:\IMAPS_DATA\interfaces\PROCESS\CLS\CLSDOWNSUMMARY.txt'
where interface_name_cd = 'CLS'
and parameter_name = 'SUM_FILE'


Update imapsstg.dbo.XX_PROCESSING_PARAMETERS
set parameter_value =  'IMAPS_TO_CLS.BIN'
where interface_name_cd = 'CLS'
and parameter_name = 'FTP_DEST_999FILE'


Update imapsstg.dbo.XX_PROCESSING_PARAMETERS
set parameter_value =  'F155PARM.TXT'
where interface_name_cd = 'CLS'
and parameter_name = 'FTP_DEST_PARMFILE'


Update imapsstg.dbo.XX_PROCESSING_PARAMETERS
set parameter_value =  'IMAPS_TO_CLS_DOWN_SUMMARY.TXT'
where interface_name_cd = 'CLS'
and parameter_name = 'FTP_DEST_SUMFILE'


INSERT INTO IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS VALUES (  
  (SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'CLS'),
  'CLS',
  'PARMFILE',
  'T:\IMAPS_DATA\Interfaces\PROCESS\CLS\CLSDOWNPARM.TXT', SUSER_SNAME(),GETDATE(),NULL,NULL,NULL)

  INSERT INTO IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS VALUES (  
  (SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'CLS'),
  'CLS',
  'TEXTFILE',
  'T:\IMAPS_DATA\Interfaces\PROCESS\CLS\IMAPS_TO_CLS_ASCII.TXT', SUSER_SNAME(),GETDATE(),NULL,NULL,NULL)

INSERT INTO IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS VALUES (  
  (SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'CLS'),
  'CLS',
  'FTP_DEST_SUMFILE',
  'IMAPS_TO_CLS_DOWN_SUMMARY.TXT', SUSER_SNAME(),GETDATE(),NULL,NULL,NULL)

 
