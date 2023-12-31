--DEV00000243 Include Exclude Criteria data

INSERT INTO [dbo].[XX_FIWLR_INC_EXC]
	( MAJOR,MINOR,SUBMINOR,EXTRACT_TYPE)
VALUES  ( '610',NULL,NULL,'I');

INSERT INTO [dbo].[XX_FIWLR_INC_EXC]
	( MAJOR,MINOR,SUBMINOR,EXTRACT_TYPE)
VALUES  ( '638',NULL,NULL,'I');

INSERT INTO [dbo].[XX_FIWLR_INC_EXC]
	( MAJOR,MINOR,SUBMINOR,EXTRACT_TYPE)
VALUES  ( '816',NULL,NULL,'I');

INSERT INTO [dbo].[XX_FIWLR_INC_EXC]
	( MAJOR,MINOR,SUBMINOR,EXTRACT_TYPE)
VALUES  ( '817',NULL,NULL,'I');

INSERT INTO [dbo].[XX_FIWLR_INC_EXC]
	( MAJOR,MINOR,SUBMINOR,EXTRACT_TYPE)
VALUES  ( '820',NULL,NULL,'I');

INSERT INTO [dbo].[XX_FIWLR_INC_EXC]
	( MAJOR,MINOR,SUBMINOR,EXTRACT_TYPE)
VALUES  ( '902',NULL,NULL,'I');

INSERT INTO [dbo].[XX_FIWLR_INC_EXC]
	( MAJOR,MINOR,SUBMINOR,EXTRACT_TYPE)
VALUES  ( '903',NULL,NULL,'I');

INSERT INTO [dbo].[XX_FIWLR_INC_EXC]
	( MAJOR,MINOR,SUBMINOR,EXTRACT_TYPE)
VALUES  ( '920',NULL,NULL,'I');

INSERT INTO [dbo].[XX_FIWLR_INC_EXC]
	( MAJOR,MINOR,SUBMINOR,EXTRACT_TYPE)
VALUES  ( '925',NULL,NULL,'I');

INSERT INTO [dbo].[XX_FIWLR_INC_EXC]
	( MAJOR,MINOR,SUBMINOR,EXTRACT_TYPE)
VALUES  ( NULL,'8440',NULL,'E');

INSERT INTO [dbo].[XX_FIWLR_INC_EXC]
	( MAJOR,MINOR,SUBMINOR,EXTRACT_TYPE)
VALUES  ( NULL,'8122',NULL,'E');

--DEV00001721
INSERT INTO [dbo].[XX_FIWLR_INC_EXC]
	( MAJOR,MINOR,SUBMINOR,EXTRACT_TYPE)
VALUES  ( '624',NULL,NULL,'I');

--DEV00001246 FIWLR change the include/exclude to include Major 940

INSERT INTO [dbo].[XX_FIWLR_INC_EXC]
	( MAJOR,MINOR,SUBMINOR,EXTRACT_TYPE)
VALUES  ( '940',NULL,NULL,'I');

--DEV00000243 Source Group Mapping data

INSERT INTO [dbo].[XX_FIWLR_APSRC_GRP]
	( SOURCE,DESCRIPTION,CONTACT)
VALUES  ( '005','EXP REIMB SOLUTION','DESOUSA DOUG IBMUS');

INSERT INTO [dbo].[XX_FIWLR_APSRC_GRP]
	( SOURCE,DESCRIPTION,CONTACT)
VALUES  ( 'N16','BMS IW','NEIL RANCOUR');

INSERT INTO [dbo].[XX_FIWLR_APSRC_GRP]
	( SOURCE,DESCRIPTION,CONTACT)
VALUES  ( '032','LDS - IPT IN 952',NULL);

INSERT INTO [dbo].[XX_FIWLR_APSRC_GRP]
	( SOURCE,DESCRIPTION,CONTACT)
VALUES  ( '072','SAP','GEHRKENS GLE IBMUS');

INSERT INTO [dbo].[XX_FIWLR_APSRC_GRP]
	( SOURCE,DESCRIPTION,CONTACT)
VALUES  ( '074','A/R FILE MAINT  952',NULL);

INSERT INTO [dbo].[XX_FIWLR_APSRC_GRP]
	( SOURCE,DESCRIPTION,CONTACT)
VALUES  ( '944','A/P - SAP GENERAL PRO 952','FARR ANN IBMUS');

INSERT INTO [dbo].[XX_FIWLR_APSRC_GRP]
	( SOURCE,DESCRIPTION,CONTACT)
VALUES  ( '945','CIBS - COMMON INTRA-COMPANY BILLING SYSTEM', 'VATMAN ANNA LOTUS');

--DEV00000243 Update Processing Parameters data

DELETE FROM dbo.XX_PROCESSING_PARAMETERS
WHERE PARAMETER_NAME = 'FIWLR_PROC_WERVER_ID'

declare @int_name_id int
select @int_name_id= PRESENTATION_ORDER
from dbo.XX_LOOKUP_DETAIL
where APPLICATION_CODE = 'FIWLR'
INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@int_name_id, 'FIWLR', 'FIWLR_PROC_SERVER_ID', ' ', SUSER_SNAME(), GETDATE())
go