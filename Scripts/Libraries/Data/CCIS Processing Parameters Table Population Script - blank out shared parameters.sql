use imapsstg

update xx_processing_parameters
set parameter_value=''
where interface_name_cd='AR_COLLECTION'
and parameter_name in ('IN_USER_NAME', 'IN_USER_PASSWORD') 

