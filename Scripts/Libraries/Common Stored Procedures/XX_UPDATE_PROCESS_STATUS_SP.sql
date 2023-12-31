
use imapsstg


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_UPDATE_PROCESS_STATUS_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_UPDATE_PROCESS_STATUS_SP]
GO





-- DROP PROCEDURE dbo.XX_UPDATE_PROCESS_STATUS_SP

CREATE PROCEDURE dbo.XX_UPDATE_PROCESS_STATUS_SP
AS
BEGIN
/***********************************************************************************
Name:		XX_UPDATE_PROCESS_STATUS_SP
Author:		KM
Created:	8/22/05
Purpose:	This stored procedure updates the status/control records of
		inbound interfaces that have completed the deltek costpoint
		processing queue.  Inbound interfaces that have transitioned
		from IN_PROGRESS to CP_COMPLETE have their the final control point 
		record is inserted and their status record updated accordingly.
Parameters:	None
Result Set:	None
Notes:
select * from xx_imaps_int_status
select * from xx_imaps_int_control
select * from imaps.deltek.process_que_entry
select * from xx_lookup_detail
exec xx_update_process_status_sp

SELECT 0 FROM imaps.deltek.process_que_entry
	WHERE PROCESS_ID = "ETIME"
		AND S_PROC_STATUS_CD = 'PENDING'
		
		
2014-02-18  Costpoint 7 changes
			Process Server replaced by Job Server
************************************************************************************/

-- Server/table variables
DECLARE	@IN_CONTROL_PT_SP sysname,
	@UP_STATUS_SP sysname,
	@ret_code integer,
	@INTERFACE_NAME varchar(50),
	@STATUS_RECORD_NUM integer,
	@MODIFIED_DATE datetime,
	@CONTROL_PT_CODE varchar(20),
	@CONTROL_PT_NUM integer,
	@LD_ID integer,
	@LD_DOMAIN_CONST  varchar(30)


SET @IN_CONTROL_PT_SP = 'dbo.xx_insert_int_control_record'
SET @UP_STATUS_SP = 'dbo.xx_update_int_status_record'

-- Need to use a cursor in order to make use of 
-- the stored procedures for inserting and updating
-- control and status records.
DECLARE IN_PROGRESS_LIST CURSOR FAST_FORWARD FOR
SELECT INTERFACE_NAME, STATUS_RECORD_NUM, MODIFIED_DATE
FROM dbo.xx_imaps_int_status 
WHERE STATUS_CODE = 'CPIN_PROGRESS' AND INTERFACE_TYPE = 'I'

-- For each Interface that is INPROGRESS
OPEN IN_PROGRESS_LIST
FETCH NEXT FROM IN_PROGRESS_LIST 
INTO @INTERFACE_NAME, @STATUS_RECORD_NUM, @MODIFIED_DATE

WHILE @@FETCH_STATUS = 0
BEGIN
	-- Check to see if it has completed
	--2014-02-18  Costpoint 7 changes   BEGIN
	select *
	from imaps.deltek.job_schedule		
	where job_id=@INTERFACE_NAME
	and time_stamp>@MODIFIED_DATE
	and SCH_START_DTT>@MODIFIED_DATE
	--2014-02-18  Costpoint 7 changes   END

	-- If it has completed, 
	IF @@ROWCOUNT <> 0
 	BEGIN
		-- Get Last Successful Control Point Code
		SELECT @CONTROL_PT_CODE = CONTROL_PT_ID 
		FROM dbo.XX_IMAPS_INT_CONTROL
		WHERE STATUS_RECORD_NUM = @STATUS_RECORD_NUM AND
	    				  CONTROL_PT_STATUS = 'SUCCESS'
		ORDER BY CONTROL_RECORD_NUM

		IF @CONTROL_PT_CODE = NULL
		BEGIN
			SET NOCOUNT OFF
			RETURN (1)
		END

		-- Look up Last Control Point Number
		SELECT @CONTROL_PT_NUM = PRESENTATION_ORDER, @LD_ID = LOOKUP_DOMAIN_ID
		FROM dbo.XX_LOOKUP_DETAIL
		WHERE APPLICATION_CODE = @CONTROL_PT_CODE

		IF @CONTROL_PT_NUM = NULL
		BEGIN
			SET NOCOUNT OFF
			RETURN (1)
		END

		SELECT @LD_DOMAIN_CONST = DOMAIN_CONSTANT
		FROM dbo.XX_LOOKUP_DOMAIN
		WHERE LOOKUP_DOMAIN_ID = @LD_ID

		IF @LD_DOMAIN_CONST = NULL
		BEGIN
			SET NOCOUNT OFF
			RETURN (1)

		END

		-- Increment Control Point Number
		SET @CONTROL_PT_NUM = @CONTROL_PT_NUM + 1	

		-- Insert Row into Control Table
		EXEC @ret_code = @IN_CONTROL_PT_SP
			@in_int_ctrl_pt_num = @CONTROL_PT_NUM,
			@in_lookup_domain_const = @LD_DOMAIN_CONST,
			@in_status_record_num = @STATUS_RECORD_NUM
	
		IF @ret_code <> 0 
		BEGIN
			SET NOCOUNT OFF
			RETURN (1)
		END


		-- And Update Status Table
		EXEC @ret_code = @UP_STATUS_SP
			@in_status_record_num = @STATUS_RECORD_NUM,
			@in_status_code = 'CP_COMPLETE',
			@in_status_description = 'INFORMATION: Pre-processor Has Completed Processing'

		IF @ret_code <> 0 
		BEGIN
			SET NOCOUNT OFF
			RETURN (1)
		END
	END
	-- Loop to next Interface that is CPIN_PROGRESS
	FETCH NEXT FROM IN_PROGRESS_LIST
	INTO @INTERFACE_NAME, @STATUS_RECORD_NUM, @MODIFIED_DATE
END
CLOSE IN_PROGRESS_LIST
DEALLOCATE IN_PROGRESS_LIST

SET NOCOUNT ON
RETURN (0)


END

GO
