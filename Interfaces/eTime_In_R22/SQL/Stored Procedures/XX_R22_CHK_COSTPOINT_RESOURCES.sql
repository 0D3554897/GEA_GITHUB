use imapsstg

IF OBJECT_ID('dbo.XX_R22_CHK_COSTPOINT_RESOURCES') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_R22_CHK_COSTPOINT_RESOURCES
    IF OBJECT_ID('dbo.XX_R22_CHK_COSTPOINT_RESOURCES') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_R22_CHK_COSTPOINT_RESOURCES >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_R22_CHK_COSTPOINT_RESOURCES >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER OFF
go

CREATE PROCEDURE dbo.XX_R22_CHK_COSTPOINT_RESOURCES
(
@in_Proc_Que_ID      varchar(12),
@in_Proc_ID          varchar(12),
@out_PROC_SERVER_ID  varchar(12) OUTPUT
)
AS
BEGIN
/************************************************************************************************  
Name:       XX_CHK_COSTPOINT_RESOURCES  
Author:     JG, HVT
Created:    06/24/2005  
Purpose:    Provide information to the Costpoint application to invoke the timesheet preprocessor.
            Called by XX_RUN_ETIME_INTERFACE.
Parameters: @in_Proc_Que_ID is deltek.PROCESS_QUEUE.PROC_QUEUE_ID set up specifically for eTime interface
            @in_Proc_ID is deltek.PROCESS_HDR.PROCESS_ID set up specifically for eTime interface
Result Set: None  
Version:    1.0
Notes:

2014-02-18  Costpoint 7 changes
			Process Server replaced by Job Server
*************************************************************************************************/  

DECLARE @SP_NAME                  sysname,
        @INTERFACE_PROCESS_GROUP  varchar(15),
        @ACTIVE_RECORD_STATUS     varchar(10)

-- set local constants
SET @SP_NAME = 'XX_R22_CHK_COSTPOINT_RESOURCES'
SET @INTERFACE_PROCESS_GROUP = 'INTERFACES'
SET @ACTIVE_RECORD_STATUS = 'ACTIVE'


--2014-02-18  Costpoint 7 changes BEGIN
/*
-- ensure that the PROCESS_ID set up for eTime interface exists
select 1
  from IMAR.DELTEK.PROCESS_HDR
 where PROCESS_ID      = @in_Proc_ID
-- and PROCESS_GRP_DC  = @INTERFACE_PROCESS_GROUP -- PROCESS_HDR.PROCESS_GRP_DC is defined as nullable
-- and CREATOR_USER_ID = SUSER_SNAME()

IF @@ROWCOUNT = 0
   BEGIN
      -- Costpoint process ID for eTime interface does not exist (see DELTEK.PROCESS_HDR.PROCESS_ID).
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 600,
         @in_display_requested   = 1,
         @in_calling_object_name = @SP_NAME
      RETURN(1) -- Return Error and exit
   END

-- ensure that the PROC_QUEUE_ID set up for eTime inbound interface exists
select 1
  from IMAR.DELTEK.PROCESS_QUEUE
 where PROC_QUEUE_ID     = @in_Proc_Que_ID
   and S_QUEUE_STATUS_CD = @ACTIVE_RECORD_STATUS

IF @@ROWCOUNT = 0
   BEGIN
      -- Costpoint process queue ID for eTime interface does not exist (see DELTEK.PROCESS_QUEUE.PROC_QUEUE_ID).
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 601,
         @in_display_requested   = 1,
         @in_calling_object_name = @SP_NAME
      RETURN(1)
   END

-- retrieve the PROC_SERVER_ID
SELECT @out_PROC_SERVER_ID = PROC_SERVER_ID
  FROM IMAR.DELTEK.PROCESS_SERVER
 WHERE PROC_QUEUE_ID = @in_Proc_Que_ID
-- AND S_SERVER_STATUS_CD = @ACTIVE_RECORD_STATUS

IF @out_PROC_SERVER_ID IS NULL
   BEGIN
      -- Costpoint process server for eTime interface is inactive (see DELTEK.PROCESS_SERVER.PROC_SERVER_ID).
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 602,
         @in_display_requested   = 1,
         @in_calling_object_name = @SP_NAME
      RETURN(1)
   END

*/
--2014-02-18  Costpoint 7 changes END


RETURN(0)
END

go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_R22_CHK_COSTPOINT_RESOURCES') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_R22_CHK_COSTPOINT_RESOURCES >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_R22_CHK_COSTPOINT_RESOURCES >>>'
go
