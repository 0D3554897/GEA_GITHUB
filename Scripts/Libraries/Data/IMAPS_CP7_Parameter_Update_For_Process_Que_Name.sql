use imapsstg

--update queue parameter name to be INTERFACES
update xx_processing_parameters
set parameter_value='INTERFACES'
where parameter_name like '%PROC_QUE%'
and interface_name_cd not like '%R22'

