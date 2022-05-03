USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE ID = object_id(N'[dbo].[XX_R22_EMP_MAP_SP]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[XX_R22_EMP_MAP_SP]
GO


CREATE PROCEDURE [dbo].[XX_R22_EMP_MAP_SP] 
(
@out_NO_DATA_FLAG       varchar(8) = NULL OUTPUT,
@out_SYS_ERROR_FLAG     varchar(8) = NULL OUTPUT
)
AS

/****************************************************************************************************
Name:       XX_R22_EMP_MAP_SP
Author:     V Veera
Created:    06/15/2008 
      This stored procedure serves as a script to run and drive all necessary tasks to
            to perform the CERIS_R22 Employee ID mapping to generated Costpoint IMAPS Employee Serial 
      Number.
Parameters: 
Result Set: None
Notes:  Updates the description in the XX_IMAPS_INT_STATUS to reflect completion
****************************************************************************************************/

DECLARE @SP_NAME                        sysname,
 
        @SQLServer_error_code    integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
    @ret_code    int,
        @IMAPS_error_number      integer,       
        @count       int,
        @current_STATUS_RECORD_NUM int,
        @in_STATUS_DESCRIPTION      varchar(50),
        @out_STATUS_DESCRIPTION     varchar(50),
        @CERIS_INTERFACE_NAME       varchar(50),
        @DIV_22_COMPANY_ID          varchar(10),
        @CERIS_COMPANY_PARAM        varchar(50),
        @CERIS_PASSKEY_VALUE        varchar(128),
        @CERIS_PASSKEY_VALUE_PARAM  varchar(30),
        @CERIS_KEYNAME        varchar(50),
    @CERIS_KEYNAME1       varchar(50),
        @CERIS_KEYNAME_PARAM    varchar(30),
    @OPEN_KEY         varchar(400),
    @CLOSE_KEY          varchar(400),
        @SQL_Server_Error_CD        integer

-- set local constants
SET @SP_NAME = 'XX_R22_EMP_MAP_SP'
SET @CERIS_INTERFACE_NAME = 'CERIS_R22'
SET @CERIS_PASSKEY_VALUE_PARAM = 'PASSKEY_VALUE'
SET @CERIS_KEYNAME_PARAM = 'CERIS_KEYNAME'
SET @CERIS_COMPANY_PARAM = 'COMPANY_ID'

SELECT @DIV_22_COMPANY_ID = PARAMETER_VALUE
FROM  dbo.XX_PROCESSING_PARAMETERS
WHERE PARAMETER_NAME    = @CERIS_COMPANY_PARAM
AND   INTERFACE_NAME_CD = @CERIS_INTERFACE_NAME

SELECT  @CERIS_PASSKEY_VALUE = PARAMETER_VALUE
FROM  dbo.XX_PROCESSING_PARAMETERS
WHERE PARAMETER_NAME    = @CERIS_PASSKEY_VALUE_PARAM
AND   INTERFACE_NAME_CD = @CERIS_INTERFACE_NAME

SELECT @CERIS_KEYNAME = PARAMETER_VALUE
FROM  dbo.XX_PROCESSING_PARAMETERS
WHERE PARAMETER_NAME    = @CERIS_KEYNAME_PARAM
AND INTERFACE_NAME_CD = @CERIS_INTERFACE_NAME

SET @OPEN_KEY = 'OPEN SYMMETRIC KEY' + '  ' + @CERIS_KEYNAME + '  ' + 'DECRYPTION BY PASSWORD = ''' +  @CERIS_PASSKEY_VALUE + '''' + '  '
SET @CLOSE_KEY = 'CLOSE SYMMETRIC KEY' + '  ' + @CERIS_KEYNAME

exec (@OPEN_KEY)

SET @SQL_Server_Error_CD = @@ERROR

IF @SQL_Server_Error_CD > 0
   BEGIN
    GOTO ENCRYP_ERROR_HANDLER
   END

--Creating temporary #table to retrieve CERIS Research Employee ID and Manager Serial Number 
CREATE TABLE #CERISSTG1  
( S_R_EMPL_ID char(6)
)

INSERT  INTO #CERISSTG1(S_R_EMPL_ID)
SELECT  DISTINCT CONVERT(VARCHAR(50),DECRYPTBYKEY(R_EMPL_ID))
FROM  dbo.xx_r22_ceris_file_Stg1
WHERE (CONVERT(VARCHAR(50),DECRYPTBYKEY(R_EMPL_ID)) IS NOT NULL OR CONVERT(VARCHAR(50),DECRYPTBYKEY(R_EMPL_ID)) = 'NULL')

/*
(CONVERT(VARCHAR(50),DECRYPTBYKEY(R_EMPL_ID)) <> '-'
AND   (CONVERT(VARCHAR(50),DECRYPTBYKEY(R_EMPL_ID)) NOT IN (SELECT EMPL_ID FROM IMAR.DELTEK.empl WHERE company_id = '2')
AND   
*/

/*
INSERT  INTO #CERISSTG1(S_R_EMPL_ID)
SELECT  DISTINCT CONVERT(VARCHAR(50),DECRYPTBYKEY(mgr_serial_num))
FROM  xx_r22_ceris_file_Stg_vt1
WHERE (CONVERT(VARCHAR(50),DECRYPTBYKEY(mgr_serial_num)) IS NOT NULL
OR    CONVERT(VARCHAR(50),DECRYPTBYKEY(mgr_serial_num)) = 'NULL')
AND   CONVERT(VARCHAR(50),DECRYPTBYKEY(mgr_serial_num))
NOT IN  (SELECT DISTINCT S_R_EMPL_ID FROM #CERISSTG1)
*/

--Generate Costpoint IMAPS Employee Number for every new Research Employee ID
INSERT  INTO dbo.XX_R22_CERIS_EMPL_ID_MAP
    (R_EMPL_ID, TIME_STAMP)
SELECT  EncryptByKey(Key_GUID(@CERIS_KEYNAME), S_R_EMPL_ID), current_timestamp
FROM  #CERISSTG1
WHERE EncryptByKey(Key_GUID(@CERIS_KEYNAME), S_R_EMPL_ID) IS NOT NULL
AND   EncryptByKey(Key_GUID(@CERIS_KEYNAME), S_R_EMPL_ID) <> 'NULL'
AND   EncryptByKey(Key_GUID(@CERIS_KEYNAME), S_R_EMPL_ID) <> '-'
AND   S_R_EMPL_ID NOT IN 
      (SELECT CONVERT(VARCHAR(50),DECRYPTBYKEY(R_EMPL_ID))
       FROM dbo.XX_R22_CERIS_EMPL_ID_MAP) 
    
UPDATE  dbo.XX_R22_CERIS_EMPL_ID_MAP
SET   EMPL_ID = 'R'+RIGHT('00000'+cast(seq_no as varchar),5),
    TIME_STAMP = current_timestamp
WHERE EMPL_ID IS NULL

DROP TABLE  #CERISSTG1

exec (@CLOSE_KEY)


  SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
  SET @ERROR_MSG_PLACEHOLDER1 = 'FIND STATUS_RECORD_NUM'
  SET @ERROR_MSG_PLACEHOLDER2 = 'FOR EMPLOYEE MAPPING'
  PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

  select @count = count(1)
  from XX_IMAPS_INT_STATUS
  where
  interface_name='CERIS_R22'
  and 
  STATUS_CODE not in ('COMPLETED', 'RESET')


  SELECT @SQLSERVER_ERROR_CODE = @@ERROR  
  IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
  IF @count <> 1 GOTO ERROR

  select @current_STATUS_RECORD_NUM = STATUS_RECORD_NUM
  from XX_IMAPS_INT_STATUS
  where
  interface_name='CERIS_R22'
  and 
  STATUS_CODE not in ('COMPLETED', 'RESET')

  EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
     @in_STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM,
     @in_STATUS_CODE       = 'INITIATED',
     @in_STATUS_DESCRIPTION = 'Employee Mapping is Accomplished'

RETURN(0)

ERROR:

PRINT @out_STATUS_DESCRIPTION

EXEC dbo.XX_ERROR_MSG_DETAIL
   @in_error_code           = @IMAPS_error_number,
   @in_display_requested    = 1,
   @in_SQLServer_error_code = @SQLServer_error_code,
   @in_placeholder_value1   = @error_msg_placeholder1,
   @in_placeholder_value2   = @error_msg_placeholder2,
   @in_calling_object_name  = @SP_NAME,
   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

PRINT @out_STATUS_DESCRIPTION

RETURN 1

ENCRYP_ERROR_HANDLER:

   BEGIN
      PRINT 'The decryption operation results in error.'
      SET @out_SYS_ERROR_FLAG = 'SYS_ERROR'
   END

RETURN(1)

/*
EXEC [dbo].[XX_R22_EMP_MAP_SP] 
DROP TABLE XX_R22_CERIS_EMPL_ID_MAP


*/
