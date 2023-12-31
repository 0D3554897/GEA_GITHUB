


--CR4663
DECLARE @INTERFACE_NAME_ID integer

SELECT @INTERFACE_NAME_ID = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t2.APPLICATION_CODE = 'FIWLR_R22'


INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@INTERFACE_NAME_ID, 'FIWLR_R22', '22_ORG_ID_default', '22.W.G.GD.KHSF', SUSER_SNAME(), GETDATE())

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@INTERFACE_NAME_ID, 'FIWLR_R22', 'YA_ORG_ID_default', '22.W.G.GD.KHSF', SUSER_SNAME(), GETDATE())

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@INTERFACE_NAME_ID, 'FIWLR_R22', 'SR_ORG_ID_default', '22.A.K.K0.KK01', SUSER_SNAME(), GETDATE())

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@INTERFACE_NAME_ID, 'FIWLR_R22', 'YB_ORG_ID_default', '22.Z', SUSER_SNAME(), GETDATE())

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@INTERFACE_NAME_ID, 'FIWLR_R22', '22_ORG_ABBRV_CD_default', 'HSF', SUSER_SNAME(), GETDATE())

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@INTERFACE_NAME_ID, 'FIWLR_R22', 'YA_ORG_ABBRV_CD_default', 'HSF', SUSER_SNAME(), GETDATE())

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@INTERFACE_NAME_ID, 'FIWLR_R22', 'SR_ORG_ABBRV_CD_default', 'K01', SUSER_SNAME(), GETDATE())

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@INTERFACE_NAME_ID, 'FIWLR_R22', 'YB_ORG_ABBRV_CD_default', '22.Z', SUSER_SNAME(), GETDATE())


/*
select *
from imar.deltek.org
where org_id in ('22.W.G.GD.KHSF','22.A.K.K0.KK01','22.Z' )

select parameter_name, parameter_value
from xx_processing_parameters
where interface_name_cd='FIWLR_R22'
*/
