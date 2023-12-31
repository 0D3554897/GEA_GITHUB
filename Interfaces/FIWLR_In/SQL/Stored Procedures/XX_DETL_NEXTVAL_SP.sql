SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[xx_detl_nextval_sp]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[xx_detl_nextval_sp]
GO



CREATE PROCEDURE dbo.xx_detl_nextval_sp
	@sequence VARCHAR(100),
	@sequence_id INT OUTPUT
AS

/************************************************************************************************/
/* Procedure Name	: XX_DETL_NEXTVAL_SP							*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   		*/
/* Description    	: Detail Nextval Sequence Procedure					*/
/* Date			: October 25, 2005						        */
/* Notes		: IMAPS Detail Nextval Sequence program will generate unique sequence 	*/
/*			  number 								*/
/* Prerequisites	: XX_SEQUENCES_DETL Table(s) should exist.				*/
/* Parameter(s)		: 									*/
/*	Input		: Next Value number							*/
/*	Output		: Sequence Number							*/
/* Tables Updated	: XX_SEQUENCES_DETL							*/
/* Version		: 1.0									*/
/************************************************************************************************/
/* Date		Modified By		Description of change			  		*/
/* ----------   -------------  	   	------------------------    			  	*/
/* 10-25-2005   Veera Veeramachanane   	Created Initial Version					*/
/************************************************************************************************/

-- return an error if sequence does not exist
-- so we will know if someone truncates the table

	SET @sequence_id = -1

	UPDATE	dbo.xx_sequences_detl
	SET	@sequence_id = sequence_id = sequence_id + 1
	WHERE	seq = @sequence

RETURN @sequence_id

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

