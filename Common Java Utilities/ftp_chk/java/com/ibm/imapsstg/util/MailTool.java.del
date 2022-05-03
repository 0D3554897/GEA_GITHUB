package com.ibm.imaps.util;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Properties;

import javax.activation.DataHandler;
import javax.activation.DataSource;
import javax.mail.Address;
import javax.mail.Message;
import javax.mail.Multipart;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeBodyPart;
import javax.mail.internet.MimeMessage;
import javax.mail.internet.MimeMultipart;

import org.apache.log4j.Logger;

/* A wrapper class around the JavaMail API used by the main program
 * to hide the details of invoking said API. In particular, this utility
 * was constructed to optionally support transmission of a single binary
 * attachment provided as an InputStream;
 * 
 * The body of the mail message is transmitted as HTML.
 * 
 * @author Michael Freeman
 * @version 1.0
 */

public class MailTool {
	
	private static final Logger logger = Logger.getLogger(MailTool.class);
		
	private List   recipients  = new ArrayList();
	private String mimeType    = "text/plain";
	private String message     = "This is an error.";
	private String subject     = "This is an error.";
	private String host        = null;
	private String user        = null;
	private String password    = null;	
	private List   ccList      = null;
	
	private InputStream attachment         = null;
	private String      attachmentName     = "unknown";
	private String      attachmentMimeType = "text/plain";
		
	public String getMessage() {
		return message;
	}

	public String getMimeType() {
		return mimeType;
	}

	public List getRecipients() {
		return recipients;
	}

	public List getCarbonCopy() {
		return this.ccList;
	}
	
	public String getSubject() {
		return subject;
	}
	
	public InputStream getAttachment() {
		return this.attachment;
	}

	public void setMessage(String message) {
		this.message = message;
	}

	public void setMimeType(String mimeType) {
		this.mimeType = mimeType;
	}

	public void setRecipients(List receipients) {
		this.recipients = receipients;
	}

	public void setCarbonCopy(List cc) {
		this.ccList = cc;
	}
	
	public void setSubject(String subject) {
		this.subject = subject;
	}

	public String getHost() {
		return host;
	}

	public String getPassword() {
		return password;
	}

	public String getUser() {
		return user;
	}

	public void setHost(String host) {
		this.host = host;
	}

	public void setPassword(String password) {
		this.password = password;
	}

	public void setUser(String user) {
		this.user = user;
	}
	
	public void setAttachment(InputStream attachment) {
		this.attachment = attachment;
	}
	
	public String getAttachmentName() {
		return attachmentName;
	}

	public void setAttachmentName(String attachmentName) {
		this.attachmentName = attachmentName;
	}

	public String getAttachmentMimeType() {
		return attachmentMimeType;
	}

	public void setAttachmentMimeType(String attachmentMimeType) {
		this.attachmentMimeType = attachmentMimeType;
	}

	public void sendMail() throws Exception {
		
		if (host == null || user == null || password == null) {
			
			throw new IllegalArgumentException(
					"One or more required properties are missing.");
		}
				
		Properties props = new Properties();
	  Session session = Session.getDefaultInstance(props, null);
	  
	  MimeMessage message = new MimeMessage(session);
	  message.setSubject(this.subject);
	  
	  for (Iterator i=this.recipients.iterator(); i.hasNext(); ) {
	  	Address to_address = new InternetAddress((String)i.next());
	  	message.addRecipient(Message.RecipientType.TO,to_address);
	  }
	  
	  if (ccList != null && ccList.size() > 0) {
		  for (Iterator i=this.ccList.iterator(); i.hasNext(); ) {
		  	Address cc_address = new InternetAddress((String)i.next());
		  	message.addRecipient(Message.RecipientType.CC,cc_address);
		  }	  	
	  }
	  
	  Address from_address = new InternetAddress(user);		  
	  message.setFrom(from_address);
	  
	  if (attachment == null ) {
	    message.setContent(this.message,this.mimeType);	  
	  }
	  else {
	  	Multipart multipart = new MimeMultipart();
	  	
	  	MimeBodyPart messageBodyPart = new MimeBodyPart();
	  	
	  	messageBodyPart.setContent(this.message,this.mimeType);
	  	multipart.addBodyPart(messageBodyPart);
	  	
	  	messageBodyPart = new MimeBodyPart();	  	  
	  	DataSource source =
  	  	 new InputStreamDataSource(attachmentName,
  	  	                           attachmentMimeType,
  	  	                           attachment);
  	  
  	  messageBodyPart.setDataHandler(new DataHandler(source));
  	  messageBodyPart.setFileName(source.getName());	  	  
  	  multipart.addBodyPart(messageBodyPart);	  	
	  	
	  	message.setContent(multipart);
	  }
	  
	  message.saveChanges(); // implicit with send()
	  
	  Transport transport = session.getTransport("smtp");
	  
	  try {
	    transport.connect(host,user,password);
		  transport.sendMessage(message, message.getAllRecipients());
		  transport.close();	  		
	  }
	  catch (Exception e) {
	  	e.printStackTrace();
	    throw new IllegalArgumentException(e.getMessage());
	  }	  
	}
	
	/*
	 * DataSource wrapper implementation around an InputStream
	 * Provides for generating attachments without having to write
	 * them to the file system first
	 */
  private class InputStreamDataSource implements DataSource {
    
    private String name;
    private String contentType;
    private ByteArrayOutputStream baos;
    
    InputStreamDataSource(String name, String contentType, InputStream inputStream) throws IOException {
        this.name = name;
        this.contentType = contentType;
        
        baos = new ByteArrayOutputStream();
        
        int read;
        byte[] buff = new byte[256];
        while((read = inputStream.read(buff)) != -1) {
            baos.write(buff, 0, read);
        }
    }
    
    public String getContentType() {
        return contentType;
    }

    public InputStream getInputStream() throws IOException {
        return new ByteArrayInputStream(baos.toByteArray());
    }

    public String getName() {
        return name;
    }

    public OutputStream getOutputStream() throws IOException {
        throw new IOException("Cannot write to this read-only resource");
    }
}

}