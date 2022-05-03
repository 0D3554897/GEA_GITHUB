
@echo off
for /F %%i in (FDS_CCS_tbl_compilation_order.txt) do type %%i >> FDS_CCS_tbl_onefile.sql