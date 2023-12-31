/****** Object:  Table imapsstg.dbo.xx_mic_eocmap_inc_exc    Script Date: 12/07/2006 ******/

IF EXISTS (	SELECT 	* 
		FROM	dbo.sysobjects 
		WHERE 	id = object_id(N'imapsstg.dbo.xx_mic_eocmap_inc_exc') 
		AND	objectproperty (id, N'IsUserTable') = 1)

	DROP TABLE imapsstg.dbo.xx_mic_eocmap_inc_exc
GO

IF NOT EXISTS (	SELECT 	* 
		FROM	dbo.sysobjects 
		WHERE 	id = object_id(N'imapsstg.dbo.xx_mic_eocmap_inc_exc') 
		AND	objectproperty (id, N'IsUserTable') = 1)
BEGIN
	CREATE TABLE imapsstg.dbo.xx_mic_eocmap_inc_exc (
		eoc_map_cd	VARCHAR (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
		acct_id		VARCHAR (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
		eoc_cd		VARCHAR (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
		inc_exc		VARCHAR (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
		created_by	VARCHAR (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
		creation_date 	DATETIME NULL
		) ON [PRIMARY]
END
GO


