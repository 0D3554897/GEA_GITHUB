use imapsstg

/****** Object:  Table [dbo].[XX_CERIS_PAY_DIFFERENTIAL_MAPPING]    Script Date: 07/21/2006 12:56:24 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_PAY_DIFFERENTIAL_MAPPING]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_CERIS_PAY_DIFFERENTIAL_MAPPING]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_PAY_DIFFERENTIAL_MAPPING]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_CERIS_PAY_DIFFERENTIAL_MAPPING] (

	[ROW_NUM] [int] IDENTITY(1,1) NOT NULL,

	[SALSETID] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[DIVISION] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[DEPT] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,

	[PAY_DIFFERENTIAL] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,

	[CREATED_BY] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CREATED_DATE] [datetime] NOT NULL 

) ON [PRIMARY]
END

GO




insert into xx_ceris_pay_differential_mapping
(
SALSETID,
DIVISION,
DEPT,
PAY_DIFFERENTIAL,
CREATED_BY,
CREATED_DATE
)
SELECT 
'55' as SALSETID,
'16' as DIVISION,
'*' as DEPT,
'R' as PAY_DIFFERENTIAL,
suser_name() as CREATED_BY,
current_timestamp as CREATED_DATE

insert into xx_ceris_pay_differential_mapping
(
SALSETID,
DIVISION,
DEPT,
PAY_DIFFERENTIAL,
CREATED_BY,
CREATED_DATE
)
SELECT 
'66' as SALSETID,
'16' as DIVISION,
'*' as DEPT,
'N' as PAY_DIFFERENTIAL,
suser_name() as CREATED_BY,
current_timestamp as CREATED_DATE

insert into xx_ceris_pay_differential_mapping
(
SALSETID,
DIVISION,
DEPT,
PAY_DIFFERENTIAL,
CREATED_BY,
CREATED_DATE
)
SELECT 
'77' as SALSETID,
'16' as DIVISION,
'*' as DEPT,
'P' as PAY_DIFFERENTIAL,
suser_name() as CREATED_BY,
current_timestamp as CREATED_DATE







insert into xx_ceris_pay_differential_mapping
(
SALSETID,
DIVISION,
DEPT,
PAY_DIFFERENTIAL,
CREATED_BY,
CREATED_DATE
)
SELECT 
'55' as SALSETID,
'1M' as DIVISION,
'*' as DEPT,
'Y' as PAY_DIFFERENTIAL,
suser_name() as CREATED_BY,
current_timestamp as CREATED_DATE

insert into xx_ceris_pay_differential_mapping
(
SALSETID,
DIVISION,
DEPT,
PAY_DIFFERENTIAL,
CREATED_BY,
CREATED_DATE
)
SELECT 
'66' as SALSETID,
'1M' as DIVISION,
'*' as DEPT,
'X' as PAY_DIFFERENTIAL,
suser_name() as CREATED_BY,
current_timestamp as CREATED_DATE

insert into xx_ceris_pay_differential_mapping
(
SALSETID,
DIVISION,
DEPT,
PAY_DIFFERENTIAL,
CREATED_BY,
CREATED_DATE
)
SELECT 
'77' as SALSETID,
'1M' as DIVISION,
'*' as DEPT,
'Z' as PAY_DIFFERENTIAL,
suser_name() as CREATED_BY,
current_timestamp as CREATED_DATE

