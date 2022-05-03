/*** 
SELECT PARAMETER_NAME, PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS/CCS'
   AND CHARINDEX('GLIM' , PARAMETER_NAME) >0

SELECT PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS/CCS'
   AND PARAMETER_NAME = 'ARCHIVE_DIR'
   
 SELECT PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS/CCS'
   AND PARAMETER_NAME = 'GLIM_FTP_DEST_FILE_1'



SELECT PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS/CCS'
   AND PARAMETER_NAME = 'GLIM_FTP_DEST_FILE_2'

SELECT '897', 00, '121', '0', 'L', '16', '107', '0112', '0016', 'FED', ' ', '121', 'TBD', 'FED', ' ', REPLACE(CONVERT(VARCHAR(10), GETDATE(), 3), '/', ''), month(GETDATE()), ' ', avg(A.INVC_AMT)-avg(CSP_AMT), '0', ' ', right(A.INVC_ID,7), ' ', 'GBS Federal Bill', ' ', 'F', ' ', A.I_MKG_DIV, ' ', A.CUST_ADDR_DC, ' ', ' ', ' ', A.PRIME_CONTR_ID, ' ', A.C_STD_IND_CLASS, ' ', A.C_STATE, A.C_CNTY, A.C_CITY, ' ', A.C_INDUS, ' ', REPLACE(CONVERT(VARCHAR(10), A.INVC_DT, 1), '/', ''), ' ', A.I_ENTERPRISE, ' ' 
  from IMAPSSTG.DBO.XX_IMAPS_INV_OUT_SUM a 
  inner join IMAPSSTG.DBO.XX_IMAPS_INV_OUT_DTL b on a.INVC_ID = b.INVC_ID  
  where a.invc_amt <> 0 AND A.STATUS_FL = 'P' 
  GROUP BY A.INVC_ID, A.I_MKG_DIV, A.CUST_ADDR_DC, A.PRIME_CONTR_ID, A.C_STD_IND_CLASS, A.C_STATE, A.C_CNTY, A.C_CITY, A.C_INDUS, A.I_ENTERPRISE,REPLACE(CONVERT(VARCHAR(10), A.INVC_DT, 1), '/', '')


SELECT PARAMETER_VALUE
     FROM XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'FDS/CCS'
      AND PARAMETER_NAME = 'FTP_CCS_COMMAND_FILE'  

 SELECT PARAMETER_VALUE
     FROM XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'FDS/CCS'
      AND PARAMETER_NAME in ('FTP_FDS_LOG_FILE','FTP_CCS_LOG_FILE','GLIM_FTP_LOG_FILE')

  SELECT PARAMETER_VALUE
     FROM XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'FDS/CCS'
      AND PARAMETER_NAME in ('FTP_FDS_LOG_FILE','FTP_CCS_LOG_FILE','GLIM_FTP_LOG_FILE')
 
 INSERT INTO imapsstg.dbo.XX_INT_ERROR_MESSAGE
   (ERROR_CODE, ERROR_TYPE, ERROR_MESSAGE, ERROR_SOURCE, CREATED_BY, CREATED_DATE)
   VALUES(562, 40, 'FTP_SUCCESS_CHECK.EXE - Actual Count does not equal desired count.',
          'Costpoint execution environment', SUSER_SNAME(), getdate())
 
 SELECT *  from imapsstg.dbo.XX_INT_ERROR_MESSAGE where  error_code > 555
 
 SELECT COUNT(INVC_ID) as failed_cnt, SUM(INVC_AMT) as failed_amt FROM dbo.XX_IMAPS_INV_OUT_SUM WHERE STATUS_FL <> 'P'

SELECT coalesce(COUNT(INVC_ID),0) as failed_cnt, coalesce(SUM(INVC_AMT),0) as failed_amt FROM dbo.XX_IMAPS_INV_OUT_SUM WHERE STATUS_FL <> 'P'

 
INSERT INTO imapsstg.dbo.XX_IMAPS_INVOICE_SENT
   (CUST_ID, PROJ_ID, INVC_ID, INVC_AMT, INVC_DT, STATUS_RECORD_NUM, DIVISION)
   SELECT CUST_ID, PROJ_ID, INVC_ID, INVC_AMT, INVC_DT, STATUS_RECORD_NUM, DIVISION
     FROM dbo.XX_IMAPS_INV_OUT_SUM      

delete from imapsstg.dbo.XX_IMAPS_INVOICE_SENT
where INVC_ID in ('IBM-0002479274','IBM-0002479298','IBM-0002479304')



    SELECT T1.PRESENTATION_ORDER, t1.APPLICATION_CODE
        FROM dbo.XX_LOOKUP_DETAIL t1,
             dbo.XX_LOOKUP_DOMAIN t2
       WHERE t1.LOOKUP_DOMAIN_ID   = t2.LOOKUP_DOMAIN_ID
        -- AND t1.PRESENTATION_ORDER = 4
         ---- @current_execution_step
         AND t2.DOMAIN_CONSTANT    = 'LD_FDS_CCS_INTFC_CTRL_PT'
         -- @LOOKUP_DOMAIN_FCSCCS_CTRL_PT
         ORDER BY t1.PRESENTATION_ORDER

***/ 
 
 select COUNT(*)AS header_count, status_fl from imapsstg.dbo.xx_imaps_inv_out_sum	group by status_fl
 
 select count(*) as detail_count, SUM(billed_amt) as detail_amt from IMAPSStg.dbo.xx_imaps_inv_out_dtl
 select count(*) as header_count, SUM(invc_amt) as header_amt from IMAPSStg.dbo.xx_imaps_inv_out_sum
 select COUNT(*) as prev_sent_count, SUM(INVC_AMT) as prev_sent_amt from imapsstg.dbo.XX_IMAPS_INVOICE_SENT
 
-- select top 5 * from imapsstg.dbo.XX_IMAPS_INVOICE_SENT order by INVC_dt desc
 
 SELECT  t1.STATUS_RECORD_NUM as last_issued_STATUS_RECORD_NUM,
       t1.STATUS_CODE as last_issued_STATUS_CODE
  FROM dbo.XX_IMAPS_INT_STATUS t1
 WHERE t1.INTERFACE_NAME = 'FDS/CCS'
   AND t1.CREATED_DATE   = (SELECT MAX(t2.CREATED_DATE) 
                              FROM dbo.XX_IMAPS_INT_STATUS t2
                             WHERE t2.INTERFACE_NAME = 'FDS/CCS') 
                           
 
      SELECT  t1.CONTROL_PT_ID as "Last Success", t1.STATUS_RECORD_NUM as "For Status Record Number",
      CREATED_DATE as "on this date/time"
        FROM dbo.XX_IMAPS_INT_CONTROL t1
       WHERE t1.STATUS_RECORD_NUM  = 
     (SELECT  t1.STATUS_RECORD_NUM
  FROM dbo.XX_IMAPS_INT_STATUS t1
 WHERE t1.INTERFACE_NAME = 'FDS/CCS'
   AND t1.CREATED_DATE   = (SELECT MAX(t2.CREATED_DATE) 
                              FROM dbo.XX_IMAPS_INT_STATUS t2
                             WHERE t2.INTERFACE_NAME = 'FDS/CCS'))    
         AND t1.INTERFACE_NAME     = 'FDS/CCS'
         AND t1.CONTROL_PT_STATUS  = 'SUCCESS'
         AND t1.CONTROL_RECORD_NUM = (select MAX(t2.CONTROL_RECORD_NUM) 
                                        from dbo.XX_IMAPS_INT_CONTROL t2
                                       where t2.STATUS_RECORD_NUM = 
                                            (SELECT  t1.STATUS_RECORD_NUM
  FROM dbo.XX_IMAPS_INT_STATUS t1
 WHERE t1.INTERFACE_NAME = 'FDS/CCS'
   AND t1.CREATED_DATE   = (SELECT MAX(t2.CREATED_DATE) 
                              FROM dbo.XX_IMAPS_INT_STATUS t2
                             WHERE t2.INTERFACE_NAME = 'FDS/CCS'))
                                       
                                         and t2.INTERFACE_NAME    = 'FDS/CCS'
                                         and t2.CONTROL_PT_STATUS = 'SUCCESS')
                                         
select * from imapsstg.dbo.XX_IMAPS_INT_STATUS WHERE STATUS_RECORD_NUM =
 ( select t1.STATUS_RECORD_NUM
        FROM dbo.XX_IMAPS_INT_CONTROL t1
       WHERE t1.STATUS_RECORD_NUM  = 
     (SELECT  t1.STATUS_RECORD_NUM
  FROM dbo.XX_IMAPS_INT_STATUS t1
 WHERE t1.INTERFACE_NAME = 'FDS/CCS'
   AND t1.CREATED_DATE   = (SELECT MAX(t2.CREATED_DATE) 
                              FROM dbo.XX_IMAPS_INT_STATUS t2
                             WHERE t2.INTERFACE_NAME = 'FDS/CCS'))    
         AND t1.INTERFACE_NAME     = 'FDS/CCS'
         AND t1.CONTROL_PT_STATUS  = 'SUCCESS'
         AND t1.CONTROL_RECORD_NUM = (select MAX(t2.CONTROL_RECORD_NUM) 
                                        from dbo.XX_IMAPS_INT_CONTROL t2
                                       where t2.STATUS_RECORD_NUM = 
                                            (SELECT  t1.STATUS_RECORD_NUM
  FROM dbo.XX_IMAPS_INT_STATUS t1
 WHERE t1.INTERFACE_NAME = 'FDS/CCS'
   AND t1.CREATED_DATE   = (SELECT MAX(t2.CREATED_DATE) 
                              FROM dbo.XX_IMAPS_INT_STATUS t2
                             WHERE t2.INTERFACE_NAME = 'FDS/CCS'))
                                       
                                         and t2.INTERFACE_NAME    = 'FDS/CCS'
                                         and t2.CONTROL_PT_STATUS = 'SUCCESS'))  
     SELECT TOP 5 * 
     FROM dbo.XX_IMAPS_INT_CONTROL t1
       WHERE t1.STATUS_RECORD_NUM  > 17271
       ORDER BY CREATED_DATE DESC