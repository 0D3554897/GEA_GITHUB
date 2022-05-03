USE [IMAPSStg]
GO

/****** Object:  UserDefinedFunction [dbo].[XX_VW_FINGERPRINT]    Script Date: 4/7/2020 10:10:13 AM ******/
DROP FUNCTION [dbo].[XX_VW_FINGERPRINT]
GO

/****** Object:  UserDefinedFunction [dbo].[XX_VW_FINGERPRINT]    Script Date: 4/7/2020 10:10:13 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE FUNCTION [dbo].[XX_VW_FINGERPRINT](@p_View_Name VARCHAR(250)) RETURNS int   
AS  

/************************************************************************************************
 Function Name	: XX_VW_FINGERPRINT  					

							
 Created By		: GEA							
 Description    : Function creates a fingerprint of a view				
 Date			: 03/19/2020						
 Notes			: The purpose of this function is to help ensure the latest and greatest is deployed to PROD. 
					-- Returns the ASCII SUM for all characters in the view code. 
					
 Usage          : DECLARE @RET INTEGER
				  SELECT @RET=dbo.XX_VW_FINGERPRINT('XX_CLS_DOWN_VW')
				  PRINT @RET		
				  
				  Use the function to insert/update processing_parameters table when deploying
				  Allows you to make sure that correct VW is compiled and being used			
						
 Prerequisites	: 
 Parameter(s)	: 															
	Input		: VW_NAME							
	Output		: A unique integer		
 Version		: 1.0							
										
************************************************************************************************
 Date			Modified By			Description of change	  									
 ----------   -------------  	   	------------------------    		
 03-30-2020   GEA   				Created Initial Version		

								
************************************************************************************************/ 
 
BEGIN  
    DECLARE @ret int;  
    DECLARE @vw_code_length int;  
    DECLARE @vw_name VARCHAR(250);  
    DECLARE @vw_code VARCHAR(250);  
	DECLARE @n int = 1;
	DECLARE @asciival int = 0;
	DECLARE @asciisum int = 0;

	select distinct @vw_name = substring(a.name, 1, 50), 	@vw_code = B.TEXT
	from sysobjects a, syscomments b
	where a.type like 'V' -- only views
	and a.id = b.id
	and a.name = @p_View_Name;

	set @vw_code_length = len(@vw_code)

	WHILE @n <= @vw_code_length
		BEGIN
			SELECT @asciival = ASCII(SUBSTRING(@vw_code, @n, 1));
			set @asciisum = @asciisum + @asciival;
			SET @n = @n + 1;
		END;

    SET @ret = @asciisum;  
    RETURN @ret;  
END;


GO


