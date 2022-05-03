USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_R22_CLS_DOWN_LOAD_STAGE_SP]    Script Date: 1/19/2021 4:40:09 PM ******/
DROP PROCEDURE [dbo].[XX_R22_CLS_DOWN_LOAD_STAGE_SP]
GO

/****** Object:  StoredProcedure [dbo].[XX_R22_CLS_DOWN_LOAD_STAGE_SP]    Script Date: 1/19/2021 4:40:09 PM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO





CREATE PROCEDURE [dbo].[XX_R22_CLS_DOWN_LOAD_STAGE_SP]
(
@in_STATUS_RECORD_NUM   integer, 
@out_SystemError        integer      = NULL OUTPUT, 
@out_STATUS_DESCRIPTION varchar(275) = NULL OUTPUT
)
AS

/************************************************************************************************  
Name:       	XX_R22_CLS_DOWN_LOAD_STAGE_SP
Created by:     HVT
Created:    	09/22/2008
Purpose:    	Populate staging table XX_R22_CLS_DOWN with GL transactions, burden data from Costpoint.
                "Reversing of FDS" does not apply to Division 22.

                Perform two main tasks:
                1. Create YTD image of Costpoint to CLS.
                2. Create CLS 999 file for current month based on difference between this month
                   YTD image and last month YTD image.

                Adapted from XX_CLS_DOWN_LOAD_STAGE_SP.
                Called by XX_R22_CLS_DOWN_RUN_INTERFACE_SP.

Prerequisites: 	Costpoint month end processing

Notes:          The CLS Down interface needs to ensure that it only sends customer numbers (CMR)
                that are exactly 7 characters (with leading zeros if required). Otherwise, the
                transactions will miscode on the CLS side. Along with these multi-company changes,
                we have changed the interface so that it will always either send valid 7-character
                CMR numbers or the default CMR number (also 7 characters).


CR2000	 		use actuals for non-DIRECT burden - KM 03/16/09

CR7602			Add Revenue Level PAG to data grouping and account mappings - KM 2014-11-18
	When the interface pulls data from Costpoint, add the Revenue level project PAG to the data groupings.
	When the interface maps the data from Costpoint accounts to CLS accounts, add the Revenue level project PAG to the account mappings.
		
	use MARKETING_OFFICE column in the CLS data tables as store for Revenue level project PAG (but remove it from file table)
	use the S_PROJ_RPT_DC column in the CLS mapping table as a store for the Revenue level project PAG (mapping is override only, normal mapping must exist)	
		in mapping for GL pull, make sure S_PROJ_RPT_DC is only applied as override (not part of normal mapping)
		in mapping for Burden pull, S_PROJ_RPT_DC is not really PAG (so not part of normal mapping by definition)
************************************************************************************************/

BEGIN

DECLARE @FY_CD                       char(4),
        @PD_NO                       integer,
        @SP_NAME                     varchar(50),
        @CLS_R22_INTERFACE_NAME_CD   varchar(20),
        @DIV_22_COMPANY_ID           varchar(10),
        @REVENUE_ACCT_ID             varchar(10),

        @ZURICH_L2_ORG_SEG_ID        varchar(18),
        @ALMADEN_PSEUDO_DIV          varchar(15),
        @RESEARCH_PSEUDO_DIV         varchar(15),
        @WATSON_PSEUDO_DIV           varchar(15),
        @ZURICH_PSEUDO_DIV           varchar(15),
        @ALMADEN_SERVICE_OFFERING    varchar(5),
        @WATSON_SERVICE_OFFERING     varchar(5),

        @PL_GL_BALANCE_MAJOR         varchar(3),
        @PL_GL_BALANCE_MINOR         varchar(4),
        @PL_GL_BALANCE_SUBMINOR      varchar(4),
        @PL_GL_BALANCE_CONTRACT      varchar(5),
        @DFLT_CUSTOMER_NUM           varchar(10),
        @DFLT_MACHINE_TYPE           varchar(7),
        @DFLT_PRODUCT_ID             varchar(12),
        @DFLT_CONTRACT_NUM           varchar(12),
        @DFLT_IGS_PROJ_ID            varchar(12),
        @DFLT_LERU_NUM				 varchar(6),

        @PL_BURDEN_TOTAL             decimal(14, 2),
        @GL_BURDEN_RECOVERY_TOTAL    decimal(14, 2),
        @CLOSING_TOTAL               decimal(14, 2),
        @BALANCE_MAJOR               varchar(3),
        @BALANCE_MINOR               varchar(4),
        @BALANCE_SUBMINOR            varchar(4),
        @BALANCE_CONTRACT            varchar(12),
        @BALANCE_DIVISION            varchar(2),

        @IMAPS_error_number          integer,
        @SQLServer_error_code        integer,
        @row_count                   integer,
        @error_msg_placeholder1      sysname,
        @error_msg_placeholder2      sysname,
        @ret_code                    integer,
		@DIV_XX_ERR_CNT				 integer,
		@DIV_ZZ_ERR_CNT				 integer




--CR2000
/* these three statements are syntactically correct.  Therefore, whether or not data is available, these
statements can fail only if something is wrong with the database.  No recovery procedure is required here 
*/

--SET LOCAL CONSTANTS
SET @SP_NAME = 'XX_R22_CLS_DOWN_LOAD_STAGE_SP'
SET @DIV_XX_ERR_CNT = 0
SET @DIV_ZZ_ERR_CNT = 0

PRINT '***********************************************************************************************************************'
PRINT '     START OF ' + @SP_NAME
PRINT '***********************************************************************************************************************'



update xx_r22_cls_down_acct_mapping
set pool_no=null
where len(ltrim(rtrim(pool_no)))=0

update xx_r22_cls_down_acct_mapping
set proj_id=null
where len(ltrim(rtrim(proj_id)))=0

update xx_r22_cls_down_acct_mapping
set S_PROJ_RPT_DC=null
where len(ltrim(rtrim(S_PROJ_RPT_DC)))=0



-- Set local constants
SET @SP_NAME = 'XX_R22_CLS_DOWN_LOAD_STAGE_SP'
SET @CLS_R22_INTERFACE_NAME_CD = 'CLS_R22'
SET @ZURICH_L2_ORG_SEG_ID = 'Z'

SET @ALMADEN_PSEUDO_DIV = 'SR'
SET @RESEARCH_PSEUDO_DIV = '22'
SET @WATSON_PSEUDO_DIV = 'YA'
SET @ZURICH_PSEUDO_DIV = 'YB'

SET @ALMADEN_SERVICE_OFFERING = 'ZW'
SET @WATSON_SERVICE_OFFERING = 'ZV'

/* the following four statements are syntactically correct.  If data is not available, then the table
being queried does not have the required and expected values.  The table would need to be updated to
reinclude these values, and the reason for their disappearance would need to be determined  
*/


-- expected value for: select parameter_value from imapsstg.dbo.xx_processing_parameters where parameter_name = 'COMPANY_ID' AND INTERFACE_NAME_CD = 'CLS_R22' = 2
SELECT @DIV_22_COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = @CLS_R22_INTERFACE_NAME_CD

   
-- expected value for: select parameter_value from imapsstg.dbo.xx_processing_parameters where parameter_name = 'REVENUE _ACCT_ID' AND INTERFACE_NAME_CD = 'CLS_R22' = 30-01-01
SELECT @REVENUE_ACCT_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = @CLS_R22_INTERFACE_NAME_CD
   AND PARAMETER_NAME = 'REVENUE_ACCT_ID'

-- expected value for: select parameter_value from imapsstg.dbo.xx_processing_parameters where parameter_name = 'DEFAULT_MACHINE_TYPE' AND INTERFACE_NAME_CD = 'CLS_R22' = GA70
SELECT @DFLT_MACHINE_TYPE = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS 
 WHERE INTERFACE_NAME_CD = @CLS_R22_INTERFACE_NAME_CD
   AND PARAMETER_NAME = 'DFLT_MACHINE_TYPE'

-- expected value for: select parameter_value from imapsstg.dbo.xx_processing_parameters where parameter_name = 'DFLT_PRODUCT_ID' AND INTERFACE_NAME_CD = 'CLS_R22' = 5696398
SELECT @DFLT_PRODUCT_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS 
 WHERE INTERFACE_NAME_CD = @CLS_R22_INTERFACE_NAME_CD
   AND PARAMETER_NAME = 'DFLT_PRODUCT_ID'

 -- presumably, this picks up the last period for which it was successfully run from the calling script
SELECT @FY_CD = FY_SENT,
       @PD_NO = MONTH_SENT
  FROM dbo.XX_R22_CLS_DOWN_LOG
 WHERE STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM

/* DATA INSERTS 
if anything fails at this point forward, the cure is to simply run it again... no prep work is required other than to determine nature of failure
*/


PRINT '1. Truncate tables'

TRUNCATE TABLE dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD
TRUNCATE TABLE dbo.XX_R22_CLS_DOWN

PRINT '2a. GL Detail INSERT - non-Direct'

SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'insert details into XX_R22_CLS_DOWN_THIS_MONTH_YTD'
SET @error_msg_placeholder2 = 'from GL_POST_SUM'

--CR7602 change
INSERT INTO dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD
   (IMAPS_ACCT, IMAPS_PROJ_ID, IMAPS_ORG_ID, DOLLAR_AMT, MARKETING_OFFICE)
   SELECT 
			GL.ACCT_ID as IMAPS_ACCT,
			GL.PROJ_ID as IMAPS_PROJ_ID, 
			GL.ORG_ID as IMAPS_ORG_ID,
			SUM(GL.AMT) as DOLLAR_AMT,
			
			isnull(REV_PROJ.ACCT_GRP_CD,'-') as MARKETING_OFFICE

     FROM 
     IMAR.DELTEK.GL_POST_SUM GL
     LEFT JOIN
     IMAR.DELTEK.PROJ_REV_SETUP PRS
     ON
     (PRS.PROJ_ID=left(GL.PROJ_ID,LEN(PRS.PROJ_ID)))
     LEFT JOIN
     IMAR.DELTEK.PROJ REV_PROJ
     ON
     (PRS.PROJ_ID=REV_PROJ.PROJ_ID)
    WHERE
		  GL.FY_CD = @FY_CD
      AND GL.PD_NO <= @PD_NO
      AND GL.PD_NO >= 1
      AND GL.COMPANY_ID = @DIV_22_COMPANY_ID 
	  --exclude Zurich
      AND SUBSTRING(GL.ORG_ID, 4, 1) != @ZURICH_L2_ORG_SEG_ID
	  --exclude Shop Order revenue and cost
	  AND NOT (GL.PROJ_ID IS NOT NULL AND(LEFT(GL.PROJ_ID,4) = 'CDOU' AND GL.ACCT_ID> '30-00-00'))
     /* --no longer get revenue from elsewhere
	  AND ACCT_ID != @REVENUE_ACCT_ID
	*/
	  --only include accounts in the mapping table
      AND (0 < (SELECT COUNT(1)
                  FROM dbo.XX_R22_CLS_DOWN_ACCT_MAPPING
                 WHERE (IMAPS_ACCT_START <= GL.ACCT_ID AND IMAPS_ACCT_END >= GL.ACCT_ID  AND LEN(IMAPS_ACCT_START)=8)
						AND len(isnull(S_PROJ_RPT_DC,''))=0   --CR7602, normal mapping must exist
               )
          )  
	  --and not DIRECT PROJECT
	 and
	(SELECT S_PROJ_RPT_DC FROM IMAR.DELTEK.PROJ WHERE PROJ_ID = gl.PROJ_ID) != 'DIRECT PROJECT' 
    GROUP BY GL.ACCT_ID, 
			GL.PROJ_ID, 
			GL.ORG_ID,
			REV_PROJ.ACCT_GRP_CD
   HAVING SUM(AMT) <> .00
--CR7602 change

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO ERROR_HANDLER




PRINT '2b. GL Detail INSERT - Direct'

SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'insert details into XX_R22_CLS_DOWN_THIS_MONTH_YTD'
SET @error_msg_placeholder2 = 'from GL_POST_SUM'


--CR7602 change
INSERT INTO dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD
   (IMAPS_ACCT, IMAPS_PROJ_ID, IMAPS_ORG_ID, DOLLAR_AMT, MARKETING_OFFICE)
   SELECT 
			GL.ACCT_ID as IMAPS_ACCT,
			'' as IMAPS_PROJ_ID, 
			LEFT(GL.ORG_ID, 4) as IMAPS_ORG_ID,
			SUM(GL.AMT) as DOLLAR_AMT,
			
			isnull(REV_PROJ.ACCT_GRP_CD,'-')  as MARKETING_OFFICE

     FROM 
     IMAR.DELTEK.GL_POST_SUM GL
     LEFT JOIN
     IMAR.DELTEK.PROJ_REV_SETUP PRS
     ON
     (PRS.PROJ_ID=left(GL.PROJ_ID,LEN(PRS.PROJ_ID)))
     LEFT JOIN
     IMAR.DELTEK.PROJ REV_PROJ
     ON
     (PRS.PROJ_ID=REV_PROJ.PROJ_ID)
    WHERE
		  GL.FY_CD = @FY_CD
      AND GL.PD_NO <= @PD_NO
      AND GL.PD_NO >= 1
      AND GL.COMPANY_ID = @DIV_22_COMPANY_ID 
	  --exclude Zurich
      AND SUBSTRING(GL.ORG_ID, 4, 1) != @ZURICH_L2_ORG_SEG_ID
	  --exclude Shop Order revenue and cost
	  AND NOT (GL.PROJ_ID IS NOT NULL AND(LEFT(GL.PROJ_ID,4) = 'CDOU' AND GL.ACCT_ID> '30-00-00'))
     /* --no longer get revenue from elsewhere
	  AND ACCT_ID != @REVENUE_ACCT_ID
	*/
	  --only include accounts in the mapping table
      AND (0 < (SELECT COUNT(1)
                  FROM dbo.XX_R22_CLS_DOWN_ACCT_MAPPING
                 WHERE (IMAPS_ACCT_START <= GL.ACCT_ID AND IMAPS_ACCT_END >= GL.ACCT_ID  AND LEN(IMAPS_ACCT_START)=8)
						AND len(isnull(S_PROJ_RPT_DC,''))=0   --CR7602, normal mapping must exist
               )
          )  
	  --and DIRECT PROJECT
	and (
			(SELECT S_PROJ_RPT_DC FROM IMAR.DELTEK.PROJ WHERE PROJ_ID = gl.PROJ_ID) = 'DIRECT PROJECT' 
			OR
			(SELECT S_PROJ_RPT_DC FROM IMAR.DELTEK.PROJ WHERE PROJ_ID = gl.PROJ_ID)  IS NULL
		)
    GROUP BY GL.ACCT_ID, 
			LEFT(GL.ORG_ID , 4),	
			REV_PROJ.ACCT_GRP_CD 
   HAVING SUM(AMT) <> .00
--CR7602 change

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO ERROR_HANDLER





/*
PRINT '3. Revenue INSERT'

SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'insert revenue into XX_R22_CLS_DOWN_THIS_MONTH_YTD'
SET @error_msg_placeholder2 = 'from PROJ_SUM'

INSERT INTO dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD
   (IMAPS_ACCT, IMAPS_PROJ_ID, IMAPS_ORG_ID, DOLLAR_AMT, DESCRIPTION2)
   SELECT @REVENUE_ACCT_ID as IMAPS_ACCT, PROJ_ID as IMAPS_PROJ_ID, ORG_ID as IMAPS_ORG_ID, SUM(-1.0 * TOT_REV_TGT_AMT) as DOLLAR_AMT, 'REVENUE'
     FROM IMAR.DELTEK.PROJ_SUM pl
    WHERE 
		  FY_CD = @FY_CD
      AND PD_NO <= @PD_NO
      AND PD_NO >= 1
      AND COMPANY_ID = @DIV_22_COMPANY_ID
		--exclude Zurich 
      AND SUBSTRING(ORG_ID, 4, 1) != @ZURICH_L2_ORG_SEG_ID
		--only get revenue for DIRECT PROJECTs
	  AND (0 < (    
				SELECT COUNT(1)
                  FROM IMAR.DELTEK.PROJ
                 WHERE PROJ_ID=pl.PROJ_ID 
				   AND S_PROJ_RPT_DC='DIRECT PROJECT'
			 )
          )
    GROUP BY PROJ_ID, ORG_ID
   HAVING SUM(-1.0 * TOT_REV_TGT_AMT) <> .00

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO ERROR_HANDLER

*/





PRINT '4a. Burden INSERT - non-Direct'

SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'insert burden into XX_R22_CLS_DOWN_THIS_MONTH_YTD'
SET @error_msg_placeholder2 = 'from PROJ_BURD_SUM'

--CR7602 change
INSERT INTO dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD
   (IMAPS_PROJ_ID, IMAPS_ORG_ID, GA_AMT, OVERHEAD_AMT, DESCRIPTION2, SERVICE_OFFERING, MARKETING_OFFICE)
   SELECT pds.PROJ_ID,
          pds.ORG_ID as IMAPS_ORG_ID,
          SUM(CASE 
                 WHEN pds.POOL_NO = 175 THEN pds.SUB_ACT_AMT --CR2000
                 ELSE 0
              END) AS GA_AMT,
          SUM(CASE 
                 WHEN pds.POOL_NO != 175 THEN pds.SUB_ACT_AMT --CR2000
                 ELSE 0
              END) AS OVERHEAD_AMT,
          'BURDEN - ' + CAST(pds.POOL_NO as varchar), 
		  pds.POOL_NO  --put POOL_NO in SERVICE_OFFERING FOR MAPPING USE
		  ,
		  
		isnull(REV_PROJ.ACCT_GRP_CD,'-')  as MARKETING_OFFICE
		  
     FROM 
     IMAR.DELTEK.PROJ_BURD_SUM pds     
     LEFT JOIN
     IMAR.DELTEK.PROJ_REV_SETUP PRS
     ON
     (PRS.PROJ_ID=left(pds.PROJ_ID,LEN(PRS.PROJ_ID)))
     LEFT JOIN
     IMAR.DELTEK.PROJ REV_PROJ
     ON
     (PRS.PROJ_ID=REV_PROJ.PROJ_ID)
    WHERE pds.FY_CD = @FY_CD
      AND pds.PD_NO <= @PD_NO
      AND pds.PD_NO >= 1
      AND pds.COMPANY_ID = @DIV_22_COMPANY_ID
		--exclude Zurich 
      AND SUBSTRING(pds.ORG_ID, 4, 1) != @ZURICH_L2_ORG_SEG_ID
		--exclude DOU projects
	  AND LEFT(pds.PROJ_ID,4) <> 'CDOU'

		/*--only get burden for DIRECT PROJECT and IR&D
	  AND (0 < (    
				SELECT COUNT(1)
                  FROM IMAR.DELTEK.PROJ
                 WHERE PROJ_ID=pds.PROJ_ID 
				   AND S_PROJ_RPT_DC in ('DIRECT PROJECT', 'IR&D')
			 )
          )*/

	--only get burden from mapping table
	   AND (0 < (    
				SELECT COUNT(1)
				FROM XX_R22_CLS_DOWN_ACCT_MAPPING map
				WHERE APPLY_BURDEN='Y'
				AND pds.POOL_NO=ISNULL(map.POOL_NO, pds.POOL_NO)
				AND (SELECT S_PROJ_RPT_DC FROM IMAR.DELTEK.PROJ WHERE PROJ_ID = pds.PROJ_ID) = map.S_PROJ_RPT_DC  
				AND pds.PROJ_ID like ISNULL(map.PROJ_ID, pds.PROJ_ID)+'%'
			 )
          )

	  --and not DIRECT PROJECT
	 and
	(SELECT S_PROJ_RPT_DC FROM IMAR.DELTEK.PROJ WHERE PROJ_ID = pds.PROJ_ID) != 'DIRECT PROJECT' 
    GROUP BY pds.PROJ_ID, pds.ORG_ID, pds.POOL_NO, REV_PROJ.ACCT_GRP_CD
--CR7602 change

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO ERROR_HANDLER




PRINT '4a. Burden INSERT - Direct'

SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'insert burden into XX_R22_CLS_DOWN_THIS_MONTH_YTD'
SET @error_msg_placeholder2 = 'from PROJ_BURD_SUM'

--CR7602 change
INSERT INTO dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD
   (IMAPS_PROJ_ID, IMAPS_ORG_ID, GA_AMT, OVERHEAD_AMT, DESCRIPTION2, SERVICE_OFFERING, MARKETING_OFFICE)
   SELECT '' as IMAPS_PROJ_ID,
          LEFT(pds.ORG_ID, 4) as IMAPS_ORG_ID,
          SUM(CASE 
                 WHEN pds.POOL_NO = 175 THEN pds.SUB_TGT_AMT
                 ELSE 0
              END) AS GA_AMT,
          SUM(CASE 
                 WHEN pds.POOL_NO != 175 THEN pds.SUB_TGT_AMT
                 ELSE 0
              END) AS OVERHEAD_AMT,
          'BURDEN - ' + CAST(pds.POOL_NO as varchar), 
		  pds.POOL_NO  --put POOL_NO in SERVICE_OFFERING FOR MAPPING USE
		  		
		  ,
		  isnull(REV_PROJ.ACCT_GRP_CD,'-')  as MARKETING_OFFICE
		  
     FROM 
     IMAR.DELTEK.PROJ_BURD_SUM pds     
     LEFT JOIN
     IMAR.DELTEK.PROJ_REV_SETUP PRS
     ON
     (PRS.PROJ_ID=left(pds.PROJ_ID,LEN(PRS.PROJ_ID)))
     LEFT JOIN
     IMAR.DELTEK.PROJ REV_PROJ
     ON
     (PRS.PROJ_ID=REV_PROJ.PROJ_ID)
    WHERE pds.FY_CD = @FY_CD
      AND pds.PD_NO <= @PD_NO
      AND pds.PD_NO >= 1
      AND pds.COMPANY_ID = @DIV_22_COMPANY_ID
		--exclude Zurich 
      AND SUBSTRING(pds.ORG_ID, 4, 1) != @ZURICH_L2_ORG_SEG_ID
		--exclude DOU projects
	  AND LEFT(pds.PROJ_ID,4) <> 'CDOU'

	    --only get burden for S_PROJ_RPT_DC in mapping table
	  AND (0 < (    
				SELECT COUNT(1)
                  FROM IMAR.DELTEK.PROJ
                 WHERE PROJ_ID=pds.PROJ_ID 
				   AND S_PROJ_RPT_DC in 
					(SELECT S_PROJ_RPT_DC
					FROM XX_R22_CLS_DOWN_ACCT_MAPPING
					WHERE APPLY_BURDEN='Y')
			 )
          )

	--only get burden from mapping table
	   AND (0 < (    
				SELECT COUNT(1)
				FROM XX_R22_CLS_DOWN_ACCT_MAPPING map
				WHERE APPLY_BURDEN='Y'
				AND pds.POOL_NO=ISNULL(map.POOL_NO, pds.POOL_NO)
				AND (SELECT S_PROJ_RPT_DC FROM IMAR.DELTEK.PROJ WHERE PROJ_ID = pds.PROJ_ID) = map.S_PROJ_RPT_DC  
				AND pds.PROJ_ID like ISNULL(map.PROJ_ID, pds.PROJ_ID)+'%'
			 )
          )

	  --and DIRECT PROJECT
	 and
	(SELECT S_PROJ_RPT_DC FROM IMAR.DELTEK.PROJ WHERE PROJ_ID = pds.PROJ_ID) = 'DIRECT PROJECT' 
    GROUP BY LEFT(pds.ORG_ID, 4), pds.POOL_NO, REV_PROJ.ACCT_GRP_CD
--CR7602 change

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO ERROR_HANDLER







	
PRINT '6. Delete XX_R22_CLS_DOWN_THIS_MONTH_YTD records with zero-dollar burden'	

SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'delete zero-dollar burden'
SET @error_msg_placeholder2 = 'from XX_R22_CLS_DOWN_THIS_MONTH_YTD'

DELETE dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD
 WHERE IMAPS_ACCT IS NULL
   AND GA_AMT = .00
   AND OVERHEAD_AMT = .00

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO ERROR_HANDLER




/* PROJECT DATA MAPPINGS */

PRINT '8. Project-related data mappings'

SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'perform'
SET @error_msg_placeholder2 = 'project-related data mappings'


SELECT @DFLT_CONTRACT_NUM = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS 
 WHERE INTERFACE_NAME_CD = @CLS_R22_INTERFACE_NAME_CD
   AND PARAMETER_NAME = 'DFLT_CONTRACT_NUM'

SELECT @DFLT_IGS_PROJ_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS 
 WHERE INTERFACE_NAME_CD = @CLS_R22_INTERFACE_NAME_CD
   AND PARAMETER_NAME = 'DFLT_IGS_PROJ_ID'

SELECT @DFLT_CUSTOMER_NUM = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS 
 WHERE INTERFACE_NAME_CD = @CLS_R22_INTERFACE_NAME_CD
   AND PARAMETER_NAME = 'DFLT_CUSTOMER_NUM'

	
UPDATE dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD
   SET L1_PROJ_SEG_ID = LEFT(IMAPS_PROJ_ID, 4),
       CONTRACT_NUM   = @DFLT_CONTRACT_NUM,
       IGS_PROJ       = @DFLT_IGS_PROJ_ID,
       CUSTOMER_NUM   = @DFLT_CUSTOMER_NUM	
	
SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO ERROR_HANDLER


UPDATE dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD
   SET IGS_PROJ       = (SELECT PROJ_ABBRV_CD FROM IMAR.DELTEK.PROJ 
						WHERE 
						    COMPANY_ID = @DIV_22_COMPANY_ID 
						AND PROJ_ABBRV_CD<>''
						AND PROJ_ID = cls.IMAPS_PROJ_ID)
FROM XX_R22_CLS_DOWN_THIS_MONTH_YTD cls
WHERE LEN(ISNULL(IMAPS_PROJ_ID, ''))>0

UPDATE XX_R22_CLS_DOwN_THIS_MONTH_YTD
SET IGS_PROJ       = @DFLT_IGS_PROJ_ID
WHERE IGS_PROJ IS NULL


SELECT @row_count = COUNT(*) FROM IMAPSSTG.DBO.XX_R22_CLS_DOWN_THIS_MONTH_YTD WHERE DESCRIPTION2 IS NULL
PRINT 'INFORMATIVE - NULL DESCRIPTION2 COUNT = ' + CAST(@row_count as varchar(10))
/* ACCOUNT MAPPINGS 
*/

PRINT '9. Update major/minor mapping for Expense Recovery projects'

PRINT '9A. MAJOR'

UPDATE  IMAPSSTG.DBO.XX_R22_CLS_DOWN_THIS_MONTH_YTD 
SET IMAPSSTG.DBO.XX_R22_CLS_DOWN_THIS_MONTH_YTD.CLS_MAJOR = (
SELECT COALESCE(IMAPSSTG.DBO.XX_R22_CLS_DOWN_EXP_RCVRY_MAPPING.CLS_MAJOR,IMAPSSTG.DBO.XX_R22_CLS_DOWN_THIS_MONTH_YTD.CLS_MAJOR)
FROM IMAPSSTG.DBO.XX_R22_CLS_DOWN_EXP_RCVRY_MAPPING
WHERE IMAPSSTG.DBO.XX_R22_CLS_DOWN_THIS_MONTH_YTD.IMAPS_ACCT >= IMAPSSTG.DBO.XX_R22_CLS_DOWN_EXP_RCVRY_MAPPING.IMAPS_ACCT_START
AND IMAPSSTG.DBO.XX_R22_CLS_DOWN_THIS_MONTH_YTD.IMAPS_ACCT <= IMAPSSTG.DBO.XX_R22_CLS_DOWN_EXP_RCVRY_MAPPING.IMAPS_ACCT_END )
WHERE IMAPSSTG.DBO.XX_R22_CLS_DOWN_THIS_MONTH_YTD.IMAPS_PROJ_ID IN (SELECT GENL_ID FROM  IMAR.DELTEK.GENL_UDEF WHERE UDEF_LBL_KEY = '83')
AND  IMAPSSTG.DBO.XX_R22_CLS_DOWN_THIS_MONTH_YTD.IMAPS_ACCT IS NOT NULL

PRINT '9B. MINOR'

UPDATE  IMAPSSTG.DBO.XX_R22_CLS_DOWN_THIS_MONTH_YTD 
SET IMAPSSTG.DBO.XX_R22_CLS_DOWN_THIS_MONTH_YTD.CLS_MINOR = (
SELECT COALESCE(IMAPSSTG.DBO.XX_R22_CLS_DOWN_EXP_RCVRY_MAPPING.CLS_MINOR,IMAPSSTG.DBO.XX_R22_CLS_DOWN_THIS_MONTH_YTD.CLS_MINOR)
FROM IMAPSSTG.DBO.XX_R22_CLS_DOWN_EXP_RCVRY_MAPPING
WHERE IMAPSSTG.DBO.XX_R22_CLS_DOWN_THIS_MONTH_YTD.IMAPS_ACCT >= IMAPSSTG.DBO.XX_R22_CLS_DOWN_EXP_RCVRY_MAPPING.IMAPS_ACCT_START
AND IMAPSSTG.DBO.XX_R22_CLS_DOWN_THIS_MONTH_YTD.IMAPS_ACCT <= IMAPSSTG.DBO.XX_R22_CLS_DOWN_EXP_RCVRY_MAPPING.IMAPS_ACCT_END )
WHERE IMAPSSTG.DBO.XX_R22_CLS_DOWN_THIS_MONTH_YTD.IMAPS_PROJ_ID IN (SELECT GENL_ID FROM  IMAR.DELTEK.GENL_UDEF WHERE UDEF_LBL_KEY = '83')
AND  IMAPSSTG.DBO.XX_R22_CLS_DOWN_THIS_MONTH_YTD.IMAPS_ACCT IS NOT NULL

PRINT '9C. SUB_MINOR'

UPDATE  IMAPSSTG.DBO.XX_R22_CLS_DOWN_THIS_MONTH_YTD 
SET IMAPSSTG.DBO.XX_R22_CLS_DOWN_THIS_MONTH_YTD.CLS_SUB_MINOR = (
SELECT COALESCE(IMAPSSTG.DBO.XX_R22_CLS_DOWN_EXP_RCVRY_MAPPING.CLS_SUB_MINOR,IMAPSSTG.DBO.XX_R22_CLS_DOWN_THIS_MONTH_YTD.CLS_SUB_MINOR)
FROM IMAPSSTG.DBO.XX_R22_CLS_DOWN_EXP_RCVRY_MAPPING
WHERE IMAPSSTG.DBO.XX_R22_CLS_DOWN_THIS_MONTH_YTD.IMAPS_ACCT >= IMAPSSTG.DBO.XX_R22_CLS_DOWN_EXP_RCVRY_MAPPING.IMAPS_ACCT_START
AND IMAPSSTG.DBO.XX_R22_CLS_DOWN_THIS_MONTH_YTD.IMAPS_ACCT <= IMAPSSTG.DBO.XX_R22_CLS_DOWN_EXP_RCVRY_MAPPING.IMAPS_ACCT_END )
WHERE IMAPSSTG.DBO.XX_R22_CLS_DOWN_THIS_MONTH_YTD.IMAPS_PROJ_ID IN (SELECT GENL_ID FROM  IMAR.DELTEK.GENL_UDEF WHERE UDEF_LBL_KEY = '83')
AND  IMAPSSTG.DBO.XX_R22_CLS_DOWN_THIS_MONTH_YTD.IMAPS_ACCT IS NOT NULL

PRINT '9D1. BURDEN MAPPING PREPARATION'

--excluding G&A from BURDEN
UPDATE dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD
   SET DOLLAR_AMT = /*GA_AMT + */OVERHEAD_AMT
 WHERE DESCRIPTION2 LIKE 'BURDEN%'
  AND IMAPSSTG.DBO.XX_R22_CLS_DOWN_THIS_MONTH_YTD.IMAPS_PROJ_ID IN (SELECT GENL_ID FROM  IMAR.DELTEK.GENL_UDEF WHERE UDEF_LBL_KEY = '83')

  PRINT '9D2. BURDEN MAPPING '

UPDATE dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD
   SET CLS_MAJOR     = map.CLS_MAJOR,
       CLS_MINOR     = map.CLS_MINOR,
       CLS_SUB_MINOR = map.CLS_SUB_MINOR
  FROM dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD cls,
       dbo.XX_R22_CLS_DOWN_EXP_RCVRY_MAPPING map
 WHERE cls.DESCRIPTION2 LIKE 'BURDEN%'
		AND	map.APPLY_BURDEN='Y'
		AND ISNULL((SELECT S_PROJ_RPT_DC FROM IMAR.DELTEK.PROJ WHERE PROJ_ID = cls.IMAPS_PROJ_ID), 'DIRECT PROJECT') = map.S_PROJ_RPT_DC  
        AND cls.IMAPS_PROJ_ID IN (SELECT GENL_ID FROM  IMAR.DELTEK.GENL_UDEF WHERE UDEF_LBL_KEY = '83')


PRINT '10. Burden account mapping for remaining projects'

SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'perform CLS account mapping'
SET @error_msg_placeholder2 = 'for burden transactions'

--excluding G&A from BURDEN
UPDATE dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD
   SET DOLLAR_AMT = /*GA_AMT + */OVERHEAD_AMT
 WHERE DESCRIPTION2 LIKE 'BURDEN%'
  AND IMAPS_PROJ_ID NOT IN (SELECT GENL_ID FROM  IMAR.DELTEK.GENL_UDEF WHERE UDEF_LBL_KEY = '83')

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO ERROR_HANDLER

--put POOL_NO in SERVICE_OFFERING FOR MAPPING USE
UPDATE dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD
   SET CLS_MAJOR     = map.CLS_MAJOR,
       CLS_MINOR     = map.CLS_MINOR,
       CLS_SUB_MINOR = map.CLS_SUB_MINOR
  FROM dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD cls,
       dbo.XX_R22_CLS_DOWN_ACCT_MAPPING map
 WHERE cls.DESCRIPTION2 LIKE 'BURDEN%'
		AND	map.APPLY_BURDEN='Y'
		AND cls.SERVICE_OFFERING=ISNULL(map.POOL_NO, cls.SERVICE_OFFERING)
		AND ISNULL((SELECT S_PROJ_RPT_DC FROM IMAR.DELTEK.PROJ WHERE PROJ_ID = cls.IMAPS_PROJ_ID), 'DIRECT PROJECT') = map.S_PROJ_RPT_DC  
		AND cls.IMAPS_PROJ_ID like ISNULL(map.PROJ_ID, cls.IMAPS_PROJ_ID)+'%'
		AND cls.CLS_MAJOR IS NULL

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO ERROR_HANDLER


--CR7602 begin
UPDATE dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD
   SET CLS_MAJOR     = map.CLS_MAJOR,
       CLS_MINOR     = map.CLS_MINOR,
       CLS_SUB_MINOR = map.CLS_SUB_MINOR
  FROM dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD cls,
       dbo.XX_R22_CLS_DOWN_ACCT_MAPPING map
 WHERE cls.DESCRIPTION2 LIKE 'BURDEN%'
		AND	map.APPLY_BURDEN='Y'
		AND cls.SERVICE_OFFERING=ISNULL(map.POOL_NO, cls.SERVICE_OFFERING)
		AND cls.MARKETING_OFFICE=map.S_PROJ_RPT_DC  --these are the Project Revenue Level PAG columns used for this override logic, not the original S_PROJ_RPT_DC
		AND cls.IMAPS_PROJ_ID like ISNULL(map.PROJ_ID, cls.IMAPS_PROJ_ID)+'%'
		AND cls.CLS_MAJOR IS NULL

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO ERROR_HANDLER
--CR7602 end


	
PRINT '11. GL and Revenue account mapping'

SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'perform CLS account mapping'
SET @error_msg_placeholder2 = 'for GL and revenue transactions'

UPDATE dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD
   SET CLS_MAJOR     = map.CLS_MAJOR,
       CLS_MINOR     = map.CLS_MINOR,
       CLS_SUB_MINOR = map.CLS_SUB_MINOR,
       DOLLAR_AMT    = (cls.DOLLAR_AMT * ISNULL(map.MULTIPLIER, 1))
  FROM dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD cls,
       dbo.XX_R22_CLS_DOWN_ACCT_MAPPING map
 WHERE cls.IMAPS_ACCT IS NOT NULL
   AND map.IMAPS_ACCT_START <= cls.IMAPS_ACCT
   AND map.IMAPS_ACCT_END   >= cls.IMAPS_ACCT
   AND len(isnull(map.S_PROJ_RPT_DC,''))=0   --CR7602, first apply normal mappings only
   AND cls.CLS_MAJOR IS NULL

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO ERROR_HANDLER


--CR7602 begin
UPDATE dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD
   SET CLS_MAJOR     = map.CLS_MAJOR,
       CLS_MINOR     = map.CLS_MINOR,
       CLS_SUB_MINOR = map.CLS_SUB_MINOR,
       DOLLAR_AMT    = (cls.DOLLAR_AMT * ISNULL(map.MULTIPLIER, 1))
  FROM dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD cls,
       dbo.XX_R22_CLS_DOWN_ACCT_MAPPING map
 WHERE cls.IMAPS_ACCT IS NOT NULL
   AND map.IMAPS_ACCT_START <= cls.IMAPS_ACCT
   AND map.IMAPS_ACCT_END   >= cls.IMAPS_ACCT
   AND len(isnull(map.S_PROJ_RPT_DC,''))<>0    --CR7602, now apply new Project Revenue Level PAG type mapping, where defined
   AND map.S_PROJ_RPT_DC=cls.MARKETING_OFFICE  --these are the Project Revenue Level PAG columns used for this override logic
   AND cls.CLS_MAJOR IS NULL

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO ERROR_HANDLER
--CR7602 end





PRINT '12. Memo Entry INSERT'

SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'insert memo entries'
SET @error_msg_placeholder2 = 'into XX_R22_CLS_DOWN_THIS_MONTH_YTD'
	
INSERT INTO dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD
   (CLS_MAJOR, CLS_MINOR, CLS_SUB_MINOR,
    IMAPS_ACCT, IMAPS_PROJ_ID, L1_PROJ_SEG_ID, IMAPS_ORG_ID,
    DOLLAR_AMT,
    CONTRACT_NUM, IGS_PROJ, CUSTOMER_NUM
   )
   SELECT map.CLS_MAJOR, map.CLS_MINOR, map.CLS_SUB_MINOR,
          cls.IMAPS_ACCT, cls.IMAPS_PROJ_ID, cls.L1_PROJ_SEG_ID, cls.IMAPS_ORG_ID,
          cls.DOLLAR_AMT * ISNULL(map.MULTIPLIER, 1),
          cls.CONTRACT_NUM, cls.IGS_PROJ, cls.CUSTOMER_NUM
     FROM dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD cls,
          dbo.XX_R22_CLS_DOWN_ACCT_MEMO_MAPPING map
    WHERE cls.IMAPS_ACCT IS NOT NULL
      AND cls.IMAPS_ACCT = map.IMAPS_ACCT


SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO ERROR_HANDLER

	



/*UPDATE DIVISION AND LERU INFORMATION BASED ON ORG*/

PRINT '13. Update DIVISION and LERU_NUM based on IMAPS_ORG'

SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'Update DIVISION and LERU_NUM'
SET @error_msg_placeholder2 = 'based on IMAPS_ORG'

UPDATE XX_R22_CLS_DOWN_THIS_MONTH_YTD 
SET		DIVISION = 
					COALESCE(CASE SUBSTRING(this.IMAPS_ORG_ID, 1, 2)
						 WHEN '22' THEN (select COALESCE(parameter_value,'XX') from imapsstg.dbo.xx_processing_parameters where interface_name_cd = 'CLS_R22' AND PARAMETER_NAME = 'ORG_ID_' + SUBSTRING(this.IMAPS_ORG_ID, 4, 1))
						 WHEN '24' THEN '24'
						 ELSE 'ZZ'
					  END,'XX'),
		LERU_NUM =  substring(this.IMAPS_ORG_ID, 12,3)+substring(this.IMAPS_ORG_ID, 12,3)
FROM XX_R22_CLS_DOWN_THIS_MONTH_YTD this

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO ERROR_HANDLER

-- NOW LOOK FOR ERRORS

SELECT @DIV_XX_ERR_CNT = COUNT(*) FROM IMAPSSTG.DBO.XX_R22_CLS_DOWN_THIS_MONTH_YTD WHERE DIVISION = 'XX'  -- 4TH CHAR OF ORG_ID DOESN'T MATCH
SELECT @DIV_ZZ_ERR_CNT = COUNT(*) FROM IMAPSSTG.DBO.XX_R22_CLS_DOWN_THIS_MONTH_YTD WHERE DIVISION = 'ZZ'  -- CHAR 1-2 OR ORG_ID DOESN'T MATCH

IF @DIV_XX_ERR_CNT > 0 GOTO ERROR_HANDLER
IF @DIV_ZZ_ERR_CNT > 0 GOTO ERROR_HANDLER

/*CHANGE 2/09 DEFAULT LERU */
SELECT @DFLT_LERU_NUM = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS 
 WHERE INTERFACE_NAME_CD = @CLS_R22_INTERFACE_NAME_CD
   AND PARAMETER_NAME = 'LERU_NUM'

UPDATE	XX_R22_CLS_DOWN_THIS_MONTH_YTD
SET		LERU_NUM = @DFLT_LERU_NUM
WHERE	LEN(LTRIM(RTRIM(ISNULL(LERU_NUM, ''))))=0


/*CHANGE 12/01/08 SPECIAL DIVISION FOR AR */
UPDATE	XX_R22_CLS_DOWN_THIS_MONTH_YTD
SET		DIVISION='10'
WHERE	IMAPS_ACCT='10-00-01'





/* Should probably leave this out at first


   Hopefully this problem won't exist for Division 22


PRINT '13. Manufactured PL and GL burden variance transaction'

SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'insert PL & GL burden variance transaction'
SET @error_msg_placeholder2 = 'into XX_R22_CLS_DOWN_THIS_MONTH_YTD'

-- Calculate difference between PL and GL burden and store it as a separate row
SELECT @PL_BURDEN_TOTAL = SUM(SUB_ACT_AMT)
  FROM IMAR.DELTEK.PROJ_BURD_SUM
 WHERE FY_CD =  @FY_CD
   AND PD_NO <= @PD_NO
   AND PD_NO >= 1
   AND SUBSTRING(ORG_ID, 4, 1) != @ZURICH_L2_ORG_SEG_ID
   AND COMPANY_ID = @DIV_22_COMPANY_ID

SELECT @GL_BURDEN_RECOVERY_TOTAL = SUM(AMT)
  FROM IMAR.DELTEK.GL_POST_SUM
 WHERE FY_CD =  @FY_CD 
   AND PD_NO <= @PD_NO
   AND PD_NO >= 1
   AND ACCT_ID LIKE 'PA%CR'
   AND ACCT_ID <> 'PA-70-CR'
   AND SUBSTRING(ORG_ID, 4, 1) != @ZURICH_L2_ORG_SEG_ID
   AND COMPANY_ID = @DIV_22_COMPANY_ID

IF @PL_BURDEN_TOTAL <> @GL_BURDEN_RECOVERY_TOTAL
   BEGIN
      SELECT @PL_GL_BALANCE_MAJOR = PARAMETER_VALUE
        FROM dbo.XX_PROCESSING_PARAMETERS
       WHERE INTERFACE_NAME_CD = @CLS_R22_INTERFACE_NAME_CD
         AND PARAMETER_NAME = 'DFLT_PL_GL_BALANCE_MAJOR'

      SELECT @PL_GL_BALANCE_MINOR = PARAMETER_VALUE
        FROM dbo.XX_PROCESSING_PARAMETERS
        WHERE INTERFACE_NAME_CD = @CLS_R22_INTERFACE_NAME_CD
         AND PARAMETER_NAME = 'DFLT_PL_GL_BALANCE_MINOR'

      SELECT @PL_GL_BALANCE_SUBMINOR = PARAMETER_VALUE
        FROM dbo.XX_PROCESSING_PARAMETERS
       WHERE INTERFACE_NAME_CD = @CLS_R22_INTERFACE_NAME_CD
         AND PARAMETER_NAME = 'DFLT_PL_GL_BALANCE_SUBMINOR'

      SELECT @PL_GL_BALANCE_CONTRACT = PARAMETER_VALUE
        FROM dbo.XX_PROCESSING_PARAMETERS
       WHERE INTERFACE_NAME_CD = @CLS_R22_INTERFACE_NAME_CD
         AND PARAMETER_NAME = 'DFLT_PL_GL_BALANCE_CONTRACT'

      INSERT INTO dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD
         (CLS_MAJOR, CLS_MINOR, CLS_SUB_MINOR, DOLLAR_AMT, DESCRIPTION2, CONTRACT_NUM)
         VALUES(@PL_GL_BALANCE_MAJOR, @PL_GL_BALANCE_MINOR, @PL_GL_BALANCE_SUBMINOR, -(@PL_BURDEN_TOTAL + @GL_BURDEN_RECOVERY_TOTAL), 
                'VARIANCE - (PA%CR + PL) ', @PL_GL_BALANCE_CONTRACT) 

      SET @SQLServer_error_code = @@ERROR
      IF @SQLServer_error_code <> 0 GOTO ERROR_HANDLER
   END

*/



PRINT '14. Manufactured file balance transaction'

SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'insert file balance transaction'
SET @error_msg_placeholder2 = 'into XX_R22_CLS_DOWN_THIS_MONTH_YTD'

SELECT @CLOSING_TOTAL = SUM(DOLLAR_AMT) 
  FROM dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD

-- Calculate final balance and store it as a separate row
IF @CLOSING_TOTAL <> 0 AND @CLOSING_TOTAL IS NOT NULL
   BEGIN
      SELECT @BALANCE_MAJOR = PARAMETER_VALUE
        FROM XX_PROCESSING_PARAMETERS
       WHERE INTERFACE_NAME_CD = @CLS_R22_INTERFACE_NAME_CD
         AND PARAMETER_NAME = 'DFLT_BALANCE_MAJOR'

      SELECT @BALANCE_MINOR = PARAMETER_VALUE
        FROM XX_PROCESSING_PARAMETERS
       WHERE INTERFACE_NAME_CD = @CLS_R22_INTERFACE_NAME_CD
         AND PARAMETER_NAME = 'DFLT_BALANCE_MINOR'

      SELECT @BALANCE_SUBMINOR = PARAMETER_VALUE
        FROM XX_PROCESSING_PARAMETERS
       WHERE INTERFACE_NAME_CD = @CLS_R22_INTERFACE_NAME_CD
         AND PARAMETER_NAME = 'DFLT_BALANCE_SUBMINOR'

      SELECT @BALANCE_CONTRACT = PARAMETER_VALUE
        FROM XX_PROCESSING_PARAMETERS
       WHERE INTERFACE_NAME_CD = @CLS_R22_INTERFACE_NAME_CD
         AND PARAMETER_NAME = 'DFLT_BALANCE_CONTRACT'

      SELECT @BALANCE_DIVISION = PARAMETER_VALUE
        FROM XX_PROCESSING_PARAMETERS
       WHERE INTERFACE_NAME_CD = @CLS_R22_INTERFACE_NAME_CD
         AND PARAMETER_NAME = 'DFLT_BALANCE_DIVISION'

      INSERT INTO dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD
         (DIVISION, LERU_NUM, CLS_MAJOR, CLS_MINOR, CLS_SUB_MINOR, DOLLAR_AMT, DESCRIPTION2, CONTRACT_NUM)
         VALUES(@BALANCE_DIVISION, @DFLT_LERU_NUM, @BALANCE_MAJOR, @BALANCE_MINOR, @BALANCE_SUBMINOR, (-1 * @CLOSING_TOTAL), 'BALANCING RECORD', @BALANCE_CONTRACT)
		
      SET @SQLServer_error_code = @@ERROR
      IF @SQLServer_error_code <> 0 GOTO ERROR_HANDLER
   END
	
	
PRINT '15. Update Customer CMR (Customer Master Record) data'

/*
We've been told we don't need this

SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'update XX_R22_CLS_DOWN_THIS_MONTH_YTD'
SET @error_msg_placeholder2 = 'with customer CMR data'

UPDATE dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD
   SET MARKETING_OFFICE               = y.I_MKTG_OFF,
       CONSOLIDATED_REV_BRANCH_OFFICE = y.I_PRIMRY_SVC_OFF,
       INDUSTRY                       = y.C_ESTAB_SIC,
       ENTERPRISE_NUM_CD              = y.I_ENT,
       BUSINESS_AREA                  = y.A_LEVEL_1_VALUE,
       MARKETING_AREA                 = 'TD'
  FROM dbo.XX_IMAPS_CMR_STG y
 WHERE y.I_CUST_ENTITY = CUSTOMER_NUM

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO ERROR_HANDLER

*/

SELECT @DFLT_CUSTOMER_NUM = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS 
 WHERE INTERFACE_NAME_CD = @CLS_R22_INTERFACE_NAME_CD
   AND PARAMETER_NAME = 'DFLT_CUSTOMER_NUM'              -- 9999500 ?

UPDATE dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD
   SET CUSTOMER_NUM = @DFLT_CUSTOMER_NUM
 WHERE CUSTOMER_NUM IS NOT NULL
   AND (MARKETING_AREA <> 'TD' or MARKETING_AREA IS NULL)

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO ERROR_HANDLER

UPDATE dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD
   SET CUSTOMER_NUM = @DFLT_CUSTOMER_NUM
 WHERE CUSTOMER_NUM IS NULL 
   AND (CLS_MAJOR + CLS_MINOR + CLS_SUB_MINOR) IN (SELECT CLS_MAJOR + CLS_MINOR + CLS_SUB_MINOR FROM dbo.XX_R22_CLS_DOWN_ACCT_MAPPING WHERE CUSTOMER = 'Y')

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO ERROR_HANDLER

	



PRINT '16. Update DESCRIPTION2'

SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'update XX_R22_CLS_DOWN_THIS_MONTH_YTD'
SET @error_msg_placeholder2 = 'with IMAPS account description'

UPDATE dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD
   SET DESCRIPTION2 = LEFT(ISNULL(acct.ACCT_NAME, cls.DESCRIPTION2), 30)
  FROM dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD cls
       LEFT JOIN
       IMAR.DELTEK.ACCT acct
       ON
       (cls.IMAPS_ACCT = acct.ACCT_ID)

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO ERROR_HANDLER


UPDATE dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD
   SET DESCRIPTION2 = LEFT(LTRIM(RTRIM(IMAPS_ACCT)) + ': ' + DESCRIPTION2,30)
   WHERE DESCRIPTION2 NOT LIKE 'BURDEN%'



	
PRINT '17. Delete zero-dollar transactions'

SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'delete zero-dollar transactions'
SET @error_msg_placeholder2 = 'from XX_R22_CLS_DOWN_THIS_MONTH_YTD'

DELETE dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD WHERE DOLLAR_AMT = .00

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO ERROR_HANDLER









/*
 * We now have the current month YTD image. Time for new delta logic to populate XX_R22_CLS_DOWN.
 */

PRINT '19. Archive YTD image'

SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'insert into XX_R22_CLS_DOWN_YTD_ARCHIVE'
SET @error_msg_placeholder2 = 'from XX_R22_CLS_DOWN_THIS_MONTH_YTD'

INSERT INTO dbo.XX_R22_CLS_DOWN_YTD_ARCHIVE
   (STATUS_RECORD_NUM, CLS_MAJOR, CLS_MINOR, CLS_SUB_MINOR,
    IMAPS_ACCT, IMAPS_PROJ_ID, L1_PROJ_SEG_ID, IMAPS_ORG_ID,
    DIVISION, LERU_NUM,
    DOLLAR_AMT, GA_AMT, OVERHEAD_AMT,
    CONTRACT_NUM, IGS_PROJ, CUSTOMER_NUM,
    MACHINE_TYPE_CD, PRODUCT_ID, DESCRIPTION2,
    BUSINESS_AREA, MARKETING_AREA, MARKETING_OFFICE, CONSOLIDATED_REV_BRANCH_OFFICE, INDUSTRY, ENTERPRISE_NUM_CD
   )
   SELECT @IN_STATUS_RECORD_NUM, CLS_MAJOR, CLS_MINOR, CLS_SUB_MINOR,
          IMAPS_ACCT, IMAPS_PROJ_ID, L1_PROJ_SEG_ID, IMAPS_ORG_ID,
          DIVISION, LERU_NUM,
          DOLLAR_AMT, GA_AMT, OVERHEAD_AMT,
          CONTRACT_NUM, IGS_PROJ, CUSTOMER_NUM,
          MACHINE_TYPE_CD, PRODUCT_ID, DESCRIPTION2,
          BUSINESS_AREA, MARKETING_AREA, MARKETING_OFFICE, CONSOLIDATED_REV_BRANCH_OFFICE, INDUSTRY, ENTERPRISE_NUM_CD
     FROM dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO ERROR_HANDLER

	
PRINT '20. Calculate simple difference between this month and last month values'

/* VALUES THAT HAVE CHANGED SINCE THE PREVIOUS MONTH OR VALUES THAT DID NOT EXIST IN THE PREVIOUS MONTH */

SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'insert into XX_R22_CLS_DOWN'
SET @error_msg_placeholder2 = 'from simple YTD difference'

/*

Add these two columns:

	[DIVISION]         [varchar](15) NULL,
	[LERU_NUM]         [varchar](6) NULL,
	[IMAPS_ORG_ID]	 
*/

INSERT INTO dbo.XX_R22_CLS_DOWN
   (DIVISION, LERU_NUM,
    CLS_MAJOR, CLS_MINOR, CLS_SUB_MINOR,
    IMAPS_ACCT, IMAPS_PROJ_ID, IMAPS_ORG_ID, L1_PROJ_SEG_ID,
    DOLLAR_AMT,
    CONTRACT_NUM, IGS_PROJ,
    CUSTOMER_NUM, MACHINE_TYPE_CD, PRODUCT_ID,
    DESCRIPTION2, BUSINESS_AREA, MARKETING_AREA,
    MARKETING_OFFICE, CONSOLIDATED_REV_BRANCH_OFFICE,
    INDUSTRY, ENTERPRISE_NUM_CD
   )
   SELECT this.DIVISION, this.LERU_NUM,
          this.CLS_MAJOR, this.CLS_MINOR, this.CLS_SUB_MINOR,
          this.IMAPS_ACCT, this.IMAPS_PROJ_ID, this.IMAPS_ORG_ID, this.L1_PROJ_SEG_ID,
          (this.DOLLAR_AMT - ISNULL(last.DOLLAR_AMT, .00)),
          this.CONTRACT_NUM, this.IGS_PROJ,
          this.CUSTOMER_NUM, this.MACHINE_TYPE_CD, this.PRODUCT_ID,
          this.DESCRIPTION2, this.BUSINESS_AREA, this.MARKETING_AREA,
          this.MARKETING_OFFICE, this.CONSOLIDATED_REV_BRANCH_OFFICE,
          this.INDUSTRY, this.ENTERPRISE_NUM_CD
     FROM dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD this
          LEFT JOIN
          dbo.XX_R22_CLS_DOWN_LAST_MONTH_YTD last
          ON
          ( 
		   this.DIVISION								   = last.DIVISION
		   AND ISNULL(this.LERU_NUM, 'NULL_MATCH')		   = ISNULL(last.LERU_NUM, 'NULL_MATCH')
           AND this.CLS_MAJOR                              = last.CLS_MAJOR
           AND this.CLS_MINOR                              = last.CLS_MINOR
           AND this.CLS_SUB_MINOR                          = last.CLS_SUB_MINOR
           AND ISNULL(this.IMAPS_ACCT, this.DESCRIPTION2)  = ISNULL(last.IMAPS_ACCT, last.DESCRIPTION2)
           AND ISNULL(this.IMAPS_PROJ_ID, 'NULL_MATCH')    = ISNULL(last.IMAPS_PROJ_ID, 'NULL_MATCH')
           AND ISNULL(this.IMAPS_ORG_ID, 'NULL_MATCH')     = ISNULL(last.IMAPS_ORG_ID, 'NULL_MATCH')
           AND ISNULL(this.CONTRACT_NUM, 'NULL_MATCH')     = ISNULL(last.CONTRACT_NUM, 'NULL_MATCH')
           AND ISNULL(this.IGS_PROJ, 'NULL_MATCH')         = ISNULL(last.IGS_PROJ, 'NULL_MATCH')
           AND ISNULL(this.MACHINE_TYPE_CD, 'NULL_MATCH')  = ISNULL(last.MACHINE_TYPE_CD, 'NULL_MATCH')
           AND ISNULL(this.PRODUCT_ID, 'NULL_MATCH')       = ISNULL(last.PRODUCT_ID, 'NULL_MATCH')
           AND ISNULL(this.CUSTOMER_NUM, 'NULL_MATCH')     = ISNULL(last.CUSTOMER_NUM, 'NULL_MATCH')
           AND ISNULL(this.SERVICE_OFFERING, 'NULL_MATCH') = ISNULL(last.SERVICE_OFFERING, 'NULL_MATCH')
           AND ISNULL(this.MARKETING_OFFICE, 'NULL_MATCH') = ISNULL(last.MARKETING_OFFICE, 'NULL_MATCH') --CR7602  
          )
    WHERE this.DOLLAR_AMT - ISNULL(last.DOLLAR_AMT, .00) <> .00

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO ERROR_HANDLER


PRINT '21. Calculate complex difference between this month and last month values'

/*
 * Values in last month YTD that need to be reversed out (zeroed) because they are not at all in this month YTD
 */

SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'insert into XX_R22_CLS_DOWN'
SET @error_msg_placeholder2 = 'from complex YTD difference'

INSERT INTO dbo.XX_R22_CLS_DOWN
   (DIVISION, LERU_NUM,
    CLS_MAJOR, CLS_MINOR, CLS_SUB_MINOR,
    IMAPS_ACCT, IMAPS_PROJ_ID, IMAPS_ORG_ID, L1_PROJ_SEG_ID,
    DOLLAR_AMT,
    CONTRACT_NUM, IGS_PROJ,
    CUSTOMER_NUM, MACHINE_TYPE_CD, PRODUCT_ID,
    DESCRIPTION2, BUSINESS_AREA, MARKETING_AREA,
    MARKETING_OFFICE, CONSOLIDATED_REV_BRANCH_OFFICE,
    INDUSTRY, ENTERPRISE_NUM_CD
   )
   SELECT last.DIVISION, last.LERU_NUM,
          last.CLS_MAJOR, last.CLS_MINOR, last.CLS_SUB_MINOR,
          last.IMAPS_ACCT, last.IMAPS_PROJ_ID, last.IMAPS_ORG_ID, last.L1_PROJ_SEG_ID,
          (-1.0 * last.DOLLAR_AMT),
          last.CONTRACT_NUM, last.IGS_PROJ,
          last.CUSTOMER_NUM, last.MACHINE_TYPE_CD, last.PRODUCT_ID,
          last.DESCRIPTION2, last.BUSINESS_AREA, last.MARKETING_AREA,
          last.MARKETING_OFFICE, last.CONSOLIDATED_REV_BRANCH_OFFICE,
          last.INDUSTRY, last.ENTERPRISE_NUM_CD
     FROM dbo.XX_R22_CLS_DOWN_LAST_MONTH_YTD last
    WHERE 0 = (SELECT COUNT(1)
                 FROM dbo.XX_R22_CLS_DOWN_THIS_MONTH_YTD this
				WHERE this.DIVISION								  = last.DIVISION
				  AND ISNULL(this.LERU_NUM, 'NULL_MATCH')		  = ISNULL(last.LERU_NUM, 'NULL_MATCH')
				  AND this.CLS_MAJOR                              = last.CLS_MAJOR
                  AND this.CLS_MINOR                              = last.CLS_MINOR
                  AND this.CLS_SUB_MINOR                          = last.CLS_SUB_MINOR
                  AND ISNULL(this.IMAPS_ACCT, this.DESCRIPTION2)  = ISNULL(last.IMAPS_ACCT, last.DESCRIPTION2)
                  AND ISNULL(this.IMAPS_PROJ_ID, 'NULL_MATCH')    = ISNULL(last.IMAPS_PROJ_ID, 'NULL_MATCH')
                  AND ISNULL(this.IMAPS_ORG_ID, 'NULL_MATCH')     = ISNULL(last.IMAPS_ORG_ID, 'NULL_MATCH')
                  AND ISNULL(this.CONTRACT_NUM, 'NULL_MATCH')     = ISNULL(last.CONTRACT_NUM, 'NULL_MATCH')
                  AND ISNULL(this.IGS_PROJ, 'NULL_MATCH')         = ISNULL(last.IGS_PROJ, 'NULL_MATCH')
                  AND ISNULL(this.MACHINE_TYPE_CD, 'NULL_MATCH')  = ISNULL(last.MACHINE_TYPE_CD, 'NULL_MATCH')
                  AND ISNULL(this.PRODUCT_ID, 'NULL_MATCH')       = ISNULL(last.PRODUCT_ID, 'NULL_MATCH')
                  AND ISNULL(this.CUSTOMER_NUM, 'NULL_MATCH')     = ISNULL(last.CUSTOMER_NUM, 'NULL_MATCH')
                  AND ISNULL(this.SERVICE_OFFERING, 'NULL_MATCH') = ISNULL(last.SERVICE_OFFERING, 'NULL_MATCH')
                  AND ISNULL(this.MARKETING_OFFICE, 'NULL_MATCH') = ISNULL(last.MARKETING_OFFICE, 'NULL_MATCH') --CR7602  
              )

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO ERROR_HANDLER



--CR7602 begin
--we need MARKETING OFFICE to be blank on the file

--if project is blank, save MARKETING OFFICE to project column (Direct Projects) for quick debugging
update XX_R22_CLS_DOWN
set L1_PROJ_SEG_ID=MARKETING_OFFICE
where 
len(isnull(L1_PROJ_SEG_ID,''))=0

--make MARKETING_OFFICE blank
update XX_R22_CLS_DOWN
set MARKETING_OFFICE=null

--CR7602 end



PRINT '22. Set default project code - NO LONGER USED'
/*
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'update XX_R22_CLS_DOWN'
SET @error_msg_placeholder2 = 'with default project codes'

UPDATE dbo.XX_R22_CLS_DOWN
   SET IGS_PROJ = @DFLT_IGS_PROJ_ID
 WHERE (IGS_PROJ IS NULL OR IGS_PROJ = ' ')
   AND (0 < (SELECT COUNT(1)
               FROM dbo.XX_R22_CLS_DOWN_ACCT_MAPPING
              WHERE (IMAPS_ACCT_START <= IMAPS_ACCT AND IMAPS_ACCT_END >= IMAPS_ACCT)
                AND PROJECT = 'Y'
            )
       )

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO ERROR_HANDLER



PRINT '23. Set default customer number'

SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'update XX_R22_CLS_DOWN'
SET @error_msg_placeholder2 = 'with default customer number'

UPDATE dbo.XX_R22_CLS_DOWN
   SET CUSTOMER_NUM = @DFLT_CUSTOMER_NUM
 WHERE (CUSTOMER_NUM IS NULL OR LEN(RTRIM(LTRIM(CUSTOMER_NUM))) <> 7)
   AND (0 < (SELECT COUNT(1)
               FROM dbo.XX_R22_CLS_DOWN_ACCT_MAPPING
              WHERE (IMAPS_ACCT_START <= IMAPS_ACCT AND IMAPS_ACCT_END >= IMAPS_ACCT)
                AND CUSTOMER = 'Y'
            )
       )

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO ERROR_HANDLER

***/
PRINT '23. Set default contract number - NO LONGER USED'
/***
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'update XX_R22_CLS_DOWN'
SET @error_msg_placeholder2 = 'with default contract number'

UPDATE dbo.XX_R22_CLS_DOWN
   SET CUSTOMER_NUM = @DFLT_CONTRACT_NUM
 WHERE (CONTRACT_NUM IS NULL OR LEN(RTRIM(LTRIM(CONTRACT_NUM))) = 0)
   AND (0 < (SELECT COUNT(1)
               FROM dbo.XX_R22_CLS_DOWN_ACCT_MAPPING
              WHERE (IMAPS_ACCT_START <= IMAPS_ACCT AND IMAPS_ACCT_END >= IMAPS_ACCT)
                AND CONTRACT_NUM = 'Y'
            )
       )

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO ERROR_HANDLER


***/
PRINT '24. Set default service offering (for XX_R22_CLS_DOWN records having revenue account IDs) - NO LONGER USED'
/***
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'update XX_R22_CLS_DOWN'
SET @error_msg_placeholder2 = 'with default service offering for records having revenue account IDs'

UPDATE dbo.XX_R22_CLS_DOWN
   SET SERVICE_OFFERING =
          CASE DIVISION
             WHEN @ALMADEN_PSEUDO_DIV THEN @ALMADEN_SERVICE_OFFERING
             WHEN @WATSON_PSEUDO_DIV  THEN @WATSON_SERVICE_OFFERING
          END
 WHERE (0 < (SELECT COUNT(1)
               FROM dbo.XX_R22_CLS_DOWN_ACCT_MAPPING
              WHERE (IMAPS_ACCT_START <= IMAPS_ACCT AND IMAPS_ACCT_END >= IMAPS_ACCT)
                AND S_PROJ_RPT_DC = 'DIRECT'
            )
       )

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO ERROR_HANDLER
*/






PRINT '***********************************************************************************************************************'
PRINT '     END OF ' + @SP_NAME
PRINT '***********************************************************************************************************************'


RETURN(0)

ERROR_HANDLER:

-- SPECIAL ERROR HANDLING FOR DIVISIONS

SET @ret_code = 0

IF @DIV_XX_ERR_CNT > 0 
  BEGIN
    PRINT '****************************** DATA ERROR **********************************************'
	PRINT '.' 
    PRINT 'DIVISION ASSIGNMENT ERROR: ORG_ID IN XX_R22_CLS_DOWN_THIS_MONTH_YTD CONTAINS INVALID CHARACTER IN POSITION 4 - NO MATCH FOUND IN PROCESSING PARAMETERS ORG_ID_?'
	PRINT 'USE SQL QUERY: SELECT IMAPS_PROJ_ID, IMAPS_ORG_ID, DIVISION FROM IMAPSSTG.DBO.XX_R22_CLS_DOWN_THIS_MONTH_YTD WHERE DIVISION = XX'
  END

IF @DIV_ZZ_ERR_CNT > 0 
  BEGIN
    PRINT '****************************** DATA ERROR **********************************************'
	PRINT '.' 
	PRINT 'DIVISION ASSIGNMENT ERROR: ORG_ID IN XX_R22_CLS_DOWN_THIS_MONTH_YTD CONTAINS UNEXPECTED CHARACTERS IN POSITIONS 1,2'
	PRINT 'USE SQL QUERY: SELECT IMAPS_PROJ_ID, IMAPS_ORG_ID, DIVISION FROM IMAPSSTG.DBO.XX_R22_CLS_DOWN_THIS_MONTH_YTD WHERE DIVISION = ZZ'
  END

SET @ret_code = @DIV_XX_ERR_CNT + @DIV_ZZ_ERR_CNT

IF @ret_code > 0 RETURN (1)

EXEC dbo.XX_ERROR_MSG_DETAIL
   @in_error_code           = @IMAPS_error_number,
   @in_display_requested    = 1,
   @in_SQLServer_error_code = @SQLServer_error_code,
   @in_placeholder_value1   = @error_msg_placeholder1,
   @in_placeholder_value2   = @error_msg_placeholder2,
   @in_calling_object_name  = @SP_NAME,
   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

RETURN(1)

END


GO


