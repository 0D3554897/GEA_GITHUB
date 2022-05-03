
@echo off
for /F %%i in (CCIS_tbl_compilation_order.txt) do type %%i >> CCIS_tbl_onefile.sql