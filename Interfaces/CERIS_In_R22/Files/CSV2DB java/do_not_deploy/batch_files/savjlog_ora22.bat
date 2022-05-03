@echo off

rem ***************** get in position
d:
cd \
cd apps_to_compile
cd csv2db


rem ***************** make sure there's something to do
IF NOT EXIST %1 GOTO DONE

rem ***************** make sure there is a folder to put the file in
IF NOT EXIST ora_log md ora_log

rem ***************** check to see if this file is already archived, if so do nothing, if not create a copy with timestamp
FOR %%V IN (%1) DO FOR /F "tokens=1-5 delims=/: " %%J IN ("%%~tV") DO IF EXIST ..\csv2db\ora_log\o22_%%~nV%%L%%J%%K_%%M%%N%%~xV (ECHO Cannot rename %%V) ELSE (COPY /Y "%%V" o22_%%~nV%%L%%J%%K_%%M%%N%%~xV)

rem ***************** go to target folder and put the archive copy there
cd ora_log
COPY /Y ..\o22_*.* *.*

rem ***************** go to working folder, delete original and archive copies
cd ..

DEL /F /Q o22_*.*
DEL /F /Q %1

:DONE
ECHO ON
