package com.ibm.imapsstg;
import java.math.BigDecimal;

import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.io.BufferedWriter;
import java.io.FileWriter;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.Statement;
import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Properties;
import java.util.StringTokenizer;

import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;

import org.apache.commons.cli.BasicParser;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.Options;
import org.apache.commons.mail.SimpleEmail;
import org.apache.log4j.FileAppender;
import org.apache.log4j.Level;
import org.apache.log4j.Logger;
import org.apache.log4j.PatternLayout;

/*
import au.com.bytecode.opencsv.CSVReader;
import com.ibm.imapsstg.util.Util;


import com.ibm.imapsstg.util.ExcelBuilder;
import com.ibm.imapsstg.util.MailTool;

*/


/*

import java_cup.runtime.Scanner;
import crypto.AESCrypto; */

/*
* This program is a command line utility writes a file in either ASCII or EBCDIC encoding
*   and includes content queried from a database.
*
*   Logging
*   ======== 
*   The program provides a log file (using Log4J) to record a time-stamped trace
*   of most activities performed by the program. The extent of logging is 
*   controlled from the command line where:
*
*	#level 0 - logs only the start of each subroutine
*	#level 1 - logs the start of each subroutine and the start of each major step
*	#level 2 - logs the start of each subroutine and the start and end of each major step
*	#level 3 - logs all of the above plus item by item detail for each line in the load file
*				 as well as verbose detail about variables during execution. Use for debugging.
*   
*   The logfile is specified on the command line as is the debug level. 
*
*  The program supports the following command line parameters as flags to control
*  which subset of processing is requested during a particular invocation. Note that multiple
*  switches can be used in a single invocation; the order of execution follows the list
*  below.  Additional libraries are compiled into the program for easy inclusion in the future,
*  such as MAIL and FTP.
*  
*  -readdb 	  Load and process a clear text file so that data is loaded into staging table
*  -          More options can be added at a later time.
*  
*  Additionally, the program requires two standard Java properties files for all external
*  configuration information. One, the credentials file, contains JDBC connection info, 
*  FTP connection info, and Mail connection info, including user names and passwords. 
*  This information is segregated to allow for easy configuration of different environments
*  as well as enhancing security by allowing placement in restricted locations on the server.
*  The second, a properties file, contains specific instructions, including SQLstatements 
*  used to interact with the database, to create the desired file. The path to each properties
*  file must be included on the command line.  An example of how to execute appears below. 
*  Substitutable items appear in all caps:
*
*  java.exe -D user.dir=\LOGPATH -cp \CLASSPATH; \LIBPATH\activation.jar;\LIBPATH\commons-cli-1.0.jar;\LIBPATH\commons-email-1.1.jar;\LIBPATH\mail.jar;\LIBPATH\commons-net-1.4.1.jar;\LIBPATH\commonslog4j-1.2.9.jar;\LIBPATH\opencsv-1.8.jar;\LIBPATH\sqljdbc4.jar; com.ibm.imapsstg.ftp_chk -ftplog d:\path\filename -phrase 250_Transfer_Successful -cnt 2 -logfile d:\path\filename -debug 0 
*  Modification
*  ============
*  CR - # goes here   
*  Changes are described in a list here:
*  
*  D:\IMAPS_Data\Interfaces\Programs\Java\ftp_chk\ftp_chk.bat GLIM D:\IMAPS_DATA\Interfaces\LOGS\GLIM/GLIM_FTP_LOG.txt 2 "250 Transfer Completed"	-- the FTP log must have a forward slash as its last folder delimiting character  
* 

*/
public class ftp_chk {
	
	private static HashMap props = new HashMap();	
	private static int        linecount  = 0;
	private static Logger     appLogger  = null;
		
	private static String ftpFile  = "unknown";
	private static String ftpdir  = "unknown";
	private static String aPhrase  = "unknown";
	private static String phraseMsg ="unknown";
	private static Integer phraseCnt = 0;
	private static String javaLog  = "unknown";
	private static String logdir = "unknown";
	private static int dbg = 0;
	
    private static String debugmarker = "init";	


	/* 
	* initialize the Log4J logger to log into the current working directory. Called from
	* main() entry point. Get log filename from command line switch
	*/
	private static void setupLogger(String[] arg) throws Exception {
		
		
		Options logoption = new Options();
/*		
		example:logoption.addOption("logfile",true,"specify log filename");
		-- true or false = required or optional
		
		-ftplog d:\path\filename -phrase 250_Transfer_Successful -cnt 2 -logfile d:\path\filename -debug 0		
*/
     	logoption.addOption("ftplog",true,"ftp log file path");
		logoption.addOption("phrase",true,"exact search term");
		logoption.addOption("cnt",true,"number of search terms you want to find");
		logoption.addOption("logfile",true,"get records from SQL db");		
		logoption.addOption("debug",true,"specify 0,1,2,or 3. See properties file.");

		CommandLineParser parseit = new BasicParser();
		CommandLine cmnd = parseit.parse(logoption, arg);	
		if (cmnd.hasOption("ftplog")) {
			//System.out.println("before get");
			ftpFile = cmnd.getOptionValue("ftplog");
			//System.out.println("after :" +ftpFile);
		}			
		if (cmnd.hasOption("phrase")) {
			aPhrase = cmnd.getOptionValue("phrase");
		}
		if (cmnd.hasOption("cnt")) {
			phraseCnt = Integer.parseInt(cmnd.getOptionValue("cnt"));
		}
		if (cmnd.hasOption("logfile")) {
			javaLog = cmnd.getOptionValue("logfile");
		}
		if (cmnd.hasOption("debug")) {
			dbg = Integer.parseInt(cmnd.getOptionValue("debug"));	
		}		
		

		ftpdir = ftpFile.substring(0, ftpFile.lastIndexOf( '/' ));		
		logdir  = javaLog.substring(0, javaLog.lastIndexOf( '/' ));
		//logdir = logdir.replaceAll("/","\\");
		javaLog = javaLog.substring(javaLog.lastIndexOf( '/' )+1, javaLog.length());
		File   logfile = new File(logdir, javaLog);
		
		Logger rootLogger = Logger.getRootLogger();
		if (!rootLogger.getAllAppenders().hasMoreElements()) {		
			rootLogger.setLevel(Level.INFO);
			FileAppender appender = new FileAppender();
			appender.setFile(logfile.getAbsolutePath(), true, false, 0);
			appender.setLayout(new PatternLayout("%d{MM/dd/yy HH:mm:ss.SSS} %15t %-30c %m%n"));
			rootLogger.addAppender(appender);	
			appLogger = rootLogger.getLoggerRepository().getLogger("com.ibm.imaps");
			appLogger.setLevel(Level.DEBUG);
		}
		appLogger.debug("Log begins here. File name is " + javaLog + ".");
	}
	


	public static void main(String[] args) {
		
		try {
			setupLogger(args);
		} catch (Exception e) {
			e.printStackTrace();
		}


		
		appLogger.debug("Executing Function: Main -arguments passed are:");
		for (String element:args ) {
			appLogger.debug( element );
		} 
		appLogger.debug("All five -arguments listed above must hava a valid value shown below them!");
		appLogger.debug("If they do not, the program will end successfully, but without results.");
		appLogger.debug("---------------------------------");
		try {
			
			if(dbg>0) appLogger.info("------- Begin execution --------");
			
			//appLogger.info(args.length);	
			
			if (args.length == 0) throw new Exception ("No arguments supplied.");
			
			BufferedReader br = null;
			String strLine = "";
			Integer howMany=0;
			Integer iFound=0;
			Integer lNumber=0;
			
			try {
				br = new BufferedReader( new FileReader(ftpFile));
				appLogger.debug("Searching for " + aPhrase);
				while( (strLine = br.readLine()) != null){
					lNumber = lNumber + 1;
					if(dbg>2) appLogger.debug("Line " + Integer.toString(lNumber) + " is: " + strLine);
					//System.out.println(strLine);
					iFound=strLine.indexOf(aPhrase);
					if(iFound>=0) {
						appLogger.info(aPhrase + " found! : " + strLine);
						howMany=howMany+1;
					}
				//appLogger.info(howMany);	
				}
				if(howMany==phraseCnt){
						strLine = "0";
						phraseMsg = "SUCCESS! ";
				}else{
						strLine = "562";
						phraseMsg = "FAILURE! ";
				}
					try {

						String content = phraseMsg + "Search Phrase is: ==> " + aPhrase + " <== Number of occurrences desired: " + phraseCnt.toString() + "; Number found: " + howMany.toString() + "; FTP log file: " + ftpFile;
						appLogger.info ("file name is : " + ftpdir + "/" + strLine + ".ftp");
						File file = new  File(ftpdir + "/" +strLine + ".ftp");
						// if file doesnt exist, then create it
						if (!file.exists()) {
							file.createNewFile();
						}
						FileWriter fw = new FileWriter(file.getAbsoluteFile());
						BufferedWriter bw = new BufferedWriter(fw);
						bw.write(content);
						bw.close();
						//System.out.println("Done");
					} catch (IOException e) {
						e.printStackTrace();
					}			
				
			} catch (FileNotFoundException e) {
				System.err.println("Unable to find the ftp log : " + ftpFile);
			} catch (IOException e) {
				System.err.println("Unable to read the ftp log : " + ftpFile);
			}



			appLogger.info("------- Execution Finished Successfully--------");
		}
		catch (Exception e) {
			StringWriter sw = new StringWriter();      
			e.printStackTrace(new PrintWriter(sw));		
			appLogger.error(sw.toString());
			appLogger.info("------- Execution Finished Unsuccessfully--------");
		}
	}

	
}

