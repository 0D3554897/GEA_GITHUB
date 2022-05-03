package com.ibm.imapsstg;

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

//import org.apache.log4j.FileAppender;
//import org.apache.log4j.Level;
//import org.apache.log4j.Logger;
//import org.apache.log4j.PatternLayout;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;


import au.com.bytecode.opencsv.CSVReader;

import com.ibm.imapsstg.util.ExcelBuilder;
import com.ibm.imapsstg.util.MailTool;
import com.ibm.imapsstg.util.Util;
/*import com.ibm.xslt4j.java_cup.runtime.Scanner;*/
import java_cup.runtime.Scanner;
import crypto.AESCrypto;

/*
* This program is a command line utility that provides several miscellaneous 
* functions associated with the encryption and inbound processing of the workday files
* for Research (Division 22).
* 
*  The program supports the following command line parameters as flags to control
*  which subset of processing is requested during a particular invocation. Note that multiple
*  switches can be used in a single invocation; the order of execution follows the list
*  below
*  
*  -key	      Generate an AES(128bit) symmetric key and store in the database
*  -truncate	  Clear the staging table  
*  -ftp    	  FTP theworkday file, encrypt and write to filesystem using the key created above
*  -loaddb 	  Load and process a clear text file so that data is loaded into staging table
*  -loaddbenc  Load and process a previously encrypted file so that data is loaded into staging table
*  -email      indicates that an email message should be sent to the admin when program completes
*  -archive    the encrypted file should be copied (archived) to the specified archive directory
*  -serialxref generate and mail a serial number cross reference report
*  
*  Additionally the program requires a standard Java properties file for all external
*  configuration information such as JDBC connection info, FTP connection info, SQL
*  statements used to interact with the database etc. The path to the properties file
*  must also be included on the command line using the following format
*  
*   -props		[path to properties file]
*   e.g. -props c:\config\ceris.properties
*   
*   Logging
*   ========
*   
*   The program provides a log file (using Log4J) to record a time-stamped trace
*   of all activities performed by the program. 
*   
*   The logfile is named cerislog.txt and will be created in whatever
*   is the current working directory when the program executes. Multiple executions of
*   the program simply append to this log file so it may need to be purged or 
*   archived periodically.
*
*  Modification
*  ============
*  CR 8503/8504 workday implementation
*  Changes:
*  - Add ability to designate which columns from CSV file will be loaded to DB
*  - Add loaddb functionality that does not require encryption SQL
*  - Add ability to specify delimiter and enclosure characters in property files

*/
public class csv2db {
	
	/* 
	* initialize the Log4J logger to log into the current working directory. Called from
	* main() entry point. Get log filename from command line switch
	*/
	private static void setupLogger(String[] arg) throws Exception {	
		String workingDir = System.getProperty("user.dir");	
		File   logdir  = new File(workingDir);
		File   logfile = new File(logdir, "csv2db.txt");

	}  //end of setupLogger
		
	/******************************************************************
	*           OLD LOG4J
	* initialize the Log4J logger to log into the current working directory. Called from
	* main() entry point.

	private static void setupLogger() throws Exception {
		
		String workingDir = System.getProperty("user.dir");
		File   logdir  = new File(workingDir);
		File   logfile = new File(logdir,"csv2db.txt");
		
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
	}
	
	***************************************************************/	
	
	private static String[] propKeys = {
		// from credentials files	
		"log.filename","prod.debug",
		"ftp.host","ftp.user","ftp.pw","ftp.remote.filename","ftp.local.filename","ftp.archive.dir","ftp.delimiter","ftp.enclosure","ftp.linestoskip",
		"db.driver","db.url","db.user","db.pw",
		"mail.host","mail.user","mail.pw","mail.addressee",
    	"serialxref.email","missingxref.email",
		//from properties file
		"serialxref.xlsname","serialxref.subject","serialxref.body","serialxref.mimeType",
    	"missingxref.xlsname","missingxref.subject","missingxref.body","missingxref.mimeType","missingxref.headers",
		"sql.h_header","sql.h_insert","sql.h_includeColumn","sql.h_process_header",
		"sql.h_adj_flg", "sql.h_adj_hdr", 
		"sql.h_truncate", "sql.truncate", "sql.useEncrypt",
		"sql.openSQLKey","sql.closeSQLKey","sql.readSQLKeyPassword",
		"sql.insert","sql.missing", "sql.missing_ra","sql.serialxref","sql.missingxref","sql.includeColumn",
		"skip.records","skip.criteria","skip.count","skip.SQL"
	};
	
	private static HashMap props = new HashMap();

	private static boolean    doFTP      = false;
	private static boolean    genKey     = false;
	private static boolean    loadDBenc  = false;
	private static boolean    loadDB     = false;
	private static boolean    truncateDB = false;
	private static boolean    sendEmail  = false;
	private static boolean    archive    = false;
	private static boolean    serialxref = false;
  	private static boolean    missingxref = false;
	private static int        linecount  = 0;
	private static Logger     appLogger  = null;
	private static int 		  dbg 		 = 0;	
	private static String propsFileName  = "unknown";
	private static String credsFileName  = "unknown";
	
	
	/* process the supplied command line and set internal flags based on 
	* the command line. Note that this logic uses the Apache Commons CLI library
	* (http://commons.apache.org/cli) to perform this processing.
	*/
	
	private static void processCommandLine(String[] args) throws Exception {
		
		Options options = new Options();
		
		options.addOption("key",false,"request generation of encryption key (with store of key to DB");
		options.addOption("ftp",false,"request FTP of file from workday host");
		options.addOption("loaddbenc",false,"load encrypted CERIS22 info from file into SQL db");
		options.addOption("loaddb",false,"load CERIS16 info from file into SQL db"); 
		options.addOption("truncate",false,"clear existing info from SQL db");
		options.addOption("email",false,"send email when program completes");
		options.addOption("archive",false,"archive encrypted FTP file");
		options.addOption("serialxref",false,"generate and send serial number cross ref report");
    	options.addOption("missingxref",false,"generate and send report of records with missing data");
    	options.addOption("props",true,"properties file path");
		options.addOption("creds",true,"credentials file path");
		options.addOption("debug",true,"specify 0,1,2,or 3. See batch file.");		
		
		CommandLineParser parser = new BasicParser();
		CommandLine cmdLine = parser.parse(options, args);
		
		if (cmdLine.hasOption("debug")) {
			dbg = Integer.parseInt(cmdLine.getOptionValue("debug"));
			if(dbg>0) Applogger.debug("Debug set to " + dbg);
		}		
		
		
		if (cmdLine.hasOption("key")) {
			genKey     = true;
			if(dbg>0) Applogger.debug("key switch activated");
		}
		
		if (cmdLine.hasOption("ftp")) {
			doFTP      = true;
			if(dbg>0) Applogger.debug("ftp switch activated");
		}
		
		if (cmdLine.hasOption("loaddbenc")) {
			loadDBenc  = true;
			if(dbg>0) Applogger.debug("loaddbenc switch activated");
		}
		
		if (cmdLine.hasOption("loaddb")) {
			loadDB     = true;
			if(dbg>0) Applogger.debug("loaddb switch activated");
		}
		
		if (cmdLine.hasOption("truncate")) {
			truncateDB = true;
			if(dbg>0) Applogger.debug("truncate switch activated");
		}
		
		if (cmdLine.hasOption("archive")) {
			archive    = true;
			if(dbg>0) Applogger.debug("archive switch activated");
		}
		
		if (cmdLine.hasOption("email")) {
			sendEmail  = true;
			if(dbg>0) Applogger.debug("email switch activated");
		}
		
		if (cmdLine.hasOption("serialxref")) {
			serialxref = true;
			if(dbg>0) Applogger.debug("serialxref switch activated");
		}
    
		if (cmdLine.hasOption("missingxref")) {
			missingxref = true;
			if(dbg>0)  Applogger.debug("missingxref switch activated");
		}
    		
		if (cmdLine.hasOption("props")) {
			propsFileName = cmdLine.getOptionValue("props");
		}
		
		if (cmdLine.hasOption("creds")) {
			credsFileName = cmdLine.getOptionValue("creds");
		}    
	}
	
	/*load properties from the supplied properties file. Uses an internal string array
	* to define the required properties. Will generate an exception if a property is
	* missing from the properties file.
	*/
	private static void loadProperties(String propsPath, String credsPath) throws Exception {
		
		if(dbg>0) Applogger.debug("Executing Function: Loading Properties");
		FileInputStream fis = new FileInputStream(propsPath);
		Properties p = new Properties();
		p.load(fis);
		fis.close();
		if(dbg>0) Applogger.debug("Loaded and Closed Properties File");
		
		if (new File(credsPath).exists()) {
			FileInputStream fisc = new FileInputStream(credsPath);
			p.load(fisc);
			fisc.close();
			if(dbg>0) Applogger.debug("Loaded and Closed Credentials File");
		}    
		
		int sev_char = 7;
		int ele_char = 11;
		for (int i=0; i<propKeys.length; i++) {
			sev_char=7;
			ele_char=11;
			String key = propKeys[i];
			int keylen = key.length();
			//if(dbg>0) Applogger.debug("keylength is " +keylen);
			if(keylen<11) ele_char = keylen;
			if(keylen<7) sev_char = keylen;
			String seven_key = key.substring(0,sev_char);
			String eleven_key = key.substring(0,ele_char);
			if(dbg>3) Applogger.debug(key+ " is being processed.");
			//if(dbg>0) Applogger.debug(key + " yields substrings " +sev_char + " : " +seven_key +" and " + ele_char + " : " +eleven_key );
			if (!p.containsKey(key)) {	
				if(dbg>0) Applogger.debug(key+ " doesn't exist.");
				if(eleven_key.equals("sql.missing")){
					if(dbg>0) Applogger.debug(key + " is not in this properties file");
					props.put(key, p.getProperty(key, "MissingValue"));
					if(key.length()>11){
						props.put(key, p.getProperty(key, "0"));
					}
				}else if(seven_key.equals("missing")){
					if(dbg>0) Applogger.debug(key + " is not in this properties file");
					props.put(key, p.getProperty(key, "MissingValue"));
					if(key.length()>7){
						props.put(key, p.getProperty(key, "0"));
					}
				}else if(seven_key.equals("sql.h_a")){
					if(dbg>0) Applogger.debug(key + " is not in this properties file and is set to zero");
					props.put(key, p.getProperty(key, "0"));
				}else{  
					throw new Exception("Could not locate required property " + key);
				}
				String keyVal = props.get(key).toString();
				if(dbg>0) Applogger.debug("Missing key " +key+ " is set to " +keyVal);
			}else{
				//if(dbg>0) Applogger.debug("p.key exists as " +key);
				props.put(key, p.getProperty(key, "NoValue"));
				String keyVal = props.get(key).toString();
				if(key.contains(".pw")){
				 if(dbg>3)  Applogger.debug("Existing property " +key+ " is a password ");
				}else{
				 if(dbg>3)  Applogger.debug("Existing property " +key+ " is set to " +keyVal);
				}
			}
		}
		
		//Integer dbg = Integer.parseInt(props.get("prod.debug").toString());
		//convert comma separated string into Array. Used later to determine if db column should be imported, and to reorder the data
		//once for the header
		Integer h_hdr = Integer.parseInt(props.get("sql.h_header").toString());
		if(h_hdr ==1) {
			if(dbg>1)  Applogger.debug("Using header, so get definitions");
			String h_colString = props.get("sql.h_includeColumn").toString();
			//  "\\s*,\\s*"        \\s*,  is a space, tab, linebreak or form feed followed by a comma   \\s is same, but not followed by a comma
			String hciString[] = h_colString.split(",");
			//java cannot take a string array, and automatically convert its contents into int, even if they are. So we have to do it.
			int h_columnsIncluded[] = new int[hciString.length];
			for(int hcii = 0; hcii < hciString.length; hcii++) {
				h_columnsIncluded[hcii] = Integer.parseInt(hciString[hcii]);
			}
			// we also want to count the number of non-zero items in the ArrayList
			// this is the number of fields that will be inserted into the table
			int numberofh_InclCols = 0;
			int numberofh_AllCols = 0;
			for (int h = 0; h < hciString.length; h++){
				numberofh_AllCols++;
				if( h_columnsIncluded[h] != 0) {
					numberofh_InclCols++;
				}
			}
			String[] headerToInsert = new String[numberofh_InclCols];
			numberofh_InclCols++;
		}else{
			if(dbg>1)  Applogger.debug("Not using header");    	
		}
		
		//once for the main body of records
		String colString = props.get("sql.includeColumn").toString();
		String ciString[] = colString.split(",");
		int columnsIncluded[] = new int[ciString.length];
		for(int cii = 0; cii < ciString.length; cii++) {
			ciString[cii]=ciString[cii].replace("*","");
			columnsIncluded[cii] = Integer.parseInt(ciString[cii]);
		}    
		// we also want to count the number of non-zero items in the ArrayList
		// this is the number of fields that will be inserted into the table
		int numberofInclCols = 0;
		int numberofAllCols = 0;
		for (int c = 0; c < ciString.length; c++){
			numberofAllCols++;
			if( columnsIncluded[c] != 0) {
				numberofInclCols++;
			}
		}
		// now we can create an array to hold the reordered records for use later - won't work, because of scope of variable.
		// Type[] variableName = new Type[capacity];
		//String[] recordsToInsert = new String[numberofInclCols];
		numberofInclCols++;
	}
	
	
	/* utility routine used to return a SQL connection to the staging database. It is
	* recognized that is not the most optimal approach as multiple connections may
	* end up being used within one single execution of the program. However, given
	* the low frequency, "middle of the night" execution profile for this program
	* combined with a desire for programming simpliciity, this basic approach was
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
		
		//Integer dbg = Integer.parseInt(props.get("prod.debug").toString());
		if(dbg>0) Applogger.debug("Executing Function: Get Database Connection");
		String dbdriver = props.get("db.driver").toString();
		String dburl    = props.get("db.url").toString();
		String dbuser   = props.get("db.user").toString();
		String dbpw     = props.get("db.pw").toString();
		Integer isOracle = dbdriver.indexOf("oracle");
		
		if(dbg>1)  Applogger.debug("Obtaining JDBC connection for driver=" + dbdriver +
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
		
		if(dbg>0)  Applogger.debug("Obtained JDBC connection successfully.");
		return conn;
	}
	
	/*
	* A utility routine to send email to the administrator designated for this program.
	* Uses Apache Commons Email which provides a simplied interface on top of the 
	* Java Mail API (which is also required)
	*/
	
	private static void sendEmail(String subject, String body) {
		//Integer dbg = Integer.parseInt(props.get("prod.debug").toString());
		if(dbg>0) Applogger.debug("Executing Function: Send Email");
		
		try {
			SimpleEmail email = new SimpleEmail();
			email.setHostName(props.get("mail.host").toString());
			email.setFrom(props.get("mail.user").toString());
			email.setAuthentication(props.get("mail.user").toString(),
			props.get("mail.pw").toString());
			email.addTo(props.get("mail.addressee").toString());
			email.setSubject(subject);
			email.setMsg(body);
			email.send();
		}
		catch (Exception e) {
			if(dbg>0) Applogger.debug("ERROR: sendEmail");
			StringWriter sw = new StringWriter();      
			e.printStackTrace(new PrintWriter(sw));
			appLogger.error(sw.toString());  		
		}
		if(dbg>0) Applogger.debug("Function Executed: Send Email");
	}
	
	/*
	* A utility subroutine used to send an email with a binary
	* attachment. Primarily used to send an Excel spreadsheet containing
	* employee serial number cross ref. In order to deal with the
	* complications of an in-memory attachment it uses Java Mail directly
	* (via a helper class called MailTool)
	*/
	
	private static void sendEmailWithAttachment(List   addressees,
	String subject,
	String body,  		                                        
	byte[] attachment,
	String attachmentFileName,
	String attachmentMimeType) 
	throws Exception {
		//Integer dbg = Integer.parseInt(props.get("prod.debug").toString());
		if(dbg>0) Applogger.debug("Executing Function: Send Email with Attachment");
		
		try {
			
			MailTool email = new MailTool();
			email.setHost(props.get("mail.host").toString());
			email.setUser(props.get("mail.user").toString());
			email.setPassword(props.get("mail.pw").toString());
			email.setRecipients(addressees);
			email.setSubject(subject);
			email.setMessage(body);
			email.setMimeType("text/html");
			email.setAttachment(new ByteArrayInputStream(attachment));
			email.setAttachmentMimeType(attachmentMimeType);
			email.setAttachmentName(attachmentFileName);
			email.sendMail();
		}
		catch (Exception e) {
			if(dbg>0) Applogger.debug("Email with Attachment error");
			StringWriter sw = new StringWriter();      
			e.printStackTrace(new PrintWriter(sw));
			appLogger.error(sw.toString());  		
		}
		if(dbg>0) Applogger.debug("Function Executed: Send Email With Attachment");
	}
	
	/* 
	* Read a property or parameter from the staging database. For each such parameter
	* it is expected that the SQL used to retrieve the parameter is defined in the 
	* external properties file under a well known key. Again, not super effiicient
	* but flexible and simple.
	*/
	private static String readStringFromSQL(String sqlKey) throws Exception {
		
		//Integer dbg = Integer.parseInt(props.get("prod.debug").toString());
		if(dbg>0) Applogger.debug("Executing Function: Read String from SQL");
		
		String SQL = props.get(sqlKey).toString();
		if (SQL == null) throw new Exception("Could not locate SQL for key="+sqlKey);
		
		String result = null;
		
		Connection conn = getSQLConnection();
		Statement s = conn.createStatement();
		ResultSet rs = s.executeQuery(SQL);
		
		while (rs.next()) {
			result = rs.getString(1);
			if (result == null) throw new Exception("Null or missing SQL entry found ="+sqlKey);
			break;
		}
		
		rs.close();
		s.close();
		conn.close();
		if(dbg>0) Applogger.debug("Function Executed: Read String from SQL");
		return result;
	}
	

	
	/*
	* Use a utility library to generate an AES key then store it in the database. The
	* SQL required to store the key is supplied in the properties file under 
	* a well known key. Will generate a SQL exception if the key already exists.
	*/
	private static void generateKey() throws Exception {
		
		//Integer dbg = Integer.parseInt(props.get("prod.debug").toString());
		if(dbg>0) Applogger.debug("Executing Function: Generate Key");
		
		if(dbg>1)  Applogger.debug("Begin key generation ...");
		SecretKey key = AESCrypto.generateKey();
		if(dbg>2)  Applogger.debug("Key generation completed");
		
		byte[] bytes = key.getEncoded();
		
		if(dbg>1)  Applogger.debug("Key insertion into db begins");
		
		String SQL = props.get("sql.writeKey").toString();
		
		Connection conn = getSQLConnection();
		PreparedStatement ps = conn.prepareStatement(SQL);
		ps.setBytes(1, bytes);
		int rc = ps.executeUpdate();
		
		ps.close();
		conn.close();
		
		if(dbg>2) {
			if (rc != 1) if(dbg>0) Applogger.debug("ERROR: Insert of key into SQL DB fails.");
		else        if(dbg>0)  Applogger.debug("Key insertion into db completed");    
		}
		if(dbg>0) Applogger.debug("Function Executed: Generate Key");
	}
	
	/* Utility function used to retrieve the encryption key from the database for
	* use in both encryption and decryption related functions. The
	* SQL required to retrieve the key is supplied in the properties file under 
	* a well known key. Will generate an application exception if the key is not found.
	* 
	*/
	private static SecretKey retrieveKey() throws Exception {
		
		//Integer dbg = Integer.parseInt(props.get("prod.debug").toString());
		if(dbg>0) Applogger.debug("Executing Function: Retrieve Key");
		if(dbg>1)  Applogger.debug("Begin retrieval of key from DB");
		String SQL    = props.get("sql.readKey").toString();
		SecretKey key = null;
		
		Connection conn = getSQLConnection();
		Statement s = conn.createStatement();
		ResultSet rs = s.executeQuery(SQL);
		
		boolean foundKey = false;
		byte[]  bytes    = null;
		
		while (rs.next()) {
			bytes    = rs.getBytes(1);
			foundKey = true;
		}
		
		rs.close();
		s.close();
		conn.close();
		
		if (foundKey) {
			key = new SecretKeySpec(bytes,"AES");
		}
		else {
			throw new Exception ("Could not locate AES encryption key in specified DB.");
		}
		
		if(dbg>0) Applogger.debug("Function Executed: Retrieve Key");
		
		return key;
	}
	
	/* uses utility functions to FTP the workday file from the mainframe, encrypt it
	* while in memory, and write the encrypted contents to an output file. The output
	* file location is assumed to be specified as an external parameter stored in
	* the staging database; all FTP parameters are stored directly in the properties 
	* file.
	*/
	
	private static void executeFTP() throws Exception {
		
		//Integer dbg = Integer.parseInt(props.get("prod.debug").toString());
		if(dbg>0) Applogger.debug("Executing Function: Execute FTP");
		
		String ftphost     = props.get("ftp.host").toString();
		String ftpuser     = props.get("ftp.user").toString();
		String ftppw       = props.get("ftp.pw").toString();
		String remoteFname = props.get("ftp.remote.filename").toString();
		
		//String localFname  = readStringFromSQL("sql.localFileName");
		String localFname  = props.get("ftp.local.filename").toString();
		//if (localFname == null)
		//  throw new Exception("Could not locate local fn in db");    
		
		if(dbg>1)  Applogger.debug("Begin file retrieval via FTP");
		byte[] bytes = Util.readFTP(ftphost, remoteFname, ftpuser, ftppw);
		if(dbg>2)  Applogger.debug("FTP completed.");
		
		ByteArrayInputStream bis = new ByteArrayInputStream(bytes);
		FileOutputStream fos = new FileOutputStream(localFname);
		SecretKey key = retrieveKey();
		
		if(dbg>1)  Applogger.debug("Begin encryption to file (" + localFname + ").");
		AESCrypto.encrypt(bis, key, fos);
		fos.close();
		if(dbg>2)  Applogger.debug("File encryption completed.");
		if(dbg>0) Applogger.debug("Function Executed: Execute FTP");
	}
	
	/* 
	* Clear the staging table into which workday file contents are loaded. Presumably used
	* at the beginning of a cycle to remove the prior contents. The SQL used to perform
	* this task must be defined externally in the properties file.
	*/
	private static void truncateDatabase() throws Exception {
		
		//Integer dbg = Integer.parseInt(props.get("prod.debug").toString());
		
		if(dbg>0) Applogger.debug("Executing Function: Truncate Database");
		if(dbg>1)  Applogger.debug("Begin db truncate ...");
		String SQL = props.get("sql.truncate").toString();
		if(dbg>3) Applogger.debug("Truncate Database SQL: " + SQL);
		String valStr = "";
		String comma = ",";
		
		Connection conn = getSQLConnection();
		Statement s = conn.createStatement();
		int rc = s.executeUpdate(SQL);
		s.close();
		if(dbg>2)  Applogger.debug("Complete records table truncate. Num rows affected="+rc);
		
		if(dbg>1)  Applogger.debug("Begin header table truncate ...");
		String hSQL = props.get("sql.h_truncate").toString();
		Statement sh = conn.createStatement();
		rc = sh.executeUpdate(hSQL);
		sh.close();
		
		conn.close();
		if(dbg>2)  Applogger.debug("Complete header table truncate. Num rows affected="+rc);
		if(dbg>0) Applogger.debug("Function Executed: Truncate Database");
	}
	
	/* load the contents of a clear text csv file into the staging database. Uses an open source library (
	* (opencsv http://opencsv.sourceforge.net/) to process the
	* CSV format into an array of strings. Finally, the program loops through the lines
	* in the CSV file performing inserts using an externally supplied SQL statement from
	* the properties file. 
	* 
	* from the docs:
	* if you single quoted your escaped characters rather than double quote them, you can use the three arg constructor:
	*
	*  CSVReader reader = new CSVReader(new FileReader("yourfile.csv"), '\t', '\'');
	*
	*
	* You may also skip the first few lines of the file if you know that the content doesn't start till later in the file. So, for example, you can skip the first two lines by doing:
	*
	*  CSVReader reader = new CSVReader(new FileReader("yourfile.csv"), '\t', '\'', 2);
	*
	*
	*/
	private static void loadDatabase() throws Exception {
		
		//Integer dbg = Integer.parseInt(props.get("prod.debug").toString());
		if(dbg>0) Applogger.debug("Executing Function: Load Database");
		
		if(dbg>1)  Applogger.debug("Begin database load ...");
		int start_i = 0;
		Connection conn = getSQLConnection();
		if(dbg>1)  Applogger.debug("Return to loadDatabase ...");
		conn.setAutoCommit(false);
		
		//if (localFname == null)
		//  throw new Exception("Could not locate local fn in db");    
		
		//if(dbg>0) Applogger.debug("Loading CERIS16 data from file=" + localFname);
		
		//FileInputStream fis = new FileInputStream(localFname);
		
		/*  SecretKey key = retrieveKey();
		
		if(dbg>0) Applogger.debug("Begin decryption of file="+localFname);
		ByteArrayOutputStream bos = new ByteArrayOutputStream();
		
		try {
			AESCrypto.decrypt(fis, key, bos);
		}
		catch (Exception e){
			fis.close();
			throw e;
		}
		
		if(dbg>0) Applogger.debug("Decryption completed.");
		
		ByteArrayInputStream bis = new ByteArrayInputStream(bos.toByteArray());
		InputStreamReader reader = new InputStreamReader(bis);
		
		Connection conn = getSQLConnection();
		conn.setAutoCommit(false);
		Statement s = conn.createStatement();
		
		String SQLPassword = readStringFromSQL("sql.readSQLKeyPassword");
		if (SQLPassword == null) {
			throw new Exception("Could not read SQL Key password from DB");	
		}
		
		String SQL = null;
		SQL = props.get("sql.openSQLKey").toString();
		SQL = str_replace(SQL,"?",SQLPassword);   
		
		s.execute(SQL);
		
		
		http://grepcode.com/file/repo1.maven.org/maven2/net.sf.opencsv/opencsv/2.1/au/com/bytecode/opencsv/CSVReader.java#CSVReader.%3Cinit%3E%28java.io.Reader%2Cchar%2Cchar%29
		
		Constructs CSVReader with supplied separator and quote char.
		
		Parameters:
		reader the reader to an underlying CSV source.
		separator the delimiter to use for separating entries
		quotechar the character to use for quoted elements
		escape the character to use for escaping a separator or quote
		
		*/
		String delim = props.get("ftp.delimiter").toString();
		String enclos = props.get("ftp.enclosure").toString();
		String skip = props.get("ftp.linestoskip").toString();
		String localFname = props.get("ftp.local.filename").toString();
		String space = "x";
		if(dbg>1)  Applogger.debug("Properties obtained ...");
		if(dbg>2)  Applogger.debug("Processing File " + localFname);
		// old code superseded by CR8503/8504 
		//CSVReader csvreader = new CSVReader(reader), where reader is a stream in memory, defined above

		/******************** this doesn't work ***********************************/
		if(dbg>1)  Applogger.debug("Filereaders Startup ...");
		FileReader fName = new FileReader(localFname);  
		CSVReader csvreader = new CSVReader(fName);
		if(dbg>2)  Applogger.debug("CSVreader initiated ...");
		/******************** this doesn't work ***********************************/

		/******************** this doesn't compile ***********************************
		try{	
			FileReader fName = new FileReader(localFname);
			if(dbg>2)  Applogger.debug("Filereader initiated ...");
		}
		catch (Exception e) {
			e.printStackTrace();
		}
		CSVReader csvreader = new CSVReader(fName);
		if(dbg>2)  Applogger.debug("CSVreader initiated ...");		
		/******************** this doesn't compile ***********************************/

		
		/******************** this doesn't compile ***********************************
		try{	
			FileReader fName = new FileReader(localFname);
			if(dbg>2)  Applogger.debug("Filereader initiated ...");
			CSVReader csvreader = new CSVReader(fName);
			if(dbg>2)  Applogger.debug("CSVreader initiated ...");
		}
		catch (Exception e) {
			e.printStackTrace();
		}	
		/******************** this doesn't compile ***********************************/
		
		String [] nextLine;
		
		if(dbg>1)  Applogger.debug("File and CSV readers initiated ...");
		String h_process_hdr = props.get("sql.h_process_header").toString();
		String h_hdr = (String) props.get("sql.h_header");
		String h_adj_flg = (String) props.get("sql.h_adj_flg");
		String h_adj_hdr = (String) props.get("sql.h_adj_hdr");
		int h_proc_hdr = Integer.parseInt(h_process_hdr);
		int h_exst_hdr = Integer.parseInt(h_hdr) * 10;
		int h_adj_flag = Integer.parseInt(h_adj_flg);
		int hdr = h_proc_hdr + h_exst_hdr;
		int hInstCommaCount=0;
		int hRecCommaCount=0;
		int hcolsInclLen=0;
		int hCommaMatch=0;
		
		//we only want to some of this once
		int oneTime=0;
		int checkLen=0;
		String checkVal="x";
		//do all this once for the main body of records
		//var declaration
		int rInstCommaCount=0;
		int rRecCommaCount=0;
		int rCommaMatch=0;
		int colsIncLen=0;
		int aprLen=0;
		int lineCount=0;
		int recordProblem=0;
		int isRequired=0;
		String SQL = props.get("sql.insert").toString();
		String mSQL = props.get("sql.missing").toString();
		if(dbg>3) Applogger.debug("sql.missing = " + mSQL);
		if(mSQL=="MissingValue"){
			mSQL=SQL;
		}
		String psmSQL = "";
		int psmCtr=0;
		String addl_val = "";
		int addl_idx=0;
		
		// SQL Missing RA, to tell us if additonal parameters expected, and which ones
		String addl_params = props.get("sql.missing_ra").toString();
		String addl_param_ra[] = addl_params.split(",");


		aprLen = addl_param_ra.length;
		int msgFlag = 0;
		int encryptIdx=999;
		int addl_param_int[] = new int[addl_param_ra.length];
		for(int api = 0; api < aprLen; api++) {
			addl_param_int[api] = Integer.parseInt(addl_param_ra[api]);
		}  //end api=0 
    int add_params=addl_param_int[0];
		
		PreparedStatement psm = conn.prepareStatement(mSQL);
		PreparedStatement ps = conn.prepareStatement(SQL);
		String colString = props.get("sql.includeColumn").toString();
		
		String ciString[] = colString.split(",");
		String cintString[] = colString.split(",");
		
		colsIncLen = ciString.length;
		if(dbg>3)  Applogger.debug("colsIncLen = " + colsIncLen);
		int columnsIncluded[] = new int[colsIncLen];
		for(int cii = 0; cii < colsIncLen; cii++) {
			isRequired = isRequired + (cintString[cii].indexOf('*')+1);
			ciString[cii] = ciString[cii].replace("*","");
			columnsIncluded[cii] = Integer.parseInt(ciString[cii]);
		}  //end for  cii=0
		isRequired=0;
		int numberofInclCols = 0;
		int numberofAllCols = 0;
		for (int c = 0; c < ciString.length; c++){
			numberofAllCols++;
			if( columnsIncluded[c] != 0) {
				numberofInclCols++;
			} // end if
		} // end for c=0
		String recordsToInsert[] = new String[numberofInclCols];
		numberofInclCols++;
		oneTime++;
		// end of one time
		if(dbg>3)  Applogger.debug("numberofInclCols = " + numberofInclCols);
		if(dbg>3)  Applogger.debug("numberofAllCols = " + numberofAllCols);
		// Encryption
		String nCode = props.get("sql.useEncrypt").toString();
		//if(dbg>0) Applogger.debug("nCode is " +nCode);
		if(nCode.equals("Y")){
			if(dbg>1)  Applogger.debug("Using Encryption");
			// Connection conn = getSQLConnection();
			// conn.setAutoCommit(false);
			Statement s = conn.createStatement();
			
			String SQLPassword = readStringFromSQL("sql.readSQLKeyPassword");
			if (SQLPassword == null) {
				throw new Exception("Could not read SQL Key password from DB"); 
			}
			
			String kSQL = null;
			kSQL = props.get("sql.openSQLKey").toString();
			kSQL = str_replace(kSQL,"?",SQLPassword);   
			
			s.execute(kSQL);
			// Encryption is performed
		} // end if  nCode=Y
		
		while ((nextLine = csvreader.readNext()) != null) {
			//read the file line by line - each line is an array called nextLine[]
			// and each element in the array is a field value
			// the array elements are in the order determined by the provider of the file, which may or may not be useful to us
			
			//we have another array we created earlier, columnsIncluded[], that has the same number of elements the CSV records (nextLine[])
			//  each element of columnsIncluded holds two instructions:
			//   1) whether or not to include this array element in the insert statement  (zero vs. a number value)
			//   2) for those records to be included, in what position to place it (number value indicates the correct position)
			// For example, 
			//  nextLine[] contains a single CSV line with D,E,Dog,A,C,Cat,B
			//  columnsIncluded[] contains 4,5,0,1,3,0,2
			//first, we have to explode the CSV line into an array
			//  using this information, we get rid of Dog and Cat, based on corresponding values of zero
			//  and place the remaining records in the target array using the element values as the target array index
			//  starting at index 0
			//  nextLine[0]=D and columnsIncluded[0]=4 therefore: recordsToInsert[columnsIncluded[0]]=nextLine[0]
			// after we iterate through all the elements in nextLine[]
			// we nullify recordsToInsert[0] (it held the value of every unwanted field in the CSV) and after that,
			// recordsToInsert[] will contain A,B,C,D,E
			
			//the idea is to parse through each element in nextLine[] 
			// and use the corresponding element in columnsIncluded[]  
			// to either discard or position the value in a third array, recordsToInsert[], that will be used to insert the records
			
			//so when we get a new line, we empty the array
			
			if(dbg>2)  Applogger.debug("hdr="+hdr);      
			if(hdr == 11) {
				if(dbg>0) Applogger.debug("Process the header record");    
				if(dbg>2){
					
						String uSQL    = "SELECT SUSER_SNAME() as UZER, GETDATE() as TODAY";
						String uzer = "";
						String tday = "";
		
						Connection uconn = getSQLConnection();
						Statement us = uconn.createStatement();
						ResultSet urs = us.executeQuery(uSQL);
		
						while (urs.next()) {
							uzer = urs.getString("Uzer");
							tday = urs.getString("Today");
						}
						
						if(dbg>0) Applogger.debug("User and datetime: " + uzer + " and " + tday);    
		
						urs.close();
						us.close();
						uconn.close();

				}
				
				
				hdr=0;  // process header only once
				String h_colString = props.get("sql.h_includeColumn").toString();
				//  "\\s*,\\s*"        \\s*,  is a space, tab, linebreak or form feed followed by a comma   \\s is same, but not followed by a comma
				// in the IBM file for which this program was created, there are two delimiters - comma and colon; we will replace the colons with commas
				
				//count the number of commas to make sure properties file instructions match the header data
				hInstCommaCount = h_colString.length() - h_colString.replace(",","").length() ;
				String h_record = Arrays.toString(nextLine);
				h_record = h_record.substring(1, h_record.length()-2).replace(":",",");
				h_record = h_record.replace(", ",",");
				if(dbg>2)  Applogger.debug("Header: " + h_record);
				hRecCommaCount = h_record.length() - h_record.replace(",","").length();
				String headLine[] = h_record.split(",");
				// if the instructions in properties file doesn't match the record format, it will fail badly if it runs. Prevent this
				try {
					hCommaMatch = hInstCommaCount - hRecCommaCount;
					//if(dbg>0) Applogger.debug("h_InstCommaCount, h_RecCommaCount, h_CommaMatch = " +hInstCommaCount +", " +hRecCommaCount +", " + hCommaMatch);
					if(dbg>2)  Applogger.debug("Commas in Header Instruction, Commas in Header Record, Difference (s/b=0) => " +hInstCommaCount +", " +hRecCommaCount +", " + hCommaMatch);
					if (hCommaMatch !=0) throw new Exception("Properties file instructions for header records do not match header line format");
				}
				catch(Exception chCommaMatch){
					if(dbg>0) Applogger.debug("ERROR: Properties file instructions for header records ("+hInstCommaCount +") do not match header line format (" +hRecCommaCount +").  Make corrections in properties file.");
					throw chCommaMatch;
				} // end try/catch
				//everything matches up, split the CSV instructions into an array
				String hciString[] = h_colString.split(",");
				hcolsInclLen = hciString.length;
				//java cannot take a string array, and automatically convert its contents into int, even if they are. So we have to do it.
				int h_columnsIncluded[] = new int[hciString.length];
				for(int hcii = 0; hcii < hciString.length; hcii++) {
					h_columnsIncluded[hcii] = Integer.parseInt(hciString[hcii]);
				} // end for
				// we also want to count the number of non-zero items in the ArrayList
				// this is the number of fields that will be inserted into the table
				int numberofh_InclCols = 0;
				int numberofh_AllCols = 0;
				for (int h = 0; h < hciString.length; h++){
					numberofh_AllCols++;
					if( h_columnsIncluded[h] != 0) {
						numberofh_InclCols++;
					} // end if  h_columnsIncluded[h]
				}  // end for h
				String[] headerToInsert = new String[numberofh_InclCols];
				if(dbg>2)  Applogger.debug("headertoinsert leng is " +headerToInsert.length);
				numberofh_InclCols++;
				
				//the first line is a header record
				//get the properties you'll need
				String h_SQL = props.get("sql.h_insert").toString();
				//String h_insert = props.get("sql.h_insert").toString();
				//String h_include = props.get("sql.h_includeColumn").toString();
				if(dbg>2)  Applogger.debug("----- creating prepared statement using h_SQL --------");
				if(dbg>2)  Applogger.debug(h_SQL);
				PreparedStatement psh = conn.prepareStatement(h_SQL);
				int new_h_index=0;
				// String h_numcol = props.get("sql.h_numcol").toString();  not used
				//split the first line (the header) into an array
				//String headerRecord[]=nextLine[1].split(",");
				//if(dbg>0) Applogger.debug("the nextLine value=" +nextLine[1]);
				//h_columnsIncluded integer array has already been declared above.  It is an array that holds the CSV order and instruction string for the header
				//headerToInsert is the already declared target array to put the reordered records into
				//we iterate through the header elements in order, and use the method described above to populate the values in the SQL statement
				//place the header element value in the target array with the index = value of the columns to include array
				if(dbg>2) Applogger.debug("HEADER RECORD");				
				for (int he=0; he<numberofh_AllCols; he++) {
					// in the properties file, for the include/order instruction, zero means exclude, and the order starts at 1. Array indexes start at 0. 
					// therefore, we want to ignore any value = 0 (don't include)
					// and we want to decrement the rest of the values by 1, so that the intended first column in the table (order=first, value=1) becomes element zero in the target array 
					//if(dbg>0)  Applogger.debug("he just incremented to " +he);
					if(h_columnsIncluded[he] > 0) {
						new_h_index = h_columnsIncluded[he] -1;
						/******
						if(dbg>0) Applogger.debug(" ");
						if(dbg>0) Applogger.debug("column value is " +headLine[he]);
						if(dbg>0) Applogger.debug("column value len gth is " +headLine[he].length());
						if(dbg>0) Applogger.debug("before numberofh_AllCols= " +numberofh_AllCols); 
						if(dbg>0) Applogger.debug("before numberofh_InclCols= " +numberofh_InclCols); 
						if(dbg>0) Applogger.debug("before he= " +he);             
						if(dbg>0) Applogger.debug("before h_columnsIncluded[he]= " +h_columnsIncluded[he]);            
						if(dbg>0) Applogger.debug("after he = " +he);
						if(dbg>0) Applogger.debug("after h_columnsIncluded[he]= " +h_columnsIncluded[he]);
						//if(dbg>0) Applogger.debug("headerRecord[he]= " +headerRecord[he]);
						******/
						if(dbg>3) {
						if(dbg>3) Applogger.debug(" ");
						if(dbg>3) Applogger.debug("column value is |" +headLine[he] + "|");
						if(dbg>3) Applogger.debug("column value length is " + headLine[he].length());						
						if(dbg>3) Applogger.debug("Inserting new element into header array 'headerToInsert'");
						if(dbg>3) Applogger.debug("index = " + new_h_index);
						if(dbg>3) Applogger.debug("column value inserted is " + headLine[he]);
						}
						if(headLine[he].length()==0){
							headLine[he]="0";
							if(dbg>3) Applogger.debug("headLine[he]=0");
						}
						headerToInsert[new_h_index]=headLine[he];
						if(dbg>2)  Applogger.debug("element successfully inserted");
						//if(dbg>0)  Applogger.debug("done with column______________________________________________________________________________ " );
					} // end if h_columnsIncluded[he]
					//else don't do anything but try the next field until you're done
				}  // end for he
				//now that we have a target array filled with the values in the correct order that they are to be inserted
				//we prepare the SQL
				if(dbg>2)  Applogger.debug("----- adding params to sql statement --------");
				for(int ih=0; ih<headerToInsert.length; ih++){
					if(dbg>2)  Applogger.debug(ih);
					if(dbg>2)  Applogger.debug("placing header record " +ih +" - " + headerToInsert[ih] +" into parameter # " + ih+1 );
					psh.setString(ih+1,headerToInsert[ih]);
				} // end for ih
				String SQLText = psh.toString();
				//String query = SQLText.substring(SQLText.indexOf( ": " )+2);
				if(dbg>2)  Applogger.debug("Header SQL: " + psh);  
				
				try {
					int rch = psh.executeUpdate();
					if(dbg>0) Applogger.debug("UNCOMMITTED Header inserted into table: " +rch + " record(s)");
					
					if (rch != 1) throw new Exception("Insert to Header SQL failed");
				} // end try
				catch(Exception he){
					if(dbg>0) Applogger.debug("ERROR: Header SQL Execution failed insert.");
					throw he;
				} //end catch
				//conn.commit();  -- don't commit until everything is done
				if(dbg>0)  Applogger.debug("Processing Data Records");
			}else{
				if(hdr==10){
					// header exists, but we don't want to process it
					if(dbg>1)  Applogger.debug("Header exists, but don't process it, just skip the line");
					hdr=0;
				}else{
					if(dbg>2)  Applogger.debug("Header either doesn't exist, has already been processed, or has been skipped. This is a new line from the file.");
					lineCount++;
					rInstCommaCount = colString.length() - colString.replace(",","").length() +1;
					rRecCommaCount = nextLine.length;
					rCommaMatch = rInstCommaCount - rRecCommaCount;
					if(rCommaMatch != 0) {
						if(dbg>0) Applogger.debug("sql.includeColumn = " + colString);
						if(dbg>0) Applogger.debug("ERROR: Properties file instructions for records ("+rInstCommaCount +") do not match record line format (" +rRecCommaCount +") at line# " +lineCount +".  Make corrections in properties file or examine file.");
						recordProblem=1;
					}else{
            			if(dbg>1)  Applogger.debug("980 Everything looks good. Line Count is " +linecount);
						recordProblem=0;
					} //end rCommaMatch
					/************************* don't throw a fatal error... just record problems in the log ****************************
					try{
						rCommaMatch = rInstCommaCount - rRecCommaCount;
						if(dbg>0) Applogger.debug("r_InstCommaCount, r_RecCommaCount, r_CommaMatch = " +rInstCommaCount +", " +rRecCommaCount +", " + rCommaMatch);
						if(rCommaMatch!=0) throw new Exception("Properties file instructions for records do not match record line format");
					}
					catch(Exception crCommaMatch){
						if(dbg>0) Applogger.debug("ERROR: Properties file instructions for records ("+rInstCommaCount +") do not match record line format (" +rRecCommaCount +").  Make corrections in properties file.");
						throw crCommaMatch;
					} // end of try / catch
					********************************************************************************************************************/
					//do this for each line
					if(dbg>3)  Applogger.debug("/*************************** Begin array reassignment for new record ***************************/");		
					//Arrays.fill(recordsToInsert, Null);
					recordsToInsert=new String[recordsToInsert.length];
					int rTI_arrayLength = recordsToInsert.length;
					if(dbg>3)  Applogger.debug("1027 rTI array length is " +rTI_arrayLength);
					int new_index = 0;
					int missing_flag = 0;
					for (int re=0; re<numberofAllCols; re++) {
						if(columnsIncluded[re] > 0){
							new_index = columnsIncluded[re]-1;
                            isRequired=-1;
                            if(dbg>3)  Applogger.debug("::");
							if(dbg>3)  Applogger.debug("Next element has new_index = " + new_index);
							//if the column is required AND there is a value, then set up the value to be used
							isRequired = (cintString[re].indexOf('*'));
							if(dbg>3)  Applogger.debug("cintString[re] value is " +cintString[re] +" and isRequired = " + isRequired);
							if(isRequired<0){
								//not required
								recordsToInsert[new_index] = nextLine[re];
							}else{
                //it's required, so find out if a value exists. If not, set a missing flag to put it into correct SQL statement
                if( nextLine[re] != null && nextLine[re].length()>0 ){
                  //column is required AND value in the data
                  if(dbg>2)  Applogger.debug("A value exists for new index " +new_index + " whose value is " +nextLine[re]);
                }else{   
                  if(dbg>2)  Applogger.debug("Set the missing flag for new index " +new_index + " whose value is " +nextLine[re]);  
                  missing_flag=1;
                }
                //do we bother with encryption?
                if(add_params==0){
                  if(dbg>3)  Applogger.debug("1023 add_params =" +add_params +" so we don't bother");
                  if(dbg>3)  Applogger.debug("msgFlag =" +msgFlag);
				  if(dbg>3)  Applogger.debug("1053 re =" +re);
				  if(dbg>3)  Applogger.debug("1054 new_index =" +new_index);
				  if(dbg>3)  Applogger.debug("1055 nextLine[re] = " +nextLine[re]);	
				  rTI_arrayLength = recordsToInsert.length;
				  if(dbg>3)  Applogger.debug("1059 rTI array length is " +rTI_arrayLength);
                  recordsToInsert[new_index] = nextLine[re];
				  if(dbg>3)  Applogger.debug("1061 records to insert array element " +new_index +" was assigned");
                }else{
  								//find out if we use extra parameters for this record
                  if(dbg>3)  Applogger.debug("1064 add_params =" +add_params +" so we add params");
  								for (int mf = 1; mf < addl_param_int.length; mf++){
  									encryptIdx= addl_param_int[mf];
  									if(new_index+1 == encryptIdx) {
  										msgFlag=1;
  										mf=addl_param_int.length;
  									} // end if new_index+1
  								}  // end for mf
                } // end do we bother with add_params
                //required, but psm query is the same as ps query
  							recordsToInsert[new_index] = nextLine[re];
 								if(dbg>3)  Applogger.debug("msgFlag = " + msgFlag);
 								if(msgFlag==1) {
  									//the psm statement is going to be different than the ps statement
  									//the value is null or it isn't. each gets treated differently
  									if( nextLine[re] != null && nextLine[re].length()>0 ){
  										//column is required AND value in the data
  										if(dbg>3)  Applogger.debug("column is required and data has a value of " +nextLine[re] +". new_index = " +new_index + " and re = " +re); 
  										if(dbg>3)  Applogger.debug("1046 (no addl params) - psm.setString(" +new_index+1 +", recordsToInsert["+new_index+"]); value is "+recordsToInsert[new_index]);
  									}else{
  										//column is required AND no value in the data
  										if(dbg>3)  Applogger.debug("column is required and data has no value: " +nextLine[re] +". new_index = " +new_index + " and re = " +re); 
  										if(addl_param_int[0]!=0){
  											//then we use additional parameters, 
  											recordsToInsert[new_index]="~MISSING"; 
  											if(dbg>3)  Applogger.debug("Record value=~MISSING");
  											if(dbg>3)  Applogger.debug("1054 psmSQL is " +psmSQL);
                        					if(dbg>3)  Applogger.debug("1055 missing_flag is set for item" +re +" ");
  										} // end addl_param_int
  									} // end if nextLine[re]
  									msgFlag=0;   
  								} //end if msgFlag               
							}	// end if required<0
							if(dbg>3)  Applogger.debug("re=" +re);
							if(dbg>3)  Applogger.debug("instruction: " + cintString[re] + " --> rearrange record: col:" + re +" new_array_idx: " +new_index +" value: " +nextLine[re]);
              if(dbg>3)  Applogger.debug("::");
						} //end if columnsIncluded[re]>0
					} //end for (re=0)
          if(dbg>3)  Applogger.debug("/*************************** End of array reassignment, begin adding values to SQL statements ***************************/");
          if(dbg>3)  Applogger.debug("missing_flag is set to " +missing_flag);
					for(int ir=0; ir<recordsToInsert.length; ir++){
						int nextIr = ir+1;
            int prevIr = ir-1;
            if(add_params==0){
              if(dbg>3)  Applogger.debug("1072 add_params =" +add_params +" so we don't bother");
            }else{            
              //check to see if this ir value is in the addl_param_int array
              for(int apira=1; apira<addl_param_int.length; apira++){
                if(dbg>3)  Applogger.debug("apira is " +apira +" and addl_param_int[" +apira +"] is " +addl_param_int[apira]);
                if(addl_param_int[apira]==ir){
                  if(dbg>3)  Applogger.debug("adding the additional parameter");
                  psmCtr=psmCtr+1;
                  psm.setString(psmCtr, recordsToInsert[prevIr]);
                  psmSQL=psmSQL + Integer.toString(psmCtr) + " " + recordsToInsert[prevIr] + ",";
                  if(dbg>3)  Applogger.debug("1082 - psm.setString(" +psmCtr +", recordsToInsert["+prevIr+"]); value is " +recordsToInsert[prevIr]);
                } //end if addl_param_int
              }// end for apira
            } // end do we bother with add_params
						if(dbg>3)  Applogger.debug("placing record #" +lineCount +": " +ir +" - " +recordsToInsert[ir] +" into data parameter # " +nextIr +" and missing parameter "+nextIr);
						ps.setString(nextIr, recordsToInsert[ir]);
						if(dbg>3)  Applogger.debug("1088 - ps.setString(" +nextIr +", recordsToInsert["+ir+"]); value is " +recordsToInsert[ir]);
            psmCtr=psmCtr+1;
/**
if( recordsToInsert[ir] ==null){
 if(dbg>0)  Applogger.debug("records to insert is null");
  recordsToInsert[ir]= space;
}
**/

            psm.setString(psmCtr, recordsToInsert[ir]);
            psmSQL=psmSQL + Integer.toString(psmCtr) + " " + recordsToInsert[ir] + ",";
            if(dbg>3)  Applogger.debug("1092: psmSQL is " +psmSQL);
            if(dbg>3)  Applogger.debug("1093 - psm.setString(" +psmCtr +", recordsToInsert["+ir+"]); value is " +recordsToInsert[ir]);
/**
            if( recordsToInsert[ir] != null && recordsToInsert[ir].length()>0 ){
              //column is required AND value in the data
              //so do nothing
            }else{
              //set the flag that tells insert to choose psm
              if(dbg>3)  Applogger.debug("isRequired = " + isRequired);
             if(dbg>0)  Applogger.debug("1080: missing_flag is set for " +ir +" item in record #" + lineCount);
              missing_flag=1;
            }// end if recordsToInsert[ir]
**/
					} //end for ir
					String l_record = Arrays.toString(recordsToInsert);
					if(dbg>3)  Applogger.debug("1107: recordProblem is " +recordProblem);
					if (recordProblem==0) {
            // the record format is ok, we can try to insert
						try {
							Integer skipRec = Integer.parseInt(props.get("skip.records").toString());
							if(dbg>3)  Applogger.debug("skipRec is " + skipRec);
							if(skipRec!=0){
								// get the other propoerties
								String criterion = props.get("skip.criteria").toString();
								Integer cntr = Integer.parseInt(props.get("skip.count").toString());
								String skipSQL = props.get("skip.SQL").toString();
								// check if it is a skip record
								// split the criteria instructions into an array; only works for one right now
								String sciString[] = criterion.split(",");
								Integer skipCol = Integer.parseInt(sciString[0]) - 1;
								if(dbg>3)  Applogger.debug(" Look for: " + sciString[1] +" in column " + sciString[0] +  " and compare to corresponding value in the current record: " + recordsToInsert[skipCol]);
								//test for the criteria value in the criteria column
								if(recordsToInsert[skipCol].equals(sciString[1])){
									//if you want to use db to keep track
									if(cntr==1){
										// then update the deleted records hash total
                    					if(dbg>3)  Applogger.debug("Using header to keep track of skip records");
										String cntrString = cntr.toString();
										PreparedStatement psu = conn.prepareStatement(skipSQL);
										psu.setString(1,cntrString);
										int ru = psu.executeUpdate();
										//conn.commit(); -- don't commit until everything is done
										if (ru != 1)  {
											throw new Exception("Update to hash failed. Employee="+recordsToInsert[1]);
										}else{
											if(dbg>2)  Applogger.debug("Hash Value " +lineCount +" Updated for Employee "+recordsToInsert[1] );
										}    			
									} // end if cntr=1
								}else{
									// if not set skipRec=0 so that the record can be put in the DB
									skipRec=0;
                  					if(dbg>3)  Applogger.debug("skipRec is reset to " + skipRec +" so that we can put record in DB");
								} // end if criteria matches record
								//now we have to reset the psm stuff
								psmCtr=0;
								psmSQL="";
							} // end if(skipRec!=0)
							if(skipRec==0){
								if(dbg>3)  Applogger.debug ("else skipRec != 1 and missing_flag = " +missing_flag);
								if(skipRec!=1){
                  				if(dbg>3)  Applogger.debug("missing flag test psm vs ps");
									if(missing_flag>0){
										// insert into missing table
										if(dbg>3)  Applogger.debug ("PSM Query: " + psmSQL);
										int rc = psm.executeUpdate();
										missing_flag=0;
										if (rc != 1)  {
											if(dbg>3)  Applogger.debug("No insert table yet");
											throw new Exception("Insert to Missing SQL failed. LineCount= "+lineCount);
										}else{
											if(dbg>3)  Applogger.debug("Missing Record: " + l_record);
											if(dbg>2)  Applogger.debug("Missing Record " +lineCount +" Inserted");
										} //end if rc!=1
										//conditionally decrement the record count in the header every time a missing record is inserted
										if(h_adj_flag==0){
											// do nothiing
										}else{
											PreparedStatement psa = conn.prepareStatement(h_adj_hdr);
											int ra = psa.executeUpdate();             
										} //end if h_adj_flag=0
									}else{ //missing_flag<=0
										// insert into data stage
										int rc = ps.executeUpdate();
										if (rc != 1)  {
											throw new Exception("Insert SQL failed. LineCount="+lineCount);
										}else{
											if(dbg>3)  Applogger.debug("Data Records: " + l_record);
											if(dbg>2)  Applogger.debug("Data Record " +lineCount +" Inserted");
										} //end if(rc!=1)
									} //end if(missing_flag>0)
									psmCtr=0;
									psmSQL="";
								} //end if(skipRec!=1)
							} //end if(skipRec==0)
						} //end try
						catch(Exception re){
							if(dbg>0) Applogger.debug("ERROR: Error message:", re);
							String valStr = "";
						for (int i = 0; i<recordsToInsert.length; i++) {valStr+= "'" + recordsToInsert[i]+"',";}
							valStr = valStr.substring(0,valStr.length()-1);
							if(dbg>0) Applogger.debug("ERROR: SQL Exception encountered during insert loop. Line #=" + (lineCount+1)  + " " + valStr );
							throw re;
						} // end catch
					}  // end RecordProblem
				} // end if hdr=10
			} //end if hdr=11
		} // end while  
		conn.commit();
		
		//Close encryption
		if(nCode.equals("Y")){
			String cSQL = props.get("sql.closeSQLKey").toString(); 
			Statement s = conn.createStatement();
			s.execute(cSQL);
			s.close();
			conn.commit();
			
		} // end if nCode=Y
		
		
		conn.close();
		if(dbg>0) Applogger.debug("Records Committed");
		if(dbg>0) Applogger.debug("Number of lines processed = "+lineCount);
		if(dbg>0) Applogger.debug("Function Executed: Load Database");
	} //end loaddatabase
	
	
	/* load the contents of a previously encrypted file into the staging database. First
	* decrypts the file into memory, then uses an open source library (
	* (opencsv http://opencsv.sourceforge.net/) to process the
	* CSV format into an array of strings. Finally, the program loops through the lines
	* in the CSV file performing inserts using an externally supplied SQL statement from
	* the properties file. 
	* 
	* A SQL encryption key is used to encrypt certain columns
	* in the database; while knowledge of which fields are encrypted is externalized
	* in the SQL statement used for inserts the use of encryption in SQL Server
	* 2005 requires that the Key be opened/closed around its use. So this routine
	* also performs that function by again relying on external SQL found in the
	* properties file. The password that must be used to open the key is held
	* in a parameter table in the staging database.
	*/
	private static void old_loadDatabaseenc() throws Exception {
		
		//Integer dbg = Integer.parseInt(props.get("prod.debug").toString());
		if(dbg>0) Applogger.debug("Executing Function: Old Database Encrypted - NO LONGER USED");
		
		if(dbg>1)  Applogger.debug("Begin database load ...");
		
		//String localFname  = readStringFromSQL("sql.localFileName");
		String localFname  = props.get("ftp.local.filename").toString();
		
		//if (localFname == null)
		//  throw new Exception("Could not locate local fn in db");    
		
		if(dbg>2)  Applogger.debug("Loading encrypted data from file=" + localFname);
		
		FileInputStream fis = new FileInputStream(localFname);
		SecretKey key = retrieveKey();
		
		if(dbg>2)  Applogger.debug("Begin decryption of file="+localFname);
		ByteArrayOutputStream bos = new ByteArrayOutputStream();
		
		try {
			AESCrypto.decrypt(fis, key, bos);
		}
		catch (Exception e){
			fis.close();
			throw e;
		}
		
		if(dbg>2)  Applogger.debug("Decryption completed.");
		
		ByteArrayInputStream bis = new ByteArrayInputStream(bos.toByteArray());
		InputStreamReader reader = new InputStreamReader(bis);
		
		Connection conn = getSQLConnection();
		conn.setAutoCommit(false);
		Statement s = conn.createStatement();
		
		String SQLPassword = readStringFromSQL("sql.readSQLKeyPassword");
		if (SQLPassword == null) {
			throw new Exception("Could not read SQL Key password from DB"); 
		}
		
		String SQL = null;
		SQL = props.get("sql.openSQLKey").toString();
		SQL = str_replace(SQL,"?",SQLPassword);   
		
		s.execute(SQL);
		
		SQL = props.get("sql.insert").toString();
		PreparedStatement ps = conn.prepareStatement(SQL);
		
		CSVReader csvreader = new CSVReader(reader);
		String [] nextLine;
		while ((nextLine = csvreader.readNext()) != null) {
			// nextLine[] is an array of values from the line
			for (int i=0; i<nextLine.length; i++) {
				ps.setString(i+1, nextLine[i]);
			}
			try {
				int rc = ps.executeUpdate();
				if (rc != 1)  throw new Exception("Update to SQL failed. LineCount="+linecount);
			}
			catch (Exception e) {
				if(dbg>0) Applogger.debug("ERROR: SQL Exception encountered during insert loop. Line #=" + (linecount+1));
				throw e;
			}
			linecount++;
			
		}                
		
		SQL = props.get("sql.closeSQLKey").toString(); 
		s.execute(SQL);
		
		conn.commit();
		
		s.close();
		conn.close();
		if(dbg>2)  Applogger.debug("Complete database load. Number of lines processed="+linecount);
	}
	
	
	/*
	* subroutine to archive the encrypted file retrieved via FTP. Archive directory
	* is supplied via a configuration parameter. File name has datetime stamp
	* preprended to it before copy occurs. Copied file is checked for datetime stamp
	* and file size before orginial is removed.
	*/
	
	private static void doArchive() throws Exception {
		
		//Integer dbg = Integer.parseInt(props.get("prod.debug").toString());
		if(dbg>0) Applogger.debug("Executing Function: Do Archive - no longer necessary");  	
		if(dbg>1)  Applogger.debug("Begin archiving request");
		
		File archiveDir = new File(props.get("ftp.archive.dir").toString());  	
		
		if (!archiveDir.exists()) {
			throw new Exception("Archive directory=" + archiveDir.getAbsolutePath() + " cannot be found.");
		}
		
		File f = new File(props.get("ftp.local.filename").toString());
		if (!f.exists()) {
			throw new Exception("Encrypted file=" + f.getAbsolutePath() + " cannot be found.");
		}
		
		long fsize = f.length();
		long ftime  = f.lastModified();
		
		Date now = new Date();
		SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd'_'HHmmss");
		String prepend = sdf.format(now);
		
		String newFname = prepend + "." + f.getName();
		File archiveFile = new File(archiveDir,newFname);
		
		if(dbg>2)  Applogger.debug("Begin copy operation (" + fsize + " bytes) from file=" + 
		f.getAbsolutePath() + " to file=" + archiveFile.getAbsolutePath());
		
		boolean rc = f.renameTo(archiveFile);
		if (!rc) throw new Exception ("Archive file rename(move) operation fails.");
		
		if(dbg>2)  Applogger.debug("Archive operation completes successfully");  	
	}
	
	/*  SERIAL XREF
	* subroutine to generate and e-mail a cross reference report for serial numbers. This
	* is generated to map "real" serial numbers to "hidden" serial numbers and also include
	* mapping of the serial number information to information in the Project Workforce
	* tables in IMAR
	*/
	private static void doSerialxref() throws Exception {
		
		//Integer dbg = Integer.parseInt(props.get("prod.debug").toString());
		if(dbg>0) Applogger.debug("Executing Function: Do Serial XRef");
		if(dbg>1)  Applogger.debug("Begin serial xref process ...");
		
		Connection conn = getSQLConnection();
		Statement s = conn.createStatement();
		
		String SQLPassword = readStringFromSQL("sql.readSQLKeyPassword");
		if (SQLPassword == null) {
			throw new Exception("Could not read SQL Key password from DB");	
		}
		
		String SQL = null;
		String RCSQL = null;
		SQL = props.get("sql.openSQLKey").toString();
		SQL = str_replace(SQL,"?",SQLPassword);       
		s.execute(SQL);
		
		SQL = props.get("sql.serialxref").toString(); 
		RCSQL = props.get("sql.serialxref").toString();   
		ResultSet rs = s.executeQuery(SQL);
		
		String[] headers = {"First Name", "Last Name", "Real Serial Number", "Fake Serial Number", "Project Being Worked On"}; 
		ByteArrayOutputStream bos = new ByteArrayOutputStream();
		ExcelBuilder.build(rs, headers, bos);   
		byte[] bytes = bos.toByteArray();
		if(dbg>0) Applogger.debug("Excel generation complete, size="+ bytes.length);
		
		SQL = props.get("sql.closeSQLKey").toString(); 
		s.execute(SQL);    
		
		ResultSet rs2 = s.executeQuery(RCSQL);
		int sxrc = 0;
		while(rs2.next()) {
			sxrc++;
		}
		linecount=sxrc;
		if(dbg>0) Applogger.debug(sxrc + " serialxref records queried");
		
		s.close();
		conn.close();
		
		if(dbg>0) Applogger.debug("Beginning email transmit ...");
		
		String baseXlsName = props.get("serialxref.xlsname").toString();
		SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd_HHmmss_");
		String xlsName = sdf.format(new Date()) + baseXlsName; 
		String addresseeStr = props.get("serialxref.email").toString();
		
		ArrayList addressees = new ArrayList();
		
		StringTokenizer st = new StringTokenizer(addresseeStr,";");
		while (st.hasMoreTokens()) {
			addressees.add(st.nextToken());
		}
		

		sendEmailWithAttachment(addressees,
		props.get("serialxref.subject").toString(),
		props.get("serialxref.body").toString(),
		bytes,
		xlsName,
		props.get("serialxref.mimeType").toString());    
		
		if(dbg>2)  Applogger.debug("Completed serial xref email transmit.");
		if(dbg>0) Applogger.debug("Function Executed: Do Serial XRef");		
	}
	
	
	/* END SERIAL XREF */


private static void doMissingxref() throws Exception {
    
    //Integer dbg = Integer.parseInt(props.get("prod.debug").toString());
   if(dbg>0)  Applogger.debug("Executing Function: Do Missing XRef");
    if(dbg>1)  Applogger.debug("Begin Missing xref process ...");
    
    Connection conn = getSQLConnection();
    Statement s = conn.createStatement();

    String nCode = props.get("sql.useEncrypt").toString();
	//if(dbg>0) Applogger.debug("nCode is " +nCode);
	if(nCode.equals("Y")){
	    String SQLPassword = readStringFromSQL("sql.readSQLKeyPassword");
			if (SQLPassword == null) {
			throw new Exception("Could not read SQL Key password from DB");	
		}		
		String SQL = null;
		String RCSQL = null;
		SQL = props.get("sql.openSQLKey").toString();
		SQL = str_replace(SQL,"?",SQLPassword);       
		s.execute(SQL);

	}
    String MSQL = null;     
    MSQL = props.get("sql.missingxref").toString(); 
    ResultSet rs = s.executeQuery(MSQL);
    
  /*String[] headers = {"First Name", "Last Name", "Real Serial Number", "Fake Serial Number", "Project Being Worked On"}; */
	String xlHeaders = props.get("missingxref.headers").toString();
	String headers[] = xlHeaders.split(",");
    //String[] headers = {"R_EMPL_ID" ,"LNAME" ,"FNAME" ,"NAME_INITIALS" ,"HIRE_EFF_DT" ,"IBM_START_DT" ,"TERM_DT" ,"MGR_SERIAL_NUM" ,"MGR_LNAME" ,"MGR_INITIALS" ,"JOB_FAM" ,"JOB_FAM_DT" ,"SAL_BAND" ,"LVL_DT_1" ,"DIVISION" ,"DIVISION_START_DT" ,"DEPT" ,"DEPT_START_DT" ,"DEPT_SUF_DT" ,"FLSA_STAT" ,"EXEMPT_DT" ,"POS_CODE" ,"POS_DESC" ,"POS_DT" ,"REG_TEMP" ,"STAT3" ,"EMPL_STAT3_DT" ,"STATUS" ,"EMPL_STAT_DT" ,"STD_HRS" ,"WORK_SCHD_DT" ,"LOA_BEG_DT" ,"LOA_END_DT" ,"LOA_TYPE" ,"LVL_SUFFIX" ,"DIVISION_FROM" ,"WORK_OFF" ,"CURR_DIV_FUNC_CODE" ,"CURR_REP_LVL_CODE" ,"PREV_DIV_FUNC_CODE" ,"PREV_REP_LVL_CODE" ,"MGR2_LNAME" ,"MGR2_INITIALS" ,"MGR3_LNAME" ,"MGR3_INITIALS" ,"HIRE_TYPE" ,"HIRE_PRGM" ,"SEPRSN" ,"DEPT_FROM" ,"VACELGD" ,"CMPLN" ,"BLDG_ID" ,"DEPT_SHIFT_DT" ,"DEPT_SHIFT_1" ,"SALARY" ,"SALARY_DT" ,"ASTYP" ,"ASNTYP" ,"MGR_FLAG" ,"CREATION_DATE" ,"CREATED_BY" ,"ASTYP" ,"ASNTYP" ,"MGR_FLAG" ,"CREATION_DATE" ,"CREATED_BY"};
    ByteArrayOutputStream bos = new ByteArrayOutputStream();
    ExcelBuilder.build(rs, headers, bos);   
    byte[] bytes = bos.toByteArray();
   if(dbg>0)  Applogger.debug("Excel generation complete, size="+ bytes.length);
    
    s.close();
    conn.close();
    
   if(dbg>0)  Applogger.debug("Beginning email transmit ...");
    
    String baseXlsName = props.get("missingxref.xlsname").toString();
    SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd_HHmmss_");
    String xlsName = sdf.format(new Date()) + baseXlsName; 
    String addresseeStr = props.get("missingxref.email").toString();
    
    ArrayList addressees = new ArrayList();
    
    StringTokenizer st = new StringTokenizer(addresseeStr,";");
    while (st.hasMoreTokens()) {
      addressees.add(st.nextToken());
    }
    
    sendEmailWithAttachment(addressees,
    props.get("missingxref.subject").toString(),
    props.get("missingxref.body").toString(),
    bytes,
    xlsName,
    props.get("missingxref.mimeType").toString());    
    
    if(dbg>2)  Applogger.debug("Completed missing email transmit.");
    if(dbg>0)  Applogger.debug("Executing Function: Do Missing XRef");
}   /* END missing XREF	
	
	/*
	* main entry point to application
	*/


private static final Logger Applogger = LogManager.getLogger(csv2db.class);
	
	public static void main(String[] args) {
		// setup logger first so we can log
		try {
			setupLogger(args);
		}
		catch (Exception e) {
			e.printStackTrace();
		}
		// grab the command line arguments so we know what to do
		try{	
			if (args.length == 0) throw new Exception ("No arguments supplied.");
			processCommandLine(args);
		}
		catch (Exception e) {
			e.printStackTrace();
		}	

		
		if(dbg>0) Applogger.debug("Executing Function: Main");    
		try {
			
			//if(dbg>1) appLogger.info("------- Begin execution --------");

			
			if (! new File(credsFileName).exists()) {
				if(dbg>0) Applogger.debug("Credentials file not found - attempting login using properties file");
			} else {
				if(dbg>0) Applogger.debug("Credentials file found");
			}
			
			if (! new File(propsFileName).exists()) {
				throw new Exception("Properties file= [" + propsFileName + "] not found.");
			} else {
				if(dbg>0) Applogger.debug("Properties file used: " + propsFileName);
			}
			
			loadProperties(propsFileName, credsFileName);
			if(dbg>0) Applogger.debug("Properties are loaded");
			if(dbg>0) Applogger.debug("Now Processing Command Line Switches"); 
			if (genKey)  		{ generateKey(); }else{if(dbg>0) Applogger.debug("No GenerateKey switch"); };
			if (truncateDB) { truncateDatabase(); }else{if(dbg>0) Applogger.debug("No Truncate DB switch"); };
			if (doFTP)      { executeFTP(); }else{if(dbg>0) Applogger.debug("No FTP switch"); };
			if (loadDB)     { loadDatabase(); }else{if(dbg>0) Applogger.debug("No LoadDB switch"); };
			if (loadDBenc)  { old_loadDatabaseenc(); }else{if(dbg>0) Applogger.debug("No OLD LoadDB switch"); };
			if (archive)    { doArchive(); }else{if(dbg>0) Applogger.debug("No Archive switch"); };
			if (serialxref) { doSerialxref(); }else{if(dbg>0) Applogger.debug("No Serial XREF switch"); };
      		if (missingxref) { doMissingxref(); }else{if(dbg>0) Applogger.debug("No Missing XREF switch"); };			
			if (sendEmail) {
				
				StringBuffer sb = new StringBuffer();
				for (int i=0; i<args.length; i++) {
					sb.append(args[i]);
					sb.append(" ");
				}
				
				if(loadDB){
					sendEmail("WORKDAY File Load Successfully Completed",
					"Processing completed successfully at " + new java.util.Date() +
					".\nCommand line was ( " + sb.toString() +
					" )\nNumber of lines processed=" + linecount); 
				}
			}
			Applogger.debug("------- Execution Finished Successfully--------");
		}
		catch (Exception e) {
			StringWriter sw = new StringWriter();      
			e.printStackTrace(new PrintWriter(sw));
			
			if (sendEmail) {
				sendEmail("WORKDAY Processing Failed",
				"The following exception occurred while processing line # " + 
				(linecount + 1) + "" +
				"\n\n"+sw.toString());      	
			}
			
			//Applogger.debug(sw.toString());
			Applogger.debug("------- Execution Finished Unsuccessfully--------");
		}
	}
	
	private static String str_replace(String source, String pattern, String replace) {
		//Integer dbg = Integer.parseInt(props.get("prod.debug").toString());
		if(dbg>0) Applogger.debug("Executing Private Function: str_replace Utility");    
		
		
		if (source!=null)
		{
			final int len = pattern.length();
			StringBuffer sb = new StringBuffer();
			int found = -1;
			int start = 0;
			
			while( (found = source.indexOf(pattern, start) ) != -1) {
				sb.append(source.substring(start, found));
				sb.append(replace);
				start = found + len;
			}
			
			sb.append(source.substring(start));
			
			return sb.toString();
		}
		else {
			return "";
		}
	}
	
}

