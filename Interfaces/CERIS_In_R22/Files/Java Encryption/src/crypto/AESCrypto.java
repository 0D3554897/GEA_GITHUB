package crypto;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;

import javax.crypto.Cipher;
import javax.crypto.CipherInputStream;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;

public class AESCrypto {
	
	public static SecretKey generateKey() throws Exception {
		KeyGenerator kgen = KeyGenerator.getInstance("AES");
		kgen.init(128);
		SecretKey key = kgen.generateKey();
    return key;
	}
	
	private static void docrypto (int mode, InputStream is, 
			                          SecretKey key, OutputStream os) throws Exception {
		
		byte[] rawkey = key.getEncoded();
		SecretKeySpec keyspec = new SecretKeySpec(rawkey,"AES");
		
		Cipher cipher = Cipher.getInstance("AES");
		cipher.init(mode, keyspec);
		
		CipherInputStream cis = new CipherInputStream(is,cipher);
		byte[] b = new byte[8];
		int i = cis.read(b);
		while (i != -1) {
			os.write(b,0,i);
			i = cis.read(b);
		}
	}

	public static void encrypt (InputStream  is, 
                              SecretKey    key, 
                              OutputStream os) 
	                            throws       Exception {
		
		docrypto(Cipher.ENCRYPT_MODE,is,key,os);
	}
	
	public static void decrypt (InputStream  is, 
      SecretKey    key, 
      OutputStream os) 
      throws       Exception {

    docrypto(Cipher.DECRYPT_MODE,is,key,os);
  }
	
	public static void main(String[] args) throws Exception {
	
		SecretKey key = generateKey();
		
		String[] paths = {
			"c:/temp/udefsql.txt",
			"c:/temp/crypt_udefsql.txt",
			"c:/temp/decrypt_udefsql.txt",
		};
		
		FileInputStream  fis = null;
		FileOutputStream fos = null;
		
		fis = new FileInputStream(paths[0]);
		fos = new FileOutputStream(paths[1]);		
		encrypt(fis,key,fos);
		fos.close();
		
		fis = new FileInputStream(paths[1]);
		fos = new FileOutputStream(paths[2]);		
		decrypt(fis,key,fos);
		fos.close();
		
	  
	}

}
