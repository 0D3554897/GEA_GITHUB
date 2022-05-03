@echo off
cls
rem ****************************************************************************************
rem Check a file to see if it is reasonably current
rem USAGE: isit_current filename #number_of_minutes_elapsed
rem EXAMPLE: isit_current testfile_pass.txt 2 
rem does the file exist?
rem is it less than two minutes old?
rem if both yes, success!
rem if either no, failure!
rem ****************************************************************************************
rem ****************************************************************************************
echo *****************************
echo  isit_current test execution
echo *****************************

echo File: %1
echo Limit: %2

rem ****************************************************************************************
rem Format the current time to prepare for comparison
rem ****************************************************************************************
rem echo off
REM set the hour to 2 digits system time
REM multiply hour * 60
REM add the minutes to get a feel for the time now

    setlocal enableextensions

    call :get12h hour
    echo System hour returned from function: %hour%

    set /A hr=%hour%*60
    rem echo %time%
    set tm=%time%
    
    rem what if minutes start with a zero?  
    rem dos will think it is HEX
    rem solution: got to go to single digit

    set tmtest=%tm:~3,1%
    if "%tmtest%" equ "0" (
      set tm=%tm:~4,1%
    ) else (
      set tm=%tm:~3,2%
    )    
    set /A sum_hr_tm=%hr% + %tm%

    rem echo This the hour: %hr% this is the time: %tm%
    echo this is the sytem time sum: %sum_hr_tm%

    rem exit /b  -- only for testing


rem ****************************************************************************************
rem ****************************************************************************************

ECHO *******************************************
ECHO 4 TESTS TO MAKE SURE FILE CREATION WORKED
ECHO *******************************************
ECHO  

rem ****************************************************************************************
rem First test - Does the target file exist?  Target file must be supplied in execution line
rem ****************************************************************************************
ECHO *****************
echo 1. EXISTENCE TEST
ECHO *****************

REM check to see if file exists, return error if not
echo Testing for existence of target file: %1

rem *****************************************************
rem two lines for testing - to create a current file
rem del %1
rem echo hello > %1
rem *****************************************************

REM if the file exists then don't exit, check date next:
    if exist %1 (
	ECHO *******************************************
        echo PASSED 1. Target file exists
	ECHO *******************************************
    ) else (
REM if the file doesn't exist, exit with error code 1:  
	ECHO *******************************************  
        echo FAILED 1. Target file does not exist
	ECHO *******************************************
        exit /B 1
    )
rem ****************************************************************************************
rem ****************************************************************************************


rem ****************************************************************************************
rem Second test -is file from today 
rem ****************************************************************************************
rem Get last modification date of the file.
ECHO ****************
echo 2. CUR DATE TEST
ECHO ****************

for %%I in ("%1") do set "FileDate=%%~tI"
echo File Date is : %FileDate%
set FileDt=%FileDate:~0,10%
set "DateTime=%DATE%
echo Comparing File Date: %FileDate:~0,10% to Today: %DateTime:~4,13%

rem Compare the first 10 characters from file date string with the last
rem 10 characters from current local date hold in environment variable DATE.
if not "%FileDate:~0,10%" == "%DateTime:~4,10%" goto FileNotToday
ECHO *******************************************
echo PASSED 2. File was created today
ECHO *******************************************

rem ****************************************************************************************
rem Third test -compute elasped minutes Comparison value must be supplied in execution line
rem ****************************************************************************************
ECHO ****************
echo 3. CUR TIME TEST
ECHO ****************
echo Computing elapsed time in minutes since file creation
echo File Date_Time: %FileDate%
echo Date Time Now: %date% %time%
rem Get last modification time of the file
rem Luckily, all file time comes in same format
rem File Date_Time: 04/02/2020 10:02 PM
rem File Date_Time: 04/03/2020 09:02 AM

rem another consideration
rem what if file minutes start with a zero?  
rem dos will treat it as HEX in math
rem solution: got to go to single digit
set mintest=%FileDate:~14,1%
if "%mintest%" equ "0" (
  set FileMn=%FileDate:~15,1%
) else (
  set FileMn=%FileDate:~14,2%
)
set File24=%FileDate:~17,1%
echo File Minutes is %FileMn%


echo File24 is %File24%
if "%File24%" == "P" (
  goto addit
) else (
  goto setit
)


:addit
rem what if file hour starts with a zero?  
rem dos will treat it as HEX in math
rem solution: got to go to single digit
set hrtest=%FileDate:~11,1%
if "%hrtest%" equ "0" (
  set FileHora=%FileDate:~12,1%
) else (
  set FileHora=%FileDate:~11,2%
)    
echo FileHour in 12HR format: %FileHora%
set /A FileHr="%FileHora%+12"
echo File Hour converted to 24HR format: %FileHr%
goto compute_it

:setit
set FileHr=%FileDate:~11,2%
rem what if file hour starts with a zero?  
rem dos will treat it as HEX in math
rem solution: got to go to single digit
set hrtest=%FileDate:~11,1%
if "%hrtest%" equ "0" (
  set FileHr=%FileDate:~12,1%
) else (
  set FileHr=%FileDate:~11,2%
)    
echo File Hour already in 24HR format: %FileHr%

:compute_it
rem Compute elapsed
set /A FileHr=%FileHr%*60
set /A FileSum=%FileHr%+%FileMn%
echo File Time Sum is: %FileSum%
set /A elapsedtime=%sum_hr_tm% - %FileSum%
echo %elapsedtime% minutes have elapsed since the creation of the file


rem echo this is the sum for time: %sum_hr_tm%
rem echo this is the sum for file: %FileSum%

if %elapsedtime% gtr %2 (
	ECHO *******************************************
	echo FAILED 3. File is not current
	ECHO *******************************************
	exit /B 2
)
ECHO *******************************************
echo PASSED 3. File is current.
ECHO *******************************************

rem ****************************************************************************************
rem Fourth test -is filesize > 1
rem ****************************************************************************************
rem Get filesize
ECHO ****************
echo 4. FILESIZE TEST
ECHO ****************
for %%I in ("%1") do set "FileSize=%%~zI"
echo File Size is : %FileSize%
if %FileSize% leq 10 (
	ECHO ************************************
	echo FAILED 4: File has insufficient data
	ECHO ************************************
	exit /B 3
)

if %FileSize% gtr 10 (
	ECHO *******************************************
	echo PASSED 4. File size greater than 10 bytes
	echo ALL TESTS PASSED
	ECHO *******************************************
)
exit /b 0

:FileNotToday
ECHO *******************************************
echo FAILED 2. Target file not from this run
ECHO *******************************************
exit /B 1

:get12h outputVar
    setlocal enableextensions
    for /f "tokens=1 delims=: " %%a in ("%time: =0%") do set /a "h=1%%a-100"
	rem echo The system time is : %h%
	rem no need for 12 hour. 
    rem if %h% gtr 11 ( 
    rem    set "td=pm" & if %h% gtr 12 set /a "h-=12"
    rem ) else ( 
    rem    set "td=am" & if %h% equ 0 set "h=12"
    rem )
    endlocal & set "%~1=%h%" 

	