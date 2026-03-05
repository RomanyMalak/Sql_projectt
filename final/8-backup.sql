
-- ============================================================
-- SECTION 10: AUTOMATED DAILY BACKUP JOB
-- ============================================================

USE msdb;
GO

-- Remove existing job if re-running
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'ExaminationSystemDB_DailyBackup')
    EXEC sp_delete_job @job_name = N'ExaminationSystemDB_DailyBackup';
GO

DECLARE @JobID UNIQUEIDENTIFIER;

EXEC sp_add_job
     @job_name   = N'ExaminationSystemDB_DailyBackup',
     @enabled    = 1,
     @description= N'Daily full backup of ExaminationSystemDB',
     @job_id     = @JobID OUTPUT;

EXEC sp_add_jobstep
     @job_name      = N'ExaminationSystemDB_DailyBackup',
     @step_name     = N'Full Backup Step',
     @subsystem     = N'TSQL',
     @database_name = N'master',
     @command       = N'
DECLARE @Path NVARCHAR(500) =
    ''C:/SQLData/'' + CONVERT(NVARCHAR(8), GETDATE(), 112) + ''.bak'';
BACKUP DATABASE ExaminationSystemDB
TO DISK = @Path
WITH COMPRESSION, CHECKSUM, STATS = 10;';

EXEC sp_add_schedule
     @schedule_name      = N'DailyAt2AM',
     @freq_type          = 4,       -- Daily
     @freq_interval      = 1,
     @active_start_time  = 20000;   -- 02:00 AM

EXEC sp_attach_schedule
     @job_name      = N'ExaminationSystemDB_DailyBackup',
     @schedule_name = N'DailyAt2AM';

EXEC sp_add_jobserver
     @job_name = N'ExaminationSystemDB_DailyBackup';
GO
