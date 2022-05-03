IF EXISTS (SELECT * FROM dbo.sysobjects WHERE ID = object_id(N'[dbo].[XX_R22_CERIS_UPDATE_ASSIGNMENT_SP]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
   DROP PROCEDURE [dbo].[XX_R22_CERIS_UPDATE_ASSIGNMENT_SP]
GO

CREATE PROCEDURE [dbo].[XX_R22_CERIS_UPDATE_ASSIGNMENT_SP]
(
@in_STATUS_RECORD_NUM      integer,
@out_SQLServer_error_code  integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION    varchar(255) = NULL OUTPUT
)
AS

/*******************************************************************************************************
Name:       XX_R22_CERIS_UPDATE_ASSIGNMENT_SP
Author:     HVT
Created:    02/23/2010
Purpose:    Update employee assignment data based on the current CERIS file data.
            Called by XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.
Parameters: 
Result Set: None
Notes:

CP600000825 02/23/2010 - BP&S Service Request CR2577

CP600001176 04/05/2011 - FSST Service Request CR3599
            (1) Add code to address the scenario where XX_R22_CERIS_ASSIGNMENT_STG record exists for an
            employee whose assignment data have been removed, based on the latest CERIS file received;
            columns ASTYP, ASNTYP of the XX_R22_CERIS_RPT_STG record have zero-length string as value.
            (2) Increase the size of column XX_R22_CERIS_ASSIGNMENT_STG.REMARKS from 200 to 500 characters.
            Restrict the value of column REMARKS to its size at all time.
            (3) When the CERIS file data remain unchanged (from the previous week), avoid inserting or
            updating XX_R22_CERIS_ASSIGNMENT_STG records except when the employee is reassigned
            to Division 22 and the assignment data exist.
            (4) Use new table XX_R22_CERIS_ASSIGNMENT_LOG to track changes in employee division,
            termination date and assignment data from the CERIS file.
********************************************************************************************************/

DECLARE @SP_NAME                 sysname,
        @SQLServer_error_code    integer,
        @IMAPS_error_code        integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
        @row_count               integer,
        @STANDARD_END_DT_STR     varchar(10),
        @STANDARD_END_DT         datetime,
        @EMPL_ID                 varchar(6),
        @LNAME                   varchar(25),
        @FNAME                   varchar(20),
        @TERM_DT                 varchar(8),
        @DIVISION                varchar(2),
        @DIVISION_START_DT       varchar(8),
        @ASTYP                   varchar(5),
        @ASNTYP                  varchar(5),
        @assignment              varchar(5),
        @assignment_type         varchar(5),
        @end_dt                  datetime,
        @proviso_end_dt          datetime,
        @pseudo_empl_id          varchar(12),
        @remarks                 varchar(500),
        @process_type            varchar(1),
        @process_desc            varchar(150),
        @PROCESS_DESC_A          varchar(150),
        @PROCESS_DESC_B          varchar(150),
        @PROCESS_DESC_C          varchar(150),
        @PROCESS_DESC_D          varchar(150),
        @PROCESS_DESC_E          varchar(150),
        @PROCESS_DESC_F          varchar(150),
        @PROCESS_DESC_G          varchar(150),
        @PROCESS_DESC_H          varchar(150),
        @PROCESS_DESC_I          varchar(150),
        @affected_rowcount       integer,
        @inserted_rowcount       integer,
        @updated_rowcount        integer,
        @log_rowcount            integer,
        @updated_log_rowcount    integer,
        @max_log_create_dt       datetime

-- Set local constants
SET @SP_NAME = 'XX_R22_CERIS_UPDATE_ASSIGNMENT_SP'
SET @STANDARD_END_DT_STR = '2099-12-31'
SET @STANDARD_END_DT = CONVERT(datetime, @STANDARD_END_DT_STR)

SET @PROCESS_DESC_A = 'Employee with assignment data found in CERIS file: Insert new assignment record'
SET @PROCESS_DESC_B = 'Active assignment, assignment data changed: Set current assignment record inactive, insert new record for new assignment'
SET @PROCESS_DESC_C = 'Active assignment, employee terminated: Set assignment record inactive'
SET @PROCESS_DESC_D = 'Active assignment, employee tranferred out of Division 22: Set record inactive'
SET @PROCESS_DESC_E = 'Inactive assignment, employee reassigned to Division 22: Insert new assignment record'
SET @PROCESS_DESC_F = 'Active assignment, employee not found in CERIS file: Set assignment record inactive'
SET @PROCESS_DESC_G = 'Active assignment, assignment data removed, currently assigned to Division 22: Set assignment record inactive'
SET @PROCESS_DESC_H = 'Active assignment, assignment data removed, employee terminated: Set assignment record inactive'
SET @PROCESS_DESC_I = 'Active assignment, assignment data removed, employee tranferred out of Division 22: Set assignment record inactive'

-- Initialize local variables
SET @IMAPS_error_code = 204
SET @affected_rowcount = 0
SET @inserted_rowcount = 0
SET @updated_rowcount = 0
SET @log_rowcount = 0
SET @updated_log_rowcount = 0

SELECT @max_log_create_dt = MAX(CREATE_DT) FROM dbo.XX_R22_CERIS_ASSIGNMENT_LOG

-- If this program is run multiple times in the same day, update XX_R22_CERIS_ASSIGNMENT_LOG only once
IF CONVERT(varchar(10), @max_log_create_dt, 121) = CONVERT(varchar(10), getdate(), 121)
   BEGIN
      --PRINT 'Update of XX_R22_CERIS_ASSIGNMENT_LOG has already been performed today.'
      --PRINT ''
      GOTO BL_WORK_ASSIGNMENT
   END

SELECT @updated_log_rowcount = COUNT(1) FROM dbo.XX_R22_CERIS_ASSIGNMENT_LOG

--PRINT 'Total number of XX_R22_CERIS_ASSIGNMENT_LOG records as of the last CERIS_R22 Interface run, ' +
--      CONVERT(varchar(10), @max_log_create_dt, 121) + ': ' +
--      CONVERT(varchar(10), @updated_log_rowcount, 121)

/*
 * Insert log records for this week's edition of the CERIS file
 * Round 1: The SELECT statement used by this INSERT is from Step 1's cursor
 */
INSERT INTO dbo.XX_R22_CERIS_ASSIGNMENT_LOG
   (EMPL_ID, DIVISION, DIVISION_START_DT, DIVISION_FROM, STATUS, TERM_DT, ASTYP, ASNTYP)
   SELECT EMPL_ID, DIVISION, DIVISION_START_DT, DIVISION_FROM, STATUS, TERM_DT, ASTYP, ASNTYP
     FROM dbo.XX_R22_CERIS_RPT_STG
    WHERE (ASTYP is not NULL and RTRIM(LTRIM(ASTYP)) != '')
      AND (ASNTYP is not NULL and RTRIM(LTRIM(ASNTYP)) != '')

SET @log_rowcount = @@ROWCOUNT
SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- Attempt to insert XX_R22_CERIS_ASSIGNMENT_LOG records (round 1) failed.
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'XX_R22_CERIS_ASSIGNMENT_LOG records (round 1)'
      GOTO BL_ERROR_HANDLER
   END

/*
 * Round 2: The SELECT statement is adapted from the INSERT used by Step 2's cursor
 * Create new record only when (1) a XX_R22_CERIS_RPT_STG record does not exist for the employee,
 * (2) a XX_R22_CERIS_ASSIGNMENT_STG record exists showing active assignment, and
 * (3) a XX_R22_CERIS_ASSIGNMENT_LOG record does not already exist to document the CERIS file event
 */
INSERT INTO dbo.XX_R22_CERIS_ASSIGNMENT_LOG
   (EMPL_ID, DIVISION, DIVISION_START_DT, DIVISION_FROM, STATUS, TERM_DT, ASTYP, ASNTYP)
   SELECT DISTINCT PSEUDO_EMPL_ID, '??', '????????', '??', '?', '????????', '?', '?'
     FROM dbo.XX_R22_CERIS_ASSIGNMENT_STG
    WHERE CONVERT(varchar(10), END_DT, 120) = @STANDARD_END_DT_STR
      AND PSEUDO_EMPL_ID not in (select EMPL_ID from dbo.XX_R22_CERIS_RPT_STG)
      AND PSEUDO_EMPL_ID not in (select EMPL_ID
                                   from dbo.XX_R22_CERIS_ASSIGNMENT_LOG
                                  where EMPL_ID = PSEUDO_EMPL_ID
                                    and (DIVISION = '??' OR (ASTYP = '?' AND ASNTYP = '?')))

SET @log_rowcount = @log_rowcount + @@ROWCOUNT
SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- Attempt to insert XX_R22_CERIS_ASSIGNMENT_LOG records (round 2) failed.
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'XX_R22_CERIS_ASSIGNMENT_LOG records (round 2)'
      GOTO BL_ERROR_HANDLER
   END

/*
 * Round 3: The SELECT statement is adapted from the INSERT used by Step 3's cursor
 */
INSERT INTO dbo.XX_R22_CERIS_ASSIGNMENT_LOG
   (EMPL_ID, DIVISION, DIVISION_START_DT, DIVISION_FROM, STATUS, TERM_DT, ASTYP, ASNTYP)
   SELECT DISTINCT t2.EMPL_ID, t2.DIVISION, t2.DIVISION_START_DT, t2.DIVISION_FROM, t2.STATUS, t2.TERM_DT, t2.ASTYP, t2.ASNTYP
     FROM dbo.XX_R22_CERIS_ASSIGNMENT_STG t1,
          dbo.XX_R22_CERIS_RPT_STG t2
    WHERE t1.PSEUDO_EMPL_ID = t2.EMPL_ID
      AND (t2.ASTYP is NULL or (t2.ASTYP is not NULL and RTRIM(LTRIM(t2.ASTYP)) = ''))
      AND (t2.ASNTYP is NULL or (t2.ASNTYP is not NULL and RTRIM(LTRIM(t2.ASNTYP)) = ''))
      AND t1.END_DT = (select MAX(t3.END_DT)
                         from dbo.XX_R22_CERIS_ASSIGNMENT_STG t3
                        where t3.PSEUDO_EMPL_ID = t1.PSEUDO_EMPL_ID)

SET @log_rowcount = @log_rowcount + @@ROWCOUNT
SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- Attempt to insert XX_R22_CERIS_ASSIGNMENT_LOG records (round 3) failed.
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'XX_R22_CERIS_ASSIGNMENT_LOG records (round 3)'
      GOTO BL_ERROR_HANDLER
   END

/*
 * Delete duplicate log records just inserted above (this approach is faster than using a cursor)
 */
DELETE dbo.XX_R22_CERIS_ASSIGNMENT_LOG
  FROM dbo.XX_R22_CERIS_ASSIGNMENT_LOG t1
 WHERE 1 < (select COUNT(1)
              from dbo.XX_R22_CERIS_ASSIGNMENT_LOG t2
             where t2.EMPL_ID           = t1.EMPL_ID 
               and t2.DIVISION          = t1.DIVISION
               and t2.DIVISION_START_DT = t1.DIVISION_START_DT
               and t2.TERM_DT           = t1.TERM_DT
               and t2.ASTYP             = t1.ASTYP
               and t2.ASNTYP            = t1.ASNTYP)
   AND CONVERT(varchar(10), t1.CREATE_DT, 121) = CONVERT(varchar(10), getdate(), 121) -- only those records created today

SET @row_count = @@ROWCOUNT
SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- Attempt to delete XX_R22_CERIS_ASSIGNMENT_LOG records failed.
      SET @error_msg_placeholder1 = 'delete'
      SET @error_msg_placeholder2 = 'XX_R22_CERIS_ASSIGNMENT_LOG records'
      GOTO BL_ERROR_HANDLER
   END

SET @log_rowcount = @log_rowcount - @row_count
SET @updated_log_rowcount = @updated_log_rowcount + @log_rowcount

/*
 * Mark log records inserted today that will not be processed because they show the following conditions
 * as recognized at the time this program behavior was developed
 * (1) assignment data changed (based on previous log record); employee is currently assigned to other divisions;
 * no active assignment exists for this employee
 * (2) assignment is inactive; employee is terminated and assigned to other divisions;
 * no active assignment exists for this employee
 *
 * "PROCESS" as used to name columns in the XX_R22_CERIS_ASSIGNMENT_LOG record means the CERIS file record
 * is examined or considered. However, any actual data manipulation based on the examination results may
 * or may not happen.
 */
UPDATE dbo.XX_R22_CERIS_ASSIGNMENT_LOG
   SET PROCESS_OMITTED = 'Y'
 WHERE DIVISION != '22'
   AND CONVERT(varchar(10), CREATE_DT, 121) = CONVERT(varchar(10), getdate(), 121) -- only those records created today
   AND EMPL_ID not in (SELECT t1.PSEUDO_EMPL_ID
                         FROM dbo.XX_R22_CERIS_ASSIGNMENT_STG t1
                        WHERE t1.END_DT = (select MAX(t2.END_DT)
                                             from dbo.XX_R22_CERIS_ASSIGNMENT_STG t2
                                            where t2.PSEUDO_EMPL_ID = t1.PSEUDO_EMPL_ID
                                              and CONVERT(varchar(10), t2.END_DT, 121) != @STANDARD_END_DT_STR))
   AND EMPL_ID not in (SELECT t3.EMPL_ID
                         FROM dbo.XX_R22_CERIS_ASSIGNMENT_LOG t3
                        WHERE CONVERT(varchar(10), t3.CREATE_DT, 121) != CONVERT(varchar(10), getdate(), 121))


SET @row_count = @@ROWCOUNT
SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- Attempt to update XX_R22_CERIS_ASSIGNMENT_LOG records failed.
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'XX_R22_CERIS_ASSIGNMENT_LOG records'
      GOTO BL_ERROR_HANDLER
   END

--PRINT 'Total number of new XX_R22_CERIS_ASSIGNMENT_LOG records inserted today: ' + CONVERT(varchar(15), @log_rowcount)
--PRINT 'Total number of new XX_R22_CERIS_ASSIGNMENT_LOG records inserted today and will not be processed: ' + CONVERT(varchar(15), @row_count)
--PRINT 'Total number of XX_R22_CERIS_ASSIGNMENT_LOG records as of today: ' + CONVERT(varchar(10), @updated_log_rowcount, 121)
--PRINT ''

BL_WORK_ASSIGNMENT:

-- Step 1: Process employees who are included in the current CERIS file

-- Traverse the main decrypted staging table
DECLARE cursor_one CURSOR FAST_FORWARD FOR
   SELECT EMPL_ID, LNAME, FNAME, DIVISION, DIVISION_START_DT, TERM_DT, ASTYP, ASNTYP
     FROM dbo.XX_R22_CERIS_RPT_STG
    WHERE (ASTYP is not NULL and RTRIM(LTRIM(ASTYP)) != '')
      AND (ASNTYP is not NULL and RTRIM(LTRIM(ASNTYP)) != '')

OPEN cursor_one
FETCH NEXT FROM cursor_one INTO @EMPL_ID, @LNAME, @FNAME, @DIVISION, @DIVISION_START_DT, @TERM_DT, @ASTYP, @ASNTYP

WHILE @@FETCH_STATUS = 0
BEGIN
   SELECT @row_count = count(1)
     FROM dbo.XX_R22_CERIS_ASSIGNMENT_STG
    WHERE PSEUDO_EMPL_ID = @EMPL_ID

   IF @row_count = 0 -- No match
      BEGIN
         IF @DIVISION = '22'
            BEGIN
               SET @proviso_end_dt =
                  CASE
                     WHEN @TERM_DT is not NULL and RTRIM(LTRIM(@TERM_DT)) != '' THEN CONVERT(datetime, @TERM_DT, 121)
                     ELSE @STANDARD_END_DT
                  END

               SET @remarks =
                  CASE
                     WHEN @TERM_DT is not NULL and RTRIM(LTRIM(@TERM_DT)) != '' THEN CAST(@in_STATUS_RECORD_NUM as varchar(15)) + '-Employee terminated'
                     ELSE CAST(@in_STATUS_RECORD_NUM as varchar(15)) + '-New entry'
                  END

               --PRINT 'Step 1 - IF Body: Insert XX_R22_CERIS_ASSIGNMENT_STG record'
               --PRINT '@EMPL_ID = ' + @EMPL_ID
               --PRINT '@proviso_end_dt = ' + CONVERT(varchar(10), @proviso_end_dt, 120) -- should be 2099-12-31
               --PRINT '@remarks = ' + @remarks

               -- Insert new record
               INSERT INTO dbo.XX_R22_CERIS_ASSIGNMENT_STG
                  (PSEUDO_EMPL_ID, ASSIGNMENT, ASSIGNMENT_TYPE, START_DT, END_DT, REMARKS)
                  VALUES(@EMPL_ID, @ASTYP, @ASNTYP, getdate(), @proviso_end_dt, @remarks)

               SELECT @SQLServer_error_code = @@ERROR

               IF @SQLServer_error_code <> 0
                  BEGIN
                     -- Attempt to insert XX_R22_CERIS_ASSIGNMENT_STG records failed.
                     SET @error_msg_placeholder1 = 'insert'
                     SET @error_msg_placeholder2 = 'XX_R22_CERIS_ASSIGNMENT_STG records'
                     GOTO BL_ERROR_HANDLER
                  END

               SET @inserted_rowcount = @inserted_rowcount + 1
               SET @affected_rowcount = @affected_rowcount + 1

               -- Update the most recent assignment tracking record
               UPDATE dbo.XX_R22_CERIS_ASSIGNMENT_LOG
                  SET PROCESS_TYPE = 'A',
                      PROCESS_DESC = 'Employee with assignment data found in CERIS file: Insert new assignment record',
                      STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM,
                      PROCESS_DT = getdate()
                WHERE EMPL_ID = @EMPL_ID
                  AND DIVISION = '22'
                  AND CREATE_DT = (select MAX(CREATE_DT) from dbo.XX_R22_CERIS_ASSIGNMENT_LOG where EMPL_ID = @EMPL_ID)

               SELECT @SQLServer_error_code = @@ERROR

               IF @SQLServer_error_code <> 0
                  BEGIN
                     -- Attempt to update XX_R22_CERIS_ASSIGNMENT_LOG record failed.
                     SET @error_msg_placeholder1 = 'update'
                     SET @error_msg_placeholder2 = 'XX_R22_CERIS_ASSIGNMENT_LOG record'
                     GOTO BL_ERROR_HANDLER
                  END
            END
      END
   ELSE -- Match found
      BEGIN
         -- Look at the most recent record
         SELECT @assignment = ASSIGNMENT, @assignment_type = ASSIGNMENT_TYPE, @end_dt = END_DT
           FROM dbo.XX_R22_CERIS_ASSIGNMENT_STG
          WHERE PSEUDO_EMPL_ID = @EMPL_ID
            AND END_DT = (select MAX(END_DT) from dbo.XX_R22_CERIS_ASSIGNMENT_STG where PSEUDO_EMPL_ID = @EMPL_ID)

         IF CONVERT(varchar(10), @end_dt, 120) = @STANDARD_END_DT_STR
            BEGIN
               -- If the most recent record is the active record, there are 2 cases to consider.
               -- Case 1: Assignment data change
               IF (@assignment = @ASTYP AND @assignment_type != @ASNTYP) OR  -- only assignment type changes
                  (@assignment != @ASTYP AND @assignment_type = @ASNTYP) OR  -- only assignment changes
                  (@assignment != @ASTYP AND @assignment_type != @ASNTYP)    -- both assignment and assignment type change
                  BEGIN
                     SET @remarks = CAST(@in_STATUS_RECORD_NUM as varchar(15)) + '-Assignment data changed'

                     -- Update the most recent record, effectively making this record the soon-to-be second most recent record.
                     -- This update marks the end of the assignment as found in table XX_R22_CERIS_ASSIGNMENT_STG.
                     UPDATE dbo.XX_R22_CERIS_ASSIGNMENT_STG
                        SET END_DT  = getdate() - 1,
                            REMARKS = CASE
                                         WHEN REMARKS IS NULL THEN @remarks
                                         WHEN REMARKS IS NOT NULL THEN CAST((REMARKS + '; ' + @remarks) AS VARCHAR(500))
                                         WHEN LEN(RTRIM(LTRIM(REMARKS))) = 0 THEN @remarks
                                         ELSE REMARKS
                                      END,
                            MODIFIED_BY = suser_sname(),
                            MODIFIED_DT = getdate()
                      WHERE PSEUDO_EMPL_ID = @EMPL_ID
                        AND END_DT = (select MAX(END_DT) from dbo.XX_R22_CERIS_ASSIGNMENT_STG where PSEUDO_EMPL_ID = @EMPL_ID)

                     SELECT @SQLServer_error_code = @@ERROR

                     IF @SQLServer_error_code <> 0
                        BEGIN
                           -- Attempt to update XX_R22_CERIS_ASSIGNMENT_STG record failed.
                           SET @error_msg_placeholder1 = 'update'
                           SET @error_msg_placeholder2 = 'XX_R22_CERIS_ASSIGNMENT_STG record'
                           GOTO BL_ERROR_HANDLER
                        END

                     SET @updated_rowcount = @updated_rowcount + 1
                     SET @affected_rowcount = @affected_rowcount + 1
                     SET @remarks = CAST(@in_STATUS_RECORD_NUM as varchar(15)) + '-New assignment data'

                     --PRINT 'Step 1 - ELSE Body: Insert XX_R22_CERIS_ASSIGNMENT_STG record'
                     --PRINT '@EMPL_ID = ' + @EMPL_ID
                     --PRINT '@proviso_end_dt = ' + CONVERT(varchar(10), @proviso_end_dt, 120)
                     --PRINT '@remarks = ' + @remarks

                     -- Insert a new record, effectively making this new record the most recent record.
                     -- This insert marks the beginning of the new assignment as found in table XX_R22_CERIS_RPT_STG.
                     INSERT INTO dbo.XX_R22_CERIS_ASSIGNMENT_STG
                        (PSEUDO_EMPL_ID, ASSIGNMENT, ASSIGNMENT_TYPE, START_DT, END_DT, REMARKS)
                        VALUES(@EMPL_ID, @ASTYP, @ASNTYP, getdate(), @STANDARD_END_DT, @remarks)

                     SELECT @SQLServer_error_code = @@ERROR

                     IF @SQLServer_error_code <> 0
                        BEGIN
                           -- Attempt to insert XX_R22_CERIS_ASSIGNMENT_STG record failed.
                           SET @error_msg_placeholder1 = 'insert'
                           SET @error_msg_placeholder2 = 'XX_R22_CERIS_ASSIGNMENT_STG record'
                           GOTO BL_ERROR_HANDLER
                        END

                     SET @inserted_rowcount = @inserted_rowcount + 1
                     SET @affected_rowcount = @affected_rowcount + 1

                     -- Update the most recent assignment tracking record
                     UPDATE dbo.XX_R22_CERIS_ASSIGNMENT_LOG
                        SET PROCESS_TYPE = 'B',
                            PROCESS_DESC = 'Active assignment, assignment data changed: Set current assignment record inactive, insert new record for new assignment',
                            STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM,
                            PROCESS_DT = getdate()
                      WHERE EMPL_ID   = @EMPL_ID
                        AND TERM_DT   = @TERM_DT
                        AND DIVISION  = '22'
                        AND ASTYP     = @ASTYP
                        AND ASNTYP    = @ASNTYP
                        AND CREATE_DT = (select MAX(CREATE_DT) from dbo.XX_R22_CERIS_ASSIGNMENT_LOG where EMPL_ID = @EMPL_ID)

                     SELECT @SQLServer_error_code = @@ERROR

                     IF @SQLServer_error_code <> 0
                        BEGIN
                           -- Attempt to update XX_R22_CERIS_ASSIGNMENT_LOG record failed.
                           SET @error_msg_placeholder1 = 'update'
                           SET @error_msg_placeholder2 = 'XX_R22_CERIS_ASSIGNMENT_LOG record'
                           GOTO BL_ERROR_HANDLER
                        END

                  END /* Assignment data change */
               ELSE
                  BEGIN
                     -- Case 2: Non-Assignment data change.
                     -- Employee is terminated (TERM_DT != '' in CERIS file): use TERM_DT as assignment end date
                     IF ((@TERM_DT is not NULL and RTRIM(LTRIM(@TERM_DT)) != '') and
                         CONVERT(varchar(10), CONVERT(datetime, @TERM_DT, 121), 121) != CONVERT(varchar(10), @end_dt, 121) and
                         @DIVISION = '22'
                        )
                        BEGIN
                           --PRINT 'Step 1 - Non-Assignment data change: Update XX_R22_CERIS_ASSIGNMENT_STG record, @TERM_DT is not blank'
                           --PRINT '@EMPL_ID  = ' + @EMPL_ID
                           --PRINT '@end_dt   = ' + CONVERT(varchar(10), @end_dt, 121)
                           --PRINT '@TERM_DT  = ' + @TERM_DT
                           --PRINT '@DIVISION = ' + @DIVISION

                           SET @remarks = CAST(@in_STATUS_RECORD_NUM as varchar(15)) + '-Employee terminated'

                           UPDATE dbo.XX_R22_CERIS_ASSIGNMENT_STG
                              SET END_DT  = CONVERT(datetime, @TERM_DT, 121),
                                  REMARKS = CASE
                                               WHEN REMARKS IS NULL THEN @remarks
                                               WHEN REMARKS IS NOT NULL THEN CAST((REMARKS + '; ' + @remarks) AS VARCHAR(500))
                                               WHEN LEN(RTRIM(LTRIM(REMARKS))) = 0 THEN @remarks
                                               ELSE REMARKS
                                            END,
                                  MODIFIED_BY = suser_sname(),
                                  MODIFIED_DT = getdate()
                            WHERE PSEUDO_EMPL_ID = @EMPL_ID
                              AND END_DT = @end_dt

                           SELECT @SQLServer_error_code = @@ERROR

                           IF @SQLServer_error_code <> 0
                              BEGIN
                                 -- Attempt to update XX_R22_CERIS_ASSIGNMENT_STG record failed.
                                 SET @error_msg_placeholder1 = 'update'
                                 SET @error_msg_placeholder2 = 'XX_R22_CERIS_ASSIGNMENT_STG record'
                                 GOTO BL_ERROR_HANDLER
                              END

                           SET @updated_rowcount = @updated_rowcount + 1
                           SET @affected_rowcount = @affected_rowcount + 1

                           -- Update the most recent assignment tracking record
                           UPDATE dbo.XX_R22_CERIS_ASSIGNMENT_LOG
                              SET PROCESS_TYPE = 'C',
                                  PROCESS_DESC = 'Active assignment, employee terminated: Set assignment record inactive',
                                  STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM,
                                  PROCESS_DT = getdate()
                            WHERE EMPL_ID = @EMPL_ID
                              AND TERM_DT = @TERM_DT
                              AND DIVISION = '22'
                              AND CREATE_DT = (select MAX(CREATE_DT) from dbo.XX_R22_CERIS_ASSIGNMENT_LOG where EMPL_ID = @EMPL_ID)

                           SELECT @SQLServer_error_code = @@ERROR

                           IF @SQLServer_error_code <> 0
                              BEGIN
                                 -- Attempt to update XX_R22_CERIS_ASSIGNMENT_LOG record failed.
                                 SET @error_msg_placeholder1 = 'update'
                                 SET @error_msg_placeholder2 = 'XX_R22_CERIS_ASSIGNMENT_LOG record'
                                 GOTO BL_ERROR_HANDLER
                              END
                        END
                     ELSE IF @DIVISION != '22'
                        BEGIN
                           SET @remarks = CAST(@in_STATUS_RECORD_NUM as varchar(15)) + '-Employee transferred out of Division 22'

                           --PRINT 'Step 1 - Non-Assignment data change: Update XX_R22_CERIS_ASSIGNMENT_STG record, @DIVISION != 22'
                           --PRINT '@EMPL_ID = ' + @EMPL_ID
                           --PRINT '@end_dt = ' + CONVERT(varchar(10), @end_dt, 121)
                           --PRINT '@DIVISION = ' + @DIVISION
                           --PRINT '@DIVISION_START_DT = ' + @DIVISION_START_DT

                           UPDATE dbo.XX_R22_CERIS_ASSIGNMENT_STG
                              SET END_DT  = CONVERT(datetime, @DIVISION_START_DT, 121),
                                  REMARKS = CASE
                                               WHEN REMARKS IS NULL THEN @remarks
                                               WHEN REMARKS IS NOT NULL THEN CAST((REMARKS + '; ' + @remarks) AS VARCHAR(500))
                                               WHEN LEN(RTRIM(LTRIM(REMARKS))) = 0 THEN @remarks
                                               ELSE REMARKS
                                            END,
                                  MODIFIED_BY = suser_sname(),
                                  MODIFIED_DT = getdate()
                            WHERE PSEUDO_EMPL_ID = @EMPL_ID
                              AND END_DT = @end_dt

                           SELECT @SQLServer_error_code = @@ERROR

                           IF @SQLServer_error_code <> 0
                              BEGIN
                                 -- Attempt to update XX_R22_CERIS_ASSIGNMENT_STG record failed.
                                 SET @error_msg_placeholder1 = 'update'
                                 SET @error_msg_placeholder2 = 'XX_R22_CERIS_ASSIGNMENT_STG record'
                                 GOTO BL_ERROR_HANDLER
                              END

                           SET @updated_rowcount = @updated_rowcount + 1
                           SET @affected_rowcount = @affected_rowcount + 1

                           -- Update the most recent assignment tracking record
                           UPDATE dbo.XX_R22_CERIS_ASSIGNMENT_LOG
                              SET PROCESS_TYPE = 'D',
                                  PROCESS_DESC = 'Active assignment, employee tranferred out of Division 22: Set assignment record inactive',
                                  STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM,
                                  PROCESS_DT = getdate()
                            WHERE EMPL_ID = @EMPL_ID
                              AND DIVISION = @DIVISION
                              AND CREATE_DT = (select MAX(CREATE_DT) from dbo.XX_R22_CERIS_ASSIGNMENT_LOG where EMPL_ID = @EMPL_ID)

                           SELECT @SQLServer_error_code = @@ERROR

                           IF @SQLServer_error_code <> 0
                              BEGIN
                                 -- Attempt to update XX_R22_CERIS_ASSIGNMENT_LOG record failed.
                                 SET @error_msg_placeholder1 = 'update'
                                 SET @error_msg_placeholder2 = 'XX_R22_CERIS_ASSIGNMENT_LOG record'
                                 GOTO BL_ERROR_HANDLER
                              END
                        END
                  END
            END /* IF CONVERT(varchar(10), @end_dt, 120) = @STANDARD_END_DT_STR */
         ELSE
            -- Each employee has one record in the CERIS file. This record, even when it is unchanged, stays in the CERIS file each week.
            -- The most recent XX_R22_CERIS_ASSIGNMENT_STG record indicates the employee is not active: either terminated or tranferred out of Division 22
            BEGIN
               -- The employee is re-hired or re-assigned to Division 22
               IF (@TERM_DT is not NULL and LEN(@TERM_DT) = 0) AND
                  @DIVISION = '22' AND
                  (@ASTYP is not NULL and LEN(@ASTYP) > 0) AND
                  (@ASNTYP is not NULL and LEN(@ASNTYP) > 0)
                  BEGIN
                     -- Insert new record
                     SET @remarks = CAST(@in_STATUS_RECORD_NUM as varchar(15)) + '-New entry as employee re-assigned to Division 22'

                     --PRINT 'Step 1 - ELSE Body @end_dt != @STANDARD_END_DT: Insert XX_R22_CERIS_ASSIGNMENT_STG record (New entry as employee re-assigned to Division 22)'
                     --PRINT '@EMPL_ID = ' + @EMPL_ID
                     --PRINT '@DIVISION = ' + @DIVISION
                     --PRINT '@DIVISION_START_DT = ' + @DIVISION_START_DT

                     INSERT INTO dbo.XX_R22_CERIS_ASSIGNMENT_STG
                        (PSEUDO_EMPL_ID, ASSIGNMENT, ASSIGNMENT_TYPE, START_DT, END_DT, REMARKS)
                        VALUES(@EMPL_ID, @ASTYP, @ASNTYP, CONVERT(datetime, @DIVISION_START_DT, 121), @STANDARD_END_DT, @remarks)

                     SELECT @SQLServer_error_code = @@ERROR

                     IF @SQLServer_error_code <> 0
                        BEGIN
                           -- Attempt to insert XX_R22_CERIS_ASSIGNMENT_STG records failed.
                           SET @error_msg_placeholder1 = 'insert'
                           SET @error_msg_placeholder2 = 'XX_R22_CERIS_ASSIGNMENT_STG records'
                           GOTO BL_ERROR_HANDLER
                        END

                     SET @inserted_rowcount = @inserted_rowcount + 1
                     SET @affected_rowcount = @affected_rowcount + 1

                     -- Update the most recent assignment tracking record
                     UPDATE dbo.XX_R22_CERIS_ASSIGNMENT_LOG
                        SET PROCESS_TYPE = 'E',
                            PROCESS_DESC = 'Inactive assignment, employee reassigned to Division 22: Insert new assignment record',
                            STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM,
                            PROCESS_DT = getdate()
                      WHERE EMPL_ID = @EMPL_ID
                        AND TERM_DT = @TERM_DT
                        AND DIVISION = '22'
                        AND CREATE_DT = (select MAX(CREATE_DT) from dbo.XX_R22_CERIS_ASSIGNMENT_LOG where EMPL_ID = @EMPL_ID)

                     SELECT @SQLServer_error_code = @@ERROR

                     IF @SQLServer_error_code <> 0
                        BEGIN
                           -- Attempt to update XX_R22_CERIS_ASSIGNMENT_LOG record failed.
                           SET @error_msg_placeholder1 = 'update'
                           SET @error_msg_placeholder2 = 'XX_R22_CERIS_ASSIGNMENT_LOG record'
                           GOTO BL_ERROR_HANDLER
                        END
                  END
               END /* The employee is re-hired or re-assigned to Division 22 */
      END /* Match found */

   FETCH NEXT FROM cursor_one INTO @EMPL_ID, @LNAME, @FNAME, @DIVISION, @DIVISION_START_DT, @TERM_DT, @ASTYP, @ASNTYP

END /* WHILE @@FETCH_STATUS = 0 */

CLOSE cursor_one
DEALLOCATE cursor_one

-- Step 2: Process employees who were included in the previous CERIS file but are not in current one

-- Traverse the assignment table
DECLARE cursor_two CURSOR FAST_FORWARD FOR
   SELECT DISTINCT PSEUDO_EMPL_ID -- use DISTINCT because there can be multiple XX_R22_CERIS_ASSIGNMENT_STG records for a single employee
     FROM dbo.XX_R22_CERIS_ASSIGNMENT_STG
    WHERE CONVERT(varchar(10), END_DT, 120) = @STANDARD_END_DT_STR

OPEN cursor_two
FETCH NEXT FROM cursor_two INTO @pseudo_empl_id

WHILE @@FETCH_STATUS = 0
BEGIN
   -- Determine if this employee is included in the current CERIS file
   SELECT @row_count = count(1)
     FROM dbo.XX_R22_CERIS_RPT_STG
    WHERE EMPL_ID = @pseudo_empl_id

   -- This employee is not included in the current CERIS file, and thus no longer in Devision 22.
   IF @row_count = 0
      BEGIN
         -- Check the log to see if this employee's assignment wasn't already processed before for this situation
         SELECT @log_rowcount = count(1)
           FROM dbo.XX_R22_CERIS_ASSIGNMENT_LOG
          WHERE EMPL_ID = @pseudo_empl_id
            AND CREATE_DT = (select MAX(CREATE_DT) from dbo.XX_R22_CERIS_ASSIGNMENT_LOG where EMPL_ID = @pseudo_empl_id)
            AND CONVERT(varchar(10), CREATE_DT, 121) != CONVERT(varchar(10), getdate(), 121)
            AND PROCESS_DT is NOT NULL

         -- This employee's assignment has never been processed before
         IF @log_rowcount = 0
            BEGIN
               SET @remarks = CAST(@in_STATUS_RECORD_NUM as varchar(15)) + '-Employee no longer in Division 22'

               --PRINT 'Step 2: This employee''''s log record shows assignment record has never been processed before for not being included in the CERIS file'
               --PRINT 'PSEUDO_EMPL_ID  = ' + @pseudo_empl_id
               --PRINT '@remarks = ' + @remarks
               --PRINT 'END_DT = ' + CONVERT(varchar(10), getdate(), 121)

               -- Update only the most recent record with today's date as END_DT
               UPDATE dbo.XX_R22_CERIS_ASSIGNMENT_STG
                  SET END_DT  = getdate(),
                      REMARKS = CASE
                                   WHEN REMARKS IS NULL THEN @remarks
                                   WHEN REMARKS IS NOT NULL THEN CAST((REMARKS + '; ' + @remarks) AS VARCHAR(500))
                                   WHEN LEN(RTRIM(LTRIM(REMARKS))) = 0 THEN @remarks
                                   ELSE REMARKS
                                END,
                      MODIFIED_BY = suser_sname(),
                      MODIFIED_DT = getdate()
                WHERE PSEUDO_EMPL_ID = @pseudo_empl_id
                  AND CONVERT(varchar(10), END_DT, 120) = @STANDARD_END_DT_STR

               SELECT @SQLServer_error_code = @@ERROR

               IF @SQLServer_error_code <> 0
                  BEGIN
                     -- Attempt to update XX_R22_CERIS_ASSIGNMENT_STG record failed.
                     SET @error_msg_placeholder1 = 'update'
                     SET @error_msg_placeholder2 = 'XX_R22_CERIS_ASSIGNMENT_STG record'
                     GOTO BL_ERROR_HANDLER
                  END

               SET @updated_rowcount = @updated_rowcount + 1
               SET @affected_rowcount = @affected_rowcount + 1

               -- Update the most recent assignment tracking record
               UPDATE dbo.XX_R22_CERIS_ASSIGNMENT_LOG
                  SET PROCESS_OMITTED = 'N',
                      PROCESS_TYPE = 'F',
                      PROCESS_DESC = 'Active assignment, employee not found in CERIS file: Set assignment record inactive',
                      STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM,
                      PROCESS_DT = getdate()
                WHERE EMPL_ID = @pseudo_empl_id
                  AND CREATE_DT = (select MAX(CREATE_DT) from dbo.XX_R22_CERIS_ASSIGNMENT_LOG where EMPL_ID = @pseudo_empl_id)

               SELECT @SQLServer_error_code = @@ERROR

               IF @SQLServer_error_code <> 0
                  BEGIN
                     -- Attempt to update XX_R22_CERIS_ASSIGNMENT_LOG record failed.
                     SET @error_msg_placeholder1 = 'update'
                     SET @error_msg_placeholder2 = 'XX_R22_CERIS_ASSIGNMENT_LOG record'
                    GOTO BL_ERROR_HANDLER
                  END
            END /* IF @log_rowcount = 0 */
      END /* IF @row_count = 0 */

   FETCH NEXT FROM cursor_two INTO @pseudo_empl_id

END /* WHILE @@FETCH_STATUS = 0 */

CLOSE cursor_two
DEALLOCATE cursor_two

-- CR3599_Begin

-- Step 3: Employees whose assignment data have been removed based on to the latest CERIS file
-- should have their active XX_R22_CERIS_ASSIGNMENT_STG records updated accordingly

SELECT @row_count = COUNT(DISTINCT t1.PSEUDO_EMPL_ID)
  FROM dbo.XX_R22_CERIS_ASSIGNMENT_STG t1,
       dbo.XX_R22_CERIS_RPT_STG t2
 WHERE t1.PSEUDO_EMPL_ID = t2.EMPL_ID
   AND (t2.ASTYP is NULL or (t2.ASTYP is not NULL and RTRIM(LTRIM(t2.ASTYP)) = ''))
   AND (t2.ASNTYP is NULL or (t2.ASNTYP is not NULL and RTRIM(LTRIM(t2.ASNTYP)) = ''))

IF @row_count > 0
   BEGIN
      DECLARE cursor_step3 CURSOR FAST_FORWARD FOR
         SELECT DISTINCT t1.PSEUDO_EMPL_ID, t1.END_DT, t2.DIVISION, t2.DIVISION_START_DT, t2.TERM_DT
           FROM dbo.XX_R22_CERIS_ASSIGNMENT_STG t1,
                dbo.XX_R22_CERIS_RPT_STG t2
          WHERE t1.PSEUDO_EMPL_ID = t2.EMPL_ID
            AND (t2.ASTYP is NULL or (t2.ASTYP is not NULL and RTRIM(LTRIM(t2.ASTYP)) = ''))
            AND (t2.ASNTYP is NULL or (t2.ASNTYP is not NULL and RTRIM(LTRIM(t2.ASNTYP)) = ''))
            AND t1.END_DT = (select MAX(t3.END_DT)
                               from dbo.XX_R22_CERIS_ASSIGNMENT_STG t3
                              where t3.PSEUDO_EMPL_ID = t1.PSEUDO_EMPL_ID)

      OPEN cursor_step3
      FETCH NEXT FROM cursor_step3 INTO @pseudo_empl_id, @end_dt, @DIVISION, @DIVISION_START_DT, @TERM_DT

      WHILE @@FETCH_STATUS = 0
         BEGIN
            /*
             * Avoid updating the same XX_R22_CERIS_ASSIGNMENT_STG record again and again when the XX_R22_CERIS_RPT_STG record
             * with ASTYP = '' and ASNTYP = '' remains unchanged in the CERIS file week after week.
             * Also, if the employee has already ended his assignment (CONVERT(varchar(10), END_DT, 120) != @STANDARD_END_DT_STR),
             * then do not update the record to show REMARKS = xxx-Assignment data removed.
             */

            /*
             * Case 1: The CERIS file record shows the employee is assigned to Division 22
             * and the current XX_R22_CERIS_ASSIGNMENT_STG record shows the employee's assignment is active
             */
            IF @DIVISION = '22' AND CONVERT(varchar(10), @end_dt, 120) = @STANDARD_END_DT_STR
               BEGIN
                  IF (@TERM_DT is not NULL AND
                      RTRIM(LTRIM(@TERM_DT)) != '' AND
                      CONVERT(varchar(10), CONVERT(datetime, @TERM_DT, 121), 121) != CONVERT(varchar(10), @end_dt, 121)
                     )
                     SET @proviso_end_dt = CONVERT(datetime, @TERM_DT, 121)
                  ELSE IF @end_dt > getdate()
                     SET @proviso_end_dt = getdate()
                  ELSE
                     SET @proviso_end_dt = @end_dt

                  IF (@TERM_DT is not NULL AND
                      RTRIM(LTRIM(@TERM_DT)) != '' AND
                      CONVERT(varchar(10), CONVERT(datetime, @TERM_DT, 121), 121) != CONVERT(varchar(10), @end_dt, 121))
                      BEGIN
                         SET @remarks = CAST(@in_STATUS_RECORD_NUM as varchar(15)) + '-Employee terminated; Assignment data removed'
                         SET @process_type = 'H'
                         SET @process_desc = @PROCESS_DESC_H
                      END
                  ELSE
                      BEGIN
                         SET @remarks = CAST(@in_STATUS_RECORD_NUM as varchar(15)) + '-Assignment data removed'
                         SET @process_type = 'G'
                         SET @process_desc = @PROCESS_DESC_G
                      END

                  -- Update only the most recent record
                  UPDATE dbo.XX_R22_CERIS_ASSIGNMENT_STG
                     SET END_DT  = @proviso_end_dt,
                         REMARKS = CASE
                                      WHEN REMARKS IS NULL THEN @remarks
                                      WHEN REMARKS IS NOT NULL THEN CAST((REMARKS + '; ' + @remarks) AS VARCHAR(500))
                                      WHEN LEN(RTRIM(LTRIM(REMARKS))) = 0 THEN @remarks
                                      ELSE REMARKS
                                   END,
                         MODIFIED_BY = suser_sname(),
                         MODIFIED_DT = getdate()
                   WHERE PSEUDO_EMPL_ID = @pseudo_empl_id
                     AND END_DT = (select MAX(END_DT) from dbo.XX_R22_CERIS_ASSIGNMENT_STG where PSEUDO_EMPL_ID = @pseudo_empl_id)

                  SELECT @SQLServer_error_code = @@ERROR

                  IF @SQLServer_error_code <> 0
                     BEGIN
                        -- Attempt to update XX_R22_CERIS_ASSIGNMENT_STG record failed.
                        SET @error_msg_placeholder1 = 'update'
                        SET @error_msg_placeholder2 = 'XX_R22_CERIS_ASSIGNMENT_STG record'
                        GOTO BL_ERROR_HANDLER
                     END

                  SET @updated_rowcount = @updated_rowcount + 1
                  SET @affected_rowcount = @affected_rowcount + 1

                  -- Update the most recent assignment tracking record
                  UPDATE dbo.XX_R22_CERIS_ASSIGNMENT_LOG
                     SET PROCESS_TYPE = @process_type,
                         PROCESS_DESC = @process_desc,
                         STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM,
                         PROCESS_DT = getdate()
                   WHERE EMPL_ID = @pseudo_empl_id
                     AND DIVISION = '22'
                     AND ASTYP = ''
                     AND ASNTYP = ''
                     AND CREATE_DT = (select MAX(CREATE_DT) from dbo.XX_R22_CERIS_ASSIGNMENT_LOG where EMPL_ID = @pseudo_empl_id)

                  SELECT @SQLServer_error_code = @@ERROR

                  IF @SQLServer_error_code <> 0
                     BEGIN
                        -- Attempt to update XX_R22_CERIS_ASSIGNMENT_LOG record failed.
                        SET @error_msg_placeholder1 = 'update'
                        SET @error_msg_placeholder2 = 'XX_R22_CERIS_ASSIGNMENT_LOG record'
                        GOTO BL_ERROR_HANDLER
                     END
               END
            /*
             * Case 2: The CERIS file record shows the employee is not assigned to Division 22
             * and the current XX_R22_CERIS_ASSIGNMENT_STG shows the employee's assignment is active
             */
            ELSE IF @DIVISION != '22' AND CONVERT(varchar(10), @end_dt, 120) = @STANDARD_END_DT_STR
               BEGIN
                  SET @remarks = CAST(@in_STATUS_RECORD_NUM as varchar(15)) + '-Employee transferred out of Division 22; Assignment data removed'

                  -- Update only the most recent record
                  UPDATE dbo.XX_R22_CERIS_ASSIGNMENT_STG
                     SET END_DT  = CONVERT(datetime, @DIVISION_START_DT, 121),
                         REMARKS = CASE
                                      WHEN REMARKS IS NULL THEN @remarks
                                      WHEN REMARKS IS NOT NULL THEN CAST((REMARKS + '; ' + @remarks) AS VARCHAR(500))
                                      WHEN LEN(RTRIM(LTRIM(REMARKS))) = 0 THEN @remarks
                                      ELSE REMARKS
                                   END,
                         MODIFIED_BY = suser_sname(),
                         MODIFIED_DT = getdate()
                   WHERE PSEUDO_EMPL_ID = @pseudo_empl_id
                     AND END_DT = (select MAX(END_DT) from dbo.XX_R22_CERIS_ASSIGNMENT_STG where PSEUDO_EMPL_ID = @pseudo_empl_id)

                  SELECT @SQLServer_error_code = @@ERROR

                  IF @SQLServer_error_code <> 0
                     BEGIN
                        -- Attempt to update XX_R22_CERIS_ASSIGNMENT_STG record failed.
                        SET @error_msg_placeholder1 = 'update'
                        SET @error_msg_placeholder2 = 'XX_R22_CERIS_ASSIGNMENT_STG record'
                        GOTO BL_ERROR_HANDLER
                     END

                  SET @updated_rowcount = @updated_rowcount + 1
                  SET @affected_rowcount = @affected_rowcount + 1

                  -- Update the most recent assignment tracking record
                  UPDATE dbo.XX_R22_CERIS_ASSIGNMENT_LOG
                     SET PROCESS_TYPE = 'I',
                         PROCESS_DESC = 'Active assignment, assignment data removed, employee tranferred out of Division 22: Set assignment record inactive',
                         STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM,
                         PROCESS_DT = getdate()
                   WHERE EMPL_ID = @pseudo_empl_id
                     AND DIVISION = @DIVISION
                     AND ASTYP = ''
                     AND ASNTYP = ''
                     AND CREATE_DT = (select MAX(CREATE_DT) from dbo.XX_R22_CERIS_ASSIGNMENT_LOG where EMPL_ID = @pseudo_empl_id)

                  SELECT @SQLServer_error_code = @@ERROR

                  IF @SQLServer_error_code <> 0
                     BEGIN
                        -- Attempt to update XX_R22_CERIS_ASSIGNMENT_LOG record failed.
                        SET @error_msg_placeholder1 = 'update'
                        SET @error_msg_placeholder2 = 'XX_R22_CERIS_ASSIGNMENT_LOG record'
                        GOTO BL_ERROR_HANDLER
                     END
               END

            FETCH NEXT FROM cursor_step3 INTO @pseudo_empl_id, @end_dt, @DIVISION, @DIVISION_START_DT, @TERM_DT
         END /* WHILE @@FETCH_STATUS = 0 */

      CLOSE cursor_step3
      DEALLOCATE cursor_step3

   END /* IF @row_count > 0 */

--PRINT 'Total number of XX_R22_CERIS_ASSIGNMENT_STG rows affected: ' + CONVERT(varchar(15), @affected_rowcount)
--PRINT 'Total number of XX_R22_CERIS_ASSIGNMENT_STG rows inserted: ' + CONVERT(varchar(15), @inserted_rowcount)
--PRINT 'Total number of XX_R22_CERIS_ASSIGNMENT_STG rows updated:  ' + CONVERT(varchar(15), @updated_rowcount)

-- CR3599_End

RETURN(0)

BL_ERROR_HANDLER:

EXEC dbo.XX_ERROR_MSG_DETAIL
   @in_error_code           = @IMAPS_error_code,
   @in_display_requested    = 1,
   @in_SQLServer_error_code = @SQLServer_error_code,
   @in_placeholder_value1   = @error_msg_placeholder1,
   @in_placeholder_value2   = @error_msg_placeholder2,
   @in_calling_object_name  = @SP_NAME,
   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

RETURN(1)
