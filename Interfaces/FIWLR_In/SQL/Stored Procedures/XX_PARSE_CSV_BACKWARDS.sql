SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_PARSE_CSV_BACKWARDS]') and xtype in (N'FN', N'IF', N'TF'))
drop function [dbo].[XX_PARSE_CSV_BACKWARDS]
GO






CREATE  function dbo.XX_PARSE_CSV_BACKWARDS(
	@csv_string varchar(254), -- Length increased to 225 from 200; Def:DEV1805-tpatel  
	@position int
	) returns varchar(30)
as
begin
declare @ret_val varchar(30)
declare @csv_string_len int
set @csv_string_len = len(@csv_string)

if @position < 0
begin
	set @ret_val = null
end

else if @position = 0
begin
	set @ret_val = substring(@csv_string,@csv_string_len-dbo.Instring_BACKWARDS(@csv_string, ',', 1), @csv_string_len)
end

else
begin
	set @ret_val = substring(@csv_string, 2+@csv_string_len-dbo.Instring_BACKWARDS(@csv_string, ',', @position+1), -1+dbo.Instring_BACKWARDS(@csv_string, ',', @position+1) - dbo.Instring_BACKWARDS(@csv_string, ',', @position))
end

return @ret_val
end






GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

