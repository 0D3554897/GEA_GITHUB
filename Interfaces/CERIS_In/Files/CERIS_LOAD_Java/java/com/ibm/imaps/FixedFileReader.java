package com.ibm.imaps;


import java.util.Properties;
import java.util.HashMap;

//import java.util.Date;
//import java.text.SimpleDateFormat;

import java.io.FileInputStream;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.io.File;
import java.io.ByteArrayOutputStream;

import org.apache.commons.io.IOUtils;

import org.apache.log4j.Logger;
import org.apache.log4j.FileAppender;
import org.apache.log4j.Level;
import org.apache.log4j.PatternLayout;

import org.apache.commons.net.ftp.FTPClient;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
//import java.sql.ResultSet;
//import java.sql.Statement;


public class FixedFileReader {

	
	//prototype for reading fixed format files
	
	//properties parameters for everything
	//put flags for getting file from FTP vs loading from parameter
	//add info for truncating/loading the db
	
	//find out if encryption needed or not
	
	/**
	 * arg[0] = properties file path
	 */

	//TODO: determine whether we will use JRE 1.4.2 or JRE 1.6
	
	
	private static Properties	p = null;	
	private static Logger		appLogger  = null;
	private static byte[]		bytes=null;
	
	


	private static void loadProperties(String propsPath) throws Exception {
		FileInputStream fis = new FileInputStream(propsPath);
		p = new Properties();
		p.load(fis);
		fis.close();
	}
	
	
	private static void setupLogFile() throws Exception {
		
		/*
		Date now = new Date();
	  	SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd'.'HHmmss");
	  	String prepend = sdf.format(now);
	  	*/
		
		String log_file_path = p.getProperty("log_file_path");	
	    File   logfile = new File(log_file_path);
	    Logger rootLogger = Logger.getRootLogger();
	    if (!rootLogger.getAllAppenders().hasMoreElements()) {
	      rootLogger.setLevel(Level.INFO);
	      FileAppender appender = new FileAppender();
	      appender.setFile(logfile.getAbsolutePath(), false, false, 0);
	      appender.setLayout(new PatternLayout("%d{MM/dd/yy HH:mm:ss.SSS} %15t %-30c %m%n"));
	      rootLogger.addAppender(appender);
	      appLogger = rootLogger.getLoggerRepository().getLogger("com.ibm.imaps");
	      appLogger.setLevel(Level.ALL);
	    } 
	    appLogger.debug("Log Created ...");
	}
	
	
	private static String getProperty(String key) throws Exception {
		try{
			String value = (String) p.get(key);				
			return value.trim();
		}
		catch(Exception e)
		{
			appLogger.error("ERROR: "+"No value for key '"+key+"' exists in properties file !!!");
			appLogger.error("ERROR: "+"Error: "+ e.getMessage());	
			StringWriter sw = new StringWriter();     
			e.printStackTrace(new PrintWriter(sw));
			appLogger.error("ERROR: "+sw.toString());
			throw e;
		}
	}

	
	private static void loadByteArray() throws Exception
	{
		String ftp_flag = getProperty("ftp.pull");
		
		if(ftp_flag.equals("no"))
		{
			appLogger.debug("Reading Local File into Byte Array...");
			String source_file_path = getProperty("source_file_path");
			FileInputStream is = new FileInputStream(source_file_path);
			bytes = IOUtils.toByteArray(is);
			is.close();						
			appLogger.debug("Local Source File: "+source_file_path);
			appLogger.debug("Bytes in File    : "+Integer.toString(bytes.length));
		}
		else
		{
			
			appLogger.debug("Initiating FTP ... ");
		    String host = getProperty("ftp.host");
		    String file = getProperty("ftp.file");
		    String user = getProperty("ftp.user");
		    String pass = getProperty("ftp.pass");
		    FTPClient client = new FTPClient();
		    ByteArrayOutputStream bos = new ByteArrayOutputStream(); 

		    try
		    {
		    	appLogger.debug("file retrieval FTP begins to host="+ host + " as user=" + user);
			    appLogger.debug("file retrieval begin connect");
			    client.connect(host);

			    appLogger.debug("file retrieval connected OK.");

			    if (!client.login(user, pass)) {

			      appLogger.error("file retrieval login to remote host failed.");

			      client.disconnect();
			      throw new Exception("Invalid FTP login credentials");
			    }
    
			    client.retrieveFile(file, bos);    

			    int clientReplyCode = client.getReplyCode();
			    appLogger.debug("file retrieval client reply code =" + clientReplyCode);

			    if (clientReplyCode < 200 || clientReplyCode >= 300) {
			      client.logout();
			      client.disconnect();
			      throw new Exception("file retrieval fails with client reply code="+clientReplyCode);
			    }
			    
			    bytes = bos.toByteArray();
			    appLogger.debug("Number of bytes read via FTP=" + bytes.length + " (" + file + ")");

			    /* see finally
			    appLogger.debug("file retrieval closing FTP connection.");
			    bos.close();
			    client.logout();
			    client.disconnect();
			    */
			    appLogger.debug("file retrieval processing completed.");	    	
		    }
		    //handle errors
			catch (Exception e) {	
				appLogger.error("ERROR: "+"Error: "+ e.getMessage());	
				StringWriter sw = new StringWriter();     
				e.printStackTrace(new PrintWriter(sw));
				appLogger.error("ERROR: "+sw.toString());
				System.out.println("Error: "+ e.getMessage());
				e.printStackTrace();
				throw e;
			}
			//ensure files are closed
			finally {
				/***************
				 CLOSE LOG FILE
				 ****************/
			    appLogger.debug("file retrieval closing FTP connection.");
				client.logout();
			    client.disconnect();
			    bos.close();
			}
		}
		   
	}
	
	
	private static Connection getSQLConnection() throws Exception {

		    String dbdriver = getProperty("db.driver");
		    String dburl    = getProperty("db.url");
		    String dbuser   = getProperty("db.user");
		    String dbpw     = getProperty("db.pw");

		    appLogger.debug("Obtaining JDBC connection for driver=" + dbdriver + ", url=" + dburl );

		    Class.forName(dbdriver).newInstance();
		    // Connection conn = DriverManager.getConnection(dburl,dbuser,dbpw);

		    Properties p = new Properties();
		    p.put("user", dbuser);
		    p.put("password", dbpw);
		    p.put("sendStringParametersAsUnicode", "false");    
		    Connection conn = DriverManager.getConnection(dburl,p);
		    
		    appLogger.debug("Obtained JDBC connection successfully.");
		    return conn;
		  }
	
	
	public static void main(String[] args) throws Exception {
		
		/***************
		 LOAD PROPERTIES
		 ****************/
		//properties file path needs to be a runtime parameter
		if (args.length == 0) throw new Exception ("No arguments supplied.");
		loadProperties(args[0]);
	    
	    /***************
		 SETUP LOG FILE
		 ****************/
		setupLogFile();
	    
		
		int rec_no=0;
		// Try Program logic
		try {
							
			/***************
			 READ SOURCE FILE FORMAT PROPERTIES
			 ****************/	
			appLogger.debug("Reading Source File Format properties ...");
			String source_file_character_encoding = getProperty("source_file_character_encoding");
			String source_file_recl_str = getProperty("source_file_recl");
			int source_file_recl = Integer.parseInt(source_file_recl_str);

			String[] record_indicator_location = getProperty("record_indicator_location").split(",");		
			int record_indicator_start = Integer.parseInt(record_indicator_location[0]);
			int record_indicator_length = Integer.parseInt(record_indicator_location[1]);
			
			
			/***************
			 READ SOURCE FILE
			 ****************/	
			loadByteArray();
			
			/***************
			 GET SQL Connection
			 ****************/
			Connection conn = getSQLConnection();
			
			int batch_start=0;
			int batch_end=0;
			int batch_length=Integer.parseInt(getProperty("insert_batch_size"));
			String record_table_insert_last = "first";
			try
			{
				//loop through records
				appLogger.debug("Looping through records in Byte Array ...");
				int start_byte = 0;
				boolean loop = true;
				PreparedStatement ps = null;
				
				while (loop)
				{
					
					HashMap record_map = new HashMap();				
					
					String record = new String(bytes, start_byte, source_file_recl, source_file_character_encoding);					
					//appLogger.debug(record);
					
					String record_indicator = record.substring(record_indicator_start,record_indicator_start+record_indicator_length);					
					//appLogger.debug("Record Indicator = " + record_indicator);
					
				
					//loop through data elements
					String[] data_elements = getProperty("record_"+ record_indicator +"_data_elements").split(",");				
					for(int i=0; i<data_elements.length; i++)
					{
						String data_element = data_elements[i];					
						
						String[] data_element_location = getProperty("record_"+ record_indicator + "_" +data_element).split(",");
						
						if (data_element_location.length != 2)
						{
							appLogger.error("ERROR: "+"record_"+ record_indicator + "_" +data_element+" property is malformed");
							throw new Exception("record_"+ record_indicator + "_" +data_element+" property is malformed");
						}
						
						int data_element_start = Integer.parseInt(data_element_location[0]);
						int data_element_length = Integer.parseInt(data_element_location[1]);					
						String data_element_value = record.substring(data_element_start, data_element_start+data_element_length);
						
						record_map.put(data_element, data_element_value);										
					}//end loop data elements


					
					//before CHECKS and TRUNCATION (XX_CERIS_LOAD_STEP1_SP)
					
					//LOAD RECORDS					
				    String record_table_insert = getProperty("record_"+ record_indicator+"_table_insert");
				    
				    batch_end++;
				    
				    if(record_table_insert_last.equals("first"))
				    {
				    	appLogger.debug("Preparing Batch Insert FIRST: " + record_indicator);
				    	batch_start=1;
				    	ps = conn.prepareStatement(record_table_insert);
				    }
				    else if (!record_table_insert_last.equals(record_table_insert) || batch_end-batch_start > batch_length-1)
				    {
				    	appLogger.debug("Executing Batch Insert: " + record_indicator + " " + Integer.toString(batch_start)+"-"+Integer.toString(batch_end-1));
						ps.executeBatch();
						appLogger.debug("Preparing Batch Insert NEW: " + record_indicator +  " " + Integer.toString(batch_end)+"-"+Integer.toString(batch_end+batch_length-1));
						batch_start=batch_end;
						ps = conn.prepareStatement(record_table_insert);
				    }				    
				    //ps = conn.prepareStatement(record_table_insert);
				    
				    for(int i=0; i<data_elements.length; i++)
					{
						String data_element = data_elements[i];	
						//appLogger.debug(data_element +":"+ record_map.get(data_element)+",");
						ps.setString(i+1, (String) record_map.get(data_element));
					}	
				    //ps.executeUpdate();
				    ps.addBatch();			
				    record_table_insert_last=record_table_insert;
					
					start_byte=start_byte+source_file_recl;
					rec_no++;
					
					
					if(!(start_byte+source_file_recl <= bytes.length))
					{
						loop=false;
						appLogger.debug("Executing Batch Insert FINAL: " + record_indicator + " " + Integer.toString(batch_start)+"-"+Integer.toString(batch_end));
						ps.executeBatch();
					}
					//END LOAD
					
					
				}//end loop records
				
				
				//after CHECKS and RECON/ARCHIVE (XX_CERIS_LOAD_STEP3_SP)
			
				
			}
			//handle errors
			catch (Exception e) {	
				appLogger.error("ERROR: "+"Record No: "+Integer.toString(rec_no));
				appLogger.error("ERROR: "+"Error: "+ e.getMessage());	
				StringWriter sw = new StringWriter();     
				e.printStackTrace(new PrintWriter(sw));
				appLogger.error("ERROR: "+sw.toString());
				System.out.println("Error: "+ e.getMessage());
				e.printStackTrace();
				throw e;
			}
			//ensure connection is closed
			finally {
				/***************
				 CLOSE CONNECTION
				 ****************/
				conn.close();
				appLogger.debug("SQL connection closed.");
				
			}
			
			
			appLogger.debug("COMPLETED - Record Count: "+Integer.toString(rec_no));
			
		}
		//handle errors
		catch (Exception e) {	
			appLogger.error("ERROR: "+"Record No: "+Integer.toString(rec_no));
			appLogger.error("ERROR: "+"Error: "+ e.getMessage());	
			StringWriter sw = new StringWriter();     
			e.printStackTrace(new PrintWriter(sw));
			appLogger.error("ERROR: "+sw.toString());
			System.out.println("Error: "+ e.getMessage());
			e.printStackTrace();
			throw e;
		}
		//ensure files are closed
		finally {
			/***************
			 CLOSE LOOSE ENDS
			 ****************/
			//conn.close();
			;
		}
		
		

	} //end main

} //end class
