SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  User Defined Function dbo.XX_GET_SOW_TYP_CD_UF    Script Date: 01/11/2007 1:31:59 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_GET_SOW_TYP_CD_UF]') and xtype in (N'FN', N'IF', N'TF'))
drop function [dbo].[XX_GET_SOW_TYP_CD_UF]
GO






CREATE FUNCTION [dbo].[XX_GET_SOW_TYP_CD_UF] 
(@in_PROJ_ID  varchar(30))
RETURNS            char(2) AS  
BEGIN 
DECLARE  
@returnvalue          char(2)


/************************************************************************************************  
Name:       XX_GET_SOW_TYP_CD_UF
Author:     	AM
Created:    	11/28/2005  
Purpose:  Conversion function called by UTILIZATION Interface

Parameters: 
	Input: @in_UDEF_DESC -- identifier of current interface run

	Returnt:  SOW_TYPE for UTILIZATION
Version: 	1.0

select dbo.XX_GET_SOW_TYP_CD_UF(proj_id), count(1)
from imaps.deltek.proj
where proj_abbrv_cd <> ' '
and left(proj_id, 4) not in ('DDOU', 'IINT', 'BOPP', 'MOSS')
group by dbo.XX_GET_SOW_TYP_CD_UF(proj_id)
order by count(1) desc

**************************************************************************************************/ 

--default return value
--SET @returnvalue = '  '
--leave null


-- get contract type
DECLARE	@UDEF_ID  varchar(20)
SELECT 	@UDEF_ID = UDEF_ID
FROM	IMAPS.DELTEK.GENL_UDEF
WHERE 	GENL_ID = @in_PROJ_ID
AND		S_TABLE_ID = 'PJ'
AND		UDEF_LBL_KEY = 5

-- if contract type is a FIXED PRICE type


-- return 'FP'
IF( @UDEF_ID in ('FPAF', 'FPPA', 'FPIF', 'FPR', 'FFP' )  )
BEGIN
	SET	@returnvalue = 'FP'
END
ELSE IF ( @UDEF_ID in ('COST RECOVERY', 'COST SHARE', 'CPAF', 'CPFF',
			'CPFH', 'CPIF', 'FPLOE', 'LABOR HR', 'T+M')  )
BEGIN
	SET 	@returnvalue = 'BE'
END


RETURN  @returnvalue
END






GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

