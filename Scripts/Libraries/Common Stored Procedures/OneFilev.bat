
@echo off

for /F %%i in (Common_SP_compilation_order.txt) do type %%i >>Common_SP_onefile.sql
