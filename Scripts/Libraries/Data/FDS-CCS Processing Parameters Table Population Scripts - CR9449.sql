-- CR-9449 New GLIM file-related processing parameters

-- IMPORTANT: Must test the SELECT statement below
declare @interface_name_id integer

select @interface_name_id = LOOKUP_ID 
  from dbo.XX_LOOKUP_DETAIL 
 where APPLICATION_CODE = 'FDS/CCS' 

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES (@interface_name_id, 'FDS/CCS', 'GLIM_EXE', 'D:\APPS_TO_COMPILE\GLIM\GLIM.BAT', SUSER_SNAME(), GETDATE())
GO

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES (@interface_name_id, 'FDS/CCS', 'GLIM_FTP_DEST_FILE_1', 'D:\APPS_TO_COMPILE\GLIM\FTP\IMAPFIW.TEST.CONTROL2.FDSCCS', SUSER_SNAME(), GETDATE())
GO

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES (@interface_name_id,'FDS/CCS', 'GLIM_FTP_DEST_FILE_2', 'D:\APPS_TO_COMPILE\GLIM\FTP\IMAPFIW.TEST.MOD999.PARM', SUSER_SNAME(), GETDATE())
GO

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES (@interface_name_id, 'FDS/CCS', 'GLIM_OUT_DEST_FILE_1', 'D:\APPS_TO_COMPILE\GLIM\OUTPUT\IMAPFIW.TEST.CONTROL2.FDSCCS', SUSER_SNAME(), GETDATE())
GO

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES (@interface_name_id, 'FDS/CCS', 'GLIM_OUT_DEST_FILE_2', 'D:\APPS_TO_COMPILE\GLIM\OUTPUT\IMAPFIW.TEST.MOD999.PARM', SUSER_SNAME(), GETDATE())
GO

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES (@interface_name_id, 'FDS/CCS', 'GLIM_FTP_COMMAND_FILE', 'D:\APPS_TO_COMPILE\GLIM\GLIM_FTP_COMMANDS.txt',SUSER_SNAME(), GETDATE())
GO

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES (@interface_name_id, 'FDS/CCS', 'GLIM_FTP_LOG_FILE', 'D:\APPS_TO_COMPILE\GLIM\OUTPUT\GLIM_FTP_LOG.TXT', SUSER_SNAME(), GETDATE())
GO

-- jan 26

insert into imapsstg.dbo.XX_PROCESSING_PARAMETERS
values (12,'FDS/CCS','FTP_GLIM_INI_FILE','D:\IMAPS_DATA\NotShared\GLIM_FTP.INI','SUSER_SNAME()',GETDATE(),NULL,NULL,NULL)

insert into imapsstg.dbo.XX_PROCESSING_PARAMETERS
values (12,'FDS/CCS','FTP_CCS_INI_FILE','D:\IMAPS_DATA\NotShared\CCS_FTP.INI','SUSER_SNAME()',GETDATE(),NULL,NULL,NULL)

insert into imapsstg.dbo.XX_PROCESSING_PARAMETERS
values (12,'FDS/CCS','FTP_FDS_INI_FILE','D:\IMAPS_DATA\NotShared\FDS_FTP.INI','SUSER_SNAME()',GETDATE(),NULL,NULL,NULL)

-- jan 30 - changes to previous inserts

insert into imapsstg.dbo.XX_PROCESSING_PARAMETERS
values (12,'UTIL','FTP_CHECK_EXE','D:\RUNTIME_PATH\mssched.EXE D:\SCRIPTPATH\FTP_CHK.SCP','SUSER_SNAME()',GETDATE(),NULL,NULL,NULL)