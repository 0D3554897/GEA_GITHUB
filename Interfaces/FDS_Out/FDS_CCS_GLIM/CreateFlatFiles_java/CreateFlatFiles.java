import java.io.BufferedWriter;
import java.io.ByteArrayOutputStream;
import java.io.FileOutputStream;
import java.math.BigDecimal;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.HashMap;
import java.util.Properties;
import java.io.FileInputStream;

/*******************************************************************************
 * Name: CreateFlatFiles.java 
 * Author: KM
 * Purpose/Function: 
 * 1 - Connects to IMAPS Database 
 * 2 - Reads invoice data tables 
 * 3 - Writes a CCS formatted flat file containing invoice image
 * 4 - Writes a FDS formatted flat file containing invoice details 
 * 5 - Writes a Transaction Report for CCS/FDS interface 
 * 6 - Writes an Log File for debugging purposes
 * 
 * 
 * Parameters: Input: Invoice Data from Staging Tables 
 * Output: Flat Files, Transaction Report
 ******************************************************************************/

public class CreateFlatFiles {

	/**
	 * VARIABLES and CONSTANTS
	 */

	// MS SQL Server 2000 JDBC Driver Variables
	private java.sql.Connection con = null;
	private String databaseName = "IMAPSStg";
	private String userName = "imapsprd";
	private String password = "prod1uction";
	private String serverName = "9.35.33.235"; // "9.48.228.52";
	
	// SQL Server 2000 JDBC Driver Constants
	// jdbc:jtds:sqlserver:
	//private static final String url = "jdbc:microsoft:sqlserver://";
	private static final String url = "jdbc:jtds:sqlserver://";
	private static final String portNumber = "1433";
	private static final String selectMethod = "cursor";

	// File Names and Locations Variables
	private BufferedWriter CCS;
	private ByteArrayOutputStream FDSArray;
	private FileOutputStream FDS;
	private java.io.PrintWriter ErrorLog;
	private BufferedWriter Report;
	private String CCSFlatFile;
	private String FDSFlatFile;
	private String TransactionReportFile;
	private String ErrorLogFile;
	private String output_Path;
	
	private HashMap FDSSummaryRecordParameters = new HashMap();
	private HashMap TransactionReportSummaryValues = new HashMap();
	//private int CCS_COUNT = 0;
	
	// File Character Encoding Constants
	private static final String CCSFlatFileEncoding = "US-ASCII";
	private static final String FDSFlatFileEncoding = "Cp500";/*EBCDIC*/
	private static final String TransactionReportFileEncoding = "US-ASCII";
	
	// JDBC Prepared Statement Variables
	private PreparedStatement SUMrs_stmt;
	private static final String SUMrs_query = "SELECT * FROM IMAPSSTG.DBO.XX_IMAPS_INV_OUT_SUM WHERE STATUS_FL = 'U' AND DIVISION = ? ORDER BY INVC_ID ";
	
	private PreparedStatement GRPrs_stmt;
	private static final String GRPrs_query = "SELECT BILL_FM_GRP_NO, BILL_FM_GRP_LBL, SUM(\"BILLED_AMT\") AS BILLED_AMT, "
		+ "SUM(\"CUM_BILLED_AMT\") AS CUM_BILLED_AMT, SUM(\"BILLED_HRS\") AS BILLED_HRS, SUM(\"CUM_BILLED_HRS\") AS CUM_BILLED_HRS, "
		+ "SUM(\"RTNGE_AMT\") AS RTNGE_AMT "
		+ "FROM IMAPSSTG.DBO.XX_IMAPS_INV_OUT_DTL "
		+ "WHERE INVC_ID = ? GROUP BY BILL_FM_GRP_NO, BILL_FM_GRP_LBL "
		+ "ORDER BY BILL_FM_GRP_NO, BILL_FM_GRP_LBL";
	
	private PreparedStatement DTLrs_CSP_stmt;
	private static final String DTLrs_CSP_query = /*"SELECT * FROM dbo.xx_imaps_inv_out_dtl WHERE INVC_ID = ? "
		+ "ORDER BY BILL_FM_GRP_NO, BILL_FM_LN_NO";*/	
	"SELECT BILL_RT_AMT, SUM(BILLED_HRS) AS BILLED_HRS, SUM(BILLED_AMT) AS BILLED_AMT, " +
	"SUM(RTNGE_AMT) AS RTNGE_AMT, ID, NAME, BILL_LAB_CAT_CD, BILL_LAB_CAT_DESC, " +
	"BILL_FM_GRP_NO, BILL_FM_GRP_LBL, BILL_FM_LN_NO, BILL_FM_LN_LBL, " +
	"SUM(CUM_BILLED_HRS) AS CUM_BILLED_HRS, SUM(CUM_BILLED_AMT) AS CUM_BILLED_AMT, " +
	"SUM(TA_BASIC) AS TA_BASIC, SUM(SALES_TAX_AMT) AS SALES_TAX_AMT, PROJ_ABBRV_CD " +
	"FROM IMAPSSTG.DBO.XX_IMAPS_INV_OUT_DTL " +
	"WHERE INVC_ID = ? " + 
	"GROUP BY RI_BILLABLE_CHG_CD, M_PRODUCT_CODE, I_MACH_TYPE, TC_AGRMNT, TC_PROD_CATGRY, TS_DT, TC_TAX, " +
	"BILL_RT_AMT, ID, NAME, BILL_LAB_CAT_CD, BILL_LAB_CAT_DESC, BILL_FM_GRP_NO, " +
	"BILL_FM_GRP_LBL, RF_GSA_INDICATOR, BILL_FM_LN_NO, BILL_FM_LN_LBL, PROJ_ABBRV_CD " +
	"ORDER BY BILL_FM_GRP_NO, BILL_FM_GRP_LBL, BILL_FM_LN_NO";  //group by must be the same
	
	private PreparedStatement DTLrs_NO_CSP_stmt;
	private static final String DTLrs_NO_CSP_query = "SELECT "
		+ "RI_BILLABLE_CHG_CD, RF_GSA_INDICATOR, M_PRODUCT_CODE, I_MACH_TYPE, SUM(BILLED_AMT) AS BILLED_AMT, SUM(RTNGE_AMT) AS RTNGE_AMT, TC_AGRMNT, "
		+ "TC_PROD_CATGRY, BILL_FM_GRP_NO, BILL_FM_LN_NO, TS_DT, TC_TAX, SUM(SALES_TAX_AMT) AS SALES_TAX_AMT, "
		+ "SUM(STATE_SALES_TAX_AMT) AS STATE_SALES_TAX_AMT, SUM(COUNTY_SALES_TAX_AMT) AS COUNTY_SALES_TAX_AMT, SUM(CITY_SALES_TAX_AMT) AS CITY_SALES_TAX_AMT, PROJ_ABBRV_CD "
		+ "FROM IMAPSSTG.DBO.XX_IMAPS_INV_OUT_DTL WHERE INVC_ID = ? AND SALES_TAX_AMT <> BILLED_AMT " //TO EXCLUDE TAX SUMMARY DETAIL LINE FROM FDS
		+ "AND (ACCT_ID NOT IN (SELECT PARAMETER_VALUE FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS WHERE PARAMETER_NAME = \'CSP_ACCT_ID\') " 
		+ "OR ACCT_ID IS NULL) " +
		"GROUP BY RI_BILLABLE_CHG_CD, M_PRODUCT_CODE, I_MACH_TYPE, TC_AGRMNT, TC_PROD_CATGRY, TS_DT, TC_TAX, " +
		"BILL_RT_AMT, ID, NAME, BILL_LAB_CAT_CD, BILL_LAB_CAT_DESC, BILL_FM_GRP_NO, " +
		"BILL_FM_GRP_LBL, RF_GSA_INDICATOR, BILL_FM_LN_NO, BILL_FM_LN_LBL, PROJ_ABBRV_CD " +
		"ORDER BY BILL_FM_GRP_NO, BILL_FM_GRP_LBL, BILL_FM_LN_NO";  //group by must be the same
	
	private PreparedStatement HDR_CSO_REF_stmt;
	private static final String HDR_CSO_REF_query = "SELECT "
		+ "PROJ.PRIME_CONTR_ID AS PRIME, "
		+ "PROJ.SUBCTR_ID AS SUB, "
		+ "PROJ.CUST_PO_ID AS PO_ID, "
		+ "ISNULL(UDEF.UDEF_ID, \'\') AS GSA_UDEF_ID "
		+ "FROM IMAPS.DELTEK.PROJ PROJ " 
		+ "LEFT JOIN " 
		+ "IMAPS.DELTEK.GENL_UDEF UDEF "
		+ "ON " 
		+ "(PROJ.PROJ_ID = UDEF.GENL_ID " 
		+ "AND UDEF.S_TABLE_ID = \'PJ\' " 
		+ "AND UDEF.UDEF_LBL_KEY = 12 "
		+ ") " 
		+ "WHERE PROJ.PROJ_ID = ? ";

	private PreparedStatement HDR_INV_COUNT_stmt;
	private static final String HDR_INV_COUNT_query = "SELECT COUNT(1) as INVC_COUNT FROM IMAPSSTG.DBO.XX_IMAPS_INV_OUT_SUM WHERE STATUS_FL = 'U' AND DIVISION = ? ";
	
	private PreparedStatement PARAM_stmt;
	private static final String PARAM_query = "SELECT PARAMETER_VALUE FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS WHERE INTERFACE_NAME_CD = 'FDS/CCS' AND PARAMETER_NAME = ? ";
	
	
	private ResultSet SUMrs;
	private ResultSet DTLrs;
	private ResultSet GRPrs;
	private ResultSet CSOrs;
	private ResultSet INVrs;
	private ResultSet PARAMrs;
	
	// CCS Header Constants and Variables ------------------------------
	
	// CCS Line End Variables
	private String INVC_ID;
	private String I_INVCE;
	private int I_PAGE_NUM = 0;
	private int C_REC_LINE_NUM = 0;
	
	// CCS Line End Constants
	private static final char C_II_INV_TYPE = 'P';

	// CCS Line 1 Constants
	private static final char V_FILLER_001_01 = '1';
	private final String T_IMG_DETL_LNE = Filler(118);
	private final String V_FILLER_023_01 = Filler(23);

	// CCS Line 3 Variables
	private String I_CST_7_COMM;
	private String D_INV_IMG_C;
	
	// CCS Line 3 Constants
	private final String V_FILLER_038_01 = Filler(38);
	private static final String V_FILLER_DASH = " ";
	private static final String I_BILL_CTRL = "00";
	private final String V_FILLER_017_01 = Filler(17);
	private final String V_FILLER_046_01 = Filler(46);

	// CCS Line 6 Varaibles
	private String I_COL_BO;
	
	// CCS Line 6 Constants
	private final String V_FILLER_048_01 = Filler(48);
	private final String V_FILLER_009_01 = Filler(9);
	private String C_AR_DIV_MAJOR = "2"; //this is now a Division parameter!
	private final String V_FILLER_006_01 = Filler(6);
	private final String V_FILLER_028_01 = Filler(28);
	private static final String I_SHIP_FROM = "   "; // Blank in spec
	private final String V_FILLER_011_01 = Filler(11);

	// CCS Line 15 Constant and Variable
	private final String V_FILLER_003_01 = Filler(3);
	private String T_SPC_CST_REF_1;

	// CCS Line 16 Variables
	private String T_SPC_CST_REF_2;
	private String I_GEMS_ORDER_NO;
	
	// CCS Line 16 Constants
	private final String V_FILLER_027_01 = Filler(27);
	private final String V_FILLER_013_01 = Filler(13);

	// CCS Line 17 Constant
	private String T_SPC_CST_REF_3 = Filler(70);

	// CCS Lines 18, 19, 20 Constants
	private final String T_T_AND_C_LN1 = Filler(32);
	private final String T_T_AND_C_LN2 = Filler(32);
	private final String T_T_AND_C_LN3 = Filler(32);
	private final String V_FILLER_039_01 = Filler(39);
	
	// CCS Image Variables
	private BigDecimal CurSubTotal = new BigDecimal("0.0");
	private BigDecimal CumSubTotal = new BigDecimal("0.0");
	
	// FDS Constants and Variables -----------------------------------
	
	// FDS Main Segment Constants
	private String D_ACCTG_YR;
	private String D_ACCTG_MO;
	private String I_ACCTG_PROC_REG = "F"; //this is now a division parameter!
	private String D_ACCTG_CUTOFF;
	private String I_SOURCE_TRANSM = "FED"; //this is now a division parameter!
	private final String I_PROJECT = Filler(5);
	private final String FILLER_MAIN_1 = Filler(3);
	private final String C_ACCTG_ANAL = Filler(3);
	private String F_BILL_DISPRS = "2"; //this is now a division parameter!
	private static final String C_TAX_CLASS_MAIN = " ";
	private final String FILLER_MAIN_2 = Filler(5);
	private static final String C_ACCTG_ERROR = " ";
	private static final String I_CUST_CNTRL = "  ";
	private static final String I_RECLASS_OFF = "   ";
	private static final String I_MKTG_DISTRC = "  ";
	private static final String I_MKTG_REGION = "  ";
	private static final String I_SVC_BO_MAIN = "   ";
	private static final String FILLER_MAIN_3 = "  ";
	private static final String FILLER_MAIN_4 = "   ";
	private static final String C_MKTG_AREA = "  ";
	private static final String I_MKTG_ORG = "  ";
	private static final String FILLER_MAIN_5 = "     ";
	private static final byte F_ALTER = (Integer.decode("0x00")).byteValue();
	private static final BigDecimal NUMBER_SEGMENTS = new BigDecimal("1.0");
	
	// FDS Main Segment Variables
	private String FY_CD;
	private String I_BO;
	//private String INVC_ID; - declared for CCS
	//private String I_INVCE; - declared for CCS
	private String D_INVCE;
	private String I_CUST;
	private byte I_RECORD_TYPE;
	private String I_ENTERPRISE;
	private String N_CUST_ABBREV;
	private String I_NAPCODE;
	private String C_STD_IND_CLASS;
	private String C_INDUS;
	private String C_STATE;
	private String C_CNTY;
	private String C_CITY;
	private String TI_CMR_CUST_TYPE;
	private String C_CMR_CUST_TYPE;
	private String I_MKG_DIV;
	private String F_OCL;
	
	
	// FDS Revenue Segment Constants
	private static final String FILLER_REV_1 = " ";
	private static final String C_DIV = "  ";
	private static final String C_MAJOR_ACCT = "    ";
	private static final String C_MINOR_ACCT = "     ";
	private String I_SOURCE = "142"; //this is now a division parameter!
	private String C_BILL = "016"; //this is now a division parameter!
	private static final String IIS_REGION = "   ";
	private static final String IIS_BRANCH = "   ";
	private static final String IIS_DEPT = "   ";
	private static final String IIS_MKTG_TEAM = "      ";
	private static final String D_EFF = "      ";
	private static final BigDecimal Q_BILLED_TO_CUST = new BigDecimal("0.0");
	private static final String D_CONTRACT_START = "    ";
	private static final String D_CONTRACT_END = "    ";
	private static final String I_ASSOC_CONTRAC = "       ";
	private static final String I_ASSOC_BILLING = "     ";
	private static final String I_ASSOC_TO_DEPT = "   ";
	private static final String I_SUBCONT_FROM_DEPT = "   ";
	private static final String COMMISION_INDICATOR = " ";
	private final String FILLER_REV_2 = Filler(27);
	private String I_BUSINESS_TYPE = "T0"; //this is now a division parameter!
	private final String RESERVED_FILLER = Filler(22);
	
	// FDS Revenue Segment Variables
	private String I_CONTR;
	private byte C_BILL_SEGMNT_TYPE; // used by other segment, hence variable
	private String I_NSD_CONTRACT;
	private String F_GSA_INDICATOR;
	private String I_BILLABLE_CHG_CD;
	private BigDecimal A_BILL_SEGMNT = new BigDecimal("0.0"); // used by other segments
	private String I_MACH_TYPE; // used by other segments
	private String M_PRODUCT_CODE;
	
	
	// FDS Tax Detail Segment Constants
	private static final String C_OVERRIDE_INDCTR = " ";
	private String C_ORIGIN = "9"; //this is now a division parameter!
	private static final String C_EQUIP = " ";
	private final String I_MDL = Filler(3);
	private final String I_MACH_SERIAL = Filler(7);
	private final String I_INDEX = Filler(7);
	private final String I_FACTRY_ORDER = Filler(7);
	private final String I_CUST_PURCH_ORDER = Filler(7);
	private final String I_SHIP_FROM_LOC = Filler(3);
	private final String D_MFR = Filler(6);
	private String C_LOCAL_APPLIC = "1"; //this is now a division parameter!
	private static final BigDecimal Q_ITEM = new BigDecimal("1.0");
	private static final String FILLER_TAX_1 = " ";
	private static final BigDecimal A_COST = new BigDecimal("000000000.00");
	private static final String FILLER_TAX_2 = " ";
	private static final BigDecimal A_OPTION_CR = new BigDecimal("000000000.00");
	private static final BigDecimal A_VOLUME_DISC = new BigDecimal("000000000.00");
	private static final BigDecimal A_ZONE_CHARGE = new BigDecimal("000000000.00");
	private static final BigDecimal A_TIME_PRICE_DIFFRN = new BigDecimal("000000000.00");
	private final String FILLER_TAX_3 = Filler(3);
	
	// FDS Tax Detail Segment Variables
	private String I_ACCPTN_BO;
	private String I_SVC_BO;
	private String C_CERTIFC_STATUS;
	private String I_CMR_CUST_TYPE;
	private String C_TAX_CLASS;
	private String C_AGRMNT;
	private String C_PROD_CATGRY;
	private String D_ACCTG;
	private String D_INVCE_TAX ;
	private String D_ACTUAL_INST;
	private String D_ACTUAL_SHPMNT;
	private String D_AGRMNT;
	private String C_TAX;
	private BigDecimal A_BASIC;
	private BigDecimal A_ST_TAX = new BigDecimal("000000000.00");
	private BigDecimal A_CNTY_TAX = new BigDecimal("000000000.00");
	private BigDecimal A_CITY_TAX = new BigDecimal("000000000.00");
	
	
	// FDS AR Segment Constants
	private static final String FILLER_NET_AR_1 = " ";
	private String I_COLL_OFF = "28W"; //this is now a division parameter!
	private String C_COLL_DIV = "12"; //this is now a division parameter!
	private static final String I_AR_DIV = " ";
	private final String D_SHIP = Filler(6);
	private static final String C_LPF_ELIG = " ";
	private static final String AR_SOURCE_PREFIX_HOLD = " ";
	private static final String F_PPD = " ";
	private static final String I_PAYOR_IND = " ";
	private final String T_CUST_REF_2 = Filler(29);
	private final String T_CUST_REF_3 = Filler(30);
	
	// FDS AR Segment Variables
	// THERE IS A FIELD T_CUST_REF_1 in the DB, but spec
	// says to take CUST_PO_ID instead?
	private String T_CUST_REF_1;
	

	// FDS Summary Record Variables
	private int TOTAL_RECORDS = 0;
	private final BigDecimal Zero = new BigDecimal("0.0");
	private BigDecimal TOTAL_DEBITS = new BigDecimal("0.0");
	private BigDecimal TOTAL_CREDITS = new BigDecimal("0.0");
	private int F7_SEGMENT_IND_COUNT = 0;
	private BigDecimal F7_SEGMENT_IND_AMOUNT = new BigDecimal("0.0");
	private int B1_SEGMENT_IND_COUNT = 0;
	private BigDecimal B1_SEGMENT_IND_AMOUNT = new BigDecimal("0.0");
	private int F1_SEGMENT_IND_COUNT = 0;
	private BigDecimal F1_SEGMENT_IND_AMOUNT = new BigDecimal("0.0");
	private int F4_SEGMENT_IND_COUNT = 0;
	private BigDecimal F4_SEGMENT_IND_AMOUNT = new BigDecimal("0.0");
	private BigDecimal B1_TAX_IND_AMT = new BigDecimal("0.0");
	
	/**
	 * METHODS
	 */

	
	/*load properties method
	 * 
	 *  audit concerns need these values out of the processing parameter table
	 *  
	 */
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
	
	// CONSTRUCTOR ########################################################
	// Connects to database
	// Creates File Names with today's date included
	// Creates Error Log Output Stream
	public CreateFlatFiles(String propsPath, String output_Path) throws Exception {

		//System.out.println("Output path: " + output_Path);

		// Set Connection Variables		
		//load properties instead of other method
		loadProperties(propsPath);		
	    serverName = props.get("db.serverName").toString();
	    databaseName    = props.get("db.databaseName").toString();
	    userName  = props.get("db.userName").toString();
	    password   = props.get("db.password").toString();
		
		// Add Run Time Dates to File Names
		java.util.Calendar calendar = java.util.Calendar.getInstance();
		int year = calendar.get(java.util.Calendar.YEAR);
		// months in Calendar are zero based i.e. Jan = 0
		int month = calendar.get(java.util.Calendar.MONTH) + 1;
		int day = calendar.get(java.util.Calendar.DAY_OF_MONTH);

		CCSFlatFile = output_Path + "IMAPS_TO_CCS" + ".txt";
 		// + Integer.toString(month) + "_" + Integer.toString(day) + "_" + Integer.toString(year) 

		FDSFlatFile = output_Path + "IMAPS_TO_FDS" + ".BIN";
		//+ Integer.toString(month) + "_" + Integer.toString(day) + "_" + Integer.toString(year) 

		TransactionReportFile = output_Path + "Transaction_Report" + ".txt";
		// + Integer.toString(month) + "_" + Integer.toString(day) + "_" + Integer.toString(year)
				
		
		ErrorLogFile = output_Path + "FDS_CCS_JAVA_LOG" + ".txt";
		//+ Integer.toString(month) + "_" + Integer.toString(day) + "_" + Integer.toString(year)
				

		// Try to Create Error Log File Output
		try {
			ErrorLog = new java.io.PrintWriter(
					new java.io.OutputStreamWriter(
							new java.io.FileOutputStream(ErrorLogFile),
							CCSFlatFileEncoding));
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

	}// end Constructor

	
	// PUBLIC METHODS ######################################################
	
	// For Leading Zeros
	// Very important, if number is larger than length
	// then the number is truncated so as to keep rightmost numbers
	// DON'T CHANGE THIS

	
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

	// For Leading Zeros
	// Very important, if number is larger than length
	// then the number is truncated so as to keep rightmost numbers
	// DON'T CHANGE THIS
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

	// For Formatting String Numbers into form N,NNN,NNN.NN
	public String MoneyComma(String s) {
		
		if (s.charAt(s.length() - 2) == '.') {
			s = s + "0";
		} else if (s.charAt(s.length() - 3) == '.') {
			;// no-op
		} else {
			s = s + ".00";
		}

		String money;

		String cents = s.substring(s.length() - 2, s.length());
		String dollars = s.substring(0, s.length() - 3);
		String sign = " ";
		
		if(s.charAt(0) == '-')
		{
			sign = "-";
			dollars = s.substring(1, s.length() - 3);
		}
		
		money = "." + cents;
		while (dollars.length() > 3) {
			money = ","
					+ dollars.substring(dollars.length() - 3, dollars.length())
					+ money;
			dollars = dollars.substring(0, dollars.length() - 3);
		}
		money = sign + dollars + money;
		return money;

	}// end MoneyComma

	// For Formatting Double Numbers into form N,NNN,NNN.NN
	public String MoneyComma(double d) {

		String s = Double.toString(d);
		return MoneyComma(s);

	}// end MoneyComma

	// WritePacked Decimal
	// In accordance with FDS Specification
	public void WritePacked(java.io.ByteArrayOutputStream BAWriter,
			BigDecimal Val, int total, int precision) {
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
			decimal_index = ValStr.length();

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
		String dbgHex = "";
		String HexValues = LeftSide + RightSide;
ErrorLog.println(" ");
ErrorLog.println("HexValues");
		// Writing Packed
		try {

			// Every Byte == 2 Nibbles
			int count = 0;
			for (int i = 0; i < HexValues.length(); i += 2) {
			
				String cur_hex = "0x" + HexValues.substring(i, i + 2);
				byte cur_byte = (Integer.decode(cur_hex)).byteValue();

				 ErrorLog.println("  cur string :" + HexValues.substring(i, i + 2));
				 ErrorLog.println("  cur hex :" + cur_hex);
				 ErrorLog.println("  cur byte :" + cur_byte);
				dbgHex = dbgHex + " " + HexValues.substring(i, i + 2);
				 ErrorLog.println("  cum Hex :" + dbgHex);

				packed_bytes[count] = cur_byte;
				count++;
			}
			BAWriter.write(packed_bytes, 0, count);

		} catch (Exception e) {
			e.printStackTrace();
		}

	} // end Write Packed Decimal


	// PRIVATE METHODS ###################################################
	
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
				
				// SetUp Prepared Statements
				PARAM_stmt = con.prepareStatement(PARAM_query);
				HDR_INV_COUNT_stmt = con.prepareStatement(HDR_INV_COUNT_query);
				HDR_CSO_REF_stmt = con.prepareStatement(HDR_CSO_REF_query);
				SUMrs_stmt = con.prepareStatement(SUMrs_query);
				GRPrs_stmt = con.prepareStatement(GRPrs_query);
				DTLrs_CSP_stmt = con.prepareStatement(DTLrs_CSP_query);
				DTLrs_NO_CSP_stmt = con.prepareStatement(DTLrs_NO_CSP_query);
				
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
	
	private void closeConnection() {
		try {
			if (con != null)
				con.close();
			con = null;
			ErrorLog.println("Connection Closed, Program Complete...");
			
			if(ErrorLog != null)
				{
					ErrorLog.close();
					ErrorLog = null;
				}
			} catch (Exception e) {
				System.out.println("Error Closing FDS/CCS JDBC Connection!!!");
				System.out.println("Exception: " + e.getMessage());
				e.printStackTrace();
		}
	}// end closeConnection
	
	
	// JDBC Record Set Loading Methods
	// aka - SELECT statements
	private void LoadSUMrs(String Division)
	{
		//Select Invoice Summary Record Set
		try {
			SUMrs_stmt.setString(1, Division);
			SUMrs = SUMrs_stmt.executeQuery();
		} 
		catch (Exception e) {
			//Try to write Error to Log
			try{
				ErrorLog.println("Error Loading Summary Records From Database!!!");
				ErrorLog.println("Exception: " + e.getMessage());
				e.printStackTrace(ErrorLog);
				
			}catch (Exception etwo)
			{
				System.out.println("Error Loading Summary Records and Writing to Error Log");		
			}
		}
	}
	
	private void LoadGRPrs()
	{
		try {
			GRPrs_stmt.setString(1, INVC_ID);
			GRPrs = GRPrs_stmt.executeQuery();
		} catch (Exception e) {
			//Try to write Error to Log
			try{
				ErrorLog.println("Error Loading Group Detail Records!!!");
				ErrorLog.println("Exception: " + e.getMessage());
				e.printStackTrace(ErrorLog);
				
			}catch (Exception etwo)
			{
				System.out.println("Error Loading Group Detail Records and Creating Error Log");		
			}
		}
	}
	
	private void LoadDTLrs(boolean includeCSP)
	{
		try {
			// Select Invoice Detail Records
			if(includeCSP)
			{	
				DTLrs_CSP_stmt.setString(1, INVC_ID);
				DTLrs = DTLrs_CSP_stmt.executeQuery();
			}
			else
			{
				DTLrs_NO_CSP_stmt.setString(1, INVC_ID);
				DTLrs = DTLrs_NO_CSP_stmt.executeQuery();
			}
		} catch (Exception e) {
//			Try to write Error to Log
			try{
				ErrorLog.println("Error Loading Detail Records!!!");
				ErrorLog.println("Exception: " + e.getMessage());
				e.printStackTrace(ErrorLog);
				
			}catch (Exception etwo)
			{
				System.out.println("Error Loading Detail Records and Creating Error Log");		
			}
		}
	}

	
	private int GetInvoiceCount(String Division) throws Exception
	{
		int INVC_COUNT = 0;
	
		HDR_INV_COUNT_stmt.setString(1, Division);
		INVrs = HDR_INV_COUNT_stmt.executeQuery();
		INVrs.next();
		
		INVC_COUNT = INVrs.getInt("INVC_COUNT");
		
		//Close CSO query
		INVrs.close();
		INVrs = null;
		
		return INVC_COUNT;
	}
	
	// CCS FlatFile Methods
	private void OpenCCSOutput()
	{
		try {
			CCS = new java.io.BufferedWriter(
					new java.io.OutputStreamWriter(
							new java.io.FileOutputStream(CCSFlatFile),
							CCSFlatFileEncoding));
		} catch (Exception e) {
//			Try to write Error to Log
			try{
				ErrorLog.println("Error Creating CCS Output File!!!");
				ErrorLog.println("Exception: " + e.getMessage());
				e.printStackTrace(ErrorLog);
				
			}catch (Exception etwo)
			{
				System.out.println("Error Creating CCS Output File and Creating Error Log");		
			}
		}
	}
	
	private void CloseCCSOutput()
	{
		try{
			if(SUMrs != null)
			{
				SUMrs.close();
				SUMrs = null;
			}
			if(GRPrs != null)
			{
				GRPrs.close();
				GRPrs = null;
			}
			if(DTLrs != null)
			{
				DTLrs.close();
				DTLrs = null;
			}
			if(CCS != null)
			{
				CCS.close();
				CCS = null;
			}	
		}
		catch (Exception e)
		{
//			Try to write Error to Log
			try{
				ErrorLog.println("Error Closing CCS JDBC RecordSets and OutputStream!!!");
				ErrorLog.println("Exception: " + e.getMessage());
				e.printStackTrace(ErrorLog);
				
			}catch (Exception etwo)
			{
				System.out.println("Error Closing CCS JDBC RecordSets and OutputStream");		
			}
		}
	}
	
	private void LoadCCSDivisionParameters(String Division) throws Exception
	{
		String PARAMETER_NAME;
		
		//I_COL_BO
		PARAMETER_NAME = Division + "_" + "I_COL_BO";
		PARAM_stmt.setString(1, PARAMETER_NAME);
		PARAMrs = PARAM_stmt.executeQuery();
		PARAMrs.next();
		I_COL_BO = PARAMrs.getString("PARAMETER_VALUE");
		PARAMrs.close();
		PARAMrs = null;
		
		//C_AR_DIV_MAJOR
		PARAMETER_NAME = Division + "_" + "C_AR_DIV_MAJOR";
		PARAM_stmt.setString(1, PARAMETER_NAME);
		PARAMrs = PARAM_stmt.executeQuery();
		PARAMrs.next();
		C_AR_DIV_MAJOR = PARAMrs.getString("PARAMETER_VALUE");
		PARAMrs.close();
		PARAMrs = null;
	}
	
	
	private void LoadCCSHeaderVariables()
	{
		try{
				
			//Line End Variables
			INVC_ID = SUMrs.getString("INVC_ID");
			I_INVCE = LZ(INVC_ID, 7);
	
			// Line 3 Variables
			I_CST_7_COMM = SUMrs.getString("CUST_ADDR_DC");
	
			// format date in accordance with specification
			java.sql.Date dt = SUMrs.getDate("INVC_DT");
	
			java.util.Calendar calendar = java.util.Calendar
					.getInstance();
			calendar.setTime(dt);
			String year = Integer.toString(calendar
					.get(java.util.Calendar.YEAR));
			// months in Calendar are zero based i.e. Jan = 0
			String month = Integer.toString(calendar
					.get(java.util.Calendar.MONTH) + 1);
			String day = Integer.toString(calendar
					.get(java.util.Calendar.DAY_OF_MONTH));
	
			D_INV_IMG_C = LZ(month, 2) + "/" + LZ(day, 2) + "/";
			D_INV_IMG_C = D_INV_IMG_C + LZ(year.substring(1), 2);
	
			// Line 6 Variables
			// ASK CLARE ABOUT I_COL_BO - this is an educated guess -
			// GUESS CONFIRMED
			//update, this is now a division-based parameter !!!
			//I_COL_BO = TSPC(SUMrs.getString("I_COLL_OFF"), 3);
	
			//CSO query
			HDR_CSO_REF_stmt.setString(1, SUMrs.getString("PROJ_ID"));
			CSOrs = HDR_CSO_REF_stmt.executeQuery();
			CSOrs.next();
			
			//Line 15 variables
			String CSO_ref;
			CSO_ref = SUMrs.getString("PROJ_ID")  + " " + SUMrs.getString("PRIME_CONTR_ID") ;
			T_SPC_CST_REF_1 = TSPC( CSO_ref , 70);
	
			// Line 16 variables
			CSO_ref = "PO: "+CSOrs.getString("PO_ID")+" PRIME: "+CSOrs.getString("PRIME")+"  SUB: "+CSOrs.getString("SUB")+"  GSA: "+CSOrs.getString("GSA_UDEF_ID");
			T_SPC_CST_REF_2 = TSPC( CSO_ref , 70);
					
			// Line 17 variables
			CSO_ref = "CUST: "+SUMrs.getString("CUST_ID")+ " CMR:"+SUMrs.getString("CUST_ADDR_DC");
			T_SPC_CST_REF_3 = TSPC( CSO_ref , 70);
			
			//Close CSO query
			CSOrs.close();
			CSOrs = null;
			
			I_GEMS_ORDER_NO = TSPC(SUMrs.getString("CUST_PO_ID"), 6);
	
		} catch (Exception e) {
//			Try to write Error to Log
			try{
				ErrorLog.println("Error Writing CCS Invoice Header!!!");
				ErrorLog.println("Exception: " + e.getMessage());
				e.printStackTrace(ErrorLog);
				
			}catch (Exception etwo)
			{
				System.out.println("Error Writing CCS Invoice Header and Creating Error Log");		
			}
		}
	}
	
	private void WriteCCSGroupTotal(boolean LaborDetail)
	{
		try{
			String HR_CUR_FL = SUMrs.getString("HR_CUR_FL");
			String HR_CUM_FL = SUMrs.getString("HR_CUM_FL");
			
			//Write Appropriate Group Totals Header
			if (HR_CUR_FL.equals("Y") && LaborDetail) {
				CCS.write(Filler(23));
				CCS.write("----------");
				CCS.write(Filler(14));
			} else {
				CCS.write(Filler(47));
			}
			
			if(HR_CUR_FL.equals("Y"))
				CCS.write("------------------");
			else
				CCS.write(Filler(18));
			
			if (HR_CUM_FL.equals("Y") && LaborDetail) {
				CCS.write("  ----------  ");
			} else {
				CCS.write(Filler(14));
			}
	
			if(HR_CUM_FL.equals("Y"))
				CCS.write("------------------");
			else
				CCS.write(Filler(18));
			
			CCS.write("  ");
			CCS.write(Filler(20));
	
			CCS.write(I_INVCE);
			CCS.write(C_II_INV_TYPE);
			CCS.write(LZ(I_PAGE_NUM, 4));
			CCS.write(LZ(C_REC_LINE_NUM, 2));
			CCS.write(V_FILLER_023_01);
			CCS.newLine();
			C_REC_LINE_NUM++;
	
			GRPrs.next();
			CCS.write("   ");
			
			if (HR_CUR_FL.equals("Y") && LaborDetail) {
				CCS.write(TSPC(GRPrs.getString("BILL_FM_GRP_LBL"), 20));
				CCS.write(LSPC(MoneyComma(GRPrs.getString("billed_hrs")), 10));
				CCS.write(Filler(14));
			} else {
				CCS.write(TSPC(GRPrs.getString("BILL_FM_GRP_LBL"), 44));
			}
	
			if(HR_CUR_FL.equals("Y"))
				CCS.write(LSPC(MoneyComma(GRPrs.getString("billed_amt")),18));
			else
				CCS.write(Filler(18));
	
			CCS.write("  ");
	
			if (HR_CUM_FL.equals("Y") && LaborDetail) {
				CCS.write(LSPC(MoneyComma(GRPrs.getString("cum_billed_hrs")), 10));
			} else {
				CCS.write(Filler(10));
			}
	
			CCS.write("  ");
	
			if(HR_CUM_FL.equals("Y"))
				CCS.write(LSPC(MoneyComma(GRPrs.getString("cum_billed_amt")), 18));
			else
				CCS.write(Filler(18));
			
			CCS.write("  ");
			CCS.write(Filler(20));
	
			CCS.write(I_INVCE);
			CCS.write(C_II_INV_TYPE);
			CCS.write(LZ(I_PAGE_NUM, 4));
			CCS.write(LZ(C_REC_LINE_NUM, 2));
			CCS.write(V_FILLER_023_01);
			CCS.newLine();
			C_REC_LINE_NUM++;
	
			// Write a Couple Blanks Lines
			for (int i = 0; i < 2; i++) {
				CCS.write(Filler(119));
	
				CCS.write(I_INVCE);
				CCS.write(C_II_INV_TYPE);
				CCS.write(LZ(I_PAGE_NUM, 4));
				CCS.write(LZ(C_REC_LINE_NUM, 2));
				CCS.write(V_FILLER_023_01);
	
				CCS.newLine();
				C_REC_LINE_NUM++;
			}// end for 2 blank lines
		}
		catch (Exception e) {
//			Try to write Error to Log
			try{
				ErrorLog.println(I_INVCE);
				ErrorLog.println("Error Writing CCS Group Totals!!!");
				ErrorLog.println("Exception: " + e.getMessage());
				e.printStackTrace(ErrorLog);
				
			}catch (Exception etwo)
			{
				System.out.println("Error Writing CCS Group Totals and Creating Error Log");		
			}
		}
	}
	
	private void WriteCCSHeader()
	{
		try{
//			 Write CCS page header Lines 1-20
			// Line 1
			CCS.write(V_FILLER_001_01);
			CCS.write(T_IMG_DETL_LNE);

			CCS.write(I_INVCE);
			CCS.write(C_II_INV_TYPE);
			CCS.write(LZ(I_PAGE_NUM, 4));
			CCS.write(LZ(C_REC_LINE_NUM, 2));
			CCS.write(V_FILLER_023_01);

			CCS.newLine();
			C_REC_LINE_NUM++;

			// Line 2
			CCS.write(Filler(119));

			CCS.write(I_INVCE);
			CCS.write(C_II_INV_TYPE);
			CCS.write(LZ(I_PAGE_NUM, 4));
			CCS.write(LZ(C_REC_LINE_NUM, 2));
			CCS.write(V_FILLER_023_01);

			CCS.newLine();
			C_REC_LINE_NUM++;

			// Line 3
			CCS.write(V_FILLER_038_01);
			CCS.write(LZ(I_CST_7_COMM, 7));
			CCS.write(V_FILLER_DASH);
			CCS.write(I_BILL_CTRL);
			CCS.write(V_FILLER_017_01);
			CCS.write(D_INV_IMG_C);
			CCS.write(V_FILLER_046_01);

			CCS.write(I_INVCE);
			CCS.write(C_II_INV_TYPE);
			CCS.write(LZ(I_PAGE_NUM, 4));
			CCS.write(LZ(C_REC_LINE_NUM, 2));
			CCS.write(V_FILLER_023_01);

			CCS.newLine();
			C_REC_LINE_NUM++;

			// Line 4,5 are skipped
			C_REC_LINE_NUM = 6;

			// Line 6
			CCS.write(V_FILLER_048_01);
			CCS.write(LZ(I_CST_7_COMM, 7));
			CCS.write(V_FILLER_DASH);
			CCS.write(I_BILL_CTRL);
			CCS.write(V_FILLER_009_01);
			CCS.write(C_AR_DIV_MAJOR);
			CCS.write(V_FILLER_006_01);
			CCS.write(I_COL_BO);
			CCS.write(V_FILLER_028_01);
			CCS.write(I_SHIP_FROM);
			CCS.write(V_FILLER_011_01);

			CCS.write(I_INVCE);
			CCS.write(C_II_INV_TYPE);
			CCS.write(LZ(I_PAGE_NUM, 4));
			CCS.write(LZ(C_REC_LINE_NUM, 2));
			CCS.write(V_FILLER_023_01);

			CCS.newLine();
			C_REC_LINE_NUM++;

			// Lines 7-12 skipped
			C_REC_LINE_NUM = 13;

			// Line 13 - basically blank like Line 2
			CCS.write(Filler(119));

			CCS.write(I_INVCE);
			CCS.write(C_II_INV_TYPE);
			CCS.write(LZ(I_PAGE_NUM, 4));
			CCS.write(LZ(C_REC_LINE_NUM, 2));
			CCS.write(V_FILLER_023_01);

			CCS.newLine();
			C_REC_LINE_NUM++;

			// Line 14 skipped
			C_REC_LINE_NUM++;

			// Line 15
			CCS.write(V_FILLER_003_01);
			CCS.write(T_SPC_CST_REF_1);
			CCS.write(V_FILLER_046_01);

			CCS.write(I_INVCE);
			CCS.write(C_II_INV_TYPE);
			CCS.write(LZ(I_PAGE_NUM, 4));
			CCS.write(LZ(C_REC_LINE_NUM, 2));
			CCS.write(V_FILLER_023_01);

			CCS.newLine();
			C_REC_LINE_NUM++;

			// Line 16
			CCS.write(V_FILLER_003_01);
			CCS.write(T_SPC_CST_REF_2);
			CCS.write(V_FILLER_027_01);
			CCS.write(I_GEMS_ORDER_NO);
			CCS.write(V_FILLER_013_01);

			CCS.write(I_INVCE);
			CCS.write(C_II_INV_TYPE);
			CCS.write(LZ(I_PAGE_NUM, 4));
			CCS.write(LZ(C_REC_LINE_NUM, 2));
			CCS.write(V_FILLER_023_01);

			CCS.newLine();
			C_REC_LINE_NUM++;

			// Line 17
			CCS.write(V_FILLER_003_01);
			CCS.write(T_SPC_CST_REF_3);
			CCS.write(V_FILLER_046_01);

			CCS.write(I_INVCE);
			CCS.write(C_II_INV_TYPE);
			CCS.write(LZ(I_PAGE_NUM, 4));
			CCS.write(LZ(C_REC_LINE_NUM, 2));
			CCS.write(V_FILLER_023_01);

			CCS.newLine();
			C_REC_LINE_NUM++;

			// Line 18
			CCS.write(V_FILLER_048_01);
			CCS.write(T_T_AND_C_LN1);
			CCS.write(V_FILLER_039_01);

			CCS.write(I_INVCE);
			CCS.write(C_II_INV_TYPE);
			CCS.write(LZ(I_PAGE_NUM, 4));
			CCS.write(LZ(C_REC_LINE_NUM, 2));
			CCS.write(V_FILLER_023_01);

			CCS.newLine();
			C_REC_LINE_NUM++;

			// Line 19
			CCS.write(V_FILLER_048_01);
			CCS.write(T_T_AND_C_LN2);
			CCS.write(V_FILLER_039_01);

			CCS.write(I_INVCE);
			CCS.write(C_II_INV_TYPE);
			CCS.write(LZ(I_PAGE_NUM, 4));
			CCS.write(LZ(C_REC_LINE_NUM, 2));
			CCS.write(V_FILLER_023_01);

			CCS.newLine();
			C_REC_LINE_NUM++;

			// Line 20
			CCS.write(V_FILLER_048_01);
			CCS.write(T_T_AND_C_LN3);
			CCS.write(V_FILLER_039_01);

			CCS.write(I_INVCE);
			CCS.write(C_II_INV_TYPE);
			CCS.write(LZ(I_PAGE_NUM, 4));
			CCS.write(LZ(C_REC_LINE_NUM, 2));
			CCS.write(V_FILLER_023_01);

			CCS.newLine();
			C_REC_LINE_NUM = 40;
		}
		catch (Exception e) {
//			Try to write Error to Log
			try{
				ErrorLog.println("Error Writing CCS Image Header!!!");
				ErrorLog.println("Exception: " + e.getMessage());
				e.printStackTrace(ErrorLog);
				
			}catch (Exception etwo)
			{
				System.out.println("Error Writing CCS Image Header and Creating Error Log");		
			}
		}
	}
	
	private void WriteCCSImageHeader(boolean LaborDetail)
	{
		try{
			
			String HR_CUR_FL = SUMrs.getString("HR_CUR_FL");
			String HR_CUM_FL = SUMrs.getString("HR_CUM_FL");
			String HR_BILL_RT_FL = SUMrs.getString("HR_BILL_RT_FL");
			
			CCS.write(Filler(23));
			
			if(HR_CUR_FL.equals("Y") && LaborDetail)
				CCS.write(LSPC("Current", 10));
			else
				CCS.write(Filler(10));
			
			CCS.write("  ");
			CCS.write(LSPC(" ", 10));
			CCS.write("  ");
			
			if(HR_CUR_FL.equals("Y"))
				CCS.write(LSPC("Current", 18));
			else
				CCS.write(Filler(18));
			
			CCS.write("  ");
			
			if(HR_CUM_FL.equals("Y") && LaborDetail)
				CCS.write(LSPC("Cumulative", 10));
			else
				CCS.write(Filler(10));
			
			CCS.write("  ");
			
			if(HR_CUM_FL.equals("Y"))
				CCS.write(LSPC("Cumulative", 18));
			else
				CCS.write(Filler(18));
			
			CCS.write("  ");
			CCS.write(Filler(20));
			
			CCS.write(I_INVCE);
			CCS.write(C_II_INV_TYPE);
			CCS.write(LZ(I_PAGE_NUM, 4));
			CCS.write(LZ(C_REC_LINE_NUM, 2));
			CCS.write(V_FILLER_023_01);
			CCS.newLine();
			C_REC_LINE_NUM++;
			
			CCS.write(Filler(23));
			
			if(HR_CUR_FL.equals("Y") && LaborDetail)
				CCS.write(LSPC("Hours", 10));
			else
				CCS.write(Filler(10));
			
			CCS.write("  ");
			
			if(HR_BILL_RT_FL.equals("Y") && LaborDetail)
				CCS.write(LSPC("Rate", 10));
			else
				CCS.write(Filler(10));
			
			CCS.write("  ");
			
			if(HR_CUR_FL.equals("Y"))
				CCS.write(LSPC("Amount", 18));
			else
				CCS.write(Filler(18));
			
			CCS.write("  ");
			
			if(HR_CUM_FL.equals("Y") && LaborDetail)
				CCS.write(LSPC("Hours", 10));
			else
				CCS.write(Filler(10));
			
			CCS.write("  ");
			
			if(HR_CUM_FL.equals("Y"))
				CCS.write(LSPC("Amount", 18));
			else
				CCS.write(Filler(18));
			
			CCS.write("  ");
			CCS.write(Filler(20));
			
			CCS.write(I_INVCE);
			CCS.write(C_II_INV_TYPE);
			CCS.write(LZ(I_PAGE_NUM, 4));
			CCS.write(LZ(C_REC_LINE_NUM, 2));
			CCS.write(V_FILLER_023_01);
			CCS.newLine();
			C_REC_LINE_NUM++;
			
			CCS.write(Filler(23));
			
			if(HR_CUR_FL.equals("Y") && LaborDetail)
				CCS.write("----------");
			else
				CCS.write(Filler(10));
			
			CCS.write("  ");
			
			if(HR_BILL_RT_FL.equals("Y") && LaborDetail)
				CCS.write("----------");
			else
				CCS.write(Filler(10));
			
			CCS.write("  ");
			
			if(HR_CUR_FL.equals("Y"))
				CCS.write("------------------");
			else
				CCS.write(Filler(18));
			
			CCS.write("  ");
			
			if(HR_CUM_FL.equals("Y") && LaborDetail)
				CCS.write("----------");
			else
				CCS.write(Filler(10));
			
			CCS.write("  ");
			
			if(HR_CUM_FL.equals("Y"))
				CCS.write("------------------");
			else
				CCS.write(Filler(18));
			
			CCS.write("  ");
			CCS.write(Filler(20));
			
			CCS.write(I_INVCE);
			CCS.write(C_II_INV_TYPE);
			CCS.write(LZ(I_PAGE_NUM, 4));
			CCS.write(LZ(C_REC_LINE_NUM, 2));
			CCS.write(V_FILLER_023_01);
			CCS.newLine();
			C_REC_LINE_NUM++;
			
			
		}catch (Exception e) {
			e.printStackTrace();
			System.out
					.println("Error Writing CCS Image Header: "
							+ e.getMessage());
		}
	}
	
	private void WriteCCSDetailLine(boolean LaborDetail, boolean New_Labor_Cat, String Labor_Cat)
	{
		try{
			
			String HR_CUR_FL = SUMrs.getString("HR_CUR_FL");
			String HR_CUM_FL = SUMrs.getString("HR_CUM_FL");
			String HR_BILL_RT_FL = SUMrs.getString("HR_BILL_RT_FL");
			String HR_EMPL_NAME_FL = SUMrs.getString("HR_EMPL_NAME_FL");
			
			CCS.write("   ");

			// HERE
			if (LaborDetail) {

				// if new lab cat
				if (New_Labor_Cat) {
					
					if (HR_EMPL_NAME_FL.equals("Y")) {
						CCS.write(TSPC(Labor_Cat.toUpperCase(), 20));
						CCS.write(Filler(96));
						CCS.write(I_INVCE);
						CCS.write(C_II_INV_TYPE);
						CCS.write(LZ(I_PAGE_NUM, 4));
						CCS.write(LZ(C_REC_LINE_NUM, 2));
						CCS.write(V_FILLER_023_01);
						CCS.newLine();
						C_REC_LINE_NUM++;
						CCS.write("   ");
						CCS.write(" " + TSPC(DTLrs.getString("NAME"), 19));
					} 
					else {
						CCS.write(" " + TSPC(Labor_Cat, 19));
					}
				} 
				else {
					String emp_name = DTLrs.getString("NAME");
					CCS.write(" " + TSPC(emp_name, 19));
				}

			} 
			else {
				CCS.write(" " + TSPC(DTLrs.getString("BILL_FM_LN_LBL"),	19));
			}

			
			
			if (HR_CUR_FL.equals("Y") && LaborDetail 
					&& DTLrs.getDouble("BILLED_HRS") != 0.00)
				CCS.write(LSPC(DTLrs.getString("BILLED_HRS"), 10));
			else
				CCS.write(Filler(10));

			CCS.write("  ");

			if (HR_BILL_RT_FL.equals("Y") && LaborDetail
					&& DTLrs.getDouble("BILL_RT_AMT") != 0.00 )
				CCS.write(LSPC(DTLrs.getString("BILL_RT_AMT"), 10));
			else 
				CCS.write(Filler(10));
			
			CCS.write("  ");
			
			if(HR_CUR_FL.equals("Y"))
				CCS.write(LSPC(MoneyComma(DTLrs.getString("BILLED_AMT")), 18));
			else
				CCS.write(Filler(18));
			
			CCS.write("  ");

			if (SUMrs.getString("HR_CUM_FL").equals("Y") && LaborDetail
					&& DTLrs.getDouble("CUM_BILLED_HRS") != 0.00)
				CCS.write(LSPC(MoneyComma(DTLrs.getString("CUM_BILLED_HRS")), 10));
			else
				CCS.write(Filler(10));

			CCS.write("  ");
			
			if(HR_CUM_FL.equals("Y"))
				CCS.write(LSPC(MoneyComma(DTLrs.getString("CUM_BILLED_AMT")), 18));
			else
				CCS.write(Filler(18));
			
			CCS.write("  ");
			CCS.write(Filler(20));

			// Keep Track of SubTotals
			CurSubTotal = CurSubTotal.add(DTLrs.getBigDecimal("BILLED_AMT"));
			CumSubTotal = CumSubTotal.add(DTLrs.getBigDecimal("CUM_BILLED_AMT"));

			CCS.write(I_INVCE);
			CCS.write(C_II_INV_TYPE);
			CCS.write(LZ(I_PAGE_NUM, 4));
			CCS.write(LZ(C_REC_LINE_NUM, 2));
			CCS.write(V_FILLER_023_01);
			CCS.newLine();
			C_REC_LINE_NUM++;
		}catch (Exception e) {
//			Try to write Error to Log
			try{
				ErrorLog.println("Error Writing CCS Detail Line!!!");
				ErrorLog.println("Exception: " + e.getMessage());
				e.printStackTrace(ErrorLog);
				
			}catch (Exception etwo)
			{
				System.out.println("Error Writing CCS Detail Line and Creating Error Log");		
			}
		}
	}
	
	private void WriteCCSContinuedLine()
	{
		try {
			// Show Blank Lines Until 89
			while (C_REC_LINE_NUM <= 89) {
				CCS.write(Filler(119));

				CCS.write(I_INVCE);
				CCS.write(C_II_INV_TYPE);
				CCS.write(LZ(I_PAGE_NUM, 4));
				CCS.write(LZ(C_REC_LINE_NUM, 2));
				CCS.write(V_FILLER_023_01);

				CCS.newLine();
				C_REC_LINE_NUM++;
			} // end while not yet 89

			// Write CONTINUED LINE 98
			CCS.write(Filler(50));
			CCS.write("CONTINUED");
			CCS.write(Filler(60));
			CCS.write(I_INVCE);
			CCS.write(C_II_INV_TYPE);
			CCS.write(LZ(I_PAGE_NUM, 4));
			CCS.write(LZ(98, 2));
			CCS.write(V_FILLER_023_01);
			CCS.newLine();		
			
		} catch (Exception e) {
//			Try to write Error to Log
			try{
				ErrorLog.println("Error Writing CCS Continue Line!!!");
				ErrorLog.println("Exception: " + e.getMessage());
				e.printStackTrace(ErrorLog);
				
			}catch (Exception etwo)
			{
				System.out.println("Error Writing CCS Continue Line and Creating Error Log");		
			}
		}
	}
	
	
	private void WriteCCSInvoiceSubtotal(boolean retainage)
	{
		try {
			String HR_CUR_FL = SUMrs.getString("HR_CUR_FL");
			String HR_CUM_FL = SUMrs.getString("HR_CUM_FL");
			
//			 INVOICE TOTAL LINES
			CCS.write(Filler(47));
			if(HR_CUR_FL.equals("Y"))
				CCS.write("------------------");
			else
				CCS.write(Filler(18));
			
			CCS.write(Filler(14));
			
			if(HR_CUM_FL.equals("Y"))
				CCS.write("------------------");
			else
				CCS.write(Filler(18));
			
			CCS.write("  ");
			CCS.write(Filler(20));

			CCS.write(I_INVCE);
			CCS.write(C_II_INV_TYPE);
			CCS.write(LZ(I_PAGE_NUM, 4));
			CCS.write(LZ(C_REC_LINE_NUM, 2));
			CCS.write(V_FILLER_023_01);
			CCS.newLine();
			C_REC_LINE_NUM++;

			CCS.write("   ");
			CCS.write(TSPC("Invoice Total", 44));
			
			if(HR_CUR_FL.equals("Y"))
			{
				CCS.write(LSPC(MoneyComma(CurSubTotal.toString()), 18));
			}
			else
				CCS.write(Filler(18));

			CCS.write(Filler(14));
			
			if(HR_CUM_FL.equals("Y"))
			{
				CCS.write(LSPC(MoneyComma(CumSubTotal.toString()), 18));
			}
			else
				CCS.write(Filler(18));
			
			CCS.write("  ");
			CCS.write(Filler(20));
			CCS.write(I_INVCE);
			CCS.write(C_II_INV_TYPE);
			CCS.write(LZ(I_PAGE_NUM, 4));
			CCS.write(LZ(C_REC_LINE_NUM, 2));
			CCS.write(V_FILLER_023_01);
			CCS.newLine();
			C_REC_LINE_NUM++;

			CCS.write(Filler(47));
			
			if(HR_CUR_FL.equals("Y"))
				CCS.write("==================");
			else
				CCS.write(Filler(18));
			
			CCS.write(Filler(14));
			
			if(HR_CUM_FL.equals("Y"))
				CCS.write("==================");
			else
				CCS.write(Filler(18));
			
			CCS.write("  ");
			CCS.write(Filler(20));

			CCS.write(I_INVCE);
			CCS.write(C_II_INV_TYPE);
			CCS.write(LZ(I_PAGE_NUM, 4));
			CCS.write(LZ(C_REC_LINE_NUM, 2));
			CCS.write(V_FILLER_023_01);
			CCS.newLine();
			C_REC_LINE_NUM++;			
			
		} catch (Exception e) {
//			Try to write Error to Log
			try{
				ErrorLog.println("Error Invoice CCS Invoice Total!!!");
				ErrorLog.println("Exception: " + e.getMessage());
				e.printStackTrace(ErrorLog);
				
			}catch (Exception etwo)
			{
				System.out.println("Error Writing CCS Invoice Total and Creating Error Log");		
			}
		}
		
	}
	
	private void WriteCCSAmountLine()
	{
		try {
			
//			 Line 99
			double AMT = SUMrs.getDouble("INVC_AMT");

			if (AMT >= 0) {
				CCS.write(LSPC("PAY THIS AMOUNT", 44));
				CCS.write(LSPC("$"
								+ MoneyComma((SUMrs
										.getString("INVC_AMT"))), 39));
			} else {
				CCS.write(LSPC("CREDIT THIS AMOUNT", 44));
				CCS.write(LSPC("$"
						+ MoneyComma((SUMrs.getString("INVC_AMT"))), 39));
			}

			CCS.write(Filler(36));
			CCS.write(I_INVCE);
			CCS.write(C_II_INV_TYPE);
			CCS.write(LZ(I_PAGE_NUM, 4));
			CCS.write(LZ(99, 2));
			CCS.write(V_FILLER_023_01);
			CCS.newLine();		
			
		} catch (Exception e) {
//			Try to write Error to Log
			try{
				ErrorLog.println("Error Writing CCS Amount Line!!!");
				ErrorLog.println("Exception: " + e.getMessage());
				e.printStackTrace(ErrorLog);
				
			}catch (Exception etwo)
			{
				System.out.println("Error Writing CCS Amount Line and Creating Error Log");		
			}
		}
	}
		
	public void WriteCCSFlatFile(String Division) {
		try {
			// If Connection is Established, Proceed
			if (con != null) {
				
				ErrorLog.println("Attempting to Write CCS Flat File...");

				// Don't do anything if there are no invoices
				if(0 == GetInvoiceCount(Division)) return;
				
				// Otherwise, load the summary records and get started
				LoadCCSDivisionParameters(Division);
				LoadSUMrs(Division);

				// For each Summary Record with Detail Records
				// Write Invoice to flat file in accordance with
				// CCS Specification
				while (SUMrs.next()) {
					
					// Load CCS Header Variables for current SUM record
					LoadCCSHeaderVariables();

					// Load Bill Form Group Totals Record Set for current SUM record
					LoadGRPrs();

					// Load DTL records for current SUM record
					LoadDTLrs(true);

					// Initialize State Variables
					
					I_PAGE_NUM = 0;
					C_REC_LINE_NUM = 0;
					
					// To Determine if a Group Total line must be written
					int PREV_FM_GRP_NO = 12345;
					int FM_GRP_NO = 0;
					String FM_GRP_LBL = "DFLT";
					String PREV_FM_GRP_LBL = "DFLT";
					String PREV_LAB_CAT = "12345";
					
					// To Determine if Detail Header has been written
					boolean NoDtlSegments = true;
					boolean NoDtlHeader = true;
					// To Determine the Invoice Header type
					boolean ServiceInvoice = false;
		
					// To keep track of Invoice SubTotal
					// Most important for Invoices with Retainage Discounts
					CurSubTotal = new BigDecimal("0.00");
					CumSubTotal = new BigDecimal("0.00");

					// For Each Invoice Detail Record
					// Write Detail Invoice Image to flat file
					// NOTE** The Flat File has not been written to yet
					// NOTE** This is where the Flat File is written to
					while (DTLrs.next()) {

						// Get Current State
						FM_GRP_NO = DTLrs.getInt("BILL_FM_GRP_NO");
						FM_GRP_LBL = DTLrs.getString("BILL_FM_GRP_LBL");
						
						if (PREV_FM_GRP_NO == 12345) {
							PREV_FM_GRP_NO = FM_GRP_NO;
							PREV_FM_GRP_LBL = FM_GRP_LBL;
						}

						// If, Form Group Number is different
						// Previous Form Group Totals Must Be Written
						if ( (FM_GRP_NO != PREV_FM_GRP_NO) ||
							  (!FM_GRP_LBL.equals(PREV_FM_GRP_LBL))	) 
						{
							WriteCCSGroupTotal(ServiceInvoice);
							PREV_FM_GRP_NO = FM_GRP_NO;
							PREV_FM_GRP_LBL = FM_GRP_LBL;
						}// end if Group Totals Must be Written
						
						
						// Acknowledge existence of detail records
						NoDtlSegments = false;
		
						/*
						 * Determine if new page is needed. A new page is needed
						 * if: 
						 * 1. This is the first page of the invoice 
						 * 2. Line Number is greater than 89 
						 * NOTE: although 89 is the 
						 * last line number before a CONTINUED line, there are
						 * several instances where more than 1 line is written
						 * to the file before the line number can be checked.
						 * For this reason, if line number is 79 or greater we
						 * write to the next page to ensure we don't go over 89.
						 * Testing may reveal that we can increase the number
						 * 79...Just being careful not to go over 89.
						 */
						
						// IF new page is needed
						if (C_REC_LINE_NUM >= 79 || C_REC_LINE_NUM == 0) {

							// If not First Page of Invoice
							// Then CONTINUED notification is Required
							if (I_PAGE_NUM != 0) {
								WriteCCSContinuedLine();
							}

							// Re-Set Line Num and Increment Page num
							C_REC_LINE_NUM = 1;
							I_PAGE_NUM++;

							// Write Page Header
							WriteCCSHeader();

						}// end if new page needed

						
						// BILL HISTORY DETAIL IMAGE lines 40-89
						
						// Determine if Service Invoice or Not
						String CUR_LAB_CAT = DTLrs
								.getString("BILL_LAB_CAT_DESC");
						String CUR_LAB_CAT_CD = DTLrs
								.getString("BILL_LAB_CAT_CD");

						if (!(CUR_LAB_CAT_CD == null)) {
							ServiceInvoice = true;
						}
						else
						{
							CUR_LAB_CAT_CD = " ";
							CUR_LAB_CAT = " ";
							ServiceInvoice = false;
						}
						
						// if needed write IMAGE HEADER
						if(NoDtlHeader)
						{
							WriteCCSImageHeader(true);
							NoDtlHeader = false;
						}
						

						// Write Detail Lines
						// This will write all of the Detail Lines
						// For all of the Detail Groups
						boolean new_lab_cat = true;
						if (PREV_LAB_CAT.equals(CUR_LAB_CAT))
						{
							new_lab_cat = false;
						}
						PREV_LAB_CAT = CUR_LAB_CAT;
						
						WriteCCSDetailLine(ServiceInvoice, new_lab_cat, CUR_LAB_CAT);

					}// end while Detail Records exist

					/*
					 * All Details and Group Totals have been written. Remember,
					 * Group Totals written at begining of Loop.
					 * 
					 * But we are NOW out of the Detail loop, and
					 * the LAST Group's Totals must be Written
					 */
					WriteCCSGroupTotal(ServiceInvoice);

					// if no detail segments, 
					// write header that hasn't been written yet
					if (NoDtlSegments) {
						// Re-Set Line Num and Increment Page num
						C_REC_LINE_NUM = 1;
						I_PAGE_NUM++;
						// Write CCS Header
						WriteCCSHeader();
					} 
					else // if detail exists write subtotal
					{
						WriteCCSInvoiceSubtotal(false);

					}// else detail segments exist

					// Close RecordSets
					GRPrs.close();
					GRPrs = null;
					DTLrs.close();
					DTLrs = null;
					
					WriteCCSAmountLine();

				}// end while Summary Records Exist

			} else
				// else if Connection was null
				ErrorLog.println("Error: No active Connection");
		} catch (Exception e) {
//			Try to write Error to Log
			try{
				ErrorLog.println("Error Writing CCS Flat File!!!");
				ErrorLog.println("Exception: " + e.getMessage());
				e.printStackTrace(ErrorLog);
				
			}catch (Exception etwo)
			{
				System.out.println("Writing CCS Flat File and Creating Error Log");		
			}
		}

	}// end WriteCCSFlatFile

	
	// FDS FlatFile Methods
	private void OpenFDSOutput()
	{
		try {
			FDS = new java.io.FileOutputStream(FDSFlatFile);
			FDSArray = new java.io.ByteArrayOutputStream();
		} catch (Exception e) {
//			Try to write Error to Log
			try{
				ErrorLog.println("Error Creating FDS OutputStreams!!!");
				ErrorLog.println("Exception: " + e.getMessage());
				e.printStackTrace(ErrorLog);
				
			}catch (Exception etwo)
			{
				System.out.println("Error Creating FDS OutputStreams and Creating Error Log");		
			}
		}
	}
	
	private void CloseFDSOutput()
	{
		try{
			if(SUMrs != null)
			{
				SUMrs.close();
				SUMrs = null;
			}
			if(DTLrs != null)
			{
				DTLrs.close();
				DTLrs = null;
			}
			if(FDS != null)
			{
				FDS.close();
				FDS = null;
			}	
			if(FDSArray != null)
			{
				FDSArray.close();
				FDSArray = null;
			}
		}
		catch (Exception etwo)
		{
//			Try to write Error to Log
			try{
				ErrorLog.println("Error Closing FDS JDBC RecordSets and OutputStream!!!");
				ErrorLog.println("Exception: " + etwo.getMessage());
				etwo.printStackTrace(ErrorLog);
				
			}catch (Exception ethree)
			{
				System.out.println("Error Closing FDS JDBC RecordSets and OutputStream and Creating Error Log");		
			}
		}
	}
	
	private void LoadFDSDivisionParameters(String Division) throws Exception
	{
		String PARAMETER_NAME;
		
		//I_ACCTG_PROC_REG
		PARAMETER_NAME = Division + "_" + "I_ACCTG_PROC_REG";
		PARAM_stmt.setString(1, PARAMETER_NAME);
		PARAMrs = PARAM_stmt.executeQuery();
		PARAMrs.next();
		I_ACCTG_PROC_REG = PARAMrs.getString("PARAMETER_VALUE");
		PARAMrs.close();
		PARAMrs = null;
		
		//I_SOURCE_TRANSM
		PARAMETER_NAME = Division + "_" + "I_SOURCE_TRANSM";
		PARAM_stmt.setString(1, PARAMETER_NAME);
		PARAMrs = PARAM_stmt.executeQuery();
		PARAMrs.next();
		I_SOURCE_TRANSM = PARAMrs.getString("PARAMETER_VALUE");
		PARAMrs.close();
		PARAMrs = null;
		
		//F_BILL_DISPRS
		PARAMETER_NAME = Division + "_" + "F_BILL_DISPRS";
		PARAM_stmt.setString(1, PARAMETER_NAME);
		PARAMrs = PARAM_stmt.executeQuery();
		PARAMrs.next();
		F_BILL_DISPRS = PARAMrs.getString("PARAMETER_VALUE");
		PARAMrs.close();
		PARAMrs = null;
		
		//I_SOURCE
		PARAMETER_NAME = Division + "_" + "I_SOURCE";
		PARAM_stmt.setString(1, PARAMETER_NAME);
		PARAMrs = PARAM_stmt.executeQuery();
		PARAMrs.next();
		I_SOURCE = PARAMrs.getString("PARAMETER_VALUE");
		PARAMrs.close();
		PARAMrs = null;
		
		//C_BILL
		PARAMETER_NAME = Division + "_" + "C_BILL";
		PARAM_stmt.setString(1, PARAMETER_NAME);
		PARAMrs = PARAM_stmt.executeQuery();
		PARAMrs.next();
		C_BILL = PARAMrs.getString("PARAMETER_VALUE");
		PARAMrs.close();
		PARAMrs = null;
		
		//I_BUSINESS_TYPE
		PARAMETER_NAME = Division + "_" + "I_BUSINESS_TYPE";
		PARAM_stmt.setString(1, PARAMETER_NAME);
		PARAMrs = PARAM_stmt.executeQuery();
		PARAMrs.next();
		I_BUSINESS_TYPE = PARAMrs.getString("PARAMETER_VALUE");
		PARAMrs.close();
		PARAMrs = null;
		
		//C_ORIGIN
		PARAMETER_NAME = Division + "_" + "C_ORIGIN";
		PARAM_stmt.setString(1, PARAMETER_NAME);
		PARAMrs = PARAM_stmt.executeQuery();
		PARAMrs.next();
		C_ORIGIN = PARAMrs.getString("PARAMETER_VALUE");
		PARAMrs.close();
		PARAMrs = null;
		
		//C_LOCAL_APPLIC
		PARAMETER_NAME = Division + "_" + "C_LOCAL_APPLIC";
		PARAM_stmt.setString(1, PARAMETER_NAME);
		PARAMrs = PARAM_stmt.executeQuery();
		PARAMrs.next();
		C_LOCAL_APPLIC = PARAMrs.getString("PARAMETER_VALUE");
		PARAMrs.close();
		PARAMrs = null;
		
		//I_COLL_OFF
		PARAMETER_NAME = Division + "_" + "I_COLL_OFF";
		PARAM_stmt.setString(1, PARAMETER_NAME);
		PARAMrs = PARAM_stmt.executeQuery();
		PARAMrs.next();
		I_COLL_OFF = PARAMrs.getString("PARAMETER_VALUE");
		PARAMrs.close();
		PARAMrs = null;
		
		//C_COLL_DIV
		PARAMETER_NAME = Division + "_" + "C_COLL_DIV";
		PARAM_stmt.setString(1, PARAMETER_NAME);
		PARAMrs = PARAM_stmt.executeQuery();
		PARAMrs.next();
		C_COLL_DIV = PARAMrs.getString("PARAMETER_VALUE");
		PARAMrs.close();
		PARAMrs = null;
		
	}
	
	private void LoadFDSMainSegmentVariables()
	{
		try {
//			 Main Segment Variables
			FY_CD = SUMrs.getString("FY_CD");
			I_BO = TSPC(SUMrs.getString("I_BO"), 3);
			INVC_ID = SUMrs.getString("INVC_ID");
			I_INVCE = LZ(INVC_ID, 7);

			// Format date in accordance with specification
			java.sql.Date dt = SUMrs.getDate("INVC_DT");

			D_INVCE = 	dt.toString().substring(5, 7) +
						dt.toString().substring(8, 10) +
						dt.toString().substring(2, 4);

			I_CUST = LZ(SUMrs.getString("CUST_ADDR_DC"), 7);
			I_RECORD_TYPE = (Integer.decode("0xf1")).byteValue();
			I_ENTERPRISE = LZ(SUMrs.getString("I_ENTERPRISE"), 7);
			N_CUST_ABBREV = TSPC(SUMrs.getString("CUST_NAME"), 15); // CMR NAME???
			I_NAPCODE = TSPC(SUMrs.getString("I_NAPCODE"), 3);
			
			C_STD_IND_CLASS = TSPC(SUMrs.getString("C_STD_IND_CLASS"), 4);
			C_INDUS = TSPC(SUMrs.getString("C_INDUS"), 2);
			C_STATE = LZ(SUMrs.getString("C_STATE"), 2);
			C_CNTY = LZ(SUMrs.getString("C_CNTY"), 3);
			C_CITY = LZ(SUMrs.getString("C_CITY"), 4);
			F_OCL = TSPC(SUMrs.getString("F_OCL"), 1);
			
			// TODO: CONVERT CMR CUST TYPE TO FDS CUST TYPE
			// SHOULD JAVA DO THIS?
			TI_CMR_CUST_TYPE = SUMrs.getString("TI_CMR_CUST_TYPE");

			switch (TI_CMR_CUST_TYPE.charAt(0)) {
			case 'B':
				C_CMR_CUST_TYPE = "F";
				break;
			case 'E':
				C_CMR_CUST_TYPE = "P";
				break;
			case 'C':
				C_CMR_CUST_TYPE = "S";
				break;
			case 'A':
				C_CMR_CUST_TYPE = "C";
				break;
			case 'H':
				C_CMR_CUST_TYPE = "A";
				break;
			case 'K':
				C_CMR_CUST_TYPE = "I";
				break;
			default:
				C_CMR_CUST_TYPE = "C";
			}

			I_MKG_DIV = TSPC(SUMrs.getString("I_MKG_DIV"), 2);
			
		} catch (Exception e) {
//			Try to write Error to Log
			try{
				ErrorLog.println("Error Writing FDS Main Segment!!!");
				ErrorLog.println("Exception: " + e.getMessage());
				e.printStackTrace(ErrorLog);
				
			}catch (Exception etwo)
			{
				System.out.println("Error Writing FDS Main Segment and Creating Error Log");		
			}
		}
	}
		
	private void WriteFDSMainSegment()
	{
		try {
			
			String MAIN_SEGMENT_1 = D_ACCTG_YR + D_ACCTG_MO
			+ I_ACCTG_PROC_REG + D_ACCTG_CUTOFF
			+ I_SOURCE_TRANSM + I_PROJECT + FILLER_MAIN_1
			+ C_ACCTG_ANAL + I_BO + I_INVCE + D_INVCE
			+ F_BILL_DISPRS + C_TAX_CLASS_MAIN + FILLER_MAIN_2
			+ C_ACCTG_ERROR + I_CUST + I_CUST_CNTRL;

			String MAIN_SEGMENT_2 = I_ENTERPRISE + N_CUST_ABBREV
			+ I_NAPCODE + I_RECLASS_OFF + I_MKTG_DISTRC
			+ I_MKTG_REGION + I_SVC_BO_MAIN + C_STD_IND_CLASS
			+ C_INDUS + C_STATE + C_CNTY + C_CITY + F_OCL
			+ C_CMR_CUST_TYPE + FILLER_MAIN_3;

			String MAIN_SEGMENT_3 = FILLER_MAIN_4 + I_MKG_DIV
			+ C_MKTG_AREA + I_MKTG_ORG + FILLER_MAIN_5;
			
		
			FDSArray.write(MAIN_SEGMENT_1
					.getBytes(FDSFlatFileEncoding));
			FDSArray.write(I_RECORD_TYPE);
			FDSArray.write(MAIN_SEGMENT_2
					.getBytes(FDSFlatFileEncoding));
			FDSArray.write(F_ALTER);
			FDSArray.write(MAIN_SEGMENT_3
					.getBytes(FDSFlatFileEncoding));
			WritePacked(FDSArray, NUMBER_SEGMENTS, 3, 0);
			
		} catch (Exception e) {
//			Try to write Error to Log
			try{
				ErrorLog.println("Error Writing FDS Main Segment!!!");
				ErrorLog.println("Exception: " + e.getMessage());
				e.printStackTrace(ErrorLog);
				
			}catch (Exception etwo)
			{
				System.out.println("Error Writing FDS Main Segment and Creating Error Log");		
			}
		}
	}
	
	// F7 Segment
	private void WriteFDSRevSegment(boolean DTLrefs)
	{
		try {
			
			// Load Rev Segment Variables
			C_BILL_SEGMNT_TYPE = (Integer.decode("0xf7")).byteValue();
			I_NSD_CONTRACT = TSPC(SUMrs.getString("PRIME_CONTR_ID"), 9);

			if(DTLrefs)
			{
				I_CONTR = TSPC(DTLrs.getString("PROJ_ABBRV_CD"), 5);
				I_BILLABLE_CHG_CD = TSPC(DTLrs.getString("RI_BILLABLE_CHG_CD"), 4);
				I_MACH_TYPE = LZ(DTLrs.getString("I_MACH_TYPE"), 5);
				M_PRODUCT_CODE = LZ(DTLrs.getString("M_PRODUCT_CODE"), 8);
				F_GSA_INDICATOR = TSPC(DTLrs.getString("RF_GSA_INDICATOR"), 1);
			}
			else
			{
				I_CONTR = Filler(5);
				I_BILLABLE_CHG_CD = "CSI ";
				I_MACH_TYPE = Filler(5);
				M_PRODUCT_CODE = Filler(8);
				F_GSA_INDICATOR = "O";
			}
			

			// Chunk String Segments together
			String F7_SEGMENT_1 = FILLER_REV_1 + C_DIV
					+ C_MAJOR_ACCT + C_MINOR_ACCT
					+ I_SOURCE + C_BILL + I_CONTR
					+ IIS_REGION + IIS_BRANCH + IIS_DEPT
					+ IIS_MKTG_TEAM + D_EFF;

			String F7_SEGMENT_2 = I_NSD_CONTRACT
					+ F_GSA_INDICATOR + I_MACH_TYPE
					+ D_CONTRACT_START + D_CONTRACT_END
					+ I_ASSOC_CONTRAC + I_ASSOC_BILLING
					+ I_ASSOC_TO_DEPT + I_SUBCONT_FROM_DEPT
					+ M_PRODUCT_CODE + I_BILLABLE_CHG_CD
					+ COMMISION_INDICATOR + FILLER_REV_2
					+ I_BUSINESS_TYPE + RESERVED_FILLER;

			// TODO: REVERSE SIGN ?????
			if(DTLrefs)
			{
				BigDecimal billed = new BigDecimal(DTLrs.getString("BILLED_AMT"));
				A_BILL_SEGMNT = billed;
				A_BILL_SEGMNT = A_BILL_SEGMNT.negate();
			}
			else
			{
				BigDecimal billed = new BigDecimal(SUMrs.getString("FDS_INV_AMT"));
				BigDecimal tax = new BigDecimal(SUMrs.getString("FDS_SALES_TAX_AMT"));
				A_BILL_SEGMNT = billed.subtract(tax);
				A_BILL_SEGMNT = billed;
				A_BILL_SEGMNT = A_BILL_SEGMNT.negate();
			}
			
			// Keep Summary Tally
			if(A_BILL_SEGMNT.compareTo(Zero) < 0)
			{
				TOTAL_CREDITS = TOTAL_CREDITS.add(A_BILL_SEGMNT);
			}
			else
			{
				TOTAL_DEBITS = TOTAL_DEBITS.add(A_BILL_SEGMNT);
			}
				

			// Write REVENUE SEGMENT
			FDSArray.write(C_BILL_SEGMNT_TYPE);
			FDSArray.write(F7_SEGMENT_1.getBytes(FDSFlatFileEncoding));
			WritePacked(FDSArray, Q_BILLED_TO_CUST, 5,1);
			FDSArray.write(F7_SEGMENT_2.getBytes(FDSFlatFileEncoding));
			WritePacked(FDSArray, A_BILL_SEGMNT, 13, 2);
			
			
		} catch (Exception e) {
//			Try to write Error to Log
			try{
				ErrorLog.println("Error Writing FDS Revenue Segment!!!");
				ErrorLog.println("Exception: " + e.getMessage());
				e.printStackTrace(ErrorLog);
				
			}catch (Exception etwo)
			{
				System.out.println("Error Writing FDS Revenue Segment");		
			}
		}
	}
		
	// B1 Segment
	private void WriteFDSTaxDtlSegment(boolean DTLrefs)
	{
		try {
			//Load Tax Detail Segment Variables
			I_MACH_TYPE = Filler(5);
			C_BILL_SEGMNT_TYPE = (Integer.decode("0xb1")).byteValue();
			I_ACCPTN_BO = TSPC(SUMrs.getString("I_BO"), 3);
			// I_SVC_BO is also part of main segment, but
			// diff
			I_SVC_BO = TSPC(SUMrs.getString("TI_SVC_BO"), 3);
			
			C_CERTIFC_STATUS = TSPC(SUMrs.getString("TC_CERTIFC_STATUS"), 1);
	
			I_CMR_CUST_TYPE = TSPC(TI_CMR_CUST_TYPE,
					1);
			// C_TAX_CLASS is also part of main segment, but
			// diff
			C_TAX_CLASS = TSPC(SUMrs.getString("TC_TAX_CLASS"), 3);
			
			if(DTLrefs)
			{
				C_AGRMNT = TSPC(DTLrs.getString("TC_AGRMNT"), 2);
				C_PROD_CATGRY = TSPC(DTLrs.getString("TC_PROD_CATGRY"), 2);
			}
			else
			{
				C_AGRMNT = "  ";
				C_PROD_CATGRY = "  ";
			}
			
			D_ACCTG = FY_CD.substring(FY_CD.length() - 2)
					+ LZ(SUMrs.getString("PD_NO"), 2);
			
			// Format date in accordance with specification
			java.sql.Date dt = SUMrs.getDate("INVC_DT");
			D_INVCE_TAX = 	dt.toString().substring(2, 4) +
							dt.toString().substring(5, 7) +
							dt.toString().substring(8, 10);
			
			// TODO: Determine where TS_DT is
			// It is supposed to be used in the next 3
			// variables
			if(DTLrefs)
			{
				//Format date in accordance with specification
				dt = DTLrs.getDate("TS_DT");
				D_ACTUAL_INST = dt.toString().substring(2, 4) +
								dt.toString().substring(5, 7) +
								dt.toString().substring(8, 10);
				D_ACTUAL_SHPMNT = D_ACTUAL_INST;
				D_AGRMNT = D_ACTUAL_INST;
			}
			else
			{
				D_ACTUAL_INST = D_INVCE_TAX;
				D_ACTUAL_SHPMNT = D_INVCE_TAX;
				D_AGRMNT = D_INVCE_TAX;
			}
			
			if(DTLrefs)
			{
				C_TAX = TSPC(DTLrs.getString("TC_TAX"),2);
			}
			else
			{
				C_TAX = "  ";
			}
			
			// TAX DETAIL
			if(DTLrefs)
			{
				A_ST_TAX = new BigDecimal(DTLrs.getString("STATE_SALES_TAX_AMT"));
				A_ST_TAX = A_ST_TAX.negate();
				
				A_CNTY_TAX = new BigDecimal(DTLrs.getString("COUNTY_SALES_TAX_AMT"));
				A_CNTY_TAX = A_CNTY_TAX.negate();
				
				A_CITY_TAX = new BigDecimal(DTLrs.getString("CITY_SALES_TAX_AMT"));
				A_CITY_TAX = A_CITY_TAX.negate();
				
				A_BASIC = A_BILL_SEGMNT;			
			}
			else
			{
				A_ST_TAX = new BigDecimal(SUMrs.getString("FDS_SALES_TAX_AMT"));
				A_ST_TAX = A_ST_TAX.negate();
				A_BASIC = A_BILL_SEGMNT;
				A_CNTY_TAX = new BigDecimal("000000000.00");
				A_CITY_TAX = new BigDecimal("000000000.00");
			}
						

			//	Debug
			B1_TAX_IND_AMT = B1_TAX_IND_AMT.add(A_ST_TAX);
			B1_TAX_IND_AMT = B1_TAX_IND_AMT.add(A_CNTY_TAX);
			B1_TAX_IND_AMT = B1_TAX_IND_AMT.add(A_CITY_TAX);
			ErrorLog.println("B1_A: " + A_BASIC);
			ErrorLog.println("A_ST_TAX: " + A_ST_TAX);
			ErrorLog.println("A_CNTY_TAX: " + A_CNTY_TAX);
			ErrorLog.println("A_CITY_TAX: " + A_CITY_TAX);
						
			A_BILL_SEGMNT = new BigDecimal("000000000.00");

			// Chunk Strings together
			String B1_SEGMENT_1 = I_SOURCE
					+ C_OVERRIDE_INDCTR + I_ACCPTN_BO
					+ I_SVC_BO + C_CERTIFC_STATUS
					+ I_CMR_CUST_TYPE + C_TAX_CLASS
					+ C_ORIGIN + C_AGRMNT + C_EQUIP
					+ C_PROD_CATGRY + I_MACH_TYPE + I_MDL
					+ I_MACH_SERIAL + D_ACCTG + I_INDEX
					+ I_FACTRY_ORDER + I_CUST_PURCH_ORDER
					+ D_INVCE_TAX + D_ACTUAL_INST
					+ D_ACTUAL_SHPMNT + D_AGRMNT
					+ I_SHIP_FROM_LOC + D_MFR
					+ C_LOCAL_APPLIC + C_TAX;

			// Write TAX_DETAIL segment
			FDSArray.write(C_BILL_SEGMNT_TYPE);
			FDSArray.write(B1_SEGMENT_1
					.getBytes(FDSFlatFileEncoding));
			WritePacked(FDSArray, Q_ITEM, 7, 0);
			FDSArray.write(FILLER_TAX_1
					.getBytes(FDSFlatFileEncoding));
			WritePacked(FDSArray, A_BASIC, 11, 2);
			WritePacked(FDSArray, A_COST, 9, 2);
			FDSArray.write(FILLER_TAX_2
					.getBytes(FDSFlatFileEncoding));
			WritePacked(FDSArray, A_OPTION_CR, 9, 2);
			WritePacked(FDSArray, A_VOLUME_DISC, 9, 2);
			WritePacked(FDSArray, A_ZONE_CHARGE, 9, 2);
			WritePacked(FDSArray, A_TIME_PRICE_DIFFRN,
					9, 2);
			WritePacked(FDSArray, A_ST_TAX, 9, 2);
			WritePacked(FDSArray, A_CNTY_TAX, 9, 2);
			WritePacked(FDSArray, A_CITY_TAX, 9, 2);
			FDSArray.write(FILLER_TAX_3
					.getBytes(FDSFlatFileEncoding));
			WritePacked(FDSArray, A_BILL_SEGMNT, 13, 2);
			
		} catch (Exception e) {
//			Try to write Error to Log
			try{
				ErrorLog.println("Error Writing FDS Tax Detail!!!");
				ErrorLog.println("Exception: " + e.getMessage());
				e.printStackTrace(ErrorLog);
				
			}catch (Exception etwo)
			{
				System.out.println("Error Writing FDS Tax Detail and Creating Error Log");		
			}
		}
	}
		
	// F1 Segment
	private void WriteFDSARSegment()
	{
		try {
			
			// Load AR Variables
			C_BILL_SEGMNT_TYPE = (Integer.decode("0xf1")).byteValue();
			T_CUST_REF_1 = TSPC(SUMrs.getString("CUST_PO_ID"), 40);
			A_BILL_SEGMNT = SUMrs.getBigDecimal("FDS_INV_AMT");
			//A_BILL_SEGMNT = A_BILL_SEGMNT.negate();
			
			if(A_BILL_SEGMNT.compareTo(Zero) < 0)
			{
				TOTAL_CREDITS = TOTAL_CREDITS.add(A_BILL_SEGMNT);
			}
			else
			{
				TOTAL_DEBITS = TOTAL_DEBITS.add(A_BILL_SEGMNT);
			}			
			
			// Chunk Strings together
			String F1_SEGMENT_1 = FILLER_NET_AR_1 + C_DIV
			+ C_MAJOR_ACCT + C_MINOR_ACCT + I_SOURCE
			+ I_COLL_OFF + C_COLL_DIV + I_AR_DIV + T_CUST_REF_1
			+ D_SHIP + C_LPF_ELIG + AR_SOURCE_PREFIX_HOLD
			+ F_PPD + I_PAYOR_IND + T_CUST_REF_2 + T_CUST_REF_3
			+ RESERVED_FILLER;

			// WRITE NET AR
			FDSArray.write(C_BILL_SEGMNT_TYPE);
			FDSArray.write(F1_SEGMENT_1.getBytes(FDSFlatFileEncoding));
			WritePacked(FDSArray, A_BILL_SEGMNT, 13, 2);
			
		} catch (Exception e) {
//			Try to write Error to Log
			try{
				ErrorLog.println("Error Writing FDS AR Segment!!!");
				ErrorLog.println("Exception: " + e.getMessage());
				e.printStackTrace(ErrorLog);
				
			}catch (Exception etwo)
			{
				System.out.println("Error Writing FDS AR Segment and Creating Error Log");		
			}
		}
	}
		
	// F4 Segment
	private void WriteFDSTaxSumSegment()
	{
		try
		{
			// SALES TAX SUMMARY VARIABLES
			//A_BILL_SEGMNT = A_BILL_SEGMNT; - this has already been set
			//								and tested to != 0.00
			C_BILL_SEGMNT_TYPE = (Integer.decode("0xf4")).byteValue();// Byte.decode("0xF4");
			String FILLER_TAX_SUM_1 = " ";
			String FILLER_TAX_SUM_2 = Filler(115+22);
			
			// Chunk together
			String F4_SEGMENT_1 = FILLER_TAX_SUM_1 + C_DIV
					+ C_MAJOR_ACCT + C_MINOR_ACCT + I_SOURCE
					+ FILLER_TAX_SUM_2;

			// WRITE TAX SUMMARY SEGMENT
			FDSArray.write(C_BILL_SEGMNT_TYPE);
			FDSArray.write(F4_SEGMENT_1.getBytes(FDSFlatFileEncoding));
			WritePacked(FDSArray, A_BILL_SEGMNT, 13, 2);
			
			//Keep Tally
			if(A_BILL_SEGMNT.compareTo(Zero) < 0)
			{
				TOTAL_CREDITS = TOTAL_CREDITS.add(A_BILL_SEGMNT);
			}
			else
			{
				TOTAL_DEBITS = TOTAL_DEBITS.add(A_BILL_SEGMNT);
			}
			
		}catch (Exception e) {
//			Try to write Error to Log
			try{
				ErrorLog.println("Error Writing FDS Tax Summary Segment!!!");
				ErrorLog.println("Exception: " + e.getMessage());
				e.printStackTrace(ErrorLog);
				
			}catch (Exception etwo)
			{
				System.out.println("Error Writing FDS Tax Summary Segment and Creating Error Log");		
			}
		}
	}
	
	private void PrepareFDSSummaryRecord(String Division) throws Exception
	{
		/* Debug */
		// Don't do anything if there are no invoices
		if(0 == GetInvoiceCount(Division)) return;
		
		ErrorLog.println("preparing FDS summary record: " + Division);
		
		ErrorLog.println("TOTAL_CREDITS:" + TOTAL_CREDITS.toString());
		ErrorLog.println("TOTAL_DEBITS:  " + TOTAL_DEBITS.toString());

		FDSSummaryRecordParameters.put(Division+"_"+"TOTAL_RECORDS", Integer.toString(TOTAL_RECORDS)); //remember type change here
		FDSSummaryRecordParameters.put(Division+"_"+"TOTAL_CREDITS", TOTAL_CREDITS);
		FDSSummaryRecordParameters.put(Division+"_"+"TOTAL_DEBITS", TOTAL_DEBITS);
		
		FDSSummaryRecordParameters.put(Division+"_"+"D_ACCTG_YR", D_ACCTG_YR);
		FDSSummaryRecordParameters.put(Division+"_"+"D_ACCTG_MO", D_ACCTG_MO);
		FDSSummaryRecordParameters.put(Division+"_"+"I_ACCTG_PROC_REG", I_ACCTG_PROC_REG);
		FDSSummaryRecordParameters.put(Division+"_"+"D_ACCTG_CUTOFF", D_ACCTG_CUTOFF);
		FDSSummaryRecordParameters.put(Division+"_"+"I_SOURCE_TRANSM", I_SOURCE_TRANSM);	

		FDSSummaryRecordParameters.put(Division+"_"+"I_SOURCE", I_SOURCE);
				
		FDSSummaryRecordParameters.put(Division+"_"+"F7_SEGMENT_IND_COUNT", Integer.toString(F7_SEGMENT_IND_COUNT)); //remember type change here
		FDSSummaryRecordParameters.put(Division+"_"+"F7_SEGMENT_IND_AMOUNT", F7_SEGMENT_IND_AMOUNT);
		
		FDSSummaryRecordParameters.put(Division+"_"+"B1_SEGMENT_IND_COUNT", Integer.toString(B1_SEGMENT_IND_COUNT)); //remember type change here
		FDSSummaryRecordParameters.put(Division+"_"+"B1_SEGMENT_IND_AMOUNT", B1_SEGMENT_IND_AMOUNT);

		FDSSummaryRecordParameters.put(Division+"_"+"F1_SEGMENT_IND_COUNT", Integer.toString(F1_SEGMENT_IND_COUNT)); //remember type change here
		FDSSummaryRecordParameters.put(Division+"_"+"F1_SEGMENT_IND_AMOUNT", F1_SEGMENT_IND_AMOUNT);

		FDSSummaryRecordParameters.put(Division+"_"+"F4_SEGMENT_IND_COUNT", Integer.toString(F4_SEGMENT_IND_COUNT)); //remember type change here
		FDSSummaryRecordParameters.put(Division+"_"+"F4_SEGMENT_IND_AMOUNT", F4_SEGMENT_IND_AMOUNT);		
		
		
		//reset values for next STI array
		TOTAL_RECORDS = 0;
		TOTAL_DEBITS = new BigDecimal("0.0");
		TOTAL_CREDITS = new BigDecimal("0.0");
		F7_SEGMENT_IND_COUNT = 0;
		F7_SEGMENT_IND_AMOUNT = new BigDecimal("0.0");
		B1_SEGMENT_IND_COUNT = 0;
		B1_SEGMENT_IND_AMOUNT = new BigDecimal("0.0");
		F1_SEGMENT_IND_COUNT = 0;
		F1_SEGMENT_IND_AMOUNT = new BigDecimal("0.0");
		F4_SEGMENT_IND_COUNT = 0;
		F4_SEGMENT_IND_AMOUNT = new BigDecimal("0.0");
		B1_TAX_IND_AMT = new BigDecimal("0.0");
		
	}
	
	private void WriteFDSSummaryRecord(String Division) throws Exception {
		try {

	       // Don't do anything if there are no invoices
			if(0 == GetInvoiceCount(Division)) return;
				
			ErrorLog.println("writing FDS summary record: " + Division);
			
			TOTAL_RECORDS = Integer.parseInt((String) FDSSummaryRecordParameters.get(Division+"_"+"TOTAL_RECORDS"));
			
			TOTAL_CREDITS = (BigDecimal)FDSSummaryRecordParameters.get(Division+"_"+"TOTAL_CREDITS");
			TOTAL_DEBITS = (BigDecimal) FDSSummaryRecordParameters.get(Division+"_"+"TOTAL_DEBITS");			

			ErrorLog.println("TOTAL_CREDITS:" + TOTAL_CREDITS.toString());
			ErrorLog.println("TOTAL_DEBITS:  " + TOTAL_DEBITS.toString());
			
			D_ACCTG_YR = (String) FDSSummaryRecordParameters.get(Division+"_"+"D_ACCTG_YR");
			D_ACCTG_MO = (String) FDSSummaryRecordParameters.get(Division+"_"+"D_ACCTG_MO");
			I_ACCTG_PROC_REG = (String) FDSSummaryRecordParameters.get(Division+"_"+"I_ACCTG_PROC_REG");
			D_ACCTG_CUTOFF = (String) FDSSummaryRecordParameters.get(Division+"_"+"D_ACCTG_CUTOFF");
			I_SOURCE_TRANSM = (String) FDSSummaryRecordParameters.get(Division+"_"+"I_SOURCE_TRANSM");
			
			I_SOURCE = (String) FDSSummaryRecordParameters.get(Division+"_"+"I_SOURCE");
			

			F7_SEGMENT_IND_COUNT = Integer.parseInt((String) FDSSummaryRecordParameters.get(Division+"_"+"F7_SEGMENT_IND_COUNT"));
			F7_SEGMENT_IND_AMOUNT = (BigDecimal) FDSSummaryRecordParameters.get(Division+"_"+"F7_SEGMENT_IND_AMOUNT");

			B1_SEGMENT_IND_COUNT = Integer.parseInt((String) FDSSummaryRecordParameters.get(Division+"_"+"B1_SEGMENT_IND_COUNT"));
			B1_SEGMENT_IND_AMOUNT = (BigDecimal) FDSSummaryRecordParameters.get(Division+"_"+"B1_SEGMENT_IND_AMOUNT");

			F1_SEGMENT_IND_COUNT = Integer.parseInt((String) FDSSummaryRecordParameters.get(Division+"_"+"F1_SEGMENT_IND_COUNT"));
			F1_SEGMENT_IND_AMOUNT = (BigDecimal) FDSSummaryRecordParameters.get(Division+"_"+"F1_SEGMENT_IND_AMOUNT");

			F4_SEGMENT_IND_COUNT = Integer.parseInt((String) FDSSummaryRecordParameters.get(Division+"_"+"F4_SEGMENT_IND_COUNT"));
			F4_SEGMENT_IND_AMOUNT = (BigDecimal) FDSSummaryRecordParameters.get(Division+"_"+"F4_SEGMENT_IND_AMOUNT");			

			String FILLER_1 = Filler(7);
			String FILLER_2 = Filler(7);
			String FILLER_3 = Filler(7);
			String FILLER_4 = Filler(5);
			byte I_RECORD_TYPE = (Integer.decode("0xf0")).byteValue(); // Byte.decode("0xF0");
			String FILLER_5 = Filler(69);
			BigDecimal I_NUMBER_SEGMENTS = new BigDecimal("1.0");
			byte C_BILL_SEGMNT_TYPE = I_RECORD_TYPE; // Byte.decode("0xF0");
			//String SOURCE = "142";
			BigDecimal SEGMENT_NUMBER = new BigDecimal("1.0");

			// Write Begining of Summary Record
			String SUM_SEGMENT_1 = D_ACCTG_YR + D_ACCTG_MO
					+ I_ACCTG_PROC_REG + D_ACCTG_CUTOFF + I_SOURCE_TRANSM;
			
			FDSArray.write(SUM_SEGMENT_1.getBytes(FDSFlatFileEncoding));

			FDSArray.write(FILLER_1.getBytes(FDSFlatFileEncoding));
			WritePacked(FDSArray, new BigDecimal(Integer
					.toString(TOTAL_RECORDS)
					+ ".0"), 7, 0);
			FDSArray.write(FILLER_2.getBytes(FDSFlatFileEncoding));
			WritePacked(FDSArray, TOTAL_DEBITS, 13, 2);
			FDSArray.write(FILLER_3.getBytes(FDSFlatFileEncoding));
			WritePacked(FDSArray, TOTAL_CREDITS, 13, 2);
			FDSArray.write(FILLER_4.getBytes(FDSFlatFileEncoding));
			FDSArray.write(I_RECORD_TYPE);
			FDSArray.write(FILLER_5.getBytes(FDSFlatFileEncoding));
			WritePacked(FDSArray, I_NUMBER_SEGMENTS, 3, 0);
			FDSArray.write(C_BILL_SEGMNT_TYPE);
			FDSArray.write(I_SOURCE.getBytes(FDSFlatFileEncoding));
			WritePacked(FDSArray, SEGMENT_NUMBER, 8, 0);

			// Write Segment Variables
			byte F7_SEGMENT_INDICATOR = (Integer.decode("0xf7"))
					.byteValue();
			byte B1_SEGMENT_INDICATOR = (Integer.decode("0xb1"))
					.byteValue();
			byte F4_SEGMENT_INDICATOR = (Integer.decode("0xf4"))
					.byteValue();
			byte F1_SEGMENT_INDICATOR = (Integer.decode("0xf1"))
					.byteValue();

			// F7			
			FDSArray.write(F7_SEGMENT_INDICATOR);
			WritePacked(FDSArray, new BigDecimal(Integer
					.toString(F7_SEGMENT_IND_COUNT)
					+ ".0"), 7, 0);
			WritePacked(FDSArray, F7_SEGMENT_IND_AMOUNT, 13, 2);

			SEGMENT_NUMBER = new BigDecimal("2.0");
			WritePacked(FDSArray, SEGMENT_NUMBER, 8, 0);
			
			/* Debug */
			ErrorLog.println(" ");
			ErrorLog.println("SUMMARY CONTROL RECORD **** ");
			ErrorLog.println(" ");
			ErrorLog.println("F7 COUNT : " + Integer
					.toString(F7_SEGMENT_IND_COUNT));
			ErrorLog.println("F7 AMOUNT: " + F7_SEGMENT_IND_AMOUNT.toString());
			
			
			// B1
			FDSArray.write(B1_SEGMENT_INDICATOR);
			WritePacked(FDSArray, new BigDecimal(Integer
					.toString(B1_SEGMENT_IND_COUNT)
					+ ".0"), 7, 0);
			WritePacked(FDSArray, B1_SEGMENT_IND_AMOUNT, 13, 2);

			SEGMENT_NUMBER = new BigDecimal("3.0");
			WritePacked(FDSArray, SEGMENT_NUMBER, 8, 0);
			
			/* Debug */
			ErrorLog.println("B1 COUNT : " + Integer
					.toString(B1_SEGMENT_IND_COUNT));
			ErrorLog.println("B1 AMOUNT: " + B1_SEGMENT_IND_AMOUNT.toString());
			

			// F1
			FDSArray.write(F1_SEGMENT_INDICATOR);
			WritePacked(FDSArray, new BigDecimal(Integer
					.toString(F1_SEGMENT_IND_COUNT)
					+ ".0"), 7, 0);
			WritePacked(FDSArray, F1_SEGMENT_IND_AMOUNT, 13, 2);

			/* Debug */
			ErrorLog.println("F1 COUNT : " + Integer
					.toString(F1_SEGMENT_IND_COUNT));
			ErrorLog.println("F1 AMOUNT: " + F1_SEGMENT_IND_AMOUNT.toString());
			
			

			// F4
			
			//	Blank Segment Variables
			byte BLANK_SEGMENT_INDICATOR = (Integer.decode("0x00")).byteValue();
			BigDecimal BLANK_SEGMENT_IND_COUNT = new BigDecimal("0.0");
			BigDecimal BLANK_SEGMENT_IND_AMOUNT = new BigDecimal("0.0");

			// If F4 Segment does not exist, don't write it's summary record
			if( F4_SEGMENT_IND_COUNT == 0)
			{
				SEGMENT_NUMBER = new BigDecimal("0.0");
				WritePacked(FDSArray, SEGMENT_NUMBER, 8, 0);
				FDSArray.write(BLANK_SEGMENT_INDICATOR);
				WritePacked(FDSArray, BLANK_SEGMENT_IND_COUNT, 7, 0);
				WritePacked(FDSArray, BLANK_SEGMENT_IND_AMOUNT, 13, 2);
			}
			else
			{
				SEGMENT_NUMBER = new BigDecimal("4.0");
				WritePacked(FDSArray, SEGMENT_NUMBER, 8, 0);
				FDSArray.write(F4_SEGMENT_INDICATOR);
				WritePacked(FDSArray, new BigDecimal(Integer
						.toString(F4_SEGMENT_IND_COUNT)
						+ ".0"), 7, 0);
				WritePacked(FDSArray, F4_SEGMENT_IND_AMOUNT, 13, 2);
				
				/* Debug */
				ErrorLog.println("F4 COUNT : " + Integer
						.toString(F4_SEGMENT_IND_COUNT));
				ErrorLog.println("F4 AMOUNT: " + F4_SEGMENT_IND_AMOUNT.toString());
			}
			

			// Blank Segment Variables
			SEGMENT_NUMBER = new BigDecimal("0.0");
			

			// Write 4 blank segements
			for (int i = 0; i < 4; i++) {
				WritePacked(FDSArray, SEGMENT_NUMBER, 8, 0);
				FDSArray.write(BLANK_SEGMENT_INDICATOR);
				WritePacked(FDSArray, BLANK_SEGMENT_IND_COUNT, 7, 0);
				WritePacked(FDSArray, BLANK_SEGMENT_IND_AMOUNT, 13, 2);
			}

			// Last Filler
			// FDS spec says 28...Our spec said 27
			// I think it's 28
			FDSArray.write(Filler(28).getBytes(FDSFlatFileEncoding));	
			
		} catch (Exception e) {
//			Try to write Error to Log
			try{
				ErrorLog.println("Error Writing FDS Summary Record!!!");
				ErrorLog.println("Exception: " + e.getMessage());
				e.printStackTrace(ErrorLog);
				
			}catch (Exception etwo)
			{
				System.out.println("Error Writing FDS Summary Record and Creating Error Log");		
			}
		}
	}
	
	private void WriteFDSArrayToFlatFile() throws Exception
	{

		//we will do this LAST, after the summary records are written.
		// Write ByteArray to File
		// WITH EORs/EOFs added
		//WriteFDSArray();
		FDSArray.writeTo(FDS);		
	}
	
	
	public void WriteFDSArray(String Division) throws Exception {
		try {
			// If Connection is Established, Proceed
			if (con != null) {
				
				ErrorLog.println("Attempting to Write FDS Flat File...");
				ErrorLog.println("");
				ErrorLog.println("");
				
				// Don't do anything if there are no invoices
				if(0 == GetInvoiceCount(Division)) return;
				
				// Otherwise, load the summary records and get started
				LoadFDSDivisionParameters(Division);
				LoadSUMrs(Division);

				// PROCESSING DATE VARIABLES
				// THESE ARE SAME FOR ALL MAIN AND SUMMARY SEGMENTS
				// BUT MUST BE CALCULATED AT RUNTIME
				java.util.Calendar calendar = java.util.Calendar.getInstance();
				int year = calendar.get(java.util.Calendar.YEAR);
				// months in Calendar are zero based i.e. Jan = 0
				int month = calendar.get(java.util.Calendar.MONTH) + 1;
				D_ACCTG_YR = LZ(year, 1);
				D_ACCTG_MO = LZ(month, 2);
				D_ACCTG_CUTOFF = LZ(calendar.get(java.util.Calendar.DAY_OF_YEAR), 3);

				// For each Summary Record with Detail Records
				// Write Invoice to flat file in accordance with
				// FDS Specification

				/* DEBUG */
				int prev_bytes = 0;

				while (SUMrs.next()) {		

					
					INVC_ID = SUMrs.getString("INVC_ID");
					/* Debug */
					ErrorLog.println("INVC_ID = " + LZ(INVC_ID, 7));
					
					LoadDTLrs(false);

					// State Variable
					boolean NoDtlSegments = true;

					// For each detail invoice record,
					// Write a MAIN+REV record
					// Write a MAIN+TAXDTL record
					while (DTLrs.next()) {
						
						NoDtlSegments = false;

						// Write MAIN+REV record
						LoadFDSMainSegmentVariables();
						WriteFDSMainSegment();
						WriteFDSRevSegment(true);
						
						// Update Summary Data
						F7_SEGMENT_IND_AMOUNT = F7_SEGMENT_IND_AMOUNT.add(A_BILL_SEGMNT);
						F7_SEGMENT_IND_COUNT++;
						TOTAL_RECORDS++;
				
						/* Debug */
						ErrorLog.println("F7 : " + A_BILL_SEGMNT.toString());
						ErrorLog.println("Record Size : "
						+ (FDSArray.size() - prev_bytes)
						+ " bytes");
						prev_bytes = FDSArray.size();

						// Write MAIN+TAXDTL record
						WriteFDSMainSegment();
						WriteFDSTaxDtlSegment(true);
						
						// Update Summary Data
						B1_SEGMENT_IND_AMOUNT = B1_SEGMENT_IND_AMOUNT.add(A_BILL_SEGMNT);
						B1_SEGMENT_IND_COUNT++;
						TOTAL_RECORDS++;
						
						/* Debug */
						ErrorLog.println("B1 : " + A_BILL_SEGMNT.toString());
						ErrorLog.println("Record Size : "
						+ (FDSArray.size() - prev_bytes)
						+ " bytes");
						prev_bytes = FDSArray.size();	

					}// for each IMAPS Invoice detail record relating to
					// Summary record

					// If No Detail Segments, 
					// Remove all references to DTLrs
					if (NoDtlSegments) {

						// Write MAIN+REV record
						LoadFDSMainSegmentVariables();
						WriteFDSMainSegment();
						WriteFDSRevSegment(false);
						
						// Update Summary Data
						F7_SEGMENT_IND_AMOUNT = F7_SEGMENT_IND_AMOUNT.add(A_BILL_SEGMNT);
						F7_SEGMENT_IND_COUNT++;
						TOTAL_RECORDS++;
				
						/* Debug */
						ErrorLog.println("F7 : " + A_BILL_SEGMNT.toString());
						ErrorLog.println("Record Size : "
						+ (FDSArray.size() - prev_bytes)
						+ " bytes");
						prev_bytes = FDSArray.size();

						// Write MAIN+TAXDTL record
						WriteFDSMainSegment();
						WriteFDSTaxDtlSegment(false);
						
						// Update Summary Data
						B1_SEGMENT_IND_AMOUNT = B1_SEGMENT_IND_AMOUNT.add(A_BILL_SEGMNT);
						B1_SEGMENT_IND_COUNT++;
						TOTAL_RECORDS++;
						
						/* Debug */
						ErrorLog.println("B1 : " + A_BILL_SEGMNT.toString());
						ErrorLog.println("Record Size : "
						+ (FDSArray.size() - prev_bytes)
						+ " bytes");
						prev_bytes = FDSArray.size();
					}// end if no detail segment

					// Write MAIN+AR record
					WriteFDSMainSegment();
					WriteFDSARSegment();
					
					// Update Summary Data
					F1_SEGMENT_IND_AMOUNT = F1_SEGMENT_IND_AMOUNT.add(A_BILL_SEGMNT);
					F1_SEGMENT_IND_COUNT++;
					TOTAL_RECORDS++;
					
					/* Debug */
					ErrorLog.println("F1 : " + A_BILL_SEGMNT.toString());
					ErrorLog.println("Record Size : "
							+ (FDSArray.size() - prev_bytes) + " bytes");
					prev_bytes = FDSArray.size();

					// if needed, write SALES TAX SUMMARY record
					A_BILL_SEGMNT = SUMrs.getBigDecimal("FDS_SALES_TAX_AMT");
					if (A_BILL_SEGMNT.compareTo(new BigDecimal("0.0")) != 0) {

						A_BILL_SEGMNT = A_BILL_SEGMNT.negate();
						// Write MAIN+TAXSUM record
						WriteFDSMainSegment();
						WriteFDSTaxSumSegment();
						
						// Update Summary Data
						F4_SEGMENT_IND_AMOUNT = F4_SEGMENT_IND_AMOUNT.add(A_BILL_SEGMNT);
						F4_SEGMENT_IND_COUNT++;
						TOTAL_RECORDS++;
						
						/* Debug */
						ErrorLog.println("F4 : " + A_BILL_SEGMNT.toString());
						ErrorLog.println("Record Size : "
								+ (FDSArray.size() - prev_bytes)
								+ " bytes");
						prev_bytes = FDSArray.size();
					}

					/* Debug */
					if (F1_SEGMENT_IND_AMOUNT.compareTo((F7_SEGMENT_IND_AMOUNT.add(F4_SEGMENT_IND_AMOUNT)).negate()) == 0)
						ErrorLog.println("Balanced");
					else
						ErrorLog.println("UNBALANCED!!!!!!!");
					ErrorLog.println("F1        TOTAL: " + F1_SEGMENT_IND_AMOUNT);
					ErrorLog.println("F7+F4     TOTAL:" + (F7_SEGMENT_IND_AMOUNT.add(F4_SEGMENT_IND_AMOUNT)) );
					ErrorLog.println("");
					ErrorLog.println("");

				}// end while summary records exist

				
				/* Div 1M changes
				 *
				 *Hi Keith,
				FDS receives multiple STIs in a single file from other billing systems.  Below is an example of the mulitple STI file format that we receive today... 
				
				Input billing file format - 
				STI_A Detail Record1
				STI_A Detail Record2
				STI_A Detail Record3
				STI_B Detail Record1
				STI_B Detail Record2
				STI_B Detail Record3
				STI_B Detail Record4
				STI_A Summary Record
				STI_B Summary Record
				End of file
				
				Regards,
				Anvisha Agarwal
				Dept: Americas Financial Information and Ledger
				(720) 396-8319, TL 938-8319
				anvisha@us.ibm.com
				
				ALSO, FOR ED: improve transaction report
				FDS/CCS Record Counts - per division and per file
				 */
				// Prepare FDS SUMMARY RECORD
				PrepareFDSSummaryRecord(Division);
				
				/* Debug */
				ErrorLog.println("Summary Record Size : "
						+ (FDSArray.size() - prev_bytes)
						+ " bytes");
				
				// Close File, RecordSet
				SUMrs.close();
				SUMrs = null;		

			} else
				// else if Connection was null
				ErrorLog.println("Error: No active Connection");
		} catch (Exception e) {
			e.printStackTrace(ErrorLog);
			ErrorLog.println("Exception: " + e.getMessage());
			e.printStackTrace(ErrorLog);
			throw e;
		}
	}// end WriteFDSFlatFile */

	
	// TransactionReport Methods
	private void OpenTransactionReportOutput()
	{
		try {
			Report = new java.io.BufferedWriter(
					new java.io.OutputStreamWriter(
							new java.io.FileOutputStream(TransactionReportFile),
							TransactionReportFileEncoding));
		} catch (Exception e) {
			ErrorLog.println("Error in SetupTransactionReportOutput(): "
							+ e.getMessage());
			e.printStackTrace(ErrorLog);
		}
	}
	
	private void CloseTransactionReportOutput()
	{
		try{
			if(SUMrs != null)
			{
				SUMrs.close();
				SUMrs = null;
			}
			if(DTLrs != null)
			{
				DTLrs.close();
				DTLrs = null;
			}
			if(Report != null)
			{
				Report.close();
				Report = null;
			}	
		}
		catch (Exception etwo)
		{
//			Try to write Error to Log
			try{
				ErrorLog.println("Error Closing TransactionReport JDBC RecordSets and OutputStream!!!");
				ErrorLog.println("Exception: " + etwo.getMessage());
				etwo.printStackTrace(ErrorLog);
				
			}catch (Exception ethree)
			{
				System.out.println("Error Closing TransactionReport JDBC RecordSets and OutputStream and Creating Error Log");		
			}
		}
	}
		
	public int getLineCount(String filename) throws Exception {
		
		 java.io.InputStream is = new java.io.BufferedInputStream(new java.io.FileInputStream(filename));
		    byte[] c = new byte[1024];
		    int count = 0;
		    int readChars = 0;
		    while ((readChars = is.read(c)) != -1) {
		        for (int i = 0; i < readChars; ++i) {
		            if (c[i] == '\n')
		                ++count;
		        }
		    }
		    return count;
	}
	
	public void WriteTransactionReportSummary(String[] Divisions) throws Exception
	{
		/*
		 FOR ED: improve transaction report
		 FDS/CCS Record Counts - per division and per file
		*/
		String CCS_COUNT_TOTAL = Integer.toString(getLineCount(CCSFlatFile));
		int FDS_COUNT_TOTAL = 0;
		BigDecimal FDS_AMOUNT_TOTAL = new BigDecimal("0.0");
		BigDecimal CCS_AMOUNT_TOTAL = new BigDecimal("0.0");
		BigDecimal CSP_AMOUNT_TOTAL = new BigDecimal("0.0");
		
	    int size = Divisions.length;
	    for (int i=0; i<size; i++)
	    {
	      String Division = Divisions[i];
	      
			if(0 == GetInvoiceCount(Division))
			{
				; // Don't do anything if there are no invoices
			}
			else
			{
				String div_FDS_COUNT_str = (String) TransactionReportSummaryValues.get(Division+"_"+"FDS_COUNT");
			    
			    BigDecimal div_FDS_AMOUNT = (BigDecimal) TransactionReportSummaryValues.get(Division+"_"+"FDS_AMOUNT");
			    BigDecimal div_CCS_AMOUNT = (BigDecimal) TransactionReportSummaryValues.get(Division+"_"+"CCS_AMOUNT");
			    BigDecimal div_CSP_AMOUNT = (BigDecimal) TransactionReportSummaryValues.get(Division+"_"+"CSP_AMOUNT");
			    
			    FDS_COUNT_TOTAL = FDS_COUNT_TOTAL + Integer.parseInt(div_FDS_COUNT_str) + 1; //add 1 for each STI summary record
			    FDS_AMOUNT_TOTAL = FDS_AMOUNT_TOTAL.add(div_FDS_AMOUNT);
			    CCS_AMOUNT_TOTAL = CCS_AMOUNT_TOTAL.add(div_CCS_AMOUNT);
			    CSP_AMOUNT_TOTAL = CSP_AMOUNT_TOTAL.add(div_CSP_AMOUNT);
			}
	    }
	    
		Report.newLine();
		Report.newLine();
		Report.write("CONTROL COUNTS/AMOUNTS - combined");
		Report.newLine();
		Report.write("CCS_COUNT : " + CCS_COUNT_TOTAL);
		Report.newLine();
		Report.write("FDS_COUNT : " + Integer.toString(FDS_COUNT_TOTAL));
		Report.newLine();
		Report.write("FDS_AMOUNT: " + FDS_AMOUNT_TOTAL.toString());
		Report.newLine();
		Report.write("CSP_AMOUNT: " + CSP_AMOUNT_TOTAL.toString());
		Report.newLine();
		Report.write("CCS_AMOUNT: " + CCS_AMOUNT_TOTAL.toString());		
		Report.newLine();

	    for (int i=0; i<size; i++)
	    {
	      String Division = Divisions[i];
	      
			if(0 == GetInvoiceCount(Division))
			{
				; // Don't do anything if there are no invoices
			}
			else
			{
				String div_FDS_COUNT_str = (String) TransactionReportSummaryValues.get(Division+"_"+"FDS_COUNT");
			    int div_FDS_COUNT_TOTAL = Integer.parseInt(div_FDS_COUNT_str) + 1; //add 1 for each STI summary record
			    
			    BigDecimal div_FDS_AMOUNT = (BigDecimal) TransactionReportSummaryValues.get(Division+"_"+"FDS_AMOUNT");
			    BigDecimal div_CCS_AMOUNT = (BigDecimal) TransactionReportSummaryValues.get(Division+"_"+"CCS_AMOUNT");
			    BigDecimal div_CSP_AMOUNT = (BigDecimal) TransactionReportSummaryValues.get(Division+"_"+"CSP_AMOUNT");
			    
				Report.newLine();
				Report.newLine();
				Report.write("CONTROL COUNTS/AMOUNTS - "+Division+" only" );
				Report.newLine();
				Report.newLine();
				Report.write("FDS_COUNT : " + Integer.toString(div_FDS_COUNT_TOTAL));
				Report.newLine();
				Report.write("FDS_AMOUNT: " + div_FDS_AMOUNT.toString());
				Report.newLine();
				Report.write("CSP_AMOUNT: " + div_CSP_AMOUNT.toString());
				Report.newLine();
				Report.write("CCS_AMOUNT: " + div_CCS_AMOUNT.toString());		
				Report.newLine();			    
			}
	    }
	    
	}
	
	public void WriteTransactionReport(String Division) {
		try {
			
			if(con != null)
			{
				ErrorLog.println("Attempting to Write Transaction Report...");
				
				// Don't do anything if there are no invoices
				if(0 == GetInvoiceCount(Division)) return;
				
				// Otherwise, load the summary records and get started
				LoadSUMrs(Division);
	
				Report.newLine();
				Report.newLine();
				Report.write(Division + " to FDS/CCS " + TransactionReportFile);
				Report.newLine();
				Report.newLine();
				
				// Write Transaction Report Header
				Report.write(LSPC("IMAPS Cust#", 15));
				Report.write("  ");
				Report.write(LSPC("CMR Cust#", 15));
				Report.write("  ");
				Report.write(LSPC("Invoice ID", 15));
				Report.write("  ");
				Report.write(LSPC("CCS Amount", 20));
				Report.write("  ");
				Report.write(LSPC("CCS Tax Amount", 20));
				Report.write("  ");
				Report.write(LSPC("CSP Amount", 20));
				Report.write("  ");
				Report.write(LSPC("CSP Tax Amount", 20));
				Report.write("  ");
				Report.write(LSPC("FDS Amount", 20));
				Report.write("  ");
				Report.write(LSPC("FDS Tax Amount", 20));
				Report.write("  ");
				Report.newLine();
				Report.write("---------------");
				Report.write("  ");
				Report.write("---------------");
				Report.write("  ");
				Report.write("---------------");
				Report.write("  ");
				Report.write("--------------------");
				Report.write("  ");
				Report.write("--------------------");
				Report.write("  ");
				Report.write("--------------------");
				Report.write("  ");
				Report.write("--------------------");
				Report.write("  ");
				Report.write("--------------------");
				Report.write("  ");
				Report.write("--------------------");
				Report.newLine();
	
				// Transaction Report Variables
				BigDecimal CCSTranTotal = new BigDecimal("0.0");
				BigDecimal CSPTranTotal = new BigDecimal("0.0");
				BigDecimal FDSTranTotal = new BigDecimal("0.0");
				
				BigDecimal CCSTaxTotal = new BigDecimal("0.0");
				BigDecimal CSPTaxTotal = new BigDecimal("0.0");
				BigDecimal FDSTaxTotal = new BigDecimal("0.0");
				
				int NumInvoices = 0;
	
				// For Each Invoice Record
				// Write Transaction Report Details
				while (SUMrs.next()) {
	
					// Write Transaction Report
					// For Each Invoice Written
					Report.write(LSPC(SUMrs.getString("CUST_ID"), 15));
					Report.write("  ");
					Report.write(LSPC(SUMrs.getString("CUST_ADDR_DC"), 15));
					Report.write("  ");
					Report.write(LSPC(SUMrs.getString("INVC_ID"), 15));
					Report.write("  ");
					Report.write(LSPC(SUMrs.getString("INVC_AMT"), 20));
					Report.write("  ");
					Report.write(LSPC(SUMrs.getString("SALES_TAX_AMT"), 20));
					Report.write("  ");
					Report.write(LSPC(SUMrs.getString("CSP_AMT"), 20));
					Report.write("  ");
					Report.write(LSPC(SUMrs.getString("CSP_TAX_AMT"), 20));
					Report.write("  ");
					Report.write(LSPC(SUMrs.getString("FDS_INV_AMT"), 20));
					Report.write("  ");
					Report.write(LSPC(SUMrs.getString("FDS_SALES_TAX_AMT"), 20));
					Report.newLine();
	
					// Calculate Transaction Totals
					CCSTranTotal = CCSTranTotal.add(SUMrs.getBigDecimal("INVC_AMT"));
					CSPTranTotal = CSPTranTotal.add(SUMrs.getBigDecimal("CSP_AMT"));
					FDSTranTotal = FDSTranTotal.add(SUMrs.getBigDecimal("FDS_INV_AMT"));

					CCSTaxTotal = CCSTaxTotal.add(SUMrs.getBigDecimal("SALES_TAX_AMT"));
					CSPTaxTotal = CSPTaxTotal.add(SUMrs.getBigDecimal("CSP_TAX_AMT"));
					FDSTaxTotal = FDSTaxTotal.add(SUMrs.getBigDecimal("FDS_SALES_TAX_AMT"));
					NumInvoices++;
				}// end for each Invoice Record
	
				// Write Transaction Report Grand Totals
				Report.newLine();
				Report.write(TSPC("Totals for the " + Integer.toString(NumInvoices)
						+ " Invoices", 51));
				Report.write(LSPC(CCSTranTotal.toString(), 20));
				Report.write("  ");
				Report.write(LSPC(CCSTaxTotal.toString(), 20));
				Report.write("  ");
				Report.write(LSPC(CSPTranTotal.toString(), 20));
				Report.write("  ");
				Report.write(LSPC(CSPTaxTotal.toString(), 20));
				Report.write("  ");
				Report.write(LSPC(FDSTranTotal.toString(), 20));
				Report.write("  ");
				Report.write(LSPC(FDSTaxTotal.toString(), 20));
				Report.write("  ");
				Report.newLine();
				
				TransactionReportSummaryValues.put(Division+"_"+"CCS_AMOUNT", CCSTranTotal); //BigDecimals
				TransactionReportSummaryValues.put(Division+"_"+"CSP_AMOUNT", CSPTranTotal);
				TransactionReportSummaryValues.put(Division+"_"+"FDS_AMOUNT", FDSTranTotal);

				String FDS_COUNT = (String) FDSSummaryRecordParameters.get(Division+"_"+"TOTAL_RECORDS");//String
				TransactionReportSummaryValues.put(Division+"_"+"FDS_COUNT", FDS_COUNT);
	
			}else{
				ErrorLog.println("Error: No active Connection");
			}

		} 
		catch (Exception e) {
			e.printStackTrace();
			ErrorLog.println("Error Writing Transaction Report: "
					+ e.getMessage());
		} 
	}// end WriteTransactionReport


	// MAIN PROGRAM ######################################
	public static void main(String[] args) throws Exception {
		
		// arg 0 is properties file, arg 1 is whether or not to include 1M, arg 2 is output folder
		CreateFlatFiles Interface = new CreateFlatFiles(args[0], args[2]); //, args[1], args[2], args[3]); // connection opened
		
		String Include_1M_on_CCS = args[1];
		String output_Path = args[2];
		
		Interface.OpenCCSOutput();
		Interface.WriteCCSFlatFile("16");
		
		if (Include_1M_on_CCS.equals("yes"))
		{
			Interface.WriteCCSFlatFile("1M");
		}
		Interface.CloseCCSOutput();
		
		Interface.OpenFDSOutput();
		Interface.WriteFDSArray("16");
		Interface.WriteFDSArray("1M");
		Interface.WriteFDSSummaryRecord("16");
		Interface.WriteFDSSummaryRecord("1M");
		Interface.WriteFDSArrayToFlatFile();
		Interface.CloseFDSOutput();
		
		Interface.OpenTransactionReportOutput();
		Interface.WriteTransactionReport("16"); 
		Interface.WriteTransactionReport("1M");
		String[] Divisions = {"16", "M"};		
		Interface.WriteTransactionReportSummary(Divisions);
		Interface.CloseTransactionReportOutput();
		
		Interface.closeConnection();// connection closed
		
	}// end main

}// end class
