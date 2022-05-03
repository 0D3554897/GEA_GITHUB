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
import org.apache.log4j.FileAppender;
import org.apache.log4j.Level;
import org.apache.log4j.Logger;
import org.apache.log4j.PatternLayout;

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
*  java.exe -D user.dir=\LOGPATH -cp \CLASSPATH; \LIBPATH\activation.jar;\LIBPATH\commons-cli-1.0.jar;\LIBPATH\commons-email-1.1.jar;\LIBPATH\mail.jar;\LIBPATH\commons-net-1.4.1.jar;\LIBPATH\commonslog4j-1.2.9.jar;\LIBPATH\opencsv-1.8.jar;\LIBPATH\sqljdbc4.jar; com.ibm.imapsstg.cff -readDB -props \PROPPATH\ANY.properties -creds\PROPPATH\ANY.credentials -logfile \LOGPATH\ANY.log -debug 0
*   
*  Modification
*  ============
*  CR - # goes here   
*  Changes are described in a list here:
*  
*  
* 

*/
public class cff {
	
	private static String[] propKeys = {
		// from credentials files	
		"ftp.host","ftp.user","ftp.pw",
		"db.driver","db.url","db.user","db.pw",
		"mail.host","mail.user","mail.pw","mail.addressee",
		//from properties file
		"log.filename","prod.debug",
		"ftp.remote.filename","ftp.asc_file","ftp.ebc_file","ftp.archive.dir",
		"file.delimiter","file.enclosure","file.linestoskip","file.lfatend",
		"sql.query","sql.to_ebcdic","sql.ebcdic_columns",
	};
	
	private static HashMap props = new HashMap();	
	private static boolean    readDB     = false;
	private static int        linecount  = 0;
	private static Logger     appLogger  = null;
	private static int 		  dbg = 0;
	
	private static String propsFileName  = "unknown";
	private static String credsFileName  = "unknown";
	private static String fileName  = "unknown";
    private static String debugmarker = "init";	
	
	private static final String ASCII_Encoding = "US-ASCII";
	private static final String EBCDIC_Encoding = "Cp500";	
	private static ByteArrayOutputStream EBCDIC_OBJ;
	private static FileOutputStream EBCDIC_FILE;
	private static String ASCII_FileName = "D:\\apps_to_compile\\cff\\ASCII.TXT";
	private static String EBCDIC_FileName = "D:\\apps_to_compile\\cff\\PACKED.TXT";
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
		//String fileName = props.get("log.filename").toString();
		File   logdir  = new File(workingDir);
		File   logfile = new File(logdir, fileName);
		
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
		appLogger.debug("Log begins here. File name is " + fileName + ".");
	}


	
	/* process the supplied command line and set internal flags based on 
	* the command line. Note that this logic uses the Apache Commons CLI library
	* (http://commons.apache.org/cli) to perform this processing.
	*/
	
	private static void processCommandLine(String[] args) throws Exception {
		
		appLogger.debug("Parsing Command Line ");
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
		options.addOption("logfile",true,"java:worst.language.ever!");
		options.addOption("debug",true,"specify 0,1,2,or 3. See properties file.");
		
		CommandLineParser parser = new BasicParser();
		CommandLine cmdLine = parser.parse(options, args);
/*	
		if (cmdLine.hasOption("ftp")) {
			doFTP      = true;
			appLogger.debug("ftp switch activated");
		}
		
		if (cmdLine.hasOption("archive")) {
			archive    = true;
			appLogger.debug("archive switch activated");
		}
		
		if (cmdLine.hasOption("email")) {
			sendEmail  = true;
			appLogger.debug("email switch activated");
		}
*/		
			
		if (cmdLine.hasOption("readDB")) {
			readDB = true;
			appLogger.debug("readdb switch activated");
		}

		if (cmdLine.hasOption("props")) {
			propsFileName = cmdLine.getOptionValue("props");
		}
		
		if (cmdLine.hasOption("creds")) {
			credsFileName = cmdLine.getOptionValue("creds");
		}    
		if(dbg>0) appLogger.debug("Command Line Parsing Complete");
	}
	
	/*load properties from the supplied properties file. Uses an internal string array
	* to define the required properties. Will generate an exception if a property is
	* missing from the properties file.
	*/
	private static void loadProperties(String propsPath, String credsPath) throws Exception {
		
		appLogger.debug("Loading Properties");
		FileInputStream fis = new FileInputStream(propsPath);
		Properties p = new Properties();
		p.load(fis);
		fis.close();
		appLogger.debug("Loaded and Closed Properties File");
		
		if (new File(credsPath).exists()) {
			FileInputStream fisc = new FileInputStream(credsPath);
			p.load(fisc);
			fisc.close();
			appLogger.debug("Loaded and Closed Credentials File");
		}    
		//old way
		//Integer dbg = Integer.parseInt(props.get("prod.debug").toString());		
		for (int i=0; i<propKeys.length; i++) {
			String key = propKeys[i];
			int keylen = key.length();
			//appLogger.debug("keylength is " +keylen);
			if(dbg>2) appLogger.debug(key+ " is being processed.");
			//appLogger.debug(key + " yields substrings " +sev_char + " : " +seven_key +" and " + ele_char + " : " +eleven_key );
			if (!p.containsKey(key)) {	
				appLogger.debug(key+ " doesn't exist.");
				throw new Exception("Could not locate required property " + key);
			}else{
				//appLogger.debug("p.key exists as " +key);
				props.put(key, p.getProperty(key, "NoValue"));
				String keyVal = props.get(key).toString();
				if(dbg>2) appLogger.debug("Existing property " +key+ " is set to " +keyVal);				
			}
		}
		if(dbg>0) appLogger.debug("Loading Properties Complete");
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
		
		
		appLogger.debug("Getting Database Connection");
		String dbdriver = props.get("db.driver").toString();
		String dburl    = props.get("db.url").toString();
		String dbuser   = props.get("db.user").toString();
		String dbpw     = props.get("db.pw").toString();
		Integer isOracle = dbdriver.indexOf("oracle");
		
		if(dbg>0) appLogger.debug("Obtaining JDBC connection for driver=" + dbdriver +
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
		
		if(dbg>0) appLogger.debug("Obtained JDBC connection successfully.");
		return conn;
	}
	
	
	
	// WritePacked Decimal
	// In accordance with FDS Specification
	public static void WritePacked(java.io.ByteArrayOutputStream BAWriter,
		BigDecimal Val, int total, int precision) {
			
		
		if(dbg>2) appLogger.debug("Packing A Decimal ...");
		if(dbg>2) appLogger.debug("Input Val = " + Val.toString());
		if(dbg>2) appLogger.debug("Input total = " + Integer.toString(total));
		if(dbg>2) appLogger.debug("Input precision = " + Integer.toString(precision));
		
		
		// establish properties of decimal being written
		boolean positive = true;
		boolean signed = false;
		int size_of_array = total;

		// LLLLLL.RR
		int left = total - precision;
		int right = precision;

		// if odd number of nibbles, last nibble for sign
		if (total % 2 != 0) {
			signed = true;
			size_of_array = total + 1;
		}

		byte[] packed_bytes = new byte[size_of_array];

		// determine sign
		if (Val.compareTo(new BigDecimal("0.0")) == -1) {
			positive = false;
		}

		// Turn double to string
		String ValStr = Val.toString();

		// Replace '-' character with 0
		ValStr = ValStr.replace('-', '0');

		int decimal_index = ValStr.indexOf(".");
		int rdecimal_index = 0;
		if (decimal_index == -1){
			decimal_index = ValStr.length();
			rdecimal_index = 0;
			if(dbg>2) appLogger.debug("line 645: decimal index = " + decimal_index);
		}else{;
			rdecimal_index = ValStr.length() - 1 - decimal_index;
		}
		if(dbg>2) appLogger.debug("Left decimal_index = " + decimal_index);
		if(dbg>2) appLogger.debug("Right decimal_index = " + rdecimal_index);
		String LeftSide = ValStr.substring(0, decimal_index);	
		String RightSide = "";
		if(rdecimal_index==0) {
			RightSide = "";
		}else{
			RightSide = ValStr.substring(decimal_index + 1, ValStr.length());
		}
		if(dbg>2) appLogger.debug("RightSide " + RightSide);
		if(dbg>2) appLogger.debug("LeftSide = " + LeftSide);		
		// Pad with Zeros where appropriate
		while (LeftSide.length() < left) {
			LeftSide = "0" + LeftSide;
			if(dbg>2) appLogger.debug("Padding left side: " + LeftSide);
		}

		while (RightSide.length() < right) {
			RightSide = RightSide + "0";
			if(dbg>2) appLogger.debug("Padding right side: " + RightSide);
		}

		// Truncate where appropriate
		if (LeftSide.length() > left) {
			LeftSide = LeftSide.substring(LeftSide.length() - left, LeftSide
					.length());
		}

		if (RightSide.length() > right) {
			RightSide = RightSide.substring(0, right);
		}
		if(dbg>2) appLogger.debug("Resulting Interim String " + LeftSide + RightSide);
		
		// Add sign nibble
		// Sign is Reversed on FDS Invoice
		if (positive && signed) {
			RightSide = RightSide + "c";
		} else if (!positive && signed) {
			RightSide = RightSide + "d";
		}
		String dbgHex = "";
		String HexValues = LeftSide + RightSide;
		if(dbg>2) appLogger.debug("Value to be converted :" + HexValues);
		// Writing Packed
		try {

			// Every Byte == 2 Nibbles
			int count = 0;
			for (int i = 0; i < HexValues.length(); i += 2) {
				String cur_hex = "0x" + HexValues.substring(i, i + 2);
				byte cur_byte = (Integer.decode(cur_hex)).byteValue();
				if(dbg>2) appLogger.debug("  cur string :" + HexValues.substring(i, i + 2));
				if(dbg>2) appLogger.debug("  cur hex :" + cur_hex);
				if(dbg>2) appLogger.debug("  cur byte :" + cur_byte);
				dbgHex = dbgHex + " " + HexValues.substring(i, i + 2);
				if(dbg>2) appLogger.debug("  cum Hex :" + dbgHex);
				packed_bytes[count] = cur_byte;
				count++;
			}
			
			BAWriter.write(packed_bytes, 0, count);
			if(dbg>2) appLogger.debug("Decimal Packed");

		} catch (Exception e) {
			e.printStackTrace();
		}

	} // end Write Packed Decimal

	
	/* readDB
	* subroutine to read the db using SQL found in properties file and write the output to
	* EBCDIC or ASCII files, or both. To add headers and footers to target file, run the
	* program more than once using a different property file each time.
	*/
	private static void readDB() throws Exception {
		
		
		appLogger.debug("Creating File");
		if(dbg>0) appLogger.debug("Begin sql query process ...");
		
		Connection conn = getSQLConnection();
		Statement s = conn.createStatement();
		
		String ASCII_FileName = props.get("ftp.asc_file").toString();
		String EBCDIC_FileName = props.get("ftp.ebc_file").toString();
		
		ASCII_FILEOBJ = new java.io.PrintWriter(
							new java.io.OutputStreamWriter(
								new java.io.FileOutputStream(ASCII_FileName),"US-ASCII"));

		EBCDIC_OBJ = new java.io.ByteArrayOutputStream();
		EBCDIC_FILE = new java.io.FileOutputStream(EBCDIC_FileName);

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
	
		if(dbg>1) appLogger.debug("SQL Executed. " + rowCount + " records returned.");
/*		
		//convert comma separated string into Array. Used later to determine if any fields are to be converted to packed decimal format
		//and if a duplicate "ascii-only" version of the file is to be created.
		int to_ebc = Integer.parseInt(props.get("sql.to_ebcdic").toString());
		if(to_ebc > 0) {
			if(dbg>0) appLogger.debug("Using ebcdic, so find out which fields and if ascii file is also to be created");
			String e_colString = props.get("sql.ebcdic_columns").toString();
			//  "\\s*,\\s*"        \\s*,  is a space, tab, linebreak or form feed followed by a comma   \\s is same, but not followed by a comma
			String e_col_raString[] = e_colString.split(",");
			//java cannot take a string array, and automatically convert its contents into int, even if they are. So we have to do it.
			int ebcdic_cols[] = new int[e_col_raString.length];
			for(int vec_i = 0; vec_i < e_col_raString.length; vec_i++) {
				ebcdic_cols[vec_i] = Integer.parseInt(e_col_raString[vec_i]);
			}
		}else{
			if(dbg>0) appLogger.debug("Not using packed decimals");    	
		}   		
*/		
		ResultSetMetaData meta = rs.getMetaData();
        int colCount = meta.getColumnCount();
		int rowCtr = 0;
		int sxrc = 0;
		String dataRow = "";
		String dataVal = "";
		String ebcVal = "";
		int negVal = 0;
		int negInd = 0;
		// to_ebcdic contains file creation instructions - (0 means ASCII, 1 means packed, 2 means both)
		int to_ebc = Integer.parseInt(props.get("sql.to_ebcdic").toString());
		// ebcdic_columns contains which columns must be packed
		String e_cols = props.get("sql.ebcdic_columns").toString();
		//split it into a string array
		String e_cols_ra[] = e_cols.split(",");
		if(dbg>2) appLogger.debug("column count is " + colCount);
		if(dbg>1) appLogger.debug("Parsing Result Set and Writing File");
		while(rs.next()) {
			rowCtr++;
		    for (int column = 1; column <= colCount; ++column)   {
				Object value = rs.getObject(column);
				int v_match = 0;
				ebcVal = "";
				negInd = 0;
				dataVal = value.toString();
				//zero filled negative numbers might come in with minus sign in middle; 
				//but if two dashes come in a row, that's not a number, so leave those alone
				negVal = dataVal.indexOf("--");
				if (negVal == -1) {
					// can't find two dashes, so fix it
					negVal = dataVal.indexOf("-");
					if (negVal != -1) {
						//we have a negative
						if(dbg>0) appLogger.debug("dataVal before: " + dataVal);
						dataVal = dataVal.replace("-","0");
						dataVal = dataVal.substring(1);
						dataVal = "-" + dataVal;					
						ebcVal = dataVal.substring(1);
						negInd = -1;
						if(dbg>0) appLogger.debug("dataVal after: " + dataVal);				  
					}
				}
				if(dbg>2) appLogger.debug("row: " + rowCtr + " and dataVal" + column + " = " + dataVal);
				// pack data?
				if(to_ebc != 1) {
					//create ascii file 
					//enclose the value with enclosure
					//if last column, add a CRLF unless it is the last record
					if(dbg>2) appLogger.debug("775:col, last_col:" + column + ", " + colCount);
					if (column==colCount) {
						if (rowCtr==rowCount) {
							ASCII_FILEOBJ.print(dataVal);
							if(dbg>2) appLogger.debug("last line of file" + rowCount);
						}else{
						    ASCII_FILEOBJ.println(dataVal);
							if(dbg>2) appLogger.debug("wrote an ASC linefeed");
						}
					}else{
						//append the delimiter to end
						ASCII_FILEOBJ.print(dataVal);
					}					 					  	
				}
				if(to_ebc > 0) {					
					// some columns will be converted to packed decimal
					// search for counter variable "column" in the array
					// if found, then pack
					for(int vec_i = 0; vec_i < e_cols_ra.length; vec_i++) {
						if(column == Integer.parseInt(e_cols_ra[vec_i])) {
							v_match++;
						}
					}
					if (v_match==1){
						//convert this column
						//get length, positive or negative
						int totlen = dataVal.length() - 1;
						//get precision	
						int prec = 0;
						int pdIndex = dataVal.indexOf(".");
						if(dbg>2) appLogger.debug("Precision marker found at " + pdIndex);
						if (pdIndex != -1) {						
							prec = dataVal.split("\\.")[1].length();
						}else{
							//adjust length for lack of decimal
							totlen = totlen + 1;
						}
						if(dbg>2) appLogger.debug("Length is " + totlen + "; and Precision is " + prec);
						//if last column, add a CRLF unless it is last record of query
						if(dbg>2) appLogger.debug("809: col, last_col:" + column + ", " + colCount);
						if ( negInd == -1) {
							packVal = new BigDecimal(ebcVal);
							packVal = packVal.negate();
						}else{
							packVal = new BigDecimal(dataVal);							
						}
						negInd=0;
						if (column==colCount) {
							if (rowCtr==rowCount) {
							WritePacked(EBCDIC_OBJ, packVal, totlen, prec);
								if(dbg>2) appLogger.debug("last line of file");	
							}else{								
								WritePacked(EBCDIC_OBJ, packVal, totlen, prec);
								//EBCDIC_OBJ.write("\r".getBytes(ASCII_Encoding));  
								//EBCDIC newline = 0x15
								//WritePacked(EBCDIC_OBJ, new BigDecimal(15), 2, 0);
								if(dbg>2) appLogger.debug("wrote a packed linefeed");
							}
						}else{
							WritePacked(EBCDIC_OBJ, packVal, totlen, prec);
							if(dbg>2) appLogger.debug("wrote a packed column");
						}					 
					}else{
						//don't convert this column
						//if last column, add a CRLF
						if(dbg>2) appLogger.debug("819:col, last_col:" + column + ", " + colCount);
						if (column==colCount) {
							if (rowCtr==rowCount) {
								EBCDIC_OBJ.write(dataVal.getBytes(EBCDIC_Encoding));
								if(dbg>2) appLogger.debug("last line of file");	
							}else{		
								EBCDIC_OBJ.write(dataVal.getBytes(EBCDIC_Encoding));
								//EBCDIC_OBJ.write("\r".getBytes(ASCII_Encoding));
								//EBCDIC newline = 0x15
								//WritePacked(EBCDIC_OBJ, new BigDecimal(15), 2, 0);
								if(dbg>2) appLogger.debug("wrote an ebc linefeed");
							}
						}else{
							EBCDIC_OBJ.write(dataVal.getBytes(EBCDIC_Encoding));
							if(dbg>2) appLogger.debug("wrote an ebc column");
						}
					}
				}
    		}
			sxrc++;
			//write the row to the file
			//appLogger.debug(dataRow);

			//EBCDIC_OBJ.write(dataRow.getBytes(EBCDIC_Encoding));
			//dataRow = "";
		}
		linecount=sxrc;

		if(to_ebc > 0) {		
			EBCDIC_OBJ.writeTo(EBCDIC_FILE);
		}
		s.close();
		conn.close();
		ASCII_FILEOBJ.close();
		EBCDIC_OBJ.close();
		EBCDIC_FILE.close();
		
		
		if(dbg>1) appLogger.debug("Query Processed");
		if(dbg>0) appLogger.debug("File Creation Complete");
	
	}
	
	/* END readDB */

	public static void main(String[] args) {
		
		try {
			setupLogger(args);
		}
		catch (Exception e) {
			e.printStackTrace();
		}
		
		appLogger.debug("Executing Function: Main - arguments passed are:");
		for (String element:args ) {
			appLogger.debug( element );
		} 
		appLogger.debug("---------------------------------");
		try {
			
			//if(dbg>0) appLogger.info("------- Begin execution --------");
			
			if (args.length == 0) throw new Exception ("No arguments supplied.");
			
			processCommandLine(args);
			
			if (! new File(credsFileName).exists()) {
				appLogger.debug("Credentials file not found - attempting login using properties file");
			} else {
				appLogger.debug("Credentials file found");
			}
			
			if (! new File(propsFileName).exists()) {
				throw new Exception("Properties file= [" + propsFileName + "] not found.");
			} else {
				appLogger.debug("Properties file used: " + propsFileName);
			}
			
			loadProperties(propsFileName, credsFileName);
			
			if (readDB)     readDB();

			appLogger.info("------- Execution Finished Successfully--------");
		}
		catch (Exception e) {
			StringWriter sw = new StringWriter();      
			e.printStackTrace(new PrintWriter(sw));		
			appLogger.error(sw.toString());
			appLogger.info("------- Execution Finished Unsuccessfully--------");
		}
	}
	
	private static String str_replace(String source, String pattern, String replace) {
		
		appLogger.debug("Executing Private Function: str_replace Utility");    
		
		
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

