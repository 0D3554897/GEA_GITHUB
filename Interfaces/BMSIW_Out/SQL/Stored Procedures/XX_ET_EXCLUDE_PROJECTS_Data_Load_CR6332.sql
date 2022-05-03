-- Added CR-6332 02/17/14

USE IMAPSStg
go

insert into dbo.XX_ET_EXCLUDE_PROJECTS
values ('P1AD',getdate(),'Y')

insert into dbo.XX_ET_EXCLUDE_PROJECTS
values ('P1SD',getdate(),'Y')

insert into dbo.XX_ET_EXCLUDE_PROJECTS
values ('P1OD',getdate(),'Y')

insert into dbo.XX_ET_EXCLUDE_PROJECTS
values ('P1OX',getdate(),'Y')

insert into dbo.XX_ET_EXCLUDE_PROJECTS
values ('P1JD',getdate(),'Y')

insert into dbo.XX_ET_EXCLUDE_PROJECTS
values ('P1ML',getdate(),'Y')

go
