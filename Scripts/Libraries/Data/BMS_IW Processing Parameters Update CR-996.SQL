use imapsstg
go
update dbo.XX_PROCESSING_PARAMETERS
set parameter_value='BMSIWT.WWUTIL.API.PUB.R00002.INPUT'
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = 'BMS_IW'
AND	PARAMETER_NAME = 'FTP_DEST_FILE'
go

-- For Development only Please change values for Integration
-- SIT=BMSIWG.WWUTIL.API.PUB.R00002.INPUT
-- PROD=BMSIWP.WWUTIL.API.PUB.R00002.INPUT
update dbo.XX_PROCESSING_PARAMETERS
set parameter_value='\\ffx23dap56\interfaces\PROCESS\bms_iw\BMSIWT.WWUTIL.API.PUB.R00002.INPUT' -- Replace value for INT and PROD
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = 'BMS_IW'
AND	PARAMETER_NAME = 'FTP_FILE'
go



-- For Development only Please change values for Integration

update dbo.XX_PROCESSING_PARAMETERS
set parameter_value='LIZM' 		-- Replace value for INT and PROD
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = 'BMS_IW'
AND	PARAMETER_NAME = 'FTP_USER'
go

-- For Development only Please change values for Integration

update dbo.XX_PROCESSING_PARAMETERS
set parameter_value='ucand0it'		-- Replace value for INT and PROD
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = 'BMS_IW'
AND	PARAMETER_NAME = 'FTP_PASS'
go

-- For Development/SIT only Please change values for Prod
-- PROD=bldbmsa.boulder.ibm.com
update dbo.XX_PROCESSING_PARAMETERS
set parameter_value='bldbmsb.boulder.ibm.com'	-- Replace value for PROD
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = 'BMS_IW'
AND	PARAMETER_NAME = 'FTP_SERVER'
go

insert into dbo.XX_PROCESSING_PARAMETERS
(	INTERFACE_NAME_ID,
	INTERFACE_NAME_CD,
	PARAMETER_NAME,
	PARAMETER_VALUE,
	CREATED_BY,
	CREATED_DATE,
	MODIFIED_BY,
    MODIFIED_DATE)
SELECT 
	 2 INTERFACE_NAME_ID,
	'BMS_IW' INTERFACE_NAME_CD,
	'REJ_FILE' PARAMETER_NAME,
	'\\ffx23dap56\inbox\bmsiw\REJFILE.TXT' PARAMETER_VALUE,		-- Replace value for INT and PROD
	'imapsprd' CREATED_BY,
	getdate() CREATED_DATE,
	'imapsprd' MODIFIED_BY,
    getdate() MODIFIED_DATE
go

insert into dbo.XX_PROCESSING_PARAMETERS
(	INTERFACE_NAME_ID,
	INTERFACE_NAME_CD,
	PARAMETER_NAME,
	PARAMETER_VALUE,
	CREATED_BY,
	CREATED_DATE,
	MODIFIED_BY,
    MODIFIED_DATE)
SELECT 
	 2 INTERFACE_NAME_ID,
	'BMS_IW' INTERFACE_NAME_CD,
	'REJ_FRMT' PARAMETER_NAME,
	'\\ffx23dap56\interfaces\FORMAT\XX_BMS_IW_REJECT.FMT' PARAMETER_VALUE,	-- Replace value for INT and PROD
	'imapsprd' CREATED_BY,
	getdate() CREATED_DATE,
	'imapsprd' MODIFIED_BY,
    getdate() MODIFIED_DATE
go

