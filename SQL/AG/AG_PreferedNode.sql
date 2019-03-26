-- This script can be executed on AG Server. It validates if the server is secondary, connected and healty; If healthy it makes it primary 
-- This is the Failback job to be configured on SQL AG which needs to be primary

-- NOTE: If, Sync mode is Async, Failover parameter needs to be updated to ' FORCE_FAILOVER_ALLOW_DATA_LOSS' ; Data movement is suspended on secondary after the execution.

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
SET @mailBody = ''
SET @mailSubject = 'AG Failover: ' + @@SERVERNAME

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
        SET @FailoverCommand = 'ALTER AVAILABILITY GROUP ' + @AGName + ' FAILOVER'
        -- ' FORCE_FAILOVER_ALLOW_DATA_LOSS'
        EXEC (@FailoverCommand)
        PRINT 'AG '+ @AGName +' has been failed over to ' + @@SERVERNAME
        SET @mailBody += 'AG '+ @AGName +' has been failed over to ' + @@SERVERNAME + CHAR(13)
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
            PRINT 'Failover of AG '+ @AGName +' not attempted as AG is not connected or not Healthy on ' + @@SERVERNAME
            SET @mailBody += 'Failover of AG '+ @AGName +' not attempted as AG is not connected or not Healthy on ' + @@SERVERNAME + CHAR(13)
            SET @failed = 1
        END
    ELSE
    BEGIN
            PRINT 'AG '+ @AGName +' is Primary, Failover was not attempted on ' + @@SERVERNAME
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
        @profile_name = 'Domain Profile',
        @recipients = 'serverteam@domain.com',
        @body = @mailBody,
        @subject = @mailSubject;
END
