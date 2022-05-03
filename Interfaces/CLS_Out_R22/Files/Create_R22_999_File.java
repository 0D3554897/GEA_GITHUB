import java.io.ByteArrayOutputStream;
import java.io.FileOutputStream;
import java.math.BigDecimal;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.Calendar;
import java.util.Properties;
import java.io.FileInputStream;
import java.util.HashMap;

/*******************************************************************************
 * Name: Create_R22_999_File.java 
 * Author: KM 
 * Created: 10/2008
 * Purpose/Function: 
 * 			Part of the IMAPS to CLS Down Interface
 * 			Creates the 999 File in EBCDIC
 * 			Creates the 999 File in ASCII
 * 			Creates the Parameter Card in ASCII
 * Prerequisites: 
 * 
 * Parameters: Input: Transaction Data from Staging Tables 
 * Output: Flat Files 
 ******************************************************************************/


public class Create_R22_999_File {

	//MS SQL Server 2000 JDBC Driver Variables
	private java.sql.Connection con = null;
	private String databaseName = "IMAPSStg";
	private String userName = "imapsprd";
	private String password = "prod1uction";
	private String serverName = "9.48.228.52";
	private String STATUS_RECORD_NUM = "291"; 
	private int return_value = 0;
	
	// SQL Server 2000 JDBC Driver Constants
	// jdbc:jtds:sqlserver:
	//private static final String url = "jdbc:microsoft:sqlserver://";
	private static final String url = "jdbc:jtds:sqlserver://";
	private static final String portNumber = "1433";
	private static final String selectMethod = "cursor";
	
	// File Names and Locations Variables
	private static final String CLS_999_File = "IMAR_TO_CLS.BIN";
	private static final String CLS_ASCII_File = "IMAR_TO_CLS_ASCII.TXT";
	private static final String ErrorLogFile = "IMAR_TO_CLS_ERROR_LOG.TXT";
	private static final String ParameterCardFile = "F156PARM.TXT";
	
	private static final String EBCDIC_Encoding = "Cp500";
	private ByteArrayOutputStream CLS_Array;
	private FileOutputStream CLS;
	private java.io.PrintWriter CLS_ASCII;
	private java.io.PrintWriter ErrorLog;
	private java.io.PrintWriter ParameterCard;
	
	
	// Parameter Card Constants and Variables
	private static final BigDecimal Zero = new BigDecimal("0.00");
	private String Accounting_Year;
	private int REC_CNT = 0;
	private BigDecimal LOCAL_DEBITS = new BigDecimal("0.00");
	private String CONFRMCD = "123456";
	private static String REVERSE = " ";
	private BigDecimal US_NET_AMT = new BigDecimal("0.00");
	
	
	// CLS 999 File Constants and Variables
	private String Country_Number;
	private String Ledger_Code;
	private String File_ID;
	private String File_Sequence_No;
	private String Type_Of_Ledger_Indicator;
	private String Division;
	private String Major;
	private String Minor;
	private String Sub_Minor;
	private String Ledger_Reporting_Unit;
	
	private final String Past_Current_Year_Indicator = Filler(1);
	private final String Task_Field = Filler(15);
	private final String Reversal_Indicator = Filler(1);
	private final String Contra_Acct_Org_Unit = Filler(2);
	private final String Contra_Acct_Major = Filler(3);
	private final String Contra_Acct_Minor = Filler(4);
	private final String Book_Number = Filler(2);
	
	private String Ledger_Source;
	private String Accountant_ID;
	private String Index_Number;
	
	private final String Pre_Index_Number = Filler(5);
	
	private String Date_Of_Ledger_Entry;
	private String Accounting_Month_Local;
	
	private final String Accounting_Month_Fiscal = Filler(2);
	
	private String Amount_Local_Currency;
	
	private final String Amount_US_Dollars = Filler(15);
	
	private String Machine_Type;
	
	private final String Machine_Model = Filler(3);
	private final String Invoice_Number = Filler(10);
	private final String Invoice_Number_Reserve = Filler(2);
	
	private String Description_1;
	private String IMAPS_ACCT;
	private String Description_2;
	
	private final String WT_Invoice_Number = Filler(12);
	private final String Freight_Mode_Code = Filler(3);
	private final String Material_Group_Code = Filler(9);
	private final String Ship_to_Location = Filler(6);
	private final String Employee_Serial_Number = Filler(6);
	private final String Job_Code = Filler(4);
	private final String Vendor_Bill_To_From = Filler(10);
	private final String Purchase_Order_No = Filler(10);
	
	private String User_ID = Filler(8);
	
	private final String Fiscal_Acct_Org_Unit = Filler(2);
	private final String Fiscal_Acct_Major = Filler(3);
	private final String Fiscal_Acct_Minor = Filler(4);
	
	private String Reference_Type_Of_Ledger_Ind;
	private String Reference_Division;
	private String Reference_Major;
	private String Reference_Minor;
	private String Reference_Sub_Minor;
	private String Reference_LERU;
	
	private final String File_Record_Verification_Run_Date = Filler(6); //DDMMYY
	private final String Transfer_Account_Indicator = Filler(2);
	
	private String HQ_Conversion_LC;
	private String HQ_Conversion_Division;
	private String HQ_Conversion_Major;
	private String HQ_Conversion_Minor;
	private String HQ_Conversion_Sub_Minor;
	private String HQ_Conversion_LERU;
	private String Input_Type_Identifier;
	
	private final String Status_Identifier = Filler(1);
	private final String Change_Identifier = Filler(1);
	private final String Reconciliation_Indicator = Filler(1);
	private final String Approver_Id = Filler(3);
	private final String Approver_User_Id = Filler(8);
	private final String Approval_Date = Filler(4);//"DDMM";
	private final String Direct_Currency_Indicator = Filler(1);
	
	private String Reference_File_ID;
	private String Reference_File_Sequence_No;
	
	private final BigDecimal Reference_Audit_Number = new BigDecimal("0.0"); // Fixed decimal (7,0)
	private final String YTD_Indicator = Filler(1);
	
	private String Fulfillment_Channel;
	
	private final String Filler_2 = Filler(7);
	private final String Revaluation_Indicator = Filler(2);
	
	private String Marketing_Division;
	
	private final String Sub_Business_Area = Filler(2);
	private final String FDS_Segment_US = Filler(2);
	
	private String Part_Number;
	
	private final String Exchange_Minor = Filler(4);
	private final String X_Org_Indicator = Filler(1);
	
	private String Product_ID;
	private String Customer_Number;
	
	private final String Customer_Number_Reserve = Filler(1);	
	private final String Feature_Number = Filler(4);
	private final String Filler_1 = Filler(2);
	
	private String From_Product_ID;
	
	private final String Quantity = Filler(15);
	
	private String Marketing_Area;
	
	private final String MES_Number = Filler(6);
	private final String RPQ = Filler(6);
	private final String Receiving_Country = Filler(3);
	private final String Corp_Use_1 = Filler(2);
	private final String Corp_Use_2 = Filler(3);
	private final String Corp_Use_3 = Filler(3);
	private final String Corp_Use_4 = Filler(4);
	private final String Corp_Use_5 = Filler(5);
	private final String Corp_Use_6 = Filler(6);
	private final String Corp_Use_7	= Filler(7);
	private final String Corp_Use_8	= Filler(8);
	private final String Corp_Use_9	= Filler(9);
	private final String Corp_Use_10 = Filler(10);
	private final String Revenue_Type = Filler(3);
	private final String Reason_Code = Filler(3);
	private final String Contract_Type = Filler(2);
	private final String Document_Type = Filler(2);
	private final String Offering_Code = Filler(3);
	private final String Agreement_Type = Filler(1);
	private final String Business_Type = Filler(1);
	private final String Print_Indicator = Filler(1);
	private final int Event_Sequence_No = 0; 	// BIN (31) INTEGER 	
	private final String Event_Code 	= Filler(3);
	private final String Event_Type = Filler(1);
	private final String Cost_Revenue_Match_Code  = Filler(3);
	private final int Cost_Revenue_Group_No = 0;  // BIN (31) INTEGER
	private final String Account_Group = Filler(3);
	private final String Account_Type  = Filler(1);
	private final int Account_Sequence_No = 0; // BIN (15)
	private final String Machine_Serial_Property_Record_Number = Filler(7);
	private final String Machine_Serial_Reserve = Filler(2);
	
	private String IGS_Project_No;
	
	private final String Top_Bill_Part_No_US = Filler(12);
	private final String IBM_Order_No = Filler(6);
	
	private String Contract_Number;
	
	private final String Contract_No_Reserve_US = Filler(3);
	
	private String Service_Product_ID;
	private String OEM_Product_ID;
	
	private final String ISIC_Code = Filler(5);
	private final String Agreement_Reference_No = Filler(9);
	
	private String Marketing_Branch_Office;
	
	private final String Marketing_Unit_Billing_Cust = Filler(3);
	private final String Accepting_Branch_Office = Filler(3);
	private final String Customer_No_User  = Filler(8);
	private final String Customer_No_Billed = Filler(8);
	private final String Customer_No_Owner = Filler(8);
	private final String Paying_Affiliated_Customer = Filler(8);
	private final String Factory_Order_No_US = Filler(7);
	private final String Form_Number = Filler(7);
	private final String Plant_Code = Filler(3);
	private final String Ship_Date = Filler(10);//"YYYY-MM-DD";
	private final String Installation_Date = Filler(10);//"YYYY-MM-DD";
	private final String Period_Start_Date = Filler(10);//"YYYY-MM-DD";
	private final String Period_End_Date = Filler(10);//"YYYY-MM-DD";
	
	private String Consolidated_Revenue_BO;
	
	private final String Department_Working_US = Filler(3);
	private final String Department_Working_Suffix = Filler(1);
	private final String Responsible_BO = Filler(3);
	private final String Appropriation_No = Filler(6);
	private final BigDecimal Hours = new BigDecimal("0.0"); // FIX DEC (7,1) 
	private final String Filler_3 = Filler(3);
	private final String Region = Filler(1);
	private final String Dept_Charged_Suffix = Filler(1);
	private final String Due_From_Div_Indicator = Filler(2);
	private final String Pre_Inventory_Indicator = Filler(1);
	private final String Engineering_Change_No = Filler(7);
	private final String Order_Reference_Number = Filler(8);
	private final String CTF_Indicator = Filler(2);
	private final String Unit_of_Measure = Filler(3);
	private final String Discount_Code = Filler(2);
	private final String HQ_CIBS_Billing_Class = Filler(5);
	
	private String Industry;
	
	private final String Old_Model_No = Filler(3);
	private final String Type_Device = Filler(1);
	private final String Accounts_Payable_Index_No = Filler(10);
	private final String State_Tax_Code = Filler(2);
	private final String County_Tax_Code = Filler(3);
	private final String City_Tax_Code = Filler(4);
	private final String Use_Tax_Code = Filler(1);
	private final String ETV_Code = Filler(6);
	private final String Direct_Indirect_Indicator = Filler(1);
	private final String Commissionable_Indicator = Filler(1);
	private final String AP_SAP_Document_Type = Filler(2);
	private final String AP_Charge_Type = Filler(2);
	private final String Direction_IND = Filler(2);
	private final String CIBS_Originator_ID = Filler(3);
	private final String GSA_Indicator = Filler(1);
	private final String Class_Number = Filler(4);
	private final String Activity_Code = Filler(3);
	private final String Start_Month = Filler(2);
	private final String Start_Year = Filler(2);
	private final String Stop_Month = Filler(2);
	private final String Stop_Year = Filler(2);
	private final String Number_of_Months = Filler(2);
	private final String Machine_Type_Prefix = Filler(1);
	private final String Original_Source = Filler(3);
	private final String FDS_Customer_Type = Filler(1);
	private final String Billing_Code = Filler(3);
	private final String Retail_Division = Filler(2);
	private final String Industry_Code = Filler(2);
	private final String Marketing_Region = Filler(1);
	private final String Invoice_Date = Filler(6);//"MMDDYY";
	private final String Accounting_Method = Filler(1);
	private final String End_Finance_Date = Filler(6);//"MMDDYY";
	private final String Lease_Term = Filler(3);
	private final String Lease_Type = Filler(1);
	private final String Start_Finance_Date = Filler(6);//"MMDDYY";
	private final String Source_Transmission_Ind = Filler(3);
	private final String In_Out_City_Limits = Filler(1);
	private final String Product_Type = Filler(1);
	private final String Quarterly_Indicator = Filler(1);
	
	private String Enterprise_Number;
	
	private final String Master_Service_Office = Filler(3);
	private final String Country_Code = Filler(4);
	private final String Analysis_Code = Filler(4);
	private final String Filler_4 = Filler(6);
	private final String Course_No_Category = Filler(4);
	private final BigDecimal Burden_Amount = new BigDecimal("0.0"); //FIX DEC (11,2) 	
	
	private final BigDecimal Use_Tax_Amount = new BigDecimal("0.0"); //FIX DEC (7,2) 	
	private final BigDecimal Foreign_Currency_Amount = new BigDecimal("0.0");  //FIX DEC (15,2) 
	private final String Course_No = Filler(10);
	private final String SAP_Identifier = Filler(4);
	private final String Part_Number_Machine_Type = Filler(12);
	private final String SODT = Filler(4);
	private final String ASSETIND = Filler(1);
	private final String Filler_5 = Filler(23);
	
	private ResultSet CLS_rs;
	private PreparedStatement CLS_stmt;
	private static final String CLS_query = "SELECT * FROM dbo.XX_R22_CLS_DOWN";
	
	private ResultSet CLS_LOG_rs;
	private PreparedStatement CLS_LOG_stmt;
	private static final String CLS_LOG_query = "SELECT * FROM dbo.XX_R22_CLS_DOWN_LOG " +
	"WHERE CAST(STATUS_RECORD_NUM AS VARCHAR(100)) = ?";
	
	private ResultSet PARAM_rs;
	private PreparedStatement PARAM_stmt;
	private static final String PARAM_query = "SELECT PARAMETER_VALUE " +
	"FROM dbo.XX_PROCESSING_PARAMETERS " + 
	"WHERE INTERFACE_NAME_CD = ? AND PARAMETER_NAME = ?";
	
	// PUBLIC METHODS
	
	// For Leading Zeors
	public String LZ(String s, int len) {

		if (s == null || s == " ") {
			s = "0";
		}

		if (s.length() > len) {
			return s.substring(s.length() - len, s.length());
		} else if (s.length() < len) // pad on left with zeros
		{
			return "00000000000000000000000000000000000000000000000".substring(
					0, len - s.length())
					+ s;
		} else {
			return s;
		}

	} // end LZ

	public String LZ(int i, int len) {

		String s = Integer.toString(i);

		return LZ(s, len);

	} // end LZ

	// For Filler Spaces
	public String Filler(int len) {

		String temp = "";
		for (int i = 0; i < len; ++i) {
			temp = temp + " ";
		}
		return temp;

	}// end Filler

	// For Leading Spaces
	public String LSPC(String s, int len) {

		if (s == null || s == " ") {
			return Filler(len);
		}

		String spaces = Filler(70);

		if (s.length() > len) {
			return s.substring(0, len);
		} else if (s.length() < len) // pad on left with zeros
		{
			return spaces.substring(0, len - s.length()) + s;
		} else {
			return s;
		}

	} // end LSPC

	// For Trailing Spaces
	public String TSPC(String s, int len) {

		if (s == null || s == " ") {
			return Filler(len);
		}

		String spaces = Filler(70);

		if (s.length() > len) {
			return s.substring(0, len);
		} else if (s.length() < len) // pad on right with zeros
		{
			return s + spaces.substring(0, len - s.length());
		} else {
			return s;
		}

	} // end TSPC

	// For Packed Decimals (FIXED DEC datatypes)
	public void WritePacked(java.io.ByteArrayOutputStream BAWriter,
			BigDecimal Val, int total, int precision) {
		
		if(Val == null)
		{
			Val = new BigDecimal("0.0");
		}
		
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
		if (decimal_index == -1)
			decimal_index = ValStr.length() - 1;

		String LeftSide = ValStr.substring(0, decimal_index);
		String RightSide = ValStr.substring(decimal_index + 1, ValStr.length());

		// Pad with Zeros where appropriate
		while (LeftSide.length() < left) {
			LeftSide = "0" + LeftSide;
		}

		while (RightSide.length() < right) {
			RightSide = RightSide + "0";
		}

		// Truncate where appropriate
		if (LeftSide.length() > left) {
			LeftSide = LeftSide.substring(LeftSide.length() - left, LeftSide
					.length());
		}

		if (RightSide.length() > right) {
			RightSide = RightSide.substring(0, right);
		}

		// Add sign nibble
		// Sign is Reversed on FDS Invoice
		if (positive && signed) {
			RightSide = RightSide + "c";
		} else if (!positive && signed) {
			RightSide = RightSide + "d";
		}

		String HexValues = LeftSide + RightSide;

		// Writing Packed
		try {

			// Every Byte == 2 Nibbles
			int count = 0;
			for (int i = 0; i < HexValues.length(); i += 2) {
				String cur_hex = "0x" + HexValues.substring(i, i + 2);
				byte cur_byte = (Integer.decode(cur_hex)).byteValue();
				packed_bytes[count] = cur_byte;
				count++;
			}
			BAWriter.write(packed_bytes, 0, count);

		} catch (Exception e) {
			e.printStackTrace();
		}

	} // end Write Packed Decimal

	// For Binary Integers (FIXED BIN datatypes)
	// Leftmost bit is sign bit
	public void WriteSignedBin(java.io.ByteArrayOutputStream BAWriter,
			int value, int length) {
		
		if(Integer.toString(value) == null ||
		   Integer.toString(value) == " ")
			value = 0;
		
		String Bits = Integer.toBinaryString(value);
		
		while(Bits.length() < length)
		{
			Bits = '0' + Bits;
		}
		
		if(value < 0)
			Bits = '1' + Bits;
		else
			Bits = '0' + Bits;
		
		
		// Writing Signed
		byte[] signed_bytes = new byte[((length+1)/8)];
		try {

			// Every Byte == 8 bits
			int count = 0;
			for (int i = 0; i < Bits.length(); i += 8) {
				String cur_bits = Bits.substring(i, i + 8);
				byte cur_byte = Byte.parseByte(cur_bits, 2);
				signed_bytes[count] = cur_byte;
				count++;
			}
			BAWriter.write(signed_bytes, 0, count);

		} catch (Exception e) {
			e.printStackTrace();
		}

	} // end Write Packed Decimal

	// For PIC(13)9V9T like datatypes
	public String GetPIC(String val, int left, int right)
	{
		if(val == null)
			val = "0.0";
		
		BigDecimal Val = new BigDecimal(val);
		
		//determine sign
		boolean positive = true;
		if (Val.compareTo(new BigDecimal("0.0")) == -1) {
			positive = false;
		}
		
		// So it works with previous code
		String ValStr = val;
		
		// Replace '-' character with 0
		ValStr = ValStr.replace('-', '0');

		int decimal_index = ValStr.indexOf(".");
		if (decimal_index == -1)
			decimal_index = ValStr.length() - 1;

		String LeftSide = ValStr.substring(0, decimal_index);
		String RightSide = ValStr.substring(decimal_index + 1, ValStr.length());
		
		//Pad with Zeros where appropriate
		while (LeftSide.length() < left) {
			LeftSide = "0" + LeftSide;
		}
		while (RightSide.length() < right) {
			RightSide = RightSide + "0";
		}

		// Truncate where appropriate
		if (LeftSide.length() > left) {
			LeftSide = LeftSide.substring(LeftSide.length() - left, LeftSide
					.length());
		}
		if (RightSide.length() > right) {
			RightSide = RightSide.substring(0, right);
		}
		
		ValStr = LeftSide + RightSide;
		
		// Now Determine Final T type character
		char Last_Num = ValStr.charAt(left + right - 1);
		String Last_Char;
		
		switch(Last_Num)
		{
			case '0':
				if(positive)
					Last_Char = "{";
				else
					Last_Char = "}";
				break;
			case '1':
				if(positive)
					Last_Char = "A";
				else
					Last_Char = "J";
				break;
			case '2':
				if(positive)
					Last_Char = "B";
				else
					Last_Char = "K";
				break;
			case '3':
				if(positive)
					Last_Char = "C";
				else
					Last_Char = "L";
				break;
			case '4':
				if(positive)
					Last_Char = "D";
				else
					Last_Char = "M";
				break;
			case '5':
				if(positive)
					Last_Char = "E";
				else
					Last_Char = "N";
				break;
			case '6':
				if(positive)
					Last_Char = "F";
				else
					Last_Char = "O";
				break;
			case '7':
				if(positive)
					Last_Char = "G";
				else
					Last_Char = "P";
				break;
			case '8':
				if(positive)
					Last_Char = "H";
				else
					Last_Char = "Q";
				break;
			case '9':
				if(positive)
					Last_Char = "I";
				else
					Last_Char = "R";
				break;
			default:
					Last_Char = "{";
		}
		
		// Combine Left and right
		// With Decimal Place Removed
		ValStr = LeftSide + RightSide;
		ValStr = LeftSide + RightSide.substring(0, right - 1) + Last_Char;
		return ValStr;
	}
	

	
	
	// PRIVATE METHODS
	

	
	  private static String[] propKeys = {
		    "db.serverName","db.databaseName","db.userName","db.password"
		  };

		  private static HashMap props = new HashMap();  


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

	// Constructor
	private Create_R22_999_File(String propsPath, String Status_Num) throws Exception {
		
		// Set Connection Variables		
		//load properties instead of other method
	    loadProperties(propsPath);
	    serverName = props.get("db.serverName").toString();
	    databaseName    = props.get("db.databaseName").toString();
	    userName  = props.get("db.userName").toString();
	    password   = props.get("db.password").toString();

		STATUS_RECORD_NUM = Status_Num;		
		
		// Try to Create Error Log File Output
		try {
			ErrorLog = new java.io.PrintWriter(
					new java.io.OutputStreamWriter(
							new java.io.FileOutputStream(ErrorLogFile),"US-ASCII"));
			ErrorLog.println("Error Log Created...");
		} 
		catch (Exception e) {
			e.printStackTrace();
			System.out.println("Error Creating BufferedWriter for Error Log: "
							+ e.getMessage());
		}
		
		// Try to Connect to Database
		try {
			ErrorLog.println("Attempting to Connect to the Database...");
			con = this.getConnection();
		} 
		catch (Exception e) {
			// Try to write Error to Log
			try{
				ErrorLog.println("Error attempting to connect to the database!!!");
				ErrorLog.println("Exception: " + e.getMessage());
				e.printStackTrace(ErrorLog);
				
			}catch (Exception etwo)
			{
				System.out.println("Error Connecting to Database and Creating Error Log");		
			}
		}
	} // End of Constructor
	
	// JDBC Connection Methods
	private String getConnectionUrl() {
		return url + serverName + ":" + portNumber + ";databaseName="
				+ databaseName + ";selectMethod=" + selectMethod + ";";
	}// end getConnectionURL

	// Connects and Loads Prepared Statements
	private java.sql.Connection getConnection() {
		try {
			//Class.forName("com.microsoft.jdbc.sqlserver.SQLServerDriver");
			Class.forName("net.sourceforge.jtds.jdbc.Driver");
			con = java.sql.DriverManager.getConnection(getConnectionUrl(),
					userName, password);
			if (con != null)
			{	
				ErrorLog.println("Connection Successful...");
				
				//Set up prepared statement
				CLS_stmt = con.prepareStatement(CLS_query);
				PARAM_stmt = con.prepareStatement(PARAM_query);
				CLS_LOG_stmt = con.prepareStatement(CLS_LOG_query);
			}
		} catch (Exception e) {
//			Try to write Error to Log
			try{
				ErrorLog.println("Error Connecting to database!!! :" + getConnectionUrl());
				ErrorLog.println("Exception: " + e.getMessage());
				e.printStackTrace(ErrorLog);
				
			}catch (Exception ethree)
			{
				System.out.println("Error Connecting to database and Creating Error Log");		
			}
		}
		return con;
	}// end getConnection
	
	// Disconnects from Database
	private void closeConnection() {
		try {
			if (con != null)
				con.close();
			con = null;
		} catch (Exception e) {
//			Try to write Error to Log
			try{
				ErrorLog.println("Error Closing CLS_DOWN JDBC Connection!!!");
				ErrorLog.println("Exception: " + e.getMessage());
				e.printStackTrace(ErrorLog);
				
			}catch (Exception ethree)
			{
				System.out.println("Error Closing CLS_DOWN JDBC Connection and Creating Error Log");		
			}
		}
	}// end closeConnection
	
	// Set up CLS Output
	private void SetupCLSOutput()
	{
		try {
			CLS = new java.io.FileOutputStream(CLS_999_File);
			CLS_Array = new java.io.ByteArrayOutputStream();
			CLS_ASCII = new java.io.PrintWriter(
					new java.io.OutputStreamWriter(
							new java.io.FileOutputStream(CLS_ASCII_File),"US-ASCII"));
			ParameterCard = new java.io.PrintWriter(
					new java.io.OutputStreamWriter(
							new java.io.FileOutputStream(ParameterCardFile),"US-ASCII"));
		} catch (Exception e) {
//			Try to write Error to Log
			try{
				ErrorLog.println("Error Creating CLS OutputStreams!!!");
				ErrorLog.println("Exception: " + e.getMessage());
				e.printStackTrace(ErrorLog);
				
			}catch (Exception etwo)
			{
				System.out.println("Error Creating CLS OutputStreams and Creating Error Log");		
			}
		}
	}
	

	
	// Loads the CLS Log ResultSet Cursor
	private void LoadCLSLOGrs()
	{
		//Select CLS Log data
		try {
			CLS_LOG_stmt.setString(1, STATUS_RECORD_NUM);
			CLS_LOG_rs = CLS_LOG_stmt.executeQuery();
		} 
		catch (Exception e) {
			//Try to write Error to Log
			try{
				ErrorLog.println("Error Loading CLS Down Log Records From Database!!!");
				ErrorLog.println("Exception: " + e.getMessage());
				e.printStackTrace(ErrorLog);
				
			}catch (Exception etwo)
			{
				System.out.println("Error Loading CLS Down Log Records and Writing to Error Log");		
			}
		}
	}
	
	
	// Loads the Constant Parameters for Current Interface Run
	private void LoadConstantParameters()
	{
		//Select and Update Parameters
		try {
			
			//get CLS_DOWN_LOG data
			LoadCLSLOGrs();
			CLS_LOG_rs.next();
			
			PARAM_stmt.setString(1, "CLS_R22");
			
			// set all parameters
			PARAM_stmt.setString(2, "COUNTRY_NUM");
			PARAM_rs = PARAM_stmt.executeQuery();
			PARAM_rs.next();
			Country_Number = TSPC(PARAM_rs.getString("PARAMETER_VALUE"), 3);
			
			PARAM_stmt.setString(2, "LEDGER_CD");
			PARAM_rs = PARAM_stmt.executeQuery();
			PARAM_rs.next();
			Ledger_Code = TSPC(PARAM_rs.getString("PARAMETER_VALUE"), 2);
			
			PARAM_stmt.setString(2, "FILE_ID");
			PARAM_rs = PARAM_stmt.executeQuery();
			PARAM_rs.next();
			File_ID = TSPC(PARAM_rs.getString("PARAMETER_VALUE"), 3);
			
			//Per Neil Rancour's Email
			//We must let the File_Sequence_No be assigned
			//By the CLS Control Module
			File_Sequence_No = LZ(0000, 4);
			
			PARAM_stmt.setString(2, "TOLI");
			PARAM_rs = PARAM_stmt.executeQuery();
			PARAM_rs.next();
			Type_Of_Ledger_Indicator = TSPC(PARAM_rs.getString("PARAMETER_VALUE"), 1);
			
			PARAM_stmt.setString(2, "LEDGER_SOURCE_CD");
			PARAM_rs = PARAM_stmt.executeQuery();
			PARAM_rs.next();
			Ledger_Source = TSPC(PARAM_rs.getString("PARAMETER_VALUE"), 3);
			
			PARAM_stmt.setString(2, "ACCOUNTANT_ID");
			PARAM_rs = PARAM_stmt.executeQuery();
			PARAM_rs.next();
			Accountant_ID = TSPC(PARAM_rs.getString("PARAMETER_VALUE"), 3);
			
			Index_Number = TSPC(CLS_LOG_rs.getString("VOUCHER_NUM"), 7);
			
			// format date in accordance with specification
			java.sql.Date dt = CLS_LOG_rs.getDate("LEDGER_ENTRY_DATE");
			
			Calendar calendar = Calendar.getInstance();
			calendar.setTime(dt);
			String year = Integer.toString(calendar
					.get(java.util.Calendar.YEAR));
			// months in Calendar are zero based i.e. Jan = 0
			String month = Integer.toString(calendar.get(java.util.Calendar.MONTH) + 1);
			String day = Integer.toString(calendar.get(java.util.Calendar.DAY_OF_MONTH));
	
			Date_Of_Ledger_Entry = LZ(day, 2) + LZ(month, 2) + LZ(year, 2);
			
			Accounting_Month_Local = LZ(CLS_LOG_rs.getInt("MONTH_SENT"), 2);
			Accounting_Year = LZ(CLS_LOG_rs.getInt("FY_SENT"), 4);
			
			PARAM_stmt.setString(2, "USER_ID");
			PARAM_rs = PARAM_stmt.executeQuery();
			PARAM_rs.next();
			User_ID = TSPC(PARAM_rs.getString("PARAMETER_VALUE"), 8);
			
			PARAM_stmt.setString(2, "INPUT_TYPE_ID");
			PARAM_rs = PARAM_stmt.executeQuery();
			PARAM_rs.next();
			Input_Type_Identifier = TSPC(PARAM_rs.getString("PARAMETER_VALUE"), 1);
			
			PARAM_stmt.setString(2, "FULFILLMENT_CHANNEL_CD");
			PARAM_rs = PARAM_stmt.executeQuery();
			PARAM_rs.next();
			Fulfillment_Channel = TSPC(PARAM_rs.getString("PARAMETER_VALUE"), 3);
			
			PARAM_stmt.setString(2, "CONFRMCD");
			PARAM_rs = PARAM_stmt.executeQuery();
			PARAM_rs.next();
			CONFRMCD = TSPC(PARAM_rs.getString("PARAMETER_VALUE"), 8);
			
			// Duplicates
			Reference_Type_Of_Ledger_Ind = Type_Of_Ledger_Indicator;
			HQ_Conversion_LC = Ledger_Code;
			Reference_File_ID = File_ID;
			Reference_File_Sequence_No = File_Sequence_No;
			
		} 
		catch (Exception e) {
			//Try to write Error to Log
			try{
				ErrorLog.println("Error Loading CLS Down Constant Parameters From Database!!!");
				ErrorLog.println("Exception: " + e.getMessage());
				e.printStackTrace(ErrorLog);
				return_value = 1;
			}catch (Exception etwo)
			{
				return_value = 1;
				System.out.println("Error Loading CLS Down Constant Parameters and Writing to Error Log");		
			}
		}finally{
			// try closing all record sets and output streams
			try{
				PARAM_rs.close();
				PARAM_rs = null;
				CLS_LOG_rs.close();
				CLS_LOG_rs = null;
			}
			catch (Exception etwo)
			{
				// Try to write Error to Log
				try{
					ErrorLog.println("Error Closing CLS Parameter JDBC RecordSets !!!");
					ErrorLog.println("Exception: " + etwo.getMessage());
					etwo.printStackTrace(ErrorLog);
					
				}catch (Exception ethree)
				{
					System.out.println("Error Closing CLS Parameter JDBC RecordSetsand Creating Error Log");		
				}
			}
			
		}// end finally
	}
	
	
	// Loads the CLS Transactions ResultSet Cursor
	private void LoadCLSrs()
	{
		//Select Invoice Summary Record Set
		try {
			CLS_rs = CLS_stmt.executeQuery();
		} 
		catch (Exception e) {
			//Try to write Error to Log
			try{
				ErrorLog.println("Error Loading CLS Down Staging Records From Database!!!");
				ErrorLog.println("Exception: " + e.getMessage());
				e.printStackTrace(ErrorLog);
				
			}catch (Exception etwo)
			{
				System.out.println("Error Loading Summary Records and Writing to Error Log");		
			}
		}
	}
	
	// Writes a 999 byte record to the flat file
	// for the current CLS Transaction
	private void Write_Current_Transaction()
	{
		try {


			

			//Division
			Division = TSPC(CLS_rs.getString("DIVISION"), 2);
			HQ_Conversion_Division = Division;
			Reference_Division = Division;
			

			//LERU
			Ledger_Reporting_Unit = TSPC(CLS_rs.getString("LERU_NUM"), 6);
			HQ_Conversion_LERU = Ledger_Reporting_Unit;
			Reference_LERU = Ledger_Reporting_Unit;


			
			// Get and Set Current Transaction Variables
			Major = TSPC(CLS_rs.getString("CLS_MAJOR"), 3);
			Minor = TSPC(CLS_rs.getString("CLS_MINOR"), 4);
			Sub_Minor = TSPC(CLS_rs.getString("CLS_SUB_MINOR"), 4);
			Amount_Local_Currency = GetPIC(CLS_rs.getString("DOLLAR_AMT"), 13, 2);
			//Amount_US_Dollars = Amount_Local_Currency;
			Machine_Type = TSPC(CLS_rs.getString("MACHINE_TYPE_CD"), 4);
			
			IMAPS_ACCT = TSPC(CLS_rs.getString("IMAPS_ACCT"), 8);
			Description_1 = TSPC( "IMAPS " + Accounting_Year + Accounting_Month_Local + " " + IMAPS_ACCT , 30);
			Description_2 = TSPC(CLS_rs.getString("DESCRIPTION2"), 30);
			
			
			// Duplicates
			Reference_Major = Major;
			Reference_Minor = Minor;
			Reference_Sub_Minor = Sub_Minor;
			HQ_Conversion_Major = Major;
			HQ_Conversion_Minor = Minor;
			HQ_Conversion_Sub_Minor = Sub_Minor;
			
			Marketing_Division = TSPC(CLS_rs.getString("BUSINESS_AREA"), 2);
			
			Part_Number = TSPC(CLS_rs.getString("PRODUCT_ID"), 12);
			Product_ID = TSPC(CLS_rs.getString("PRODUCT_ID"), 12);
			From_Product_ID = TSPC(CLS_rs.getString("PRODUCT_ID"), 12);
			Service_Product_ID = TSPC(CLS_rs.getString("PRODUCT_ID"), 12);
			OEM_Product_ID = TSPC(CLS_rs.getString("PRODUCT_ID"), 12);
			
			//Just to be safe
			if( !Machine_Type.equals(Filler(4)) )
			{
				Part_Number = TSPC(CLS_rs.getString("MACHINE_TYPE_CD"), 12);
				Product_ID = TSPC(CLS_rs.getString("MACHINE_TYPE_CD"), 12);
				From_Product_ID = TSPC(CLS_rs.getString("MACHINE_TYPE_CD"), 12);
				Service_Product_ID = TSPC(CLS_rs.getString("MACHINE_TYPE_CD"), 12);
				OEM_Product_ID = TSPC(CLS_rs.getString("MACHINE_TYPE_CD"), 12);
			}			
			
			Customer_Number = TSPC(CLS_rs.getString("CUSTOMER_NUM"), 7);
			Marketing_Area = TSPC(CLS_rs.getString("MARKETING_AREA"), 2);
			Contract_Number = TSPC(CLS_rs.getString("CONTRACT_NUM"), 12);
			Marketing_Branch_Office = TSPC(CLS_rs.getString("MARKETING_OFFICE"), 3);
			Consolidated_Revenue_BO = TSPC(CLS_rs.getString("CONSOLIDATED_REV_BRANCH_OFFICE"), 3);
			Industry = TSPC(CLS_rs.getString("INDUSTRY"), 4);
			Enterprise_Number = TSPC(CLS_rs.getString("ENTERPRISE_NUM_CD"), 7);
			IGS_Project_No = TSPC(CLS_rs.getString("IGS_PROJ"), 7);
			
			// Combine all Bytes for 999 Byte Record
			String CLS_999_Bytes_0_To_350 = 
					Country_Number 
					+  Ledger_Code 
					+  File_ID 
					+  File_Sequence_No 
					+  Type_Of_Ledger_Indicator 
					+  Division 
					+  Major 
					+  Minor 
					+  Sub_Minor 
					+  Ledger_Reporting_Unit 
					+  Past_Current_Year_Indicator 
					+  Task_Field 
					+  Reversal_Indicator 
					+  Contra_Acct_Org_Unit 
					+  Contra_Acct_Major 
					+  Contra_Acct_Minor 
					+  Book_Number 
					+  Ledger_Source 
					+  Accountant_ID 
					+  Index_Number 
					+  Pre_Index_Number 
					+  Date_Of_Ledger_Entry 
					+  Accounting_Month_Local 
					+  Accounting_Month_Fiscal 
					+  Amount_Local_Currency 
					+  Amount_US_Dollars 
					+  Machine_Type 
					+  Machine_Model 
					+  Invoice_Number 
					+  Invoice_Number_Reserve 
					+  Description_1 
					+  Description_2 
					+  WT_Invoice_Number 
					+  Freight_Mode_Code 
					+  Material_Group_Code 
					+  Ship_to_Location 
					+  Employee_Serial_Number 
					+  Job_Code 
					+  Vendor_Bill_To_From 
					+  Purchase_Order_No
					+  User_ID 
					+  Fiscal_Acct_Org_Unit 
					+  Fiscal_Acct_Major 
					+  Fiscal_Acct_Minor 
					+  Reference_Type_Of_Ledger_Ind 
					+  Reference_Division 
					+  Reference_Major 
					+  Reference_Minor 
					+  Reference_Sub_Minor 
					+  Reference_LERU 
					+  File_Record_Verification_Run_Date
					+  Transfer_Account_Indicator 
					+  HQ_Conversion_LC 
					+  HQ_Conversion_Division 
					+  HQ_Conversion_Major 
					+  HQ_Conversion_Minor 
					+  HQ_Conversion_Sub_Minor 
					+  HQ_Conversion_LERU 
					+  Input_Type_Identifier 
					+  Status_Identifier 
					+  Change_Identifier 
					+  Reconciliation_Indicator 
					+  Approver_Id 
					+  Approver_User_Id 
					+  Approval_Date
					+  Direct_Currency_Indicator 
					+  Reference_File_ID 
					+  Reference_File_Sequence_No;
					
			String CLS_999_Bytes_355_To_533 = 
				YTD_Indicator 
					+  Fulfillment_Channel 
					+  Filler_2 
					+  Revaluation_Indicator 
					+  Marketing_Division 
					+  Sub_Business_Area 
					+  FDS_Segment_US 
					+  Part_Number 
					+  Exchange_Minor 
					+  X_Org_Indicator 
					+  Product_ID
					+  Customer_Number 
					+  Customer_Number_Reserve 	
					+  Feature_Number 
					+  Filler_1 
					+  From_Product_ID
					+  Quantity 
					+  Marketing_Area  
					+  MES_Number 
					+  RPQ 
					+  Receiving_Country 
					+  Corp_Use_1 
					+  Corp_Use_2 
					+  Corp_Use_3 
					+  Corp_Use_4 
					+  Corp_Use_5 
					+  Corp_Use_6 
					+  Corp_Use_7	
					+  Corp_Use_8	
					+  Corp_Use_9	
					+  Corp_Use_10
					+  Revenue_Type 
					+  Reason_Code 
					+  Contract_Type 
					+  Document_Type 
					+  Offering_Code 
					+  Agreement_Type 
					+  Business_Type 
					+  Print_Indicator; 
					
			String CLS_999_Bytes_538_To_544 =
					Event_Code 	
					+  Event_Type 
					+  Cost_Revenue_Match_Code; 
				 						

			String CLS_999_Bytes_549_To_552 = 
					Account_Group 
					+  Account_Type;
				 
					
			String CLS_999_Bytes_555_To_755 = 
					Machine_Serial_Property_Record_Number 
					+  Machine_Serial_Reserve 
					+  IGS_Project_No 
					+  Top_Bill_Part_No_US
					+  IBM_Order_No
					+  Contract_Number
					+  Contract_No_Reserve_US 
					+  Service_Product_ID
					+  OEM_Product_ID
					+  ISIC_Code 
					+  Agreement_Reference_No 
					+  Marketing_Branch_Office 
					+  Marketing_Unit_Billing_Cust 
					+  Accepting_Branch_Office 
					+  Customer_No_User  
					+  Customer_No_Billed 
					+  Customer_No_Owner 
					+  Paying_Affiliated_Customer 
					+  Factory_Order_No_US 
					+  Form_Number 
					+  Plant_Code 
					+  Ship_Date
					+  Installation_Date
					+  Period_Start_Date
					+  Period_End_Date
					+  Consolidated_Revenue_BO 
					+  Department_Working_US 
					+  Department_Working_Suffix 
					+  Responsible_BO 
					+  Appropriation_No;
				 
					
			String CLS_999_Bytes_760_To_927 =
			    Filler_3 
				+  Region 
				+  Dept_Charged_Suffix 
				+  Due_From_Div_Indicator 
				+  Pre_Inventory_Indicator 
				+  Engineering_Change_No 
				+  Order_Reference_Number 
				+  CTF_Indicator 
				+  Unit_of_Measure 
				+  Discount_Code 
				+  HQ_CIBS_Billing_Class 
				+  Industry 
				+  Old_Model_No 
				+  Type_Device 
				+  Accounts_Payable_Index_No
				+  State_Tax_Code 
				+  County_Tax_Code 
				+  City_Tax_Code 
				+  Use_Tax_Code 
				+  ETV_Code 
				+  Direct_Indirect_Indicator 
				+  Commissionable_Indicator 
				+  AP_SAP_Document_Type 
				+  AP_Charge_Type 
				+  Direction_IND 
				+  CIBS_Originator_ID 
				+  GSA_Indicator 
				+  Class_Number 
				+  Activity_Code 
				+  Start_Month 
				+  Start_Year 
				+  Stop_Month 
				+  Stop_Year 
				+  Number_of_Months 
				+  Machine_Type_Prefix 
				+  Original_Source 
				+  FDS_Customer_Type 
				+  Billing_Code 
				+  Retail_Division 
				+  Industry_Code 
				+  Marketing_Region 
				+  Invoice_Date
				+  Accounting_Method 
				+  End_Finance_Date
				+  Lease_Term 
				+  Lease_Type 
				+  Start_Finance_Date
				+  Source_Transmission_Ind 
				+  In_Out_City_Limits 
				+  Product_Type 
				+  Quarterly_Indicator
				+  Enterprise_Number 
				+  Master_Service_Office 
				+  Country_Code 
				+  Analysis_Code 
				+  Filler_4 
				+  Course_No_Category;
		
					
			 String CLS_999_Bytes_946_To_999 =
			 			Course_No
						+  SAP_Identifier 
						+  Part_Number_Machine_Type
						+  SODT 
						+  ASSETIND
						+  Filler_5;
			
			 // Write EBCDIC bytes
			 CLS_Array.write(CLS_999_Bytes_0_To_350.getBytes(EBCDIC_Encoding));
			 WritePacked(CLS_Array, Reference_Audit_Number, 7, 0);
			 CLS_Array.write(CLS_999_Bytes_355_To_533.getBytes(EBCDIC_Encoding));
			 WriteSignedBin(CLS_Array, Event_Sequence_No, 31);
			 CLS_Array.write(CLS_999_Bytes_538_To_544.getBytes(EBCDIC_Encoding));	
			 WriteSignedBin(CLS_Array, Cost_Revenue_Group_No, 31);
			 CLS_Array.write(CLS_999_Bytes_549_To_552.getBytes(EBCDIC_Encoding));	
			 WriteSignedBin(CLS_Array, Account_Sequence_No, 15);
			 CLS_Array.write(CLS_999_Bytes_555_To_755.getBytes(EBCDIC_Encoding));	
			 WritePacked(CLS_Array, Hours, 7, 1);
			 CLS_Array.write(CLS_999_Bytes_760_To_927.getBytes(EBCDIC_Encoding));	
			 WritePacked(CLS_Array, Burden_Amount, 11, 2);
			 WritePacked(CLS_Array, Use_Tax_Amount, 7, 2);
			 WritePacked(CLS_Array, Foreign_Currency_Amount, 15, 2);
			 CLS_Array.write(CLS_999_Bytes_946_To_999.getBytes(EBCDIC_Encoding));	
			 
			 // Write ASCII file
			 CLS_ASCII.print(CLS_999_Bytes_0_To_350);
			 CLS_ASCII.print(Reference_Audit_Number);
			 CLS_ASCII.print(CLS_999_Bytes_355_To_533);
			 CLS_ASCII.print(Event_Sequence_No);
			 CLS_ASCII.print(CLS_999_Bytes_538_To_544);
			 CLS_ASCII.print(Cost_Revenue_Group_No);
			 CLS_ASCII.print(CLS_999_Bytes_549_To_552);
			 CLS_ASCII.print(Account_Sequence_No);
			 CLS_ASCII.print(CLS_999_Bytes_555_To_755);
			 CLS_ASCII.print(Hours);
			 CLS_ASCII.print(CLS_999_Bytes_760_To_927);
			 CLS_ASCII.print(Burden_Amount);
			 CLS_ASCII.print(Use_Tax_Amount);
			 CLS_ASCII.print(Foreign_Currency_Amount);
			 CLS_ASCII.println(CLS_999_Bytes_946_To_999);	
			 
			 // Update Parameter Card Totals
			 REC_CNT++;
			 
			BigDecimal AMT_LOCAL_CURRENCY = CLS_rs.getBigDecimal("DOLLAR_AMT");
			if(AMT_LOCAL_CURRENCY == null)
				AMT_LOCAL_CURRENCY = new BigDecimal("0.0");
			
			US_NET_AMT = US_NET_AMT.add(AMT_LOCAL_CURRENCY);
			if(AMT_LOCAL_CURRENCY.compareTo(Zero) < 1)
			{	
				;
			}
			else
			{
				LOCAL_DEBITS = LOCAL_DEBITS.add(AMT_LOCAL_CURRENCY);
			}
			 
			 
		} 
		catch (Exception e) {
			//Try to write Error to Log
			try{
				return_value = 1;
				ErrorLog.println("Error Writing CLS Down File!!!");
				ErrorLog.println("Exception: " + e.getMessage());
				e.printStackTrace(ErrorLog);
				
			}catch (Exception etwo)
			{
				System.out.println("Error Writing CLS Down File and Writing to Error Log");		
			}
		}
	}
	
	// Write Parameter Card
	private void Write_Parameter_Card()
	{
		String Parameters = "CC" + File_ID + 
							"  " + Accounting_Year + Accounting_Month_Local + 
							"  " + LSPC(LOCAL_DEBITS.toString(), 16) + 
							"  " + LZ(REC_CNT, 7) + 
							" " + LZ(CONFRMCD, 8) + 
							" " +  REVERSE +
							" " + LSPC(US_NET_AMT.toString(), 16) + 
							"         " + Country_Number;
		ParameterCard.print(Parameters);
	}
	
	// Write the CLS 999 File in Accordance with Specification
	private int Write_CLS_999_File() {
		
		try {
			// If Connection is Established, Proceed
			if (con != null) {
				
				// Set Up Output Streams
				SetupCLSOutput();
				
				ErrorLog.println("Attempting to Write CLS 999 File...");
				
				// Constants
				LoadConstantParameters();
				
				// Load CLS Transactions
				LoadCLSrs();
				
				// For Each Transaction
				while(CLS_rs.next())
				{
					Write_Current_Transaction();
				}				
			 
				// Write to 999 Byte Records to File
				CLS_Array.writeTo(CLS);
				
				// Write Parameter Card
				Write_Parameter_Card();
				
				closeConnection();		
				
			} else
			{
				// else if Connection was null
				ErrorLog.println("Error: No active Connection");
				return_value = 1;
			}
			return return_value;
		} catch (Exception e) {
			e.printStackTrace();
			return_value = 1;
			return return_value;
		}finally{
			// try closing all record sets and output streams
			try{
				CLS_Array.close();
				CLS.close();
				CLS = null;
				CLS_ASCII.close();
				CLS_ASCII = null;
				CLS_Array = null;
				ErrorLog.println("File Created and Output Streams closed...");
				ErrorLog.println("Closing Error Log...");
				ErrorLog.close();
				ErrorLog = null;
				ParameterCard.close();
				ParameterCard = null;
				CLS_rs.close();
				CLS_rs = null;
				closeConnection();
				return return_value;
			}
			catch (Exception etwo)
			{
				// Try to write Error to Log
				try{
					ErrorLog.println("Error Closing CLS JDBC RecordSets and OutputStream!!!");
					ErrorLog.println("Exception: " + etwo.getMessage());
					etwo.printStackTrace(ErrorLog);	
					return_value = 1;
					return return_value;
				}catch (Exception ethree)
				{
					System.out.println("Error Closing CLS JDBC RecordSets and OutputStream and Creating Error Log");		
				}
			}
			
		}// end finally

	}// end write 999 file

	
	// MAIN PROGRAM
	public static void main(String[] args) throws Exception {
		Create_R22_999_File Interface = new Create_R22_999_File(args[0], args[1]); //, args[2], args[3], args[4]); // connection opened
		System.out.println(Interface.Write_CLS_999_File());
	}

}
