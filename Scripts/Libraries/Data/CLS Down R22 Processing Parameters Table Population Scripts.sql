-- BP&S Reference No.: CR1656
-- ClearQuest Reference No.: CP600000465

-- Insert a total of 48 XX_PROCESSING_PARAMETERS records

DELETE FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'CLS_R22'



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'IGS_WEB_PROJ_ID', '144F', SUSER_SNAME(), GETDATE())        -- may be useless
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'IN_SOURCE_SYSOWNER', 'main.user@org_name.org', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'IN_DESTINATION_SYSOWNER', 'name.last@org_name.org', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'IMAPS_DATABASE_NAME', 'IMAPSStg', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'IMAPS_SCHEMA_OWNER', 'dbo', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'SUM_FILE', '\\Ffx23dap08\interfaces\PROCESS\CLS_R22\IMAPS_R22_TO_CLS_DOWN_SUMMARY.txt', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'SUM_FMT', '\\Ffx23dap08\interfaces\FORMAT\XX_CLS_DOWN_SUMMARY.fmt', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'COUNTRY_NUM', '897', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'LEDGER_CD', '00', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'FILE_ID', '156', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'TOLI', 'L', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'DIVISION', '22', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'LERU_NUM', 'QQQQQQ', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'LEDGER_SOURCE_CD', '156', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'ACCOUNTANT_ID', 'IMAPS', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'USER_ID', 'IMAPS', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'INPUT_TYPE_ID', 'F', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'FULFILLMENT_CHANNEL_CD', 'CCS', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'IGS_CSI_PROJ_ID', '144F', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'JAVA_CMD', 'java -jar \\Ffx23dap08\interfaces\PROGRAMS\java\exe\Create_R22_999_File.jar', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'PROCESS_DIR', '\\Ffx23dap08\interfaces\PROCESS\CLS_R22\', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'ARCH_DIR', '\\Ffx23dap08\interfaces\ARCHIVE\CLS_R22\', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'ERROR_DIR', '\\Ffx23dap08\interfaces\ERRORS\CLS_R22\', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'SERVER_PARAM', '9.48.228.62', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'DB_PARAM', 'IMAPSStg', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'USER_PARAM', 'imapsprd', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'PWD_PARAM', 'prod1uction', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'DFLT_CUSTOMER_NUM', '9999500', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'DFLT_DEPARTMENT', 'YKE', SUSER_SNAME(), GETDATE())           -- may be useless
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'DFLT_MACHINE_TYPE', 'GA70', SUSER_SNAME(), GETDATE())       -- may be useless
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'DFLT_PRODUCT_ID', '5696398', SUSER_SNAME(), GETDATE())     -- may be useless
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'IGS_BTO_PROJ_ID', 'VS98', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'DFLT_CONTRACT_NUM', 'PS001', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'DFLT_BALANCE_MAJOR', '456', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'DFLT_BALANCE_MINOR', '0300', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'DFLT_BALANCE_SUBMINOR', '0000', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'DFLT_BALANCE_CONTRACT', ' ', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'DFLT_PL_NO_GL_MAJOR', '456', SUSER_SNAME(), GETDATE())     -- may be useless
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'DFLT_PL_NO_GL_MINOR', '0300', SUSER_SNAME(), GETDATE())    -- may be useless
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'DFLT_PL_NO_GL_SUBMINOR', '0000', SUSER_SNAME(), GETDATE())  -- may be useless
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'DFLT_PL_GL_BALANCE_MAJOR', '456', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'DFLT_PL_GL_BALANCE_MINOR', '0300', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'DFLT_PL_GL_BALANCE_SUBMINOR', '0000', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'DFLT_PL_GL_BALANCE_CONTRACT', ' ', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'REVENUE_ACCT_ID', '30-01-01', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'CONFRMCD', '1JAN1JAN', SUSER_SNAME(), GETDATE())
GO



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'COMPANY_ID', '2', SUSER_SNAME(), GETDATE())
GO






use imapsstg
update xx_processing_parameters
set parameter_value='0000000'
where interface_name_cd='CLS_R22'
and parameter_name in ('DFLT_CONTRACT_NUM', 'DFLT_BALANCE_CONTRACT')


go


