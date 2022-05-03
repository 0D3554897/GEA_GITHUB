-- Added CR-1333/Cr-1335
Use IMAPSStg
go
alter table xx_util_lab_out 
add acct_grp_cd varchar(3)
go



alter table xx_util_lab_out_arch
 add acct_grp_cd varchar(3)

go