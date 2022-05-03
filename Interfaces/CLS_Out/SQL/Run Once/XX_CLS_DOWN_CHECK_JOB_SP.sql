USE [IMAPSStg]
GO

DECLARE @CNT INT

SELECT @CNT = COUNT(*) FROM
sys.sysobjects a,
sys.syscomments b
where a.type like 'P' -- only stored procedures
and a.id = b.id
and a.name like '%XX_CLS_DOWN_CHECK_JOB_SP%'

PRINT @CNT

IF @CNT<>0
  BEGIN
      DROP PROCEDURE [dbo].[XX_CLS_DOWN_CHECK_JOB_SP]
  END
  

DELETE FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS 
  where interface_name_cd = 'CLS' AND PARAMETER_NAME = 'XX_CLS_DOWN_CHECK_JOB_SP'

GO





