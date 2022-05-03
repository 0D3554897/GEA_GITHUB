USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_R22_CERIS_ASSIGNMENT_STG]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
   DROP TABLE [dbo].[XX_R22_CERIS_ASSIGNMENT_STG]
GO

CREATE TABLE [dbo].[XX_R22_CERIS_ASSIGNMENT_STG](
    [PSEUDO_EMPL_ID]    [varchar](12)  NOT NULL,
    [ASSIGNMENT]        [varchar](5)   NOT NULL,
    [ASSIGNMENT_TYPE]   [varchar](5)   NOT NULL,
    [START_DT]          [datetime]     NOT NULL,
    [END_DT]            [datetime]     NOT NULL,
    [CREATED_BY]        [varchar](20)  NOT NULL DEFAULT (suser_sname()),
    [CREATED_DT]        [datetime]     NOT NULL DEFAULT (getdate()),
    [MODIFIED_BY]       [varchar](20)  NULL     DEFAULT (suser_sname()),
    [MODIFIED_DT]       [datetime]     NULL     DEFAULT (getdate()),
    [REMARKS]           [varchar](200) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF