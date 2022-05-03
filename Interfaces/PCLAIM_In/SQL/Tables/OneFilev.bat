
@echo off
for /F %%i in (pclaim_tbl_list.txt) do type %%i >>pclaim_tbl_onefile.sql
