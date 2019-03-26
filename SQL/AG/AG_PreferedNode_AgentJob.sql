USE [msdb]
GO

/****** Object:  Job [MAINT AG Failback]    Script Date: 9/26/2018 10:03:23 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 9/26/2018 10:03:23 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'MAINT AG Failback', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'Server Team', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Failback]    Script Date: 9/26/2018 10:03:23 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Failback', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- This script can be executed on AG Server. It validates if the server is secondary, connected and healty; If healthy it makes it primary 
-- This is the Failback job to be configured on SQL AG which needs to be primary

-- NOTE: If, Sync mode is Async, Failover parameter needs to be updated to '' FORCE_FAILOVER_ALLOW_DATA_LOSS'' ; Data movement is suspended on secondary after the execution.

DECLARE curAG CURSOR FOR
	SELECT DISTINCT group_name
FROM sys.dm_hadr_availability_replica_cluster_nodes

OPEN curAG

DECLARE @AGName varchar(80)
DECLARE @FailoverCommand varchar(280)
DECLARE @mailBody nvarchar(MAX)
DECLARE @mailSubject nvarchar(255)
DECLARE @failed bit

SET @failed = 0
SET @mailBody = ''''
SET @mailSubject = ''AG Failover: '' + @@SERVERNAME

FETCH NEXT FROM curAG INTO
    @AGName

WHILE @@FETCH_STATUS = 0
	BEGIN
    if EXISTS (SELECT 1
    FROM sys.availability_replicas ar
        inner join sys.dm_hadr_availability_replica_states ags on ar.replica_id=ags.replica_id
        JOIN sys.availability_groups AS ag ON ag.group_id = ar.group_id
    WHERE name = @AGName
        AND is_local = 1 -- LocalReplica
        AND ROLE = 2 -- Secondary
        AND connected_state = 1 -- CONNECTED
        AND synchronization_health = 2 -- HEALTHY
    )
    BEGIN
        SET @FailoverCommand = ''ALTER AVAILABILITY GROUP '' + @AGName + '' FAILOVER''
        -- '' FORCE_FAILOVER_ALLOW_DATA_LOSS''
        EXEC (@FailoverCommand)
        PRINT ''AG ''+ @AGName +'' has been failed over to '' + @@SERVERNAME
        SET @mailBody += ''AG ''+ @AGName +'' has been failed over to '' + @@SERVERNAME + CHAR(13)
		SET @failed = 1
    END
    ELSE
    BEGIN
        if EXISTS (SELECT 1
        FROM sys.availability_replicas               ar
            inner join sys.dm_hadr_availability_replica_states ags on ar.replica_id=ags.replica_id
            JOIN sys.availability_groups AS ag ON ag.group_id = ar.group_id
        WHERE name = @AGName
            AND is_local = 1 -- LocalReplica
            AND ROLE = 2 -- Secondary
    )
    BEGIN
            PRINT ''Failover of AG ''+ @AGName +'' not attempted as AG is not connected or not Healthy on '' + @@SERVERNAME
            SET @mailBody += ''Failover of AG ''+ @AGName +'' not attempted as AG is not connected or not Healthy on '' + @@SERVERNAME + CHAR(13)
            SET @failed = 1
        END
    ELSE
    BEGIN
            PRINT ''AG ''+ @AGName +'' is Primary, Failover was not attempted on '' + @@SERVERNAME
        END
    END
    FETCH NEXT FROM curAG INTO
    @AGName
END

CLOSE curAG
DEALLOCATE curAG

if @failed = 1
BEGIN
    EXEC msdb.dbo.sp_send_dbmail
        @profile_name = ''Domain Profile'',
        @recipients = ''serverteam@domain.com'',
        @body = @mailBody,
        @subject = @mailSubject;
END
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'MAINT AG Failback', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180926, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'0c20aba8-bf1a-4740-9af0-df1ba532b9a4'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO
