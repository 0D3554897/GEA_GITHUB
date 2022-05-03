

INSERT INTO dbo.XX_INT_ERROR_MESSAGE
   (ERROR_CODE, ERROR_TYPE, ERROR_MESSAGE, ERROR_SOURCE, CREATED_BY, CREATED_DATE)
   VALUES(605, 40, 'Only CSP invoices are available for processing: This will result in an empty file being sent to GLIM, which will cause an error.',
          'Costpoint execution environment', SUSER_SNAME(), getdate()) 
          
INSERT INTO dbo.XX_INT_ERROR_MESSAGE
   (ERROR_CODE, ERROR_TYPE, ERROR_MESSAGE, ERROR_SOURCE, CREATED_BY, CREATED_DATE)
   VALUES(606, 40, 'No valid invoices are available for processing: This will result in an empty file being sent to GLIM, which will cause an error.',
          'Costpoint execution environment', SUSER_SNAME(), getdate())           