cls
d:
cd \
cd apps_to_compile
cd cff
del build.log /f /q

rem lazy way to avoid jumping back and forth between folders when updating code
copy /y cff.java d:\apps_to_compile\cff\java\com\ibm\imapsstg\*.*



set JAVA_HOME=D:\ibmjavasdk16\bin
SET PATH=D:\ibmjavasdk16\bin\;%PATH%
set JAVACMD=
set ANT_HOME=D:\ant\

GO
%ANT_HOME%bin\ant.bat -v clean cff > build.log

find /c "BUILD SUCCESSFUL" build.log
if errorlevel equ 1 goto notfound
pause BUILD SUCCESSFUL
goto done
:notfound
pause BUILD UNSUCCESSFUL
goto done
:done
