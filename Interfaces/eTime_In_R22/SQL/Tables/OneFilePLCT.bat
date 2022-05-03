
@echo off
for /F %%i in (PLC_R22_TBL_compilation_order.txt) do type %%i >> PLC_R22_tbl_onefile.sql