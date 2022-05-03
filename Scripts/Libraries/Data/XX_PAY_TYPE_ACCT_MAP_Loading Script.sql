USE [IMAPSStg]
GO
/****** Object:  Table Loading script [dbo].[XX_PAY_TYPE_ACCT_MAP]    Script Date: 05/20/2008 10:47:35 ******/


truncate table XX_PAY_TYPE_ACCT_MAP
go

insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','B&P','FA','80-01-18','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','B&P','FA','80-01-18','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','B&P','FB','80-01-11','80-01-1E','Labor - Cons Offsite B&P','Labor - ConsOff B&P STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','B&P','FB','80-01-11','80-01-1F','Labor - Cons Offsite B&P','Labor - ConsOff B&P STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','B&P','FC','80-01-02','80-01-0E','Labor - Cons Onsite B&P','Labor - ConsOn B&P STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','B&P','FC','80-01-02','80-01-0F','Labor - Cons Onsite B&P','Labor - ConsOn B&P STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','B&P','FF','80-01-10','80-01-1A','Labor - Off Site','Labor - Off Site STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','B&P','FF','80-01-10','80-01-1B','Labor - Off Site','Labor - Off Site STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','B&P','FK','80-01-35','80-01-3E','B&P Labor','B&P Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','B&P','FK','80-01-35','80-01-3F','B&P Labor','B&P Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','B&P','FN','80-01-01','80-01-0A','Labor - On Site','Labor - On Site STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','B&P','FN','80-01-01','80-01-0B','Labor - On Site','Labor - On Site STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','B&P','FP','80-01-35','80-01-3E','B&P Labor','B&P Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','B&P','FP','80-01-35','80-01-3F','B&P Labor','B&P Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','B&P','FV','80-01-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','B&P','FV','80-01-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','B&P','MM','80-01-16','80-01-1G','O&M Labor on B&P','O&M Labor on B&P STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','B&P','MM','80-01-16','80-01-1H','O&M Labor on B&P','O&M Labor on B&P STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','BAE','FE','71-01-40','71-01-4A','BAE Labor','BAE Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','BAE','FE','71-01-40','71-01-4B','BAE Labor','BAE Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','BAE','ME','71-01-40','71-01-4A','BAE Labor','BAE Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','BAE','ME','71-01-40','71-01-4B','BAE Labor','BAE Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','DEX','FA','41-01-18','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','DEX','FA','41-01-18','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','DEX','FB','41-01-11','41-01-1E','Dir Labor- Cons Offsite','Direct Labor-ConsOff STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','DEX','FB','41-01-11','41-01-1F','Dir Labor- Cons Offsite','Direct Labor-ConsOff STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','DEX','FC','41-01-02','41-01-0E','Direct Labor- Cons Onsite','Direct Labor- ConsOn STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','DEX','FC','41-01-02','41-01-0F','Direct Labor- Cons Onsite','Direct Labor- ConsOn STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','DEX','FF','41-01-10','41-01-1A','Direct Labo-Tech Off Site','Direct Labor-TechOff STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','DEX','FF','41-01-10','41-01-1B','Direct Labo-Tech Off Site','Direct Labor-TechOff STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','DEX','FK','41-01-35','41-01-3E','Direct Labor - Other','Direct Labor - Other STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','DEX','FK','41-01-35','41-01-3F','Direct Labor - Other','Direct Labor - Other STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','DEX','FN','41-01-01','41-01-0A','Direct Labor-Tech On Site','Direct Labor-TechOn STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','DEX','FN','41-01-01','41-01-0B','Direct Labor-Tech On Site','Direct Labor-TechOn STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','DEX','FP','41-01-35','41-01-3E','Direct Labor - Other','Direct Labor - Other STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','DEX','FP','41-01-35','41-01-3F','Direct Labor - Other','Direct Labor - Other STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','DEX','FV','41-01-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','DEX','FV','41-01-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','DEX','MM','41-01-16','41-01-1G','O&M Offsite Direct Labor','O&M Labor Offsite STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','DEX','MM','41-01-16','41-01-1H','O&M Offsite Direct Labor','O&M Labor Offsite STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','DFH','FA','41-01-18','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','DFH','FA','41-01-18','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','DFH','FB','41-01-11','41-01-1E','Dir Labor- Cons Offsite','Direct Labor-ConsOff STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','DFH','FB','41-01-11','41-01-1F','Dir Labor- Cons Offsite','Direct Labor-ConsOff STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','DFH','FC','41-01-02','41-01-0E','Direct Labor- Cons Onsite','Direct Labor- ConsOn STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','DFH','FC','41-01-02','41-01-0F','Direct Labor- Cons Onsite','Direct Labor- ConsOn STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','DFH','FF','41-01-10','41-01-1A','Direct Labo-Tech Off Site','Direct Labor-TechOff STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','DFH','FF','41-01-10','41-01-1B','Direct Labo-Tech Off Site','Direct Labor-TechOff STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','DFH','FK','41-01-35','41-01-3E','Direct Labor - Other','Direct Labor - Other STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','DFH','FK','41-01-35','41-01-3F','Direct Labor - Other','Direct Labor - Other STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','DFH','FN','41-01-01','41-01-0A','Direct Labor-Tech On Site','Direct Labor-TechOn STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','DFH','FN','41-01-01','41-01-0B','Direct Labor-Tech On Site','Direct Labor-TechOn STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','DFH','FP','41-01-35','41-01-3E','Direct Labor - Other','Direct Labor - Other STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','DFH','FP','41-01-35','41-01-3F','Direct Labor - Other','Direct Labor - Other STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','DFH','FV','41-01-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','DFH','FV','41-01-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','DFH','MM','41-01-16','41-01-1G','O&M Offsite Direct Labor','O&M Labor Offsite STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','DFH','MM','41-01-16','41-01-1H','O&M Offsite Direct Labor','O&M Labor Offsite STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','DTM','FA','41-01-18','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','DTM','FA','41-01-18','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','DTM','FB','41-01-11','41-01-1E','Dir Labor- Cons Offsite','Direct Labor-ConsOff STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','DTM','FB','41-01-11','41-01-1F','Dir Labor- Cons Offsite','Direct Labor-ConsOff STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','DTM','FC','41-01-02','41-01-0E','Direct Labor- Cons Onsite','Direct Labor- ConsOn STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','DTM','FC','41-01-02','41-01-0F','Direct Labor- Cons Onsite','Direct Labor- ConsOn STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','DTM','FF','41-01-10','41-01-1A','Direct Labo-Tech Off Site','Direct Labor-TechOff STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','DTM','FF','41-01-10','41-01-1B','Direct Labo-Tech Off Site','Direct Labor-TechOff STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','DTM','FK','41-01-35','41-01-3E','Direct Labor - Other','Direct Labor - Other STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','DTM','FK','41-01-35','41-01-3F','Direct Labor - Other','Direct Labor - Other STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','DTM','FN','41-01-01','41-01-0A','Direct Labor-Tech On Site','Direct Labor-TechOn STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','DTM','FN','41-01-01','41-01-0B','Direct Labor-Tech On Site','Direct Labor-TechOn STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','DTM','FP','41-01-35','41-01-3E','Direct Labor - Other','Direct Labor - Other STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','DTM','FP','41-01-35','41-01-3F','Direct Labor - Other','Direct Labor - Other STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','DTM','FV','41-01-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','DTM','FV','41-01-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','DTM','MM','41-01-16','41-01-1G','O&M Offsite Direct Labor','O&M Labor Offsite STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','DTM','MM','41-01-16','41-01-1H','O&M Offsite Direct Labor','O&M Labor Offsite STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','G&A','FA','70-01-18','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','G&A','FA','70-01-18','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','G&A','FB','70-01-11','70-01-1E','Labor - Cons Offsite G&A','Labor - ConsOff G&A STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','G&A','FB','70-01-11','70-01-1F','Labor - Cons Offsite G&A','Labor - ConsOff G&A STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','G&A','FC','70-01-02','70-01-0E','Labor - Cons Onsite G&A','Labor - ConsOn G&A STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','G&A','FC','70-01-02','70-01-0F','Labor - Cons Onsite G&A','Labor - ConsOn G&A STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','G&A','FF','70-01-10','70-01-1A','Labor - Off Site','Labor - Off Site STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','G&A','FF','70-01-10','70-01-1B','Labor - Off Site','Labor - Off Site STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','G&A','FG','70-01-35','70-01-3E','Labor - Indirect','Labor - Indirect STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','G&A','FG','70-01-35','70-01-3F','Labor - Indirect','Labor - Indirect STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','G&A','FK','70-01-25','70-01-2E','Labor - Office Services','Office Svcs Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','G&A','FK','70-01-25','70-01-2F','Labor - Office Services','Office Svcs Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','G&A','FN','70-01-01','70-01-0A','G&A Labor - Tech On Site','G&A Lab-TechOn Site STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','G&A','FN','70-01-01','70-01-0B','G&A Labor - Tech On Site','G&A Lab-TechOn Site STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','G&A','FV','70-01-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','G&A','FV','70-01-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','G&A','MG','70-01-35','70-01-3E','Labor - Indirect','Labor - Indirect STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','G&A','MG','70-01-35','70-01-3F','Labor - Indirect','Labor - Indirect STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','G&A','MM','70-01-16','70-01-1G','O&M Off Ind G&A Labor','O&M Off G&A Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','G&A','MM','70-01-16','70-01-1H','O&M Off Ind G&A Labor','O&M Off G&A Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','GOH','FA','60-01-18','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','GOH','FA','60-01-18','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','GOH','FB','60-01-11','60-01-1E','Labor - Cons Offsite OH','Labor - ConsOff OH STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','GOH','FB','60-01-11','60-01-1F','Labor - Cons Offsite OH','Labor - ConsOff OH STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','GOH','FC','60-01-02','60-01-0E','Labor - Cons On Site OH','Labor - ConsOn Site STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','GOH','FC','60-01-02','60-01-0F','Labor - Cons On Site OH','Labor - ConsOn Site STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','GOH','FF','60-01-10','60-01-1A','Labor- Tech Off Site','Labor- Tech Off Site STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','GOH','FF','60-01-10','60-01-1B','Labor- Tech Off Site','Labor- Tech Off Site STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','GOH','FN','60-01-01','60-01-0A','Labor- Tech On Site','Labor- Tech On Site STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','GOH','FN','60-01-01','60-01-0B','Labor- Tech On Site','Labor- Tech On Site STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','GOH','FV','60-01-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','GOH','FV','60-01-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','GOH','MM','60-01-16','60-01-1G','O&M Offsite Ind Labor','O&M Off OH Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','GOH','MM','60-01-16','60-01-1H','O&M Offsite Ind Labor','O&M Off OH Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','GWA','FA','52-01-30','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','GWA','FA','52-01-30','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','GWA','FB','52-01-30','52-01-3A','General Works Labor','General Works Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','GWA','FB','52-01-30','52-01-3B','General Works Labor','General Works Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','GWA','FC','52-01-30','52-01-3A','General Works Labor','General Works Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','GWA','FC','52-01-30','52-01-3B','General Works Labor','General Works Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','GWA','FF','52-01-30','52-01-3A','General Works Labor','General Works Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','GWA','FF','52-01-30','52-01-3B','General Works Labor','General Works Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','GWA','FK','52-01-30','52-01-3A','General Works Labor','General Works Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','GWA','FK','52-01-30','52-01-3B','General Works Labor','General Works Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','GWA','FN','52-01-30','52-01-3A','General Works Labor','General Works Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','GWA','FN','52-01-30','52-01-3B','General Works Labor','General Works Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','GWA','FP','52-01-30','52-01-3A','General Works Labor','General Works Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','GWA','FP','52-01-30','52-01-3B','General Works Labor','General Works Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','GWA','FV','52-01-30','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','GWA','FV','52-01-30','??-??-??','','','1','imapsprd', current_timestamp

go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','GWA','MM','52-01-30','52-01-3A','General Works Labor','General Works Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','GWA','MM','52-01-30','52-01-3B','General Works Labor','General Works Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','HOM','0Q','73-01-50','73-01-5A','Home Office Labor','Home Office Labor - STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','HOM','0Q','73-01-50','73-01-5B','Home Office Labor','Home Office Labor - STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','HOM','1Q','73-01-50','73-01-5A','Home Office Labor','Home Office Labor - STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','HOM','1Q','73-01-50','73-01-5B','Home Office Labor','Home Office Labor - STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','ICA','FB','41-01-11','41-01-1E','Dir Labor- Cons Offsite','Direct Labor-ConsOff STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','ICA','FB','41-01-11','41-01-1F','Dir Labor- Cons Offsite','Direct Labor-ConsOff STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','ICA','FC','41-01-02','41-01-0E','Direct Labor- Cons Onsite','Direct Labor- ConsOn STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','ICA','FC','41-01-02','41-01-0F','Direct Labor- Cons Onsite','Direct Labor- ConsOn STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','ICA','FF','41-01-10','41-01-1A','Direct Labo-Tech Off Site','Direct Labor-TechOff STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','ICA','FF','41-01-10','41-01-1B','Direct Labo-Tech Off Site','Direct Labor-TechOff STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','ICA','FK','41-01-35','41-01-3E','Direct Labor - Other','Direct Labor - Other STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','ICA','FK','41-01-35','41-01-3F','Direct Labor - Other','Direct Labor - Other STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','ICA','FN','41-01-01','41-01-0A','Direct Labor-Tech On Site','Direct Labor-TechOn STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','ICA','FN','41-01-01','41-01-0B','Direct Labor-Tech On Site','Direct Labor-TechOn STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','ICA','FP','41-01-35','41-01-3E','Direct Labor - Other','Direct Labor - Other STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','ICA','FP','41-01-35','41-01-3F','Direct Labor - Other','Direct Labor - Other STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','ICA','FV','41-01-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','ICA','FV','41-01-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','ICA','MM','41-01-16','41-01-1G','O&M Offsite Direct Labor','O&M Labor Offsite STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','ICA','MM','41-01-16','41-01-1H','O&M Offsite Direct Labor','O&M Labor Offsite STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','IRD','FA','82-01-18','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','IRD','FA','82-01-18','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','IRD','FB','82-01-11','82-01-1E','Labor - Cons Offsite IR&D','Labor - ConsOff IR&D STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','IRD','FB','82-01-11','82-01-1F','Labor - Cons Offsite IR&D','Labor - ConsOff IR&D STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','IRD','FC','82-01-02','82-01-0E','Labor - Cons Onsite IR&D','Labor - ConsOn IR&D STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','IRD','FC','82-01-02','82-01-0F','Labor - Cons Onsite IR&D','Labor - ConsOn IR&D STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','IRD','FF','82-01-10','82-01-1A','Labor - Off Site','Labor - Off Site STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','IRD','FF','82-01-10','82-01-1B','Labor - Off Site','Labor - Off Site STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','IRD','FK','82-01-35','82-01-3E','Labor - Indirect','Labor - Indirect STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','IRD','FK','82-01-35','82-01-3F','Labor - Indirect','Labor - Indirect STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','IRD','FN','82-01-01','82-01-0A','Labor - On Site','Labor - On Site STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','IRD','FN','82-01-01','82-01-0B','Labor - On Site','Labor - On Site STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','IRD','FP','82-01-35','82-01-3E','Labor - Indirect','Labor - Indirect STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','IRD','FP','82-01-35','82-01-3F','Labor - Indirect','Labor - Indirect STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','IRD','FV','82-01-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','IRD','FV','82-01-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','IRD','MM','82-01-16','82-01-1G','O&M Labor on IR&D','O&M Labor on IR&D STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','IRD','MM','82-01-16','82-01-1H','O&M Labor on IR&D','O&M Labor on IR&D STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','MOS','FA','71-01-18','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','MOS','FA','71-01-18','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','MOS','FB','71-01-11','71-01-1E','Labor - Cons Offsite BAE','Labor - ConsOff BAE STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','MOS','FB','71-01-11','71-01-1F','Labor - Cons Offsite BAE','Labor - ConsOff BAE STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','MOS','FC','71-01-02','71-01-0E','Labor - Cons Onsite BAE','Labor - ConsOn BAE STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','MOS','FC','71-01-02','71-01-0F','Labor - Cons Onsite BAE','Labor - ConsOn BAE STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','MOS','FF','71-01-10','71-01-1A','Labor - Off Site','Labor - Off Site STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','MOS','FF','71-01-10','71-01-1B','Labor - Off Site','Labor - Off Site STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','MOS','FK','71-01-25','71-01-2E','Labor - Office Services','Office Svcs Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','MOS','FK','71-01-25','71-01-2F','Labor - Office Services','Office Svcs Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','MOS','FN','71-01-01','71-01-0A','Labor - On Site','Labor - On Site STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','MOS','FN','71-01-01','71-01-0B','Labor - On Site','Labor - On Site STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','MOS','FP','71-01-20','71-01-2A','Labor - Occupancy','Labor - Occupancy STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','MOS','FP','71-01-20','71-01-2B','Labor - Occupancy','Labor - Occupancy STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','MOS','FV','71-01-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','MOS','FV','71-01-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','MOS','MM','71-01-16','71-01-1G','O&M OH Labor for BAE','O&M OH Labor for BAE STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','MOS','MM','71-01-16','71-01-1H','O&M OH Labor for BAE','O&M OH Labor for BAE STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','NSO','FB','41-01-11','41-01-1E','Dir Labor- Cons Offsite','Direct Labor-ConsOff STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','NSO','FB','41-01-11','41-01-1F','Dir Labor- Cons Offsite','Direct Labor-ConsOff STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','NSO','FC','41-01-02','41-01-0E','Direct Labor- Cons Onsite','Direct Labor- ConsOn STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','NSO','FC','41-01-02','41-01-0F','Direct Labor- Cons Onsite','Direct Labor- ConsOn STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','NSO','FF','41-01-10','41-01-1A','Direct Labo-Tech Off Site','Direct Labor-TechOff STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','NSO','FF','41-01-10','41-01-1B','Direct Labo-Tech Off Site','Direct Labor-TechOff STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','NSO','FK','41-01-35','41-01-3E','Direct Labor - Other','Direct Labor - Other STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','NSO','FK','41-01-35','41-01-3F','Direct Labor - Other','Direct Labor - Other STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','NSO','FN','41-01-01','41-01-0A','Direct Labor-Tech On Site','Direct Labor-TechOn STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','NSO','FN','41-01-01','41-01-0B','Direct Labor-Tech On Site','Direct Labor-TechOn STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','NSO','FP','41-01-35','41-01-3E','Direct Labor - Other','Direct Labor - Other STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','NSO','FP','41-01-35','41-01-3F','Direct Labor - Other','Direct Labor - Other STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','NSO','FV','41-01-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','NSO','FV','41-01-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','NSO','MM','41-01-16','41-01-1G','O&M Offsite Direct Labor','O&M Labor Offsite STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','NSO','MM','41-01-16','41-01-1H','O&M Offsite Direct Labor','O&M Labor Offsite STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','OCC','FK','50-01-20','50-01-2A','Occupancy Labor','Occupancy Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','OCC','FK','50-01-20','50-01-2B','Occupancy Labor','Occupancy Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','OCC','FP','50-01-20','50-01-2A','Occupancy Labor','Occupancy Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','OCC','FP','50-01-20','50-01-2B','Occupancy Labor','Occupancy Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','OSC','FK','51-01-25','51-01-2E','Office Services Labor','Office Svcs Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','OSC','FK','51-01-25','51-01-2F','Office Services Labor','Office Svcs Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','OSO','MM','41-01-16','41-01-1G','O&M Offsite Direct Labor','O&M Labor Offsite STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','OSO','MM','41-01-16','41-01-1H','O&M Offsite Direct Labor','O&M Labor Offsite STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','PSO','FB','41-01-11','41-01-1E','Dir Labor- Cons Offsite','Direct Labor-ConsOff STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','PSO','FB','41-01-11','41-01-1F','Dir Labor- Cons Offsite','Direct Labor-ConsOff STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','PSO','FC','41-01-02','41-01-0E','Direct Labor- Cons Onsite','Direct Labor- ConsOn STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','PSO','FC','41-01-02','41-01-0F','Direct Labor- Cons Onsite','Direct Labor- ConsOn STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','PSO','FF','41-01-10','41-01-1A','Direct Labo-Tech Off Site','Direct Labor-TechOff STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','PSO','FF','41-01-10','41-01-1B','Direct Labo-Tech Off Site','Direct Labor-TechOff STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','PSO','FK','41-01-35','41-01-3E','Direct Labor - Other','Direct Labor - Other STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','PSO','FK','41-01-35','41-01-3F','Direct Labor - Other','Direct Labor - Other STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','PSO','FN','41-01-01','41-01-0A','Direct Labor-Tech On Site','Direct Labor-TechOn STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','PSO','FN','41-01-01','41-01-0B','Direct Labor-Tech On Site','Direct Labor-TechOn STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','PSO','FP','41-01-35','41-01-3E','Direct Labor - Other','Direct Labor - Other STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','PSO','FP','41-01-35','41-01-3F','Direct Labor - Other','Direct Labor - Other STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','PSO','FV','41-01-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','PSO','FV','41-01-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','PSO','MM','41-01-16','41-01-1G','O&M Offsite Direct Labor','O&M Labor Offsite STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','PSO','MM','41-01-16','41-01-1H','O&M Offsite Direct Labor','O&M Labor Offsite STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U40','FA','41-81-18','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U40','FA','41-81-18','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U40','FB','41-81-11','41-81-1E','UA Dir Lab - Cons Offsite','UA Dir Lab-ConsOff STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U40','FB','41-81-11','41-81-1F','UA Dir Lab - Cons Offsite','UA Dir Lab-ConsOff STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U40','FC','41-81-02','41-81-0E','UA Dir Lab - Cons Onsite','UA Dir Labor-ConsOn STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U40','FC','41-81-02','41-81-0F','UA Dir Lab - Cons Onsite','UA Dir Labor-ConsOn STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U40','FF','41-81-10','41-81-1A','UA Direct Lab-TechOf Site','UA Dir Lab-TechOff STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U40','FF','41-81-10','41-81-1B','UA Direct Lab-TechOf Site','UA Dir Lab-TechOff STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U40','FK','41-81-35','41-81-3E','UA Direct Labor - Other','UA Dir Labor - Other STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U40','FK','41-81-35','41-81-3F','UA Direct Labor - Other','UA Dir Labor - Other STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U40','FN','41-81-01','41-81-0A','UA Direct Lab-TechOn Site','UA Dir Lab-TechOn STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U40','FN','41-81-01','41-81-0B','UA Direct Lab-TechOn Site','UA Dir Lab-TechOn STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U40','FP','41-81-35','41-81-3E','UA Direct Labor - Other','UA Dir Labor - Other STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U40','FP','41-81-35','41-81-3F','UA Direct Labor - Other','UA Dir Labor - Other STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U40','FV','41-81-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U40','FV','41-81-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U40','MM','41-81-16','41-81-1G','UA O&M Offsite Labor','UA O&M Offsite Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U40','MM','41-81-16','41-81-1H','UA O&M Offsite Labor','UA O&M Offsite Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U50','FK','50-81-20','50-81-2A','UA Occupancy Labor','UA Occupancy Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U50','FK','50-81-20','50-81-2B','UA Occupancy Labor','UA Occupancy Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U50','FP','50-81-20','50-81-2A','UA Occupancy Labor','UA Occupancy Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U50','FP','50-81-20','50-81-2B','UA Occupancy Labor','UA Occupancy Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U51','FK','51-81-25','51-81-2E','UA Office Svcs Labor','UA Office Svcs Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U51','FK','51-81-25','51-81-2F','UA Office Svcs Labor','UA Office Svcs Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U52','FA','52-81-30','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U52','FA','52-81-30','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U52','FB','52-81-30','52-81-3A','UA General Works Labor','UA Gen Works Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U52','FB','52-81-30','52-81-3B','UA General Works Labor','UA Gen Works Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U52','FC','52-81-30','52-81-3A','UA General Works Labor','UA Gen Works Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U52','FC','52-81-30','52-81-3B','UA General Works Labor','UA Gen Works Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U52','FF','52-81-30','52-81-3A','UA General Works Labor','UA Gen Works Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U52','FF','52-81-30','52-81-3B','UA General Works Labor','UA Gen Works Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U52','FK','52-81-30','52-81-3A','UA General Works Labor','UA Gen Works Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U52','FK','52-81-30','52-81-3B','UA General Works Labor','UA Gen Works Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U52','FN','52-81-30','52-81-3A','UA General Works Labor','UA Gen Works Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U52','FN','52-81-30','52-81-3B','UA General Works Labor','UA Gen Works Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U52','FP','52-81-30','52-81-3A','UA General Works Labor','UA Gen Works Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U52','FP','52-81-30','52-81-3B','UA General Works Labor','UA Gen Works Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U52','FV','52-81-30','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U52','FV','52-81-30','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U52','FW','52-81-30','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U52','FW','52-81-30','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U52','MM','52-81-30','52-81-3A','UA General Works Labor','UA Gen Works Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U52','MM','52-81-30','52-81-3B','UA General Works Labor','UA Gen Works Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U60','FA','60-81-18','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U60','FA','60-81-18','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U60','FB','60-81-11','60-81-1E','UA Ind Labor-CNS Offsite','UA Ind Labor-ConsOff STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U60','FB','60-81-11','60-81-1F','UA Ind Labor-CNS Offsite','UA Ind Labor-ConsOff STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U60','FC','60-81-02','60-81-0E','UA Ind Labor-CNS Onsite','UA Labor-ConsOn STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U60','FC','60-81-02','60-81-0F','UA Ind Labor-CNS Onsite','UA Labor-ConsOn STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U60','FF','60-81-10','60-81-1A','UA Ind Labor-TechOff Site','UA Ind Labor-TechOff STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U60','FF','60-81-10','60-81-1B','UA Ind Labor-TechOff Site','UA Ind Labor-TechOff STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U60','FN','60-81-01','60-81-0A','UA Ind Labor-TechOn Site','UA Labor-TechOn Site STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U60','FN','60-81-01','60-81-0B','UA Ind Labor-TechOn Site','UA Labor-TechOn Site STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U60','FV','60-81-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U60','FV','60-81-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U60','MM','60-81-16','60-81-1G','UA O&M Offsite OH Labor','UA O&M Off OH Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U60','MM','60-81-16','60-81-1H','UA O&M Offsite OH Labor','UA O&M Off OH Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U70','FA','70-81-18','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U70','FA','70-81-18','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U70','FB','70-81-11','70-81-1E','UA Labor - Cons Offsite','UA Labor - ConsOff STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U70','FB','70-81-11','70-81-1F','UA Labor - Cons Offsite','UA Labor - ConsOff STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U70','FC','70-81-02','70-81-0E','UA Labor - Cons Onsite','UA Labor - ConsOn STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U70','FC','70-81-02','70-81-0F','UA Labor - Cons Onsite','UA Labor - ConsOn STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U70','FF','70-81-10','70-81-1A','UA Labor - Tech Offsite','UA Labor - TechOff STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U70','FF','70-81-10','70-81-1B','UA Labor - Tech Offsite','UA Labor - TechOff STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U70','FG','70-81-35','70-81-3E','UA G&A Labor','UA G&A Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U70','FG','70-81-35','70-81-3F','UA G&A Labor','UA G&A Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U70','FK','70-81-25','70-81-2E','UA Labor-Office Services','UA Office Svcs Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U70','FK','70-81-25','70-81-2F','UA Labor-Office Services','UA Office Svcs Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U70','FN','70-81-01','70-81-0A','UA Labor - Tech On Site','UA Labor-TechOn Site STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U70','FN','70-81-01','70-81-0B','UA Labor - Tech On Site','UA Labor-TechOn Site STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U70','FV','70-81-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U70','FV','70-81-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U70','MM','70-81-16','70-81-1G','UA O&M OH Lbr to G&A','UA O&M OH Lbr to G&A STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U70','MM','70-81-16','70-81-1H','UA O&M OH Lbr to G&A','UA O&M OH Lbr to G&A STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U71','FA','71-81-18','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U71','FA','71-81-18','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U71','FB','71-81-11','71-81-1E','UA Dir Lab - Cons Offsite','UA Dir Lab - ConsOff STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U71','FB','71-81-11','71-81-1F','UA Dir Lab - Cons Offsite','UA Dir Lab - ConsOff STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U71','FC','71-81-02','71-81-0E','UA Direct Lab-Cons Onsite','UA DirLab-ConsOn STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U71','FC','71-81-02','71-81-0F','UA Direct Lab-Cons Onsite','UA DirLab-ConsOn STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U71','FE','71-81-40','71-81-4A','UA BAE Labor','UA BAE Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U71','FE','71-81-40','71-81-4B','UA BAE Labor','UA BAE Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U71','FF','71-81-10','71-81-1A','UA Drect Lab-Tech Offsite','UA Drect Lab-TechOff STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U71','FF','71-81-10','71-81-1B','UA Drect Lab-Tech Offsite','UA Drect Lab-TechOff STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U71','FK','71-81-25','71-81-2E','Labor-Office Services UA','UA Office Svcs Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U71','FK','71-81-25','71-81-2F','Labor-Office Services UA','UA Office Svcs Labor STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U71','FN','71-81-01','71-81-0A','UA Direct Lab-Tech Onsite','UA DirLab-TechOn STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U71','FN','71-81-01','71-81-0B','UA Direct Lab-Tech Onsite','UA DirLab-TechOn STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U71','FP','71-81-20','71-81-2A','UA Labor - Occupancy','UA Labor - Occupancy STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U71','FP','71-81-20','71-81-2B','UA Labor - Occupancy','UA Labor - Occupancy STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U71','FV','71-81-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U71','FV','71-81-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U71','MM','71-81-16','71-81-1G','UA O&M Offsite Lbr to BAE','UA O&M Lbr to BAE STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U71','MM','71-81-16','71-81-1H','UA O&M Offsite Lbr to BAE','UA O&M Lbr to BAE STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U73','0Q','73-81-50','73-81-5A','Home Office Labor','Home Office Labor - STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U73','0Q','73-81-50','73-81-5B','Home Office Labor','Home Office Labor - STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','U73','1Q','73-81-50','73-81-5A','Home Office Labor','Home Office Labor - STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','U73','1Q','73-81-50','73-81-5B','Home Office Labor','Home Office Labor - STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','UNB','FA','41-01-18','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','UNB','FA','41-01-18','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','UNB','FB','41-01-11','41-01-1E','Dir Labor- Cons Offsite','Direct Labor-ConsOff STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','UNB','FB','41-01-11','41-01-1F','Dir Labor- Cons Offsite','Direct Labor-ConsOff STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','UNB','FC','41-01-02','41-01-0E','Direct Labor- Cons Onsite','Direct Labor- ConsOn STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','UNB','FC','41-01-02','41-01-0F','Direct Labor- Cons Onsite','Direct Labor- ConsOn STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','UNB','FF','41-01-10','41-01-1A','Direct Labo-Tech Off Site','Direct Labor-TechOff STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','UNB','FF','41-01-10','41-01-1B','Direct Labo-Tech Off Site','Direct Labor-TechOff STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','UNB','FK','41-01-35','41-01-3E','Direct Labor - Other','Direct Labor - Other STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','UNB','FK','41-01-35','41-01-3F','Direct Labor - Other','Direct Labor - Other STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','UNB','FN','41-01-01','41-01-0A','Direct Labor-Tech On Site','Direct Labor-TechOn STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','UNB','FN','41-01-01','41-01-0B','Direct Labor-Tech On Site','Direct Labor-TechOn STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','UNB','FP','41-01-35','41-01-3E','Direct Labor - Other','Direct Labor - Other STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','UNB','FP','41-01-35','41-01-3F','Direct Labor - Other','Direct Labor - Other STW','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','UNB','FV','41-01-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','UNB','FV','41-01-15','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','UNB','MM','41-01-16','41-01-1G','O&M Offsite Direct Labor','O&M Labor Offsite STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','UNB','MM','41-01-16','41-01-1H','O&M Offsite Direct Labor','O&M Labor Offsite STW','1','imapsprd', current_timestamp
 
go


--new accounts from Sean
 /*
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','GWA','FW','52-01-30','??-??-??','','','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','GWA','FW','52-01-30','??-??-??','','','1','imapsprd', current_timestamp
*/

go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STB','GWA','FW','52-01-30','52-01-3A','General Works Labor','General Works Labor STB','1','imapsprd', current_timestamp
 
go
insert into XX_PAY_TYPE_ACCT_MAP
(PAY_TYPE, ACCT_GRP_CD, LAB_GRP_TYPE, REG_ACCT_ID, STB_ACCT_ID, REG_ACCT_NAME, STB_ACCT_NAME, COMPANY_ID, CREATED_BY, TIME_STAMP)
select 'STW','GWA','FW','52-01-30','52-01-3B','General Works Labor','General Works Labor STW','1','imapsprd', current_timestamp
 
go
