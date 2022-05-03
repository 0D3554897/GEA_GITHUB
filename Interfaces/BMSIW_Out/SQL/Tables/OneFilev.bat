
@echo off
for /F %%i in (BMS_IW_tbl_compilation_order.txt) do type %%i >> BMS_IW_tbl_onefile.sql