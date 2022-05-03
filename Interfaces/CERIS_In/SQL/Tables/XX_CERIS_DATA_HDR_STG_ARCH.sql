USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_DATA_HDR_STG_ARCH]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
   DROP TABLE [dbo].[XX_CERIS_DATA_HDR_STG_ARCH]
GO

CREATE TABLE [dbo].[XX_CERIS_DATA_HDR_STG_ARCH](

	[STATUS_RECORD_NUM] int NOT NULL,

	REC_TYPE           CHAR(01) NOT NULL,       -- /*RECORD TYPE          1-   1 */| 'H'                                   
	LAB1               CHAR(06) NOT NULL,       -- /*'|DATE: '            2-   7 */| '|DATE: '                             
	RUN_DATE           CHAR(08) NOT NULL,       -- /*RUN DATE             8-  15 */| SYSTEM DATE yyyymmdd                  
	FIL2               CHAR(06) NOT NULL,       -- /*'|TIME: '           16-  21 */| '|TIME: '                             
	RUN_TIME           CHAR(08) NOT NULL,       -- /*RUN TIME            22-  29 */| SYSTEM TIME 24 HOUR hh:mm:ss          
	LAB3               CHAR(06) NOT NULL,       -- /*'|RECS: '           30-  35 */| '|TIME: '                             
	RECS_OUT           CHAR(06) NOT NULL,	--PIC 'ZZZZZ9',   -- /*DET RECS WRITTEN    36-  41 */| Number of detail recs written         
	LAB4               CHAR(06) NOT NULL,       -- /*'|SEQ#: '           42-  47 */| '|SEQ#: '                             
	SEQ_OUT            CHAR(04) NOT NULL,	--PIC 'ZZZ9',     -- /*SEQ#                48-  51 */| Sequence Number                       
	LAB5               CHAR(06) NOT NULL,       -- /*'HASH: '            52-  57 */| '|HASH: '                             
	HASH               CHAR(06) NOT NULL,	--PIC 'ZZZZZ9',   -- /*HASH TOTOAL         58-  63 */| Hash - Simple CERIS Type              
	LAB6               CHAR(21) NOT NULL,       -- /*'CERIS ... DATE: '  64-  84 */| '|CERIS INFO... DATE: '               
	IBM_CLASSIFICATION CHAR(20) NOT NULL,       -- /*'IBM CONF...'       85- 104 */| '|IBM CONFIDENTIAL'                   
	DMEM_AS_OF_DATE    CHAR(8) NOT NULL,        -- /*INPUT DATA DATE    105- 112 */| BY NAME (IS THIS FROM DUMP FILE?)     
	LAB7               CHAR(16) NOT NULL,       -- /*|EMP FILE NAME: '  113- 128 */| '|EMP FILE NAME: '                    
	EMP_FILENAME       CHAR(45) NOT NULL,       -- /*CERIS EMP DSN      129- 173 */| VIA PL/I FILENAME FUNCTION EMP PIT    
	LAB8               CHAR(16) NOT NULL,       -- /*'CERIS ... DATE: ' 174- 189 */| '|WKL FILE NAME: '                    
	WKL_FILENAME       CHAR(45) NOT NULL,       -- /*CERIS WKL DSN      190- 234 */| VIA PL/I FILENAME FUNCTION WORK LOC   
	--ENDPAD             CHAR(216) NOT NULL,      -- /*END PAD            235- 450 */| '' 


	[CREATION_DATE] [datetime] NOT NULL,
	[CREATED_BY] [varchar](35) NOT NULL,


	[ARCHIVE_DATE] [datetime] NOT NULL DEFAULT getdate(),
	[ARCHIVED_BY] [varchar](35) NOT NULL DEFAULT suser_sname()
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF



