package com.ibm.imaps.util;

import java.io.OutputStream;
import java.sql.ResultSet;

import org.apache.poi.hssf.usermodel.HSSFRichTextString;
import org.apache.poi.hssf.usermodel.HSSFRow;
import org.apache.poi.hssf.usermodel.HSSFSheet;
import org.apache.poi.hssf.usermodel.HSSFWorkbook;

/*
 * Utility class used to generate an Excel spreadsheet from a JDBC result set.
 * Passed array of strings to use for first row and assumes that defines
 * number of columns to be processed in each resultset row. Each column is
 * output using getString() from the result set.
 * 
 * Uses the Apache POI library to generate the result set.
 * 
 * Output is generated into a user supplied output stream.
 */
public class ExcelBuilder {
	
	public static void build(ResultSet rs, String[] headers, OutputStream os) throws Exception {
		
		HSSFWorkbook wb = new HSSFWorkbook();
		HSSFSheet sheet = wb.createSheet("Sheet1");
		
		HSSFRow row = sheet.createRow(0);
		for (int i=0; i<headers.length; i++) {
			row.createCell(i).setCellValue(new HSSFRichTextString(headers[i]));			
		}
		
		int rowcount = 0;
		while (rs.next()) {
			row = sheet.createRow(++rowcount);
			for (int j=0; j<headers.length; j++) {
				row.createCell(j).setCellValue(new HSSFRichTextString(rs.getString(j+1)));
			}
		}
		
		wb.write(os);
		os.flush();
	}

}
