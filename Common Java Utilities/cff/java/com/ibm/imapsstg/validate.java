package com.ibm.imapsstg;
import java.math.BigDecimal;

import java.io.BufferedWriter;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileReader;
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

//import org.apache.logging.log4j.Appender;
//import org.apache.logging.log4j.Level;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
//import org.apache.logging.log4j.PatternLayout;

import au.com.bytecode.opencsv.CSVReader;

import com.ibm.imapsstg.util.ExcelBuilder;
import com.ibm.imapsstg.util.MailTool;
import com.ibm.imapsstg.util.Util;
/*import com.ibm.xslt4j.java_cup.runtime.Scanner;*/
import java_cup.runtime.Scanner;
import crypto.AESCrypto;

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
*  java.exe -D user.dir=\LOGPATH -cp \CLASSPATH; \LIBPATH\activation.jar;\LIBPATH\commons-cli-1.0.jar;\LIBPATH\commons-email-1.1.jar;\LIBPATH\mail.jar;\LIBPATH\commons-net-1.4.1.jar;\LIBPATH\commonslog4j-1.2.9.jar;\LIBPATH\opencsv-1.8.jar;\LIBPATH\sqljdbc4.jar; com.ibm.imapsstg.validate -readDB -props \PROPPATH\ANY.properties -creds\PROPPATH\ANY.credentials -logfile \LOGPATH\ANY.log -debug 0
*   
*  Modification
*  ============
*  CR - # goes here   
*  Changes are described in a list here:
*  
*  
* 

*/
public class validate {
	
	private static String[] propKeys = {
		// from credentials files	
		"ftp.host","ftp.user","ftp.pw",
		"db.driver","db.url","db.user","db.pw",
		"mail.host","mail.user","mail.pw","mail.addressee",
		//from properties file
		"log.filename","prod.debug",
		//"ftp.remote.filename","ftp.asc_file","ftp.ebc_file","ftp.archive.dir",  - now supplied as command line option
		"file.delimiter","file.enclosure","file.linestoskip","file.lfatend",
		"sql.query","sql.to_ebcdic","sql.ebcdic_columns",
	};
	
	private static HashMap props = new HashMap();	
	private static boolean    readDB     = false;
	private static int        linecount  = 0;
	//private static Logger     appLogger  = null;
	private static int 		  dbg = 0;
	
	private static String propsFileName  = "unknown";
	private static String credsFileName  = "unknown";
	private static String outFilePrefix  = "unknown";
	private static String fileName  = "unknown";
    private static String debugmarker = "init";	
	
	private static final String ASCII_Encoding = "US-ASCII";
	private static final String EBCDIC_Encoding = "Cp500";	
	private static ByteArrayOutputStream EBCDIC_OBJ;
	private static FileOutputStream EBCDIC_FILE;
	private static String ASCII_FileName = "D:\\apps_to_compile\\validate\\ASCII.TXT";
	private static String EBCDIC_FileName = "D:\\apps_to_compile\\validate\\PACKED.TXT";
	private static java.io.PrintWriter ASCII_FILEOBJ;
	private static BigDecimal packVal = new BigDecimal("000000000.00");


	/* 
	* initialize the Log4J logger to log into the current working directory. Called from
	* main() entry point. Get log filename from command line switch
	*/
	private static void setupLogger(String[] arg) throws Exception {
		
		Options logoption = new Options();
/*		
		logoption.addOption("logfile",true,"specify log filename");
		logoption.addOption("ftp",false,"send FTP to workday host");
		logoption.addOption("email",false,"send email when program completes");
		logoption.addOption("archive",false,"archive FTP file");
*/
     	logoption.addOption("props",true,"properties file path");
		logoption.addOption("creds",true,"credentials file path");
		logoption.addOption("outfile",true,"output file path");
		logoption.addOption("logfile",true,"java:worst.language.ever!");
		logoption.addOption("debug",true,"specify 0,1,2,or 3. See properties file.");
		logoption.addOption("readDB",false,"get records from SQL db");
		CommandLineParser parseit = new BasicParser();
		CommandLine cmnd = parseit.parse(logoption, arg);	
		if (cmnd.hasOption("logfile")) {
			fileName = cmnd.getOptionValue("logfile");
		}
		if (cmnd.hasOption("debug")) {
			dbg = Integer.parseInt(cmnd.getOptionValue("debug"));
		}		


		String workingDir = System.getProperty("user.dir");
		File   logdir  = new File(workingDir);
		File   logfile = new File(logdir, fileName);
		if(dbg>0) logger.debug("Validate Log begins here. File name is " + fileName + ".");


	}


	
	/* process the supplied command line and set internal flags based on 
	* the command line. Note that this logic uses the Apache Commons CLI library
	* (http://commons.apache.org/cli) to perform this processing.
	*/
	
	private static void processCommandLine(String[] args) throws Exception {
		
		if(dbg>0) logger.debug("Parsing Command Line ");
		Options options = new Options();
		
		//options.addOption("key",false,"request generation of encryption key (with store of key to DB");
		//options.addOption("loaddbenc",false,"load encrypted CERIS22 info from file into SQL db");
		//options.addOption("loaddb",false,"load CERIS16 info from file into SQL db"); 
		//options.addOption("serialxref",false,"generate and send serial number cross ref report");
      	//options.addOption("missingxref",false,"generate and send report of records with missing data");
		//options.addOption("ftp",false,"send FTP to workday host");
		//options.addOption("email",false,"send email when program completes");
		//options.addOption("archive",false,"archive FTP file");
		options.addOption("readDB",false,"get records from SQL db");
     	options.addOption("props",true,"properties file path");
		options.addOption("creds",true,"credentials file path");
		options.addOption("outfile",true,"output file path");
		options.addOption("logfile",true,"java:worst.language.ever!");
		options.addOption("debug",true,"specify 0,1,2,or 3. See properties file.");
		
		CommandLineParser parser = new BasicParser();
		CommandLine cmdLine = parser.parse(options, args);
/*	
		if (cmdLine.hasOption("ftp")) {
			doFTP      = true;
			if(dbg>0) logger.debug("ftp switch activated");
		}
		
		if (cmdLine.hasOption("archive")) {
			archive    = true;
			if(dbg>0) logger.debug("archive switch activated");
		}
		
		if (cmdLine.hasOption("email")) {
			sendEmail  = true;
			if(dbg>0) logger.debug("email switch activated");
		}
*/		
			
		if (cmdLine.hasOption("readDB")) {
			readDB = true;
			if(dbg>0) logger.debug("readdb switch activated");
		}

		if (cmdLine.hasOption("props")) {
			propsFileName = cmdLine.getOptionValue("props");
		}
		
		if (cmdLine.hasOption("creds")) {
			credsFileName = cmdLine.getOptionValue("creds");
		}  

		if (cmdLine.hasOption("outfile")) {
			outFilePrefix = cmdLine.getOptionValue("outfile");
		}  
		
		if(dbg>0) if(dbg>0) logger.debug("Command Line Parsing Complete");
	}
	
	/*load properties from the supplied properties file. Uses an internal string array
	* to define the required properties. Will generate an exception if a property is
	* missing from the properties file.
	*/
	private static void loadProperties(String propsPath, String credsPath) throws Exception {
		
		if(dbg>0) logger.debug("Loading Properties");
		FileInputStream fis = new FileInputStream(propsPath);
		Properties p = new Properties();
		p.load(fis);
		fis.close();
		if(dbg>0) logger.debug("Loaded and Closed Properties File");
		
		if (new File(credsPath).exists()) {
			FileInputStream fisc = new FileInputStream(credsPath);
			p.load(fisc);
			fisc.close();
			if(dbg>0) logger.debug("Loaded and Closed Credentials File");
		}    
		//old way
		//Integer dbg = Integer.parseInt(props.get("prod.debug").toString());		
		for (int i=0; i<propKeys.length; i++) {
			String key = propKeys[i];
			int keylen = key.length();
			//if(dbg>0) logger.debug("keylength is " +keylen);
			if(dbg>0) if(dbg>0) logger.debug(key+ " is being processed.");
			//if(dbg>0) logger.debug(key + " yields substrings " +sev_char + " : " +seven_key +" and " + ele_char + " : " +eleven_key );
			if (!p.containsKey(key)) {	
				if(dbg>0) logger.debug(key+ " doesn't exist.");
				throw new Exception("Could not locate required property " + key);
			}else{
				//if(dbg>0) logger.debug("p.key exists as " +key);
				props.put(key, p.getProperty(key, "NoValue"));
				String keyVal = props.get(key).toString();
				if(dbg>0) if(dbg>0) logger.debug("Existing property " +key+ " is set to " +keyVal);				
			}
		}
		if(dbg>0) logger.debug("Loading Properties Complete");
	}
	
	
	/* utility routine used to return a SQL connection to the staging database. It is
	* recognized that is not the most optimal approach as multiple connections may
	* end up being used within one single execution of the program. However, given
	* the low frequency, "middle of the night" execution profile for this program
	* combined with a desire for programming simplicity, this basic approach was
	* used.
	* 
	* All JDBC connection parameters are assumed to be stored in the properties
	* file whose path is supplied on the command line.
	*/
	private static Connection getSQLConnection() throws Exception  {
		/****
		try {
			Class.forName("oracle.jdbc.driver.OracleDriver").newInstance();
		}
		catch(ClassNotFoundException ex) {
			System.out.println("Error: unable to load driver class!");
			System.exit(1);
		}
		catch(IllegalAccessException ex) {
			System.out.println("Error: access problem while loading!");
			System.exit(2);
		}
		catch(InstantiationException ex) {
			System.out.println("Error: unable to instantiate driver!");
			System.exit(3);
		} 
		****/   
		
		
		if(dbg>0) logger.debug("Getting Database Connection");
		if(props.get("db.driver").toString() == null) if(dbg>0) logger.debug("db.driver is null");
		String dbdriver = props.get("db.driver").toString();
		if(dbg>0) logger.debug("Obtaining JDBC connection for driver=" + dbdriver );
		String dburl    = props.get("db.url").toString();
		if(dbg>0) logger.debug("Obtaining JDBC connection for url=" + dburl );		
		String dbuser   = props.get("db.user").toString();
		if(dbg>0) logger.debug("Obtaining JDBC connection for user=" + dbuser );
		String dbpw     = props.get("db.pw").toString();
		if(dbg>0) if(dbg>0) logger.debug("Obtaining JDBC connection with password=" + dbpw );		
		Integer isOracle = dbdriver.indexOf("oracle");
		
		if(dbg>0) if(dbg>0) logger.debug("Obtaining JDBC connection for driver=" + dbdriver +
		", url=" + dburl + ", user=" + dbuser );
		
		//Oracle requires a special way to register the driver
		if(isOracle>=0) {
			DriverManager.registerDriver (new oracle.jdbc.OracleDriver());
		}else{
			Class.forName(dbdriver).newInstance();
		}
		//    Connection conn = DriverManager.getConnection(dburl,dbuser,dbpw);
		
		Properties p = new Properties();
		p.put("user", dbuser);
		p.put("password", dbpw);
		p.put("sendStringParametersAsUnicode", "false");    
		Connection conn = DriverManager.getConnection(dburl,p);
		//    Connection conn = DriverManager.getConnection(dburl,dbuser,dbpw);
		
		if(dbg>0) logger.debug("Obtained JDBC connection successfully.");
		return conn;
	}
	
	/* readDB
	* subroutine to read the db using SQL found in properties file and write the output to
	* EBCDIC or ASCII files, or both. To add headers and footers to target file, run the
	* program more than once using a different property file each time.
	*/
	private static void readDB() throws Exception {
		
		
		if(dbg>0) logger.debug("Begin sql query process ...");
		
		Connection conn = getSQLConnection();
		Statement s = conn.createStatement();
		String SQL = null;
		SQL = props.get("sql.query").toString(); 
		// rs used to get data
		// cr used to count rows

		ResultSet cr = s.executeQuery(SQL);
		//worst language ever doesn't capture rowcount
		  //int rowCount = meta.getRowCount();
		//so do this instead:
		Integer lf = Integer.parseInt(props.get("file.lfatend").toString());
		int rowCount = 0;
		//worst language ever doesn't support this either:
		  //cr.last();
		//worst language ever doesn't support this either:
		  //rs.beforeFirst();
		  //so two queries are required, one to use, one to count
		while(cr.next()) {
			rowCount++;
		}
		//artificially inflate rowCount by one if you want a linefeed at end of the file
		rowCount = rowCount + lf;

		ResultSet rs = s.executeQuery(SQL);
	
		if(dbg>0) logger.debug("SQL Executed. " + rowCount + " records returned.");
		s.close();
		conn.close();
		if(dbg>0) logger.debug("Query Processed");
		if(dbg>0) logger.debug("File Creation Complete");
	
	}
	
	/* END readDB */


private static final Logger logger = LogManager.getLogger(validate.class);

	public static void main(String[] args) {
		
		try {
			setupLogger(args);
		}
		catch (Exception e) {
			e.printStackTrace();
		}
		
		if(dbg>0) logger.debug("Executing Function: Main - arguments passed are:");
		for (String element:args ) {
			if(dbg>0) logger.debug( element );
		} 
		if(dbg>0) logger.debug("---------------------------------");
		try {
			
			//if(dbg>0) if(dbg>0) logger.debug("------- Begin execution --------");
			
			if (args.length == 0) throw new Exception ("No arguments supplied.");
			
			processCommandLine(args);
			
			if (! new File(credsFileName).exists()) {
				if(dbg>0) logger.debug("Credentials file not found - attempting login using properties file");
			} else {
				if(dbg>0) logger.debug("Credentials file found");
			}
			
			if (! new File(propsFileName).exists()) {
				throw new Exception("Properties file= [" + propsFileName + "] not found.");
			} else {
				if(dbg>0) logger.debug("Properties file used: " + propsFileName);
			}
			
			loadProperties(propsFileName, credsFileName);
			
			if (readDB)     readDB();

			if(dbg>0) logger.debug("------- Execution Finished Successfully--------");
		}
		catch (Exception e) {
			StringWriter sw = new StringWriter();      
			e.printStackTrace(new PrintWriter(sw));		
			if(dbg>0) logger.debug(sw.toString());
			if(dbg>0) logger.debug("------- Execution Finished Unsuccessfully--------");
		}
	}
	
	
}

