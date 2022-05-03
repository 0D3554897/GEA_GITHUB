SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[InString]') and xtype in (N'FN', N'IF', N'TF'))
drop function [dbo].[InString]
GO

CREATE  function InString(

	@string varchar(254), 
	@searchfor varchar(50), 
	@position int
	) returns int

/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Keith Grabbed this for free online at :
http://www.novicksoftware.com/UDFofWeek/Vol2/T-SQL-UDF-Vol-2-Num-49-instring.htm


Returns the position of the character AFTER the nth instance 
of the string

-- TEST CASE #1
-- should return 18
select dbo.InString('123456 123456 123456 123456', '23', 3) 
                    as [Test Case #1]

-- TEST CASE #2
-- should return 25
select dbo.InString('test1/test2/test3/test4/test5/', '/', 4) 
                     as [Test Case #2]

-- TEST CASE #3
declare @teststring varchar(50)
set @teststring = 'test1/test2/test3/test4/test5/'
select substring(@teststring, dbo.Instring(@teststring,'/',3),5)
                     as [Test Case #3]
-- should return 'test4'

-- TEST CASE #4 (variable length delimited fields
declare @teststring2 varchar(50)
set @teststring2 = 'test123/test/testtestestest/testxyz/test/'
select substring(	@teststring2, 
			dbo.Instring(@teststring2, '/', 3),
			(dbo.Instring(@teststring2, '/', 4) -1) 
                           - dbo.Instring(@teststring2, '/', 3)
			) as [Test Case #4]
-- should return 'testxyz'
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

as
begin
declare @lenstring int, @poscount int, @stringpos int
set @lenstring = datalength(@searchfor)
set @poscount = 1
set @stringpos = 1
while @poscount <= @position and @stringpos <= len(@string) 
	begin
		-- if we find the string segment we're looking for 
        if substring(@string, @stringpos, @lenstring)=@searchfor
			begin
                -- is the instance of the string the one we are
                --  looking for?
				if @poscount = @position 
					begin
                        set @stringpos = @stringpos + @lenstring
						return @stringpos
					end
                -- else look for the next instance of the string
                -- segment
				else 
					begin
						set @poscount = @poscount + 1
					end
			end
		set @stringpos = @stringpos + 1
	end
return null
end

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

