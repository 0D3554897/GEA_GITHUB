-- 05/27/2015: This table is not used at all by the Division 16 ETIME Interface.
-- Its presence in ClearCase is the result of a mistake associated with CM steps involving CR6706 and ClearQuest record number CP600002176.
-- It may be put to use for any new potential purpose.

DROP TABLE [dbo].[XX_IMAPS_TS_PREP_CONFIG_ERRORS_STG]

CREATE TABLE [dbo].[XX_IMAPS_TS_PREP_CONFIG_ERRORS_STG](
   [STATUS_RECORD_NUM_CREATED] [int] NOT NULL,
   [STATUS_RECORD_NUM_REPROCESSED] [int] NULL,
   [TS_DT] [char](10) NOT NULL,
   [EMPL_ID] [char](12) NOT NULL,
   [S_TS_TYPE_CD] [char](2) NOT NULL,
   [CORRECTING_REF_DT] [char](10) NULL,
   [S_TS_LN_TYPE_CD] [char](1) NULL,
   [CHG_HRS] [char](10) NULL,
   [BILL_LAB_CAT_CD] [char](6) NULL,
   [PROJ_ABBRV_CD] [char](6) NULL,
   [TS_HDR_SEQ_NO] [char](3) NULL,
   [EFFECT_BILL_DT] [char](10) NULL,
   [NOTES] [char](254) NULL,
   [FEEDBACK] [varchar](8000) NULL,
   [ROW_ID] [int] NOT NULL,
   [UPDATE_DT] [datetime] NOT NULL,
   [CREATE_DT] [datetime] NOT NULL DEFAULT (getdate())
) ON [PRIMARY]
