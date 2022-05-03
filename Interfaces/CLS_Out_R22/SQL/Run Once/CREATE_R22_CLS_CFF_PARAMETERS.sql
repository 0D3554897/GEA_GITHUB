

insert into imapsstg.dbo.XX_PROCESSING_PARAMETERS values ((SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'CLS_R22'),'CLS_R22','JAVA_LOG_DIR','T:\IMAPS_DATA\Interfaces\LOGS\R22_CLS\',SUSER_SNAME(),GETDATE(),NULL,NULL,NULL)
insert into imapsstg.dbo.XX_PROCESSING_PARAMETERS values ((SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'CLS_R22'),'CLS_R22','CFF_FILES','"R22_clsdown,R22_clsdownparm,R22_clsdownsummary"',SUSER_SNAME(),GETDATE(),NULL,NULL,NULL)
insert into imapsstg.dbo.XX_PROCESSING_PARAMETERS values ((SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'CLS_R22'),'CLS_R22','SQL_TO_EBCDIC','"2,0,0"',SUSER_SNAME(),GETDATE(),NULL,NULL,NULL)
insert into imapsstg.dbo.XX_PROCESSING_PARAMETERS values ((SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'CLS_R22'),'CLS_R22','PARMFILE','%DATA_DRIVE%IMAPS_DATA\Interfaces\PROCESS\CLS\CLSDOWNPARM.TXT',SUSER_SNAME(),GETDATE(),NULL,NULL,NULL)
insert into imapsstg.dbo.XX_PROCESSING_PARAMETERS values ((SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'CLS_R22'),'CLS_R22','FTP_DEST_SUMFILE','IMAPS_TO_CLS_DOWN_SUMMARY.TXT',SUSER_SNAME(),GETDATE(),NULL,NULL,NULL)
insert into imapsstg.dbo.XX_PROCESSING_PARAMETERS values ((SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'CLS_R22'),'CLS_R22','TEXTFILE','%DATA_DRIVE%IMAPS_DATA\Interfaces\PROCESS\CLS\IMAPS_TO_CLS_ASCII.TXT',SUSER_SNAME(),GETDATE(),NULL,NULL,NULL)

--BATCH UTILITY THAT CHECKS FOR FILE NAME AND HOW LONG AGO IT WAS CREATED
insert into imapsstg.dbo.XX_PROCESSING_PARAMETERS
values ((SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'UTIL'),'UTIL','ISIT_CURRENT','%DATA_DRIVE%Interfaces\PROGRAMS\BATCH\ISIT_CURRENT.BAT',SUSER_SNAME(),GETDATE(),NULL,NULL,NULL)

--BATCH UTILITY THAT RUNS THE FTP
insert into imapsstg.dbo.XX_PROCESSING_PARAMETERS
values ((SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'UTIL'),'UTIL','FTP_EXE','%DATA_DRIVE%Interfaces\PROGRAMS\BATCH\WINSCP_FTP.BAT',SUSER_SNAME(),GETDATE(),NULL,NULL,NULL)



-- TARGET FILE CREATED BY JAVA PROGRAM
/*** THIS VALUE MUST MATCH THE OUTPUT VALUE IN THE PROPERTIES FILE ***/
insert into imapsstg.dbo.XX_PROCESSING_PARAMETERS
values ((SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'CLS_R22'),'CLS_R22','CURRENT_FILE','%DATA_DRIVE%IMAPS_DATA\Interfaces\PROGRAMS\java\cff\output\CLS_R22\CLSDOWN.EBC',SUSER_SNAME(),GETDATE(),NULL,NULL,NULL)

-- TARGET FILE ELAPSED TIME LIMIT
insert into imapsstg.dbo.XX_PROCESSING_PARAMETERS
values ((SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'CLS_R22'),'CLS_R22','ELAPSED','2',SUSER_SNAME(),GETDATE(),NULL,NULL,NULL)

insert into imapsstg.dbo.XX_PROCESSING_PARAMETERS values ((SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'CLS_R22'),'CLS_R22','CLS_SEARCH_PHRASE','"250 Transfer completed"',SUSER_SNAME(),GETDATE(),NULL,NULL,NULL)
insert into imapsstg.dbo.XX_PROCESSING_PARAMETERS values ((SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'CLS_R22'),'CLS_R22','CLS_FTP_ADJUST','2',SUSER_SNAME(),GETDATE(),NULL,NULL,NULL)

insert into imapsstg.dbo.XX_PROCESSING_PARAMETERS values ((SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'CLS_R22'),'CLS_R22','ORG_ID_A','SR',SUSER_SNAME(),GETDATE(),NULL,NULL,NULL)
insert into imapsstg.dbo.XX_PROCESSING_PARAMETERS values ((SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'CLS_R22'),'CLS_R22','ORG_ID_D','22',SUSER_SNAME(),GETDATE(),NULL,NULL,NULL)
insert into imapsstg.dbo.XX_PROCESSING_PARAMETERS values ((SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'CLS_R22'),'CLS_R22','ORG_ID_W','YA',SUSER_SNAME(),GETDATE(),NULL,NULL,NULL)
insert into imapsstg.dbo.XX_PROCESSING_PARAMETERS values ((SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'CLS_R22'),'CLS_R22','ORG_ID_Z','YB',SUSER_SNAME(),GETDATE(),NULL,NULL,NULL)



