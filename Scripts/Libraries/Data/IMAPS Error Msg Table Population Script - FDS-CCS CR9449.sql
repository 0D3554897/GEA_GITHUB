-- CR-9449 Add record for FDS-CCS Interface-specific system error message
INSERT INTO imapsstg.dbo.XX_INT_ERROR_MESSAGE
   (ERROR_CODE, ERROR_TYPE, ERROR_MESSAGE, ERROR_SOURCE, CREATED_BY, CREATED_DATE)
   VALUES(556, 40, 'FDS-CCS Out of balance: Header invoice amount total is not equal to detail invoice billed amount total.',
          'Costpoint execution environment', SUSER_SNAME(), getdate())

-- jan 26

INSERT INTO imapsstg.dbo.XX_INT_ERROR_MESSAGE
   (ERROR_CODE, ERROR_TYPE, ERROR_MESSAGE, ERROR_SOURCE, CREATED_BY, CREATED_DATE)
   VALUES(557, 40, 'Expected File Not Found. See SQL Server Job Log for Details.',
          'Costpoint execution environment', SUSER_SNAME(), getdate())

		  
-- jan 30 - changes to previous inserts

INSERT INTO imapsstg.dbo.XX_INT_ERROR_MESSAGE
   (ERROR_CODE, ERROR_TYPE, ERROR_MESSAGE, ERROR_SOURCE, CREATED_BY, CREATED_DATE)
   VALUES(558, 40, 'FTP_SUCCESS_CHECK - ini file not specified on command line. ',
          'Costpoint execution environment', SUSER_SNAME(), getdate())

INSERT INTO imapsstg.dbo.XX_INT_ERROR_MESSAGE
   (ERROR_CODE, ERROR_TYPE, ERROR_MESSAGE, ERROR_SOURCE, CREATED_BY, CREATED_DATE)
   VALUES(559, 40, 'FTP_SUCCESS_CHECK - ftp log file not specified on command line.',
          'Costpoint execution environment', SUSER_SNAME(), getdate())

INSERT INTO imapsstg.dbo.XX_INT_ERROR_MESSAGE
   (ERROR_CODE, ERROR_TYPE, ERROR_MESSAGE, ERROR_SOURCE, CREATED_BY, CREATED_DATE)
   VALUES(560, 40, 'FTP_SUCCESS_CHECK - ini file missing search_string parameter.',
          'Costpoint execution environment', SUSER_SNAME(), getdate())


INSERT INTO imapsstg.dbo.XX_INT_ERROR_MESSAGE
   (ERROR_CODE, ERROR_TYPE, ERROR_MESSAGE, ERROR_SOURCE, CREATED_BY, CREATED_DATE)
   VALUES(561, 40, 'FTP_SUCCESS_CHECK - ini file missing desired_cnt parameter.',
          'Costpoint execution environment', SUSER_SNAME(), getdate())

INSERT INTO imapsstg.dbo.XX_INT_ERROR_MESSAGE
   (ERROR_CODE, ERROR_TYPE, ERROR_MESSAGE, ERROR_SOURCE, CREATED_BY, CREATED_DATE)
   VALUES(562, 40, 'FTP_SUCCESS_CHECK - Actual Count does not equal desired count.',
          'Costpoint execution environment', SUSER_SNAME(), getdate())