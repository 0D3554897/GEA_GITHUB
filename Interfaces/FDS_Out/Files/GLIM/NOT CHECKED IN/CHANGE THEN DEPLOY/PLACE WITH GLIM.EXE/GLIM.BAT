rem del /Q D:\APPS_TO_COMPILE\GLIM\GLIMLOG.TXT
rem del /Q D:\IMAPS_DATA\Interfaces\PROCESS\fds_ccs\IMAPFIW*.*

rem - the following commands create a verbose log file that slows down the process.  Use only to diagnose issues
rem D:\Progra~2\MacroS~1\msched.exe D:\apps_to_compile\GLIM\GLIM.SCP /conn_path=D:\APPS_TO_COMPILE\GLIM\GLIMCONN.ini /ini_file=D:\APPS_TO_COMPILE\GLIM\GLIMHDR.INI /logfile=D:\APPS_TO_COMPILE\GLIM\GLIMLOG.TXT
rem D:\Progra~2\MacroS~1\msched.exe D:\apps_to_compile\GLIM\GLIM.SCP /conn_path=D:\APPS_TO_COMPILE\GLIM\GLIMCONN.ini /ini_file=D:\APPS_TO_COMPILE\GLIM\GLIMTAX.INI /logfile=D:\APPS_TO_COMPILE\GLIM\GLIMLOG.TXT
rem D:\Progra~2\MacroS~1\msched.exe D:\apps_to_compile\GLIM\GLIM.SCP /conn_path=D:\APPS_TO_COMPILE\GLIM\GLIMCONN.ini /ini_file=D:\APPS_TO_COMPILE\GLIM\GLIMDTL.INI /logfile=D:\APPS_TO_COMPILE\GLIM\GLIMLOG.TXT
rem D:\Progra~2\MacroS~1\msched.exe D:\apps_to_compile\GLIM\GLIMPARM.SCP /conn_path=D:\APPS_TO_COMPILE\GLIM\GLIMCONN.ini /ini_path=D:\APPS_TO_COMPILE\GLIM\GLIMPARM.INI /logfile=D:\APPS_TO_COMPILE\GLIM\GLIMLOG.TXT

rem - use these commands under normal conditions
D:\Progra~2\MacroS~1\msched.exe D:\apps_to_compile\GLIM\GLIM.SCP /conn_path=D:\APPS_TO_COMPILE\GLIM\GLIMCONN.ini /ini_file=D:\APPS_TO_COMPILE\GLIM\GLIMHDR.INI
D:\Progra~2\MacroS~1\msched.exe D:\apps_to_compile\GLIM\GLIM.SCP /conn_path=D:\APPS_TO_COMPILE\GLIM\GLIMCONN.ini /ini_file=D:\APPS_TO_COMPILE\GLIM\GLIMTAX.INI
D:\Progra~2\MacroS~1\msched.exe D:\apps_to_compile\GLIM\GLIM.SCP /conn_path=D:\APPS_TO_COMPILE\GLIM\GLIMCONN.ini /ini_file=D:\APPS_TO_COMPILE\GLIM\GLIMDTL.INI
D:\Progra~2\MacroS~1\msched.exe D:\apps_to_compile\GLIM\GLIMPARM.SCP /conn_path=D:\APPS_TO_COMPILE\GLIM\GLIMCONN.ini /ini_path=D:\APPS_TO_COMPILE\GLIM\GLIMPARM.INI