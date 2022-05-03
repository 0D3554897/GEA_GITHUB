use imapsstg

IF OBJECT_ID('dbo.XX_CERIS_PROCESS_RETRO_RECLASS_SP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_CERIS_PROCESS_RETRO_RECLASS_SP
    IF OBJECT_ID('dbo.XX_CERIS_PROCESS_RETRO_RECLASS_SP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_CERIS_PROCESS_RETRO_RECLASS_SP >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_CERIS_PROCESS_RETRO_RECLASS_SP >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER OFF
go

CREATE procedure [dbo].[XX_CERIS_PROCESS_RETRO_RECLASS_SP]
as

/************************************************************************************************  
Name:           XX_CERIS_PROCESS_RETRO_RECLASS_SP
Author:         Tejas Patel
Created:        07/2012
Purpose:        

    
    THIS ENTIRE STORED PROCEDURE IS FOR CR-4885 Actuals Implementation
    
    1.Non-Exempt employee

    Non-Exempt emplyee needs a special logic to reclassify the hours between default account and special account.
    Non-Exempt employee needs a special logic to default the account when the pay_type is OT

execute XX_CERIS_PROCESS_RETRO_RECLASS_SP

Prerequisites:     none 
Version:     1.0
                    
************************************************************************************************/ 
BEGIN

	--KM 10/10/12
	--this procedure is being totally replaced by the XX_CERIS_INSERT_TS_RECLASS_SP procedure
	--if this is ever called, it should not do anything

    RETURN (0)
    
END


go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_CERIS_PROCESS_RETRO_RECLASS_SP') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_CERIS_PROCESS_RETRO_RECLASS_SP >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_CERIS_PROCESS_RETRO_RECLASS_SP >>>'
go
