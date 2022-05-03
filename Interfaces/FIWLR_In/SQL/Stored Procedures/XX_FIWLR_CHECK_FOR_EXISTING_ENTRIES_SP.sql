USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_FIWLR_CHECK_FOR_EXISTING_ENTRIES_SP]    Script Date: 10/28/2015 11:04:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Tatiana Perova
-- Create date: 9-30-2015
-- Description:	procedure checks that no FIWLR records were added in the 
-- period before running the first feed for the period
-- It is called as step 1 of special run that pick data from 01-01-1900 till current date
-- =============================================
ALTER PROCEDURE [dbo].[XX_FIWLR_CHECK_FOR_EXISTING_ENTRIES_SP]
AS
BEGIN

	-- Declare the return variable here
	DECLARE 	@fy_cd			 char(4),
	@MESSAGE         varchar(300),
	@pd_no			 smallint,
	@sub_pd_no		 smallint,
	@FIWLR_USER_ID  char(5)

	
	
	
	
	SELECT	@fy_cd 		= fiscal_year, 
			@pd_no 		= CAST(period as SMALLINT), 
			@sub_pd_no	= CAST(sub_pd_no as SMALLINT)
	FROM	IMAPSstg.dbo.xx_fiwlr_rundate_acctcal
	WHERE 	CONVERT(VARCHAR(10),GETDATE(),120) BETWEEN run_start_date AND run_end_date

	set @FIWLR_USER_ID  = 'FIWLR'
	   
	IF @fy_cd is NULL or @pd_no is NULL begin
		RAISERROR  ('Could not find in IMAPSSTG.dbo.xx_fiwlr_rundate_acctcal 
			year/period to check for FIWLR entries',16,1)	
			return;
	end 
	
	

	
	if exists(	SELECT 1 from IMAPS.DELTEK.JE_HDR
	where FY_CD = @fy_cd and PD_NO = @pd_no 
	and ENTR_USER_ID = @FIWLR_USER_ID)  begin 
	    SET @MESSAGE = 'There are records in JE_HDR table that indicate that ' + @FIWLR_USER_ID + 
	     ' run was already done for fy: ' +  @fy_cd + '  period: ' + CAST( @pd_no  AS VARCHAR(2))
	 	RAISERROR (@MESSAGE ,16,1)	
	end 

	
	if EXISTS (	SELECT 1 from IMAPS.DELTEK.JE_HDR_HS
	where FY_CD = @fy_cd and PD_NO = @pd_no 
	and ENTR_USER_ID = @FIWLR_USER_ID) begin 
	    SET @MESSAGE = 'There are records in JE_HDR_HS table that indicate that ' + @FIWLR_USER_ID + 
	 	' run was already done for fy: ' +  @fy_cd + '  period: ' + CAST( @pd_no  AS VARCHAR(2))
	 	RAISERROR (@MESSAGE ,16,1)	
	end 
	  

	
	if EXISTS ( SELECT 1 from IMAPS.DELTEK.VCHR_HDR
	where FY_CD = @fy_cd and PD_NO = @pd_no 
	and ENTR_USER_ID = @FIWLR_USER_ID) begin 
	    SET @MESSAGE = 'There are records in VCHR_HDR table that indicate that ' + @FIWLR_USER_ID + 
	 	' run was already done for fy: ' + @fy_cd + '  period: ' + CAST( @pd_no  AS VARCHAR(2))
	 	RAISERROR (@MESSAGE ,16,1)	
	end 
	

	
	if EXISTS(	SELECT 1 from IMAPS.DELTEK.VCHR_HDR_HS
	where FY_CD = @fy_cd and PD_NO = @pd_no 
	and ENTR_USER_ID = @FIWLR_USER_ID ) begin 
	    SET @MESSAGE = 'There are records in VCHR_HDR_HS table that indicate that ' + @FIWLR_USER_ID + 
	 	' run was already done for fy: ' + @fy_cd + '  period: ' + CAST( @pd_no  AS VARCHAR(2))
	 	RAISERROR (@MESSAGE ,16,1)	
	end 

END



GO



