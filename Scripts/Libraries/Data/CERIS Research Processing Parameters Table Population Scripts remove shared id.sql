USE imapsstg

-- CR3856 removal of application ids

delete from IMAPSstg.dbo.XX_PROCESSING_PARAMETERS
where INTERFACE_NAME_CD = 'CERIS_R22'
and PARAMETER_NAME in ('IN_USER_NAME','IN_USER_PASSWORD')


-- (2 row(s) affected)