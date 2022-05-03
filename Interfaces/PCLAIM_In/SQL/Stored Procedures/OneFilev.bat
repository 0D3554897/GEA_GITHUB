
@echo off
for /F %%i in (PCLAIM_SP_compilation_order.txt) do type %%i >>pclaim_sp_onefile.sql
