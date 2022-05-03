
-- CR-10231 Add record for FDS-CCS Interface-specific system error message
--     based on switch to non-update
INSERT INTO imapsstg.dbo.XX_INT_ERROR_MESSAGE
   (ERROR_CODE, ERROR_TYPE, ERROR_MESSAGE, ERROR_SOURCE, CREATED_BY, CREATED_DATE)
   VALUES(563, 40, 'FTP_SUCCESS_CHECK - No db connection file specified on command line.',
          'Costpoint execution environment', SUSER_SNAME(), getdate())
 
INSERT INTO imapsstg.dbo.XX_INT_ERROR_MESSAGE
   (ERROR_CODE, ERROR_TYPE, ERROR_MESSAGE, ERROR_SOURCE, CREATED_BY, CREATED_DATE)
   VALUES(564, 40, 'GLIM - GLIM file is out of balance. Check GLIM PARM file.',
          'Costpoint execution environment', SUSER_SNAME(), getdate())

INSERT INTO imapsstg.dbo.XX_INT_ERROR_MESSAGE
   (ERROR_CODE, ERROR_TYPE, ERROR_MESSAGE, ERROR_SOURCE, CREATED_BY, CREATED_DATE)
   VALUES(565, 40, 'GLIM - GLIM FAILED TO EXECUTE. CHECK MACRO SCHEDULER',
          'Costpoint execution environment', SUSER_SNAME(), getdate())

