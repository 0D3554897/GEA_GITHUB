use imapsstg
ALTER TABLE xx_imaps_inv_out_sum ADD DIVISION CHAR(2)
GO

ALTER TABLE xx_imaps_invoice_sent ADD DIVISION CHAR(2)
GO

update xx_imaps_invoice_sent
set division = '16'

go


ALTER TABLE xx_cls_down_fds_reverse ADD DIVISION CHAR(2)
GO

update xx_cls_down_fds_reverse
set division = '16'

go

