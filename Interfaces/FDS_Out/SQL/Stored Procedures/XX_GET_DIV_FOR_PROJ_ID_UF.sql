use imapsstg

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  User Defined Function dbo.XX_GET_DIV_FOR_PROJ_ID_UF    Script Date: 03/07/2007 3:02:41 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_GET_DIV_FOR_PROJ_ID_UF]') and xtype in (N'FN', N'IF', N'TF'))
drop function [dbo].[XX_GET_DIV_FOR_PROJ_ID_UF]
GO


CREATE FUNCTION [dbo].[XX_GET_DIV_FOR_PROJ_ID_UF] 
(@in_proj_id varchar(30))
RETURNS char(2) AS  
BEGIN 


/************************************************************************************************  
Name:       XX_GET_DIV_FOR_PROJ_ID_UF
Author:     	KM
Created:    	2010-09-09
Purpose:  Returns left 2 characters of project's owning org
Parameters: 
**************************************************************************************************/ 
	
	
	declare @div char(2)
	set @div = '??'
	
	select @div = left(org_id,2)
	from imaps.deltek.proj
	where proj_id=@in_proj_id

	return @div

END


GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

