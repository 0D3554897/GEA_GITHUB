USE [IMAPSStg]
GO
/****** Object:  StoredProcedure [dbo].[XX_RETRORATE_REMOVE_OBD_FOR_YEAR_DELETE_DOU_NONCOST_SP]    Script Date: 10/24/2007 07:47:55 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

IF EXISTS (SELECT * FROM DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'[DBO].[XX_RETRORATE_REMOVE_OBD_FOR_YEAR_DELETE_DOU_NONCOST_SP]') AND OBJECTPROPERTY(ID, N'ISPROCEDURE') = 1)
DROP PROCEDURE [DBO].[XX_RETRORATE_REMOVE_OBD_FOR_YEAR_DELETE_DOU_NONCOST_SP]
GO

