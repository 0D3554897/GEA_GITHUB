


USE [IMAPSStg]
GO
/****** Object:  UserDefinedFunction [dbo].[XX_GET_HR_TYPE_UF]    Script Date: 07/02/2014 21:47:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER FUNCTION [dbo].[XX_GET_HR_TYPE_UF]
(
@in_PROJ_ID     VARCHAR(30),
@in_ACCOUNT_ID  VARCHAR(15)   -- not used
)  
RETURNS CHAR(2)
AS  

BEGIN 

/************************************************************************************************  
Name:       XX_GET_HR_TYPE_UF
Author:     Tatiana Perova
Created:    10/27/2005  
Purpose:    This function determines the type of hours based on the IMAPS project structure.
            Valid/active hour type codes are stored in the lookup table XX_UTIL_HOURS_HR_TYPE
            which is populated once at software installation time.
            Called by XX_UTIL_LOAD_STAGING_DATA_SP.
Parameters:
Return:     HR_TYPE for XX_UTIL_LAB_OUT
Version:    1.1

Notes:      Examples of function call: Prepare column values for the XX_UTIL_LAB_OUT record

            select dbo.XX_GET_HR_TYPE_UF(d.PROJ_ID, NULL) as HR_TYPE

            select dbo.XX_GET_ACCT_TYP_CD_UF(dbo.XX_GET_HR_TYPE_UF(d.PROJ_ID, a.ACCT_ID)) as ACCT_TYP_CD

KM 7/7/06
LOGIC CHANGE - DEV00001021
Tejas Patel 10/15/2007
Logic Change DR-1239 PGNA, MGOH will get OA credit.

--review this HR type logic....there appear to be holes and no defaults
--I'm confused...not sure if returnvalue could be null

--USE ACCT_ID TO DETERMINE THE ALLOWABLE AND UNALLOWABLE

08/29/2006 CR036 - Restructure of Indirect Projects

11/27/07 - CR-1333 Changes UNB PAG will get unbillable credit for Div. 16 projects
12/05/07 - CR-1335 Changes PU1X will no longer receive Billable credit
05/20/08 - CR-1543 Modified for Company ID
05/20/08 - CR-1539 Modified for RIRD logic
09/25/08 - CR-1689 Modified for IINT.MBAE Logic
01/06/10 - CR-2627 Modified for EDU codes logic
10/05/10 - CR-3098 Modified for NISC changes
11/05/02 - CR-3719 Modified for MMOS Logic
12/01/10 - CR-5352 Modified for New LWP/OT Hr Types
02/17/14 - CR-6332 Modified for 1P Changes
07/06/14 - CR-7369 modified for OA Credit for SUBK Projects
12/14/14 - CR-7530 Modified for SHTD Charge codes UTIL types
0/03/2019- CR-10825 Modified for Leave codes
06/10/2021- CR-12915 Modified for IINT.FSVC.FSPJ - IP Credit
**************************************************************************************************/ 

DECLARE @HOUR_TYPE_CD           CHAR(2),
        @DIRECT_PROJ_IND        CHAR(1),
        @PAG_PROJ_IND           CHAR(3),
        @UNALLOWABLE_IND        CHAR(1),
        @BILLABLE               VARCHAR(2),
        @BID_AND_PROPOSAL       VARCHAR(2),
        @COST_RECOVERY          VARCHAR(2),
        @UNALLOWABLE_OVERHEAD   VARCHAR(2),
        @ALLOWABLE_OVERHEAD     VARCHAR(2),
        @CONTINUING_EDUCATION   VARCHAR(2),
        @HOLIDAY                VARCHAR(2),
        @SICK                   VARCHAR(2),
        @AUTHORIZED_ABSENCE     VARCHAR(2),
        @VACATION               VARCHAR(2),
        @OTHER_ABSENCE          VARCHAR(2),
        @INTERNAL_PROJECT       VARCHAR(2),
        @BENCH                  VARCHAR(2),
        @GENERAL_AND_ADMIN      VARCHAR(2),
        @L1_PROJ_SEG_ID         VARCHAR(30),
        @L2_PROJ_SEG_ID         VARCHAR(30),
        @L3_PROJ_SEG_ID         VARCHAR(30),
        @L4_PROJ_SEG_ID         VARCHAR(30),
		@IN_COMPANY_ID			SYSNAME		-- Added CR-1543

-- set local constants
SET @DIRECT_PROJ_IND      = 'D'
SET @UNALLOWABLE_IND      = 'U'

SET @BILLABLE             = 'B'
SET @BID_AND_PROPOSAL     = 'BP'
SET @COST_RECOVERY        = 'CR'
SET @UNALLOWABLE_OVERHEAD = 'OU'
SET @ALLOWABLE_OVERHEAD   = 'OA'
SET @CONTINUING_EDUCATION = 'CE'
SET @HOLIDAY              = 'HD'
SET @SICK                 = 'SD'
SET @AUTHORIZED_ABSENCE   = 'AD'
SET @VACATION             = 'VD'
SET @OTHER_ABSENCE        = 'OD' -- e.g., leave without pay
SET @INTERNAL_PROJECT     = 'IP'
SET @BENCH                = 'BE'
SET @GENERAL_AND_ADMIN    = 'OA' -- CR-1305 changed from GA to OA

-- Retrieve Additional parameters
-- Added CR-1543
SELECT @in_COMPANY_ID= PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'UTIL'   
   AND PARAMETER_NAME = 'COMPANY_ID'

-- retrieve the PROJ record for the input project ID @in_PROJ_ID
SELECT @L1_PROJ_SEG_ID = L1_PROJ_SEG_ID, @L2_PROJ_SEG_ID = L2_PROJ_SEG_ID, @L3_PROJ_SEG_ID = L3_PROJ_SEG_ID, @L4_PROJ_SEG_ID = L4_PROJ_SEG_ID, @PAG_PROJ_IND=ACCT_GRP_CD
  FROM IMAPS.Deltek.PROJ
 WHERE PROJ_ID = @in_PROJ_ID
	AND COMPANY_ID=@in_COMPANY_ID -- Added CR-1543

/*
 * Billable
 */
-- CR-1335 Changes begin
/*
IF (@in_PROJ_ID like 'DDOU.PUBL.PU1X%' OR (LEFT(@in_PROJ_ID, 1) = @DIRECT_PROJ_IND AND (@L1_PROJ_SEG_ID != 'DDOU' OR @PAG_PROJ_IND!='UNB'))) --Modified for CR-1333
   SET @HOUR_TYPE_CD = @BILLABLE

IF (@in_PROJ_ID like 'DDOU.PUBL.PU1X%' OR (LEFT(@in_PROJ_ID, 1) = @DIRECT_PROJ_IND AND @L1_PROJ_SEG_ID != 'DDOU' AND @PAG_PROJ_IND='UNB')) --Added for CR-1333
   SET @HOUR_TYPE_CD = @COST_RECOVERY
*/
IF ((LEFT(@in_PROJ_ID, 1) = @DIRECT_PROJ_IND AND (@L1_PROJ_SEG_ID != 'DDOU' AND @PAG_PROJ_IND!='UNB'))) --Modified for CR-1333
   SET @HOUR_TYPE_CD = @BILLABLE

IF ((LEFT(@in_PROJ_ID, 1) = @DIRECT_PROJ_IND AND @L1_PROJ_SEG_ID != 'DDOU' AND @PAG_PROJ_IND='UNB')) --Added for CR-1333
   SET @HOUR_TYPE_CD = @COST_RECOVERY
-- CR-1335 Changes END

/*
 * BOPP = Bid & Proposal
 * MOSS = Marketing Opportunity Support
 */
IF @L1_PROJ_SEG_ID IN ('BOPP', 'MOSS', 'RIRD','MMOS') -- RIRD Added CR-1539 --MMOS Added CR-3719
   SET @HOUR_TYPE_CD = @BID_AND_PROPOSAL

/*
 * Cost Recovery
 */
--CR-1335  Changes BEGIN
/*
IF @L1_PROJ_SEG_ID = 'DDOU' AND @in_PROJ_ID not like 'DDOU.PUBL.PU1X%'
   SET @HOUR_TYPE_CD = @COST_RECOVERY
*/
IF @L1_PROJ_SEG_ID = 'DDOU'
   SET @HOUR_TYPE_CD = @COST_RECOVERY
--CR-1335  Changes END

/*
 * Unallowable Overhead
 * Beginning at level 2, the segment ID values use the following 1-char prefix: F = Federal, M = Operations & Maintenance (O&M), and P = ?
 * Under IINT, at level 2, F and M projects are set up similarly; i.e., each consists of G&H, G&A, BAE and SVC.
 * From Prashant: Add two conditions
 * (1) that unallowable overhead hours are from IINT projects
 * (2) that unallowable overhead hours are not bench project hours.
 */

IF (@L1_PROJ_SEG_ID = 'IINT'
    AND (SELECT LEFT(ACCT_GRP_CD, 1) FROM IMAPS.Deltek.PROJ WHERE PROJ_ID = @in_PROJ_ID AND COMPANY_ID=@in_COMPANY_ID ) = @UNALLOWABLE_IND 
	-- Modified CR-1543
    AND (SELECT PROJ_ABBRV_CD FROM IMAPS.Deltek.PROJ WHERE PROJ_ID = @in_PROJ_ID AND COMPANY_ID=@in_COMPANY_ID) NOT IN (SELECT PROJ_ABBRV_CD FROM dbo.XX_UTIL_BENCH_CODES)
   )
   SET @HOUR_TYPE_CD = @UNALLOWABLE_OVERHEAD

/*
 * Allowable Overhead
 * From Prashant: Add the condition that allowable overhead hours are not bench project hours.
 */

IF (
    (
     @L1_PROJ_SEG_ID + '.' + @L2_PROJ_SEG_ID = 'IINT.FGOH'
     OR
     @L1_PROJ_SEG_ID + '.' + @L2_PROJ_SEG_ID = 'IINT.XGOH'
     -- Added CR-3098 NISC Changes
     OR
     @L1_PROJ_SEG_ID + '.' + @L2_PROJ_SEG_ID = 'IINT.XXOH'
     -- Added CR-3098 NISC Changes
     OR
	 -- Added 'IINT.FSVC.FSPJ' on 07/02/2014 CR-7369
	 -- Removed 'IINT.FSVC.FSPJ' on 06/10/2021 CR-12915
     @L1_PROJ_SEG_ID + '.' + @L2_PROJ_SEG_ID + '.' + @L3_PROJ_SEG_ID IN ('IINT.FSVC.FOCC', 'IINT.FSVC.FSVC', 'IINT.FSVC.FGWK')
    )
   AND (SELECT LEFT(ACCT_GRP_CD, 1) FROM IMAPS.Deltek.PROJ WHERE PROJ_ID = @in_PROJ_ID AND COMPANY_ID=@in_COMPANY_ID) != @UNALLOWABLE_IND
   AND ((SELECT PROJ_ABBRV_CD FROM IMAPS.Deltek.PROJ WHERE PROJ_ID = @in_PROJ_ID AND COMPANY_ID=@in_COMPANY_ID) NOT IN (SELECT PROJ_ABBRV_CD FROM dbo.XX_UTIL_BENCH_CODES))
   )
	-- Modified for CR-1543
   SET @HOUR_TYPE_CD = @ALLOWABLE_OVERHEAD



/* Allowable Overhead
 * From Prashant: Add the condition that allowable overhead hours  for MGOH and PGNA (DR-1239 10/15/2007)
 */
IF (
     @L1_PROJ_SEG_ID + '.' + @L2_PROJ_SEG_ID = 'IINT.MGOH'
   )
   SET @HOUR_TYPE_CD = @ALLOWABLE_OVERHEAD

IF (
     @L1_PROJ_SEG_ID + '.' + @L2_PROJ_SEG_ID = 'IINT.PGNA'
   )
   SET @HOUR_TYPE_CD = @ALLOWABLE_OVERHEAD



/*
 * Continuing Education
 */
IF (@L1_PROJ_SEG_ID + '.' + @L2_PROJ_SEG_ID + '.' + @L3_PROJ_SEG_ID = 'IINT.FSVC.FEDU'
    AND (SELECT LEFT(ACCT_GRP_CD, 1) FROM IMAPS.Deltek.PROJ WHERE PROJ_ID = @in_PROJ_ID AND COMPANY_ID=@in_COMPANY_ID) != @UNALLOWABLE_IND
   )
	-- Modified for CR-1543
   SET @HOUR_TYPE_CD = @CONTINUING_EDUCATION



/*
 * Holiday, Sick, Authorized Absence, Vacation, Other Absence
 * PROJ.L2_PROJ_SEG_ID = IINT.PPTO = Paid Time Off (PTO)
 */

IF @L1_PROJ_SEG_ID + '.' + @L2_PROJ_SEG_ID + '.' + @L3_PROJ_SEG_ID = 'IINT.PPTO.0001'

   SET @HOUR_TYPE_CD =
      CASE @L4_PROJ_SEG_ID
         WHEN 'HD16' THEN @HOLIDAY
         WHEN 'SD16' THEN @SICK
			-- Added CR-7530 Begin Change
			WHEN 'D6ST' THEN @SICK
			WHEN 'D6S4' THEN @SICK
			WHEN 'D6IA' THEN @SICK
			WHEN 'DMST' THEN @SICK
			WHEN 'DMS4' THEN @SICK
			WHEN 'DMIA' THEN @SICK
			/* Commented CR-10825 move block to next section
			WHEN 'DPST' THEN @SICK
			WHEN 'DPS2' THEN @SICK
			WHEN 'DPS3' THEN @SICK
			WHEN 'DPIA' THEN @SICK
			*/ 
			-- End Change
         WHEN 'AD16' THEN @AUTHORIZED_ABSENCE
         WHEN 'VD16' THEN @VACATION
         WHEN 'OD16' THEN @OTHER_ABSENCE
         --BEGIN CR-3098 Changes
         WHEN 'OP1M' THEN @HOLIDAY
		 WHEN 'OS1M' THEN @SICK
         WHEN 'OD1M' THEN @AUTHORIZED_ABSENCE
         WHEN 'OV1M' THEN @VACATION
         WHEN 'OA1M' THEN @OTHER_ABSENCE
         --END CR-3098 Changes
		 --BEGIN- CR-5352 Change
			WHEN 'JF58' THEN @AUTHORIZED_ABSENCE
			WHEN 'JF9Z' THEN @AUTHORIZED_ABSENCE
			WHEN 'JFA0' THEN @AUTHORIZED_ABSENCE
			WHEN 'O48M' THEN @AUTHORIZED_ABSENCE
			WHEN 'O48N' THEN @AUTHORIZED_ABSENCE
			WHEN 'O48O' THEN @AUTHORIZED_ABSENCE
		 --END- CR-5352 Change
		 -- Begin CR-10825 Change
		 	WHEN 'Q82O' THEN @AUTHORIZED_ABSENCE
		 	WHEN 'Q814' THEN @AUTHORIZED_ABSENCE
		 	WHEN 'Q83A' THEN @AUTHORIZED_ABSENCE
		 	WHEN 'Q83E' THEN @AUTHORIZED_ABSENCE
		 	WHEN 'Q83G' THEN @AUTHORIZED_ABSENCE
		 -- End CR-10825 Change
      END

-- BEGIN CR-6332
IF @L1_PROJ_SEG_ID + '.' + @L2_PROJ_SEG_ID + '.' + @L3_PROJ_SEG_ID = 'IINT.PPTO.001P'
   SET @HOUR_TYPE_CD =
      CASE @L4_PROJ_SEG_ID
         WHEN 'P1DY' THEN @HOLIDAY
         WHEN 'P1SD' THEN @SICK
         WHEN 'P1AD' THEN @AUTHORIZED_ABSENCE
         WHEN 'P1VD' THEN @VACATION
         WHEN 'P1OD' THEN @OTHER_ABSENCE
         WHEN 'P1JD' THEN @AUTHORIZED_ABSENCE
         WHEN 'P1ML' THEN @AUTHORIZED_ABSENCE
         WHEN 'P1OX' THEN @AUTHORIZED_ABSENCE
		-- Begin CR-10825 change
		 	WHEN 'Q83J' THEN @AUTHORIZED_ABSENCE
		 	WHEN 'Q82G' THEN @AUTHORIZED_ABSENCE
		 	WHEN 'Q83M' THEN @AUTHORIZED_ABSENCE
		 	WHEN 'Q83W' THEN @AUTHORIZED_ABSENCE
		 	WHEN 'Q84B' THEN @AUTHORIZED_ABSENCE
			-- moved block from top section
			WHEN 'DPST' THEN @SICK
			WHEN 'DPS2' THEN @SICK
			WHEN 'DPS3' THEN @SICK
			WHEN 'DPIA' THEN @SICK
		-- End CR-10825 change
      END
-- END CR-6332

/*
 * Internal/Special Project
 */
 
/*  Commented this code - - for OA credit for 'IINT.FSVC.FSPJ' on 07/02/2014 CR-7369 */
/* Un-Commented this code for IP Credit for 'IINT.FSVC.FSPJ' on 06/10/2021 CR-12915 */
IF (@L1_PROJ_SEG_ID + '.' + @L2_PROJ_SEG_ID + '.' + @L3_PROJ_SEG_ID = 'IINT.FSVC.FSPJ'
    AND (SELECT LEFT(ACCT_GRP_CD, 1) FROM IMAPS.Deltek.PROJ WHERE PROJ_ID = @in_PROJ_ID AND COMPANY_ID=@in_COMPANY_ID) != @UNALLOWABLE_IND
   )
   SET @HOUR_TYPE_CD = @INTERNAL_PROJECT
	-- Modified for CR-1543




/*
 * Allowable Overheads for SUBK Projects
 */
IF ((SELECT PROJ_ABBRV_CD FROM IMAPS.Deltek.PROJ WHERE PROJ_ID = @in_PROJ_ID AND COMPANY_ID=@in_COMPANY_ID) IN (SELECT PROJ_ABBRV_CD FROM dbo.XX_UTIL_OA_CODES WHERE ACTIVE_FL='Y'))
   SET @HOUR_TYPE_CD = @ALLOWABLE_OVERHEAD
	-- Modified for CR-7369 07/02/2014

/*
 * Bench
 */
IF ((SELECT PROJ_ABBRV_CD FROM IMAPS.Deltek.PROJ WHERE PROJ_ID = @in_PROJ_ID AND COMPANY_ID=@in_COMPANY_ID) IN (SELECT PROJ_ABBRV_CD FROM dbo.XX_UTIL_BENCH_CODES))
   SET @HOUR_TYPE_CD = @BENCH
	-- Modified for CR-1543

/*
 * Continuing Education logic based on Table
 */

IF ((SELECT PROJ_ABBRV_CD FROM IMAPS.Deltek.PROJ WHERE PROJ_ID = @in_PROJ_ID AND COMPANY_ID=@in_COMPANY_ID) IN (SELECT PROJ_ABBRV_CD FROM dbo.XX_UTIL_EDU_CODES))
   SET @HOUR_TYPE_CD = @CONTINUING_EDUCATION
	-- Modified for CR-2627


/*
 * General & Administrative
 */
IF (@L1_PROJ_SEG_ID + '.' + @L2_PROJ_SEG_ID IN ('IINT.FGNA','IINT.XGNA', 'IINT.FBAE', 'IINT.PHOM', 'IINT.MBAE')
    AND (SELECT LEFT(ACCT_GRP_CD, 1) FROM IMAPS.Deltek.PROJ WHERE PROJ_ID = @in_PROJ_ID AND COMPANY_ID=@in_COMPANY_ID) != @UNALLOWABLE_IND
   )
   SET @HOUR_TYPE_CD = @GENERAL_AND_ADMIN
	-- Modified for CR-1543
    -- Modified for CR-1689 MBAE added in the list
    -- Modified for CR-3098 Added XGNA

RETURN @HOUR_TYPE_CD

END

