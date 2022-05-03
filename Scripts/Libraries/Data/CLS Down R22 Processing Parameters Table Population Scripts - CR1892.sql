use imapsstg



DECLARE @interface_name_id integer

SELECT @interface_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@interface_name_id, 'CLS_R22', 'DFLT_BALANCE_DIVISION', 'YA', SUSER_SNAME(), GETDATE())
GO



update xx_processing_parameters
set parameter_value='700'
where interface_name_cd='CLS_R22'
and parameter_name='DFLT_BALANCE_MAJOR'


update xx_processing_parameters
set parameter_value='9817'
where interface_name_cd='CLS_R22'
and parameter_name='DFLT_BALANCE_MINOR'


update xx_processing_parameters
set parameter_value='0000'
where interface_name_cd='CLS_R22'
and parameter_name='DFLT_BALANCE_SUBMINOR'



update xx_processing_parameters
set parameter_value='CSTPOI'
where interface_name_cd='CLS_R22'
and parameter_name='LERU_NUM'


