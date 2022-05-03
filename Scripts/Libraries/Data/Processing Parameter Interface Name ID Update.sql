update	imapsstg.dbo.xx_processing_parameters
set 	INTERFACE_NAME_ID = l.LOOKUP_ID
from 	imapsstg.dbo.xx_processing_parameters p
inner join
	imapsstg.dbo.xx_lookup_detail l
on
(
	l.APPLICATION_CODE = p.INTERFACE_NAME_CD
)

GO