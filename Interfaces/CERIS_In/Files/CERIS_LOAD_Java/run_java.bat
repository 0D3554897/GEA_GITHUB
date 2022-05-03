set CERIS_IMAPS_HOME="C:\Users\IBM_ADMIN\Desktop\ActualRates\IMAPS CERIS\changes\Files\CERIS_LOAD_Java"
set INTERFACE_PROTECTED_PROP="C:\Users\IBM_ADMIN\Desktop\ActualRates\IMAPS CERIS\changes\Files\CERIS_LOAD_Java"
java -cp %CERIS_IMAPS_HOME%\classes;%CERIS_IMAPS_HOME%\libs\commons-io-1.4.jar;%CERIS_IMAPS_HOME%\libs\commons-net-1.4.1.jar;%CERIS_IMAPS_HOME%\libs\commons-logging-1.1.1.jar;%CERIS_IMAPS_HOME%\libs\log4j-1.2.9.jar;%CERIS_IMAPS_HOME%\libs\sqljdbc.jar; com.ibm.imaps.FixedFileReader %INTERFACE_PROTECTED_PROP%\runtime.properties

