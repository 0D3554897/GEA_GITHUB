
@echo off
for /F %%i in (CERIS_tbl_compilation_order.txt) do type %%i >> CERIS_tbl_onefile.sql