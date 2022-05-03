@echo off

d:
cd \
cd apps_to_compile
cd csv2db
cd testdata

IF NOT EXIST %1 GOTO DONE

copy /Y %1 ..\*.*

cd ..

IF NOT EXIST arkive md arkive

IF EXIST 22_sql_workday.csv DEL /F /Q 22_sql_workday.csv
IF EXIST 22_ora_workday.csv DEL /F /Q 22_ora_workday.csv


FOR %%V IN (%1) DO FOR /F "tokens=1-5 delims=/: " %%J IN ("%%~tV") DO IF EXIST ..\csv2db\arkive\a_%%~nV%%L%%J%%K_%%M%%N%%~xV (ECHO Cannot rename %%V) ELSE (COPY /Y "%%V" a_%%~nV%%L%%J%%K_%%M%%N%%~xV)


cd arkive
COPY /Y ..\a_*.* *.*

CD ..
cd testdata

IF NOT EXIST 22_sql_workday.csv COPY /Y %1 22_sql_workday.csv
IF NOT EXIST 22_ora_workday.csv COPY /Y %1 22_ora_workday.csv
DEL /F /Q %1

cd ..

DEL /F /Q a_*.*
DEL /F /Q %1

:DONE
ECHO ON
