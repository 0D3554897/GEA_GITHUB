SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.XX_RETRORATE_CHECK_DATA_SP    Script Date: 01/25/2006 3:20:18 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_RETRORATE_CHECK_DATA_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_RETRORATE_CHECK_DATA_SP]
GO


CREATE PROCEDURE dbo.XX_RETRORATE_CHECK_DATA_SP
(
@in_FY char(4)
)
AS

/************************************************************************************************
Name:       XX_RETRORATE_CHECK_DATA_SP
Author:     HVT
Created:    01/09/2006
Purpose:    Verify that retro rate change data exist to run the interface.
            Called by XX_RETRORATE_RUN_INTERFACE_SP.
Parameters: 
Result Set: None
Notes:
************************************************************************************************/

DECLARE @SQLServer_error_code integer,
        @row_count integer

IF @in_FY IS NULL
   -- if process year is not passed as parameter, then set the default as current year
   SET @in_FY = DATEPART(yyyy, GETDATE())

SELECT @row_count = COUNT(1)
  FROM IMAPS.Deltek.ts_ln_hs tlh,
       IMAPS.Deltek.ts_hdr_hs thh
 WHERE tlh.ts_dt = thh.ts_dt 
   AND ((fy_cd = @in_FY AND thh.s_ts_type_cd = 'R') OR
        (DATEPART(YYYY, corecting_ref_dt) = @in_FY AND thh.s_ts_type_Cd = 'C')
       )
   AND pay_type = 'R'
   AND thh.empl_id = tlh.empl_id
   AND thh.s_ts_type_cd = tlh.s_ts_type_cd
   AND thh.ts_hdr_seq_no = tlh.ts_hdr_seq_no
   AND tlh.genl_lab_cat_cd IN (SELECT genl_lab_cat_cd
                                 FROM dbo.XX_GENL_LAB_CAT glc1
                                WHERE genl_lab_cat_cd = tlh.genl_lab_cat_cd 
                                  AND rate_delta <> 0
                                  AND time_stamp = (SELECT MAX(time_stamp) 
                                                      FROM dbo.XX_GENL_LAB_CAT
                                                     WHERE genl_lab_cat_cd = glc1.genl_lab_cat_cd))
 GROUP BY thh.empl_id, thh.fy_cd, tlh.acct_id,
       tlh.proj_id, tlh.bill_lab_cat_cd, tlh.genl_lab_cat_cd, org_id
HAVING (SUM(tlh.chg_hrs) <> 0 AND SUM(tlh.lab_cst_amt) <> 0)

SELECT @SQLServer_error_code = @@ERROR, @row_count = @@ROWCOUNT

IF @SQLServer_error_code <> 0
   RETURN(1)

IF @row_count = 0
   BEGIN
      -- If XX_RATE_RETRO_TS_PREP_TEMP is empty, is it necessary to perform the rest of the program?
      PRINT 'No rate change data exist to continue ...'
      RETURN(1)
   END

RETURN(0)

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

