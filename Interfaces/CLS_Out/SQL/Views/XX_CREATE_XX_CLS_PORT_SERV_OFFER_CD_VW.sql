USE [IMAPSStg]
GO

/****** Object:  View [dbo].[XX_CLS_PORT_SERV_OFFER_CD_VW]    Script Date: 7/14/2022 1:03:54 PM ******/
DROP VIEW [dbo].[XX_CLS_PORT_SERV_OFFER_CD_VW]
GO

/****** Object:  View [dbo].[XX_CLS_PORT_SERV_OFFER_CD_VW]    Script Date: 7/14/2022 1:03:54 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[XX_CLS_PORT_SERV_OFFER_CD_VW]
AS

 select * from port.dbo.xx_ref_serv_offer_code

GO


