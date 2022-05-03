IF OBJECT_ID('dbo.XX_ETIME_SIMULATE_COSTPOINT_SP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_ETIME_SIMULATE_COSTPOINT_SP
    IF OBJECT_ID('dbo.XX_ETIME_SIMULATE_COSTPOINT_SP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_ETIME_SIMULATE_COSTPOINT_SP >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_ETIME_SIMULATE_COSTPOINT_SP >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER ON
go



CREATE PROCEDURE [dbo].[XX_ETIME_SIMULATE_COSTPOINT_SP] 
(
@in_COMPANY_ID char(1)= NULL -- Added CR-1543
)
AS
/************************************************************************************************  
Name:       	XX_ETIME_SIMULATE_COSTPOINT_SP
Author:     	Keith McGuire
Created:    	04/2007  
Purpose:    	
	
	THIS ENTIRE STORED PROCEDURE IS FOR DR-922
	
	IMAPS ETIME INTERFACE HAS 2 TYPES OF TIMESHEET PROCESSING:
	
	1.REGULAR TIMESHEETS
	2.CORRECTING TIMESHEETS

	EVERYTHING IS COSTED AT THE CURRENT YEAR RATES (GENL_LAB_CAT)
	BUT LABOR INFORMATION IS DERIVED FROM EMPL_LAB_INFO	
	
	THIS STORED PROCEDURE HANDLES CASES 1 AND 2

Prerequisites: 	none 
Version: 	1.0
Version: 	2.0 	Modified for CR-1543 COMPANY_ID added tp 05/01/2008
					Modified for CR-1539 pay_type logic added tp 05/01/2008
                    Modified for CR-4886 Actuals Change C,N,D 12/13/2012
                    Modified for CR-5554 PLC replaced with GLC for DDOUs
************************************************************************************************/  
BEGIN
		
	--1	GRAB LABOR INFORMATION FROM EMPL_LAB_INFO
	UPDATE XX_IMAPS_TS_PREP_TEMP
	SET
	GENL_LAB_CAT_CD = ELI.GENL_LAB_CAT_CD,
	ORG_ID = ELI.ORG_ID
	FROM
	XX_IMAPS_TS_PREP_TEMP TS
	INNER JOIN
	IMAPS.DELTEK.EMPL_LAB_INFO ELI
	ON
	(
	ELI.EMPL_ID = TS.EMPL_ID
	AND
	 (
		( TS.S_TS_TYPE_CD = 'R'
		  AND
		  TS.TS_DT BETWEEN ELI.EFFECT_DT AND ELI.END_DT	)
		OR
		( TS.S_TS_TYPE_CD in ( 'C','N','D')
		  AND
		  TS.CORRECTING_REF_DT BETWEEN ELI.EFFECT_DT AND ELI.END_DT)
	 )
	)

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

	

	--2	PERFORM ACCOUNT MAPPING 
	--	AND 
	--	CURRENT YEAR RATE LAB_CST_AMT
	UPDATE XX_IMAPS_TS_PREP_TEMP
	SET
	ACCT_ID = LAGD.ACCT_ID,
	LAB_CST_AMT = 
	CAST(   
		CAST(  (
		CAST(TS.CHG_HRS AS DECIMAL(14,2))
		*
	   	(SELECT GENL_AVG_RT_AMT
		 FROM IMAPS.DELTEK.GENL_LAB_CAT
	         WHERE GENL_LAB_CAT_CD = TS.GENL_LAB_CAT_CD
	         AND COMPANY_ID=@in_COMPANY_ID) -- Modified for CR-1543
		*
		(SELECT PAY_TYPE_FCTR_QTY
		 FROM IMAPS.DELTEK.PAY_TYPE
	         WHERE PAY_TYPE = LAGD.REG_PAY_TYPE)
		 ) AS DECIMAL(14,2)) AS VARCHAR
	     )
	FROM XX_IMAPS_TS_PREP_TEMP TS
	INNER JOIN
	IMAPS.DELTEK.LAB_ACCT_GRP_DFLT LAGD
	ON
	( 
	 LAGD.LAB_GRP_TYPE = SUBSTRING(TS.ORG_ID, 10, 2)
	 AND
	 LAGD.COMPANY_ID=@in_COMPANY_ID -- Modified for CR-1543
	 AND
	 LAGD.ACCT_GRP_CD = (SELECT ACCT_GRP_CD FROM IMAPS.DELTEK.PROJ WHERE PROJ_ABBRV_CD = TS.PROJ_ABBRV_CD AND COMPANY_ID=@in_COMPANY_ID) -- Modified for CR-1543
	)

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER



	--2a Update ACCT_ID from PAY Type look up map table for Pay_type=Standby
	-- Added for CR-1539
	UPDATE XX_IMAPS_TS_PREP_TEMP
	SET
	ACCT_ID = PTAM.STB_ACCT_ID
	FROM XX_IMAPS_TS_PREP_TEMP TS
	INNER JOIN
	XX_PAY_TYPE_ACCT_MAP PTAM
	ON
	( 
	 PTAM.PAY_TYPE = TS.PAY_TYPE
	 AND
	 PTAM.LAB_GRP_TYPE = SUBSTRING(TS.ORG_ID, 10, 2)
	 AND
	 PTAM.COMPANY_ID=@in_COMPANY_ID -- Modified for CR-1543
	 AND
	 PTAM.ACCT_GRP_CD = (SELECT ACCT_GRP_CD FROM IMAPS.DELTEK.PROJ WHERE PROJ_ABBRV_CD = TS.PROJ_ABBRV_CD AND COMPANY_ID=@in_COMPANY_ID) -- Modified for CR-1543
	)

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

    --3 Added CR-5554 01/23/2012
    --recurring AI for CR3532 not being implemented
    --configure 1M project timesheet defaults
    INSERT INTO  IMAPS.DELTEK.PROJ_TS_DFLT
        (PROJ_ID,
         APPLY_LOWER_LVL_FL,
         ORG_ID,
         ACCT_ID,
         REF1_ID,
         REF2_ID,
         REG_PAY_TYPE,
         OT_PAY_TYPE,
         GENL_LAB_CAT_CD,
         LAB_LOC_CD,
         WORK_COMP_CD,
         BILL_LAB_CAT_CD,
         MODIFIED_BY,
         TIME_STAMP,
	    ROWVERSION,
        WH_STATE_CD)
    SELECT 
             A.PROJ_ID,
             'N' APPLY_LOWER_LVL_FL,
             A.ORG_ID,
             NULL ACCT_ID,
             NULL REF1_ID,
             NULL REF2_ID,
             NULL REG_PAY_TYPE,
             NULL OT_PAY_TYPE,
             NULL GENL_LAB_CAT_CD,
             NULL LAB_LOC_CD,
             NULL WORK_COMP_CD,
             NULL BILL_LAB_CAT_CD,
             suser_sname() MODIFIED_BY,
             GETDATE() TIME_STAMP,
             0 ROWVERSION,
             NULL WH_STATE_CD
    FROM IMAPS.DELTEK.PROJ A LEFT OUTER JOIN  IMAPS.DELTEK.PROJ_TS_DFLT B
    ON A.PROJ_ID=B.PROJ_ID
    WHERE A.PROJ_ID NOT LIKE 'I%'
    AND A.PROJ_ABBRV_CD <>''
    AND A.ORG_ID LIKE '1M%'
    AND B.PROJ_ID IS NULL 


	--4	UPDATE ORG_ID FROM PROJ_TS_DFLT
	--	FOR DIRECT PROJECTS
	UPDATE XX_IMAPS_TS_PREP_TEMP
	SET ORG_ID = PTD.ORG_ID
	FROM 
	XX_IMAPS_TS_PREP_TEMP TS
	INNER JOIN
	IMAPS.DELTEK.PROJ_TS_DFLT PTD
	ON
	(PTD.PROJ_ID = (SELECT PROJ_ID FROM IMAPS.DELTEK.PROJ WHERE PROJ_ABBRV_CD = TS.PROJ_ABBRV_CD AND COMPANY_ID=@in_COMPANY_ID) -- Modified for CR-1543
	)


	--5 Calculate Cost for Standby pay types
	--Added CR-1539 for STB PAY_TYPE value
	
	UPDATE XX_IMAPS_TS_PREP_TEMP
	SET
	LAB_CST_AMT = 
	CAST(   
		CAST(  (
		CAST(TS.CHG_HRS AS DECIMAL(14,2))
		*
	   	(SELECT GENL_AVG_RT_AMT
		 FROM IMAPS.DELTEK.GENL_LAB_CAT
	         WHERE GENL_LAB_CAT_CD = TS.GENL_LAB_CAT_CD
	         AND COMPANY_ID=@in_COMPANY_ID) -- Modified for CR-1543
		*
		(SELECT PAY_TYPE_FCTR_QTY
		 FROM IMAPS.DELTEK.PAY_TYPE
	         WHERE PAY_TYPE = TS.PAY_TYPE)
		 ) AS DECIMAL(14,2)) AS VARCHAR
	     )
	FROM XX_IMAPS_TS_PREP_TEMP TS
	WHERE (RTRIM(PAY_TYPE)<>'')


    --6. Change PLCs with GLC for NPUB and ICAB
    --Added CR-5554
    UPDATE xx_imaps_ts_prep_temp
    SET bill_lab_cat_cd=eli.genl_lab_cat_cd
    FROM 
    xx_imaps_ts_prep_temp ts
    INNER JOIN
    imaps.deltek.empl_lab_info eli
    ON
    ( 
    --fits DDOU PLC criteria
    0<>(SELECT COUNT(1) 
        FROM imaps.deltek.proj 
        WHERE LEFT(proj_id,9) IN ('DDOU.NPUB','DDOU.ICAB')
        AND proj_abbrv_cd<>''
        AND proj_abbrv_cd=ts.proj_abbrv_cd)
    AND
    eli.empl_id=ts.empl_id
    AND
    CAST(isnull(correcting_ref_dt,ts_dt) AS datetime) BETWEEN eli.effect_dt AND eli.end_dt
    )
    

    --7. At the same time we will also load record into TM_RT_ORDER for PLC mapping
    --link top LEVEL 2 source project to lower-level charge codes where not already linked
    INSERT INTO imaps.deltek.tm_rt_order
    (proj_id, s_bill_rt_tbl_cd, seq_no, modified_by, time_stamp, srce_proj_id, tm_rt_order_key, rowversion)
    SELECT proj_id, 'PC', 1, suser_sname(), CURRENT_TIMESTAMP, LEFT(proj_id,9) AS srce_proj_id, 1, 0
    FROM imaps.deltek.proj P
    WHERE LEFT(proj_id,9) IN ('DDOU.NPUB','DDOU.ICAB')
    AND proj_abbrv_cd<>''
    AND 0 = (SELECT COUNT(1) FROM imaps.deltek.tm_rt_order WHERE proj_id=P.proj_id)

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

	RETURN (0)
	
	BL_ERROR_HANDLER:
	
	PRINT 'ERROR UPDATING TABLE'
	RETURN(1)

END





go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_ETIME_SIMULATE_COSTPOINT_SP') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_ETIME_SIMULATE_COSTPOINT_SP >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_ETIME_SIMULATE_COSTPOINT_SP >>>'
go
