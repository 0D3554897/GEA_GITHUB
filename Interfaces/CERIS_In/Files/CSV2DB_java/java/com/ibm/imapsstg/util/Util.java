package com.ibm.imapsstg.util;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.util.Properties;

import org.apache.commons.net.ftp.FTPClient;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/* A utility class for performing various operations required by the main program */

public class Util {
	
	private static final Logger logger = LogManager.getLogger(Util.class);
	
	/* 
	 * execute an FTP read from a remote host returning the result as a byte array. 
	 * Assumes the contents of the remote file are ASCII. Uses the Apache Commons Net
	 * library to perform the actual FTP.
	 */ 
	public static byte[] readFTP(String host,
			                         String remoteFileName,
			                         String user,
			                         String password) 
	                             throws Exception {
		
    FTPClient client = new FTPClient();

    logger.debug("file retrieval FTP begins to host="+ host + " as user=" + user);
    logger.debug("file retrieval begin connect");

    client.connect(host);

    logger.debug("file retrieval connected OK.");

    if (!client.login(user, password)) {

      logger.error("file retrieval login to remote host failed.");

      client.disconnect();
      throw new Exception("Invalid FTP login credentials");
    }

    ByteArrayOutputStream bos = new ByteArrayOutputStream();     
    boolean rc = client.retrieveFile(remoteFileName, bos);    

    int clientReplyCode = client.getReplyCode();
    logger.debug("file retrieval client reply code =" + clientReplyCode);

    if (clientReplyCode < 200 || clientReplyCode >= 300) {
      client.logout();
      client.disconnect();
      throw new Exception("file retrieval fails with client reply code="+clientReplyCode);
    }
    
    byte[] bytes = bos.toByteArray();
    logger.debug("Number of bytes read via FTP=" + bytes.length + " (" + remoteFileName + ")");

    logger.debug("file retrieval closing FTP connection.");

    client.logout();
    client.disconnect();

    logger.debug("file retrieval processing completed.");
    
    return bytes;
	}
	
	/* 
	 * Load a Java properties file 
	 */ 
	public static Properties loadPropeties(String propFilePath) throws Exception {
		
		if (!new File(propFilePath).exists()) {
			throw new Exception("Specified properties file=" + propFilePath + " not found.");
		}
		
		FileInputStream fis = new FileInputStream(propFilePath);
		Properties p = new Properties();
		p.load(fis);
		fis.close();
		return p;		
	}

	/*test driver */
	
	public static void main(String[] args) throws Exception {
		
		byte[] bytes = readFTP("stfmvs1.pok.ibm.com",
				                     "'PWCCFTP.PWCC22.CSV'",
				                     "pwccftp",
				                     "get1slow");
		
		FileOutputStream fos = new FileOutputStream("c:/temp/ftptest.txt");
		fos.write(bytes);
		fos.close();
	}
}
