rem this batch file is run from top level, ie where java folder resides
cls
d:
cd \
cd apps_to_compile
cd csv2db
del build.log /f /q

rem lazy way to avoid jumping back and forth between folders when updating code
rem requires that java source file is at same level as java folder
copy /y csv2db.java d:\apps_to_compile\csv2db\java\com\ibm\imapsstg\*.*



set JAVA_HOME=D:\ibmjavasdk16\bin
SET PATH=D:\ibmjavasdk16\bin\;%PATH%
set JAVACMD=
set ANT_HOME=D:\ant\

GO
%ANT_HOME%bin\ant.bat -v clean csv2db > build.log

find /c "BUILD SUCCESSFUL" build.log
if errorlevel equ 1 goto notfound
pause BUILD SUCCESSFUL
goto done
:notfound
pause BUILD UNSUCCESSFUL
goto done
:done
