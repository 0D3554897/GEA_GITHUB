package com.ibm.imaps;

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
import java.sql.Statement;
import java.text.SimpleDateFormat;
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

import com.ibm.imaps.util.ExcelBuilder;
import com.ibm.imaps.util.MailTool;
import com.ibm.imaps.util.Util;
import com.ibm.xslt4j.java_cup.runtime.Scanner;

import crypto.AESCrypto;

/*
 * This program is a command line utility that provides several miscellaneous 
 * functions associated with the encryption and inbound processing of the CERIS files
 * for Research (Division 22).
 * 
 *  The program supports the following command line parameters as flags to control
 *  which subset of processing is requested during a particular invocation. Note that multiple
 *  switches can be used in a single invocation; the order of execution follows the list
 *  below
 *  
 *  -key			  Generate an AES(128bit) symmetric key and store in the database
 *  -truncate	  Clear the staging table  
 *  -ftp    	  FTP the CERIS file, encrypt and write to filesystem using the key created above
 *  -loaddb 	  Load and process a previously encrypted file so that data is loaded into staging table
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
 */

public class CERISEncrypter {

  private static String[] propKeys = {
    "ftp.host","ftp.user","ftp.pw","ftp.remote.filename","ftp.local.filename","ftp.archive.dir",
    "serialxref.email","serialxref.xlsname","serialxref.subject","serialxref.body","serialxref.mimeType",
    "db.driver","db.url","db.user","db.pw",
    "mail.host","mail.user","mail.pw","mail.addressee",
    "sql.readKey", "sql.writeKey","sql.truncate",
    "sql.openSQLKey","sql.closeSQLKey","sql.readSQLKeyPassword",
    "sql.insert","sql.serialxref"
  };

  private static HashMap props = new HashMap();

  private static boolean    doFTP      = false;
  private static boolean    genKey     = false;
  private static boolean    loadDB     = false;
  private static boolean    truncateDB = false;
  private static boolean    sendEmail  = false;
  private static boolean    archive    = false;
  private static boolean    serialxref = false;
  
  private static int        linecount  = 0;
  private static Logger     appLogger  = null;

  private static String propsFileName = "unknown";
  
  /* process the supplied command line and set internal flags based on 
   * the command line. Note that this logic uses the Apache Commons CLI library
   * (http://commons.apache.org/cli) to perform this processing.
   */

  private static void processCommandLine(String[] args) throws Exception {

    Options options = new Options();

    options.addOption("key",false,"request generation of encryption key (with store of key to DB");
    options.addOption("ftp",false,"request FTP of file from CERIS host");
    options.addOption("loaddb",false,"load CERIS info from file into SQL db");
    options.addOption("truncate",false,"clear existing info from SQL db");
    options.addOption("email",false,"send email when program completes");
    options.addOption("archive",false,"archive encrypted FTP file");
    options.addOption("serialxref",false,"generate and send serial number cross ref report");
    options.addOption("props",true,"properties file path");

    CommandLineParser parser = new BasicParser();
    CommandLine cmdLine = parser.parse(options, args);

    if (cmdLine.hasOption("key"))        genKey     = true;
    if (cmdLine.hasOption("ftp"))        doFTP      = true;
    if (cmdLine.hasOption("loaddb"))     loadDB     = true;
    if (cmdLine.hasOption("truncate"))   truncateDB = true;
    if (cmdLine.hasOption("archive"))    archive    = true;
    if (cmdLine.hasOption("email"))      sendEmail  = true;
    if (cmdLine.hasOption("serialxref")) serialxref  = true;

    if (cmdLine.hasOption("props")) {
      propsFileName = cmdLine.getOptionValue("props");
    }
  }

  /*load properties from the supplied properties file. Uses an internal string array
   * to define the required properties. Will generate an exception if a property is
   * missing from the properties file.
   */
  private static void loadProperties(String propsPath) throws Exception {

    FileInputStream fis = new FileInputStream(propsPath);
    Properties p = new Properties();
    p.load(fis);
    fis.close();

    for (int i=0; i<propKeys.length; i++) {
      String key = propKeys[i];
      if (!p.containsKey(key)) {
        throw new Exception("Could not locate required property " + key);
      }
      props.put(key, p.getProperty(key, "MissingValue"));
    }
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
  private static Connection getSQLConnection() throws Exception {

    String dbdriver = props.get("db.driver").toString();
    String dburl    = props.get("db.url").toString();
    String dbuser   = props.get("db.user").toString();
    String dbpw     = props.get("db.pw").toString();

    appLogger.debug("Obtaining JDBC connection for driver=" + dbdriver +
                    ", url=" + dburl + ", user=" + dbuser );

    Class.forName(dbdriver).newInstance();
//    Connection conn = DriverManager.getConnection(dburl,dbuser,dbpw);

    Properties p = new Properties();
    p.put("user", dbuser);
    p.put("password", dbpw);
    p.put("sendStringParametersAsUnicode", "false");    
    Connection conn = DriverManager.getConnection(dburl,p);
    
    appLogger.debug("Obtained JDBC connection successfully.");
    return conn;
  }
  
  /*
   * A utility routine to send email to the administrator designated for this program.
   * Uses Apache Commons Email which provides a simplied interface on top of the 
   * Java Mail API (which is also required)
   */
  
  private static void sendEmail(String subject, String body) {
  	
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
      StringWriter sw = new StringWriter();      
      e.printStackTrace(new PrintWriter(sw));
      appLogger.error(sw.toString());  		
  	}
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
      StringWriter sw = new StringWriter();      
      e.printStackTrace(new PrintWriter(sw));
      appLogger.error(sw.toString());  		
  	}
  }
  
  /* 
   * Read a property or parameter from the staging database. For each such parameter
   * it is expected that the SQL used to retrieve the parameter is defined in the 
   * external properties file under a well known key. Again, not super effiicient
   * but flexible and simple.
   */
  private static String readStringFromSQL(String sqlKey) throws Exception {
  	
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
  	
  	return result;
  }

  /* 
   * initialize the Log4J logger to log into the current working directory. Called from
   * main() entry point.
   */
  private static void setupLogger() throws Exception {

    String workingDir = System.getProperty("user.dir");
    File   logdir  = new File(workingDir);
    File   logfile = new File(logdir,"cerislog.txt");

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

  /*
   * Use a utility library to generate an AES key then store it in the database. The
   * SQL required to store the key is supplied in the properties file under 
   * a well known key. Will generate a SQL exception if the key already exists.
   */
  private static void generateKey() throws Exception {

    appLogger.debug("Begin key generation ...");
    SecretKey key = AESCrypto.generateKey();
    appLogger.debug("Key generation completed");

    byte[] bytes = key.getEncoded();

    appLogger.debug("Key insertion into db begins");

    String SQL = props.get("sql.writeKey").toString();

    Connection conn = getSQLConnection();
    PreparedStatement ps = conn.prepareStatement(SQL);
    ps.setBytes(1, bytes);
    int rc = ps.executeUpdate();

    ps.close();
    conn.close();

    if (rc != 1) appLogger.error("Insert of key into SQL DB fails.");
    else         appLogger.debug("Key insertion into db completed");
  }

  /* Utility function used to retrieve the encryption key from the database for
   * use in both encryption and decryption related functions. The
   * SQL required to retrieve the key is supplied in the properties file under 
   * a well known key. Will generate an application exception if the key is not found.
   * 
   */
  private static SecretKey retrieveKey() throws Exception {

    appLogger.debug("Begin retrieval of key from DB");
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

    appLogger.debug("Complete retrieval of key from DB");

    return key;
  }
  
  /* uses utility functions to FTP the CERIS file from the mainframe, encrypt it
   * while in memory, and write the encrypted contents to an output file. The output
   * file location is assumed to be specified as an external parameter stored in
   * the staging database; all FTP parameters are stored directly in the properties 
   * file.
   */

  private static void executeFTP() throws Exception {

    String ftphost     = props.get("ftp.host").toString();
    String ftpuser     = props.get("ftp.user").toString();
    String ftppw       = props.get("ftp.pw").toString();
    String remoteFname = props.get("ftp.remote.filename").toString();

    //String localFname  = readStringFromSQL("sql.localFileName");
    String localFname  = props.get("ftp.local.filename").toString();
    //if (localFname == null)
    //  throw new Exception("Could not locate local fn in db");    

    appLogger.debug("Begin file retrieval via FTP");
    byte[] bytes = Util.readFTP(ftphost, remoteFname, ftpuser, ftppw);
    appLogger.debug("FTP completed.");

    ByteArrayInputStream bis = new ByteArrayInputStream(bytes);
    FileOutputStream fos = new FileOutputStream(localFname);
    SecretKey key = retrieveKey();

    appLogger.debug("Begin encryption to file (" + localFname + ").");
    AESCrypto.encrypt(bis, key, fos);
    fos.close();
    appLogger.debug("File encryption completed.");
  }

  /* 
   * Clear the staging table into which CERIS file contents are loaded. Presumably used
   * at the beginning of a cycle to remove the prior contents. The SQL used to perform
   * this task must be defined externally in the properties file.
   */
  private static void truncateDatabase() throws Exception {

    appLogger.debug("Begin db truncate ...");

    String SQL = props.get("sql.truncate").toString();

    Connection conn = getSQLConnection();
    Statement s = conn.createStatement();
    int rc = s.executeUpdate(SQL);

    s.close();
    conn.close();

    appLogger.debug("Complete db truncate. Num rows affected="+rc);
  }

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
  private static void loadDatabase() throws Exception {

    appLogger.debug("Begin database load ...");

    //String localFname  = readStringFromSQL("sql.localFileName");
    String localFname  = props.get("ftp.local.filename").toString();
    
    //if (localFname == null)
    //  throw new Exception("Could not locate local fn in db");    

    appLogger.debug("Loading encrypted data from file=" + localFname);

    FileInputStream fis = new FileInputStream(localFname);
    SecretKey key = retrieveKey();

    appLogger.debug("Begin decryption of file="+localFname);
    ByteArrayOutputStream bos = new ByteArrayOutputStream();

    try {
      AESCrypto.decrypt(fis, key, bos);
    }
    catch (Exception e){
      fis.close();
      throw e;
    }

    appLogger.debug("Decryption completed.");

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
    	  if (rc != 1) 	throw new Exception("Update to SQL failed. LineCount="+linecount);
    	}
    	catch (Exception e) {
    		appLogger.error("SQL Exception encountered during insert loop. Line #=" + (linecount+1));
    		throw e;
    	}
      linecount++;
      
    }                
    
    SQL = props.get("sql.closeSQLKey").toString(); 
    s.execute(SQL);
    
    conn.commit();
    
    s.close();
    conn.close();
    appLogger.debug("Complete database load. Number of lines processed="+linecount);
  }
  
  /*
   * subroutine to archive the encrypted file retrieved via FTP. Archive directory
   * is supplied via a configuration parameter. File name has datetime stamp
   * preprended to it before copy occurs. Copied file is checked for datetime stamp
   * and file size before orginial is removed.
   */
  
  private static void doArchive() throws Exception {
  	
  	appLogger.debug("Begin archiving request");
  	
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
  	
  	appLogger.debug("Begin copy operation (" + fsize + " bytes) from file=" + 
  			             f.getAbsolutePath() + " to file=" + archiveFile.getAbsolutePath());
 
  	boolean rc = f.renameTo(archiveFile);
  	if (!rc) throw new Exception ("Archive file rename(move) operation fails.");
 
  	appLogger.debug("Archive operation completes successfully");  	
  }

  /* 
   * subroutine to generate and e-mail a cross reference report for serial numbers. This
   * is generated to map "real" serial numbers to "hidden" serial numbers and also include
   * mapping of the serial number information to information in the Project Workforce
   * tables in IMAR
   */
  private static void doSerialxref() throws Exception {

    appLogger.debug("Begin serial xref process ...");

    Connection conn = getSQLConnection();
    Statement s = conn.createStatement();
    
    String SQLPassword = readStringFromSQL("sql.readSQLKeyPassword");
    if (SQLPassword == null) {
      throw new Exception("Could not read SQL Key password from DB");	
    }
    
    String SQL = null;
    SQL = props.get("sql.openSQLKey").toString();
    SQL = str_replace(SQL,"?",SQLPassword);       
    s.execute(SQL);
    
    SQL = props.get("sql.serialxref").toString();    
    ResultSet rs = s.executeQuery(SQL);
    
    String[] headers = {"First Name", "Last Name", "Real Serial Number", 
                       "Fake Serial Number", "Project Being Worked On"};
    ByteArrayOutputStream bos = new ByteArrayOutputStream();
    ExcelBuilder.build(rs, headers, bos);    
    
    SQL = props.get("sql.closeSQLKey").toString(); 
    s.execute(SQL);    
        
    s.close();
    conn.close();
    
    byte[] bytes = bos.toByteArray();
    
    appLogger.debug("Excel generation complete, size="+ bytes.length);
    
    appLogger.debug("Beginning email transmit ...");
    
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
    
    appLogger.debug("Completed email transmit.");
    appLogger.debug("Complete serial xref generation");  	
  }
  
  /*
   * main entry point to application
   */
  
  public static void main(String[] args) {
  	
    try {
      setupLogger();
    }
    catch (Exception e) {
      e.printStackTrace();
    }

    try {

      appLogger.info("------- Begin execution --------");

      if (args.length == 0) throw new Exception ("No arguments supplied.");

      processCommandLine(args);

      if (! new File(propsFileName).exists()) {
        throw new Exception("Properties file= [" + propsFileName + "] not found.");
      }

      loadProperties(propsFileName);

      if (genKey)     generateKey();
      if (truncateDB) truncateDatabase();
      if (doFTP)      executeFTP();
      if (loadDB)     loadDatabase();
      if (archive)    doArchive();
      if (serialxref) doSerialxref();
      
      if (sendEmail) {
      	
      	StringBuffer sb = new StringBuffer();
      	for (int i=0; i<args.length; i++) {
      		sb.append(args[i]);
      		sb.append(" ");
      	}
      	
      	sendEmail("CERIS Encrytption Processing Successfully Completed",
      			      "Processing completed successfully at " + new java.util.Date() +
      			      ".\nCommand line was ( " + sb.toString() +
      			      " )\nNumber of lines processed=" + linecount); 
      }

      appLogger.info("------- Finish execution --------");
    }
    catch (Exception e) {
      StringWriter sw = new StringWriter();      
      e.printStackTrace(new PrintWriter(sw));
      
      if (sendEmail) {
      	sendEmail("CERIS Encrytption Processing Failed",
      			      "The following exception occurred while processing line # " + 
      			      (linecount + 1) + "" +
      			      "\n\n"+sw.toString());      	
      }
      
      appLogger.error(sw.toString());
    }
  }
  
  private static String str_replace(String source, String pattern, String replace)
  {
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
