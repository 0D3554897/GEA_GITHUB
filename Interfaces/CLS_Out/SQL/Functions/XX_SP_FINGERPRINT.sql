USE [IMAPSStg]
GO

/****** Object:  UserDefinedFunction [dbo].[XX_SP_FINGERPRINT]    Script Date: 4/7/2020 10:11:23 AM ******/
DROP FUNCTION [dbo].[XX_SP_FINGERPRINT]
GO

/****** Object:  UserDefinedFunction [dbo].[XX_SP_FINGERPRINT]    Script Date: 4/7/2020 10:11:23 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE FUNCTION [dbo].[XX_SP_FINGERPRINT](@p_Procedure_Name VARCHAR(250)) RETURNS int   
AS  

/************************************************************************************************
 Function Name	: XX_SP_FINGERPRINT  					

							
 Created By		: GEA							
 Description    : Function creates a fingerprint of a stored procedure				
 Date			: 03/19/2020						
 Notes			: The purpose of this function is to help ensure the latest and greatest is deployed to PROD. 
					-- Returns the ASCII SUM for all characters in the procedure code. 
					
 Usage          : DECLARE @RET INTEGER
				  SELECT @RET=dbo.XX_SP_FINGERPRINT('XX_CLS_DOWN_ARCHIVE_FILES_SP')
				  PRINT @RET		
				  
				  Use the function to insert/update processing_parameters table when deploying
				  Allows you to make sure that correct SP is compiled and being used			
						
 Prerequisites	: 
 Parameter(s)	: 															
	Input		: SP_NAME							
	Output		: A unique integer		
 Version		: 1.0							
										
************************************************************************************************
 Date			Modified By			Description of change	  									
 ----------   -------------  	   	------------------------    		
 12-30-2009   GEA   				Created Initial Version		

								
************************************************************************************************/ 
 
BEGIN  
    DECLARE @ret int;  
    DECLARE @sp_code_length int;  
    DECLARE @sp_name VARCHAR(250);  
    DECLARE @sp_code VARCHAR(250);  
	DECLARE @n int = 1;
	DECLARE @asciival int = 0;
	DECLARE @asciisum int = 0;

	select distinct @sp_name = substring(a.name, 1, 50), 	@sp_code = B.TEXT
	from sysobjects a, syscomments b
	where a.type like 'P' -- only stored procedures
	and a.id = b.id
	and a.name = @p_Procedure_Name;

	set @sp_code_length = len(@sp_code)

	WHILE @n <= @sp_code_length
		BEGIN
			SELECT @asciival = ASCII(SUBSTRING(@sp_code, @n, 1));
			set @asciisum = @asciisum + @asciival;
			SET @n = @n + 1;
		END;

    SET @ret = @asciisum;  
    RETURN @ret;  
END;


GO


