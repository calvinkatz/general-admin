/*
Must perform FULL backup before running this script.
For each USER database, run DBCC SHRINKFILE on Log file.
Skip databases currently being backed up.
*/

DECLARE @dbname VARCHAR(100)
DECLARE @dbid INT
DECLARE @dbrec INT
DECLARE @dbstatement NVARCHAR(MAX)
DECLARE @dbfilename VARCHAR(100)

DECLARE curDatabases CURSOR FOR
	SELECT name, database_id, recovery_model FROM sys.databases
		WHERE name NOT IN ('master', 'tempdb', 'model', 'msdb')
		AND state = 0

OPEN curDatabases

FETCH NEXT FROM curDatabases INTO
	@dbname,
	@dbid,
	@dbrec
WHILE @@FETCH_STATUS = 0
	BEGIN
		IF NOT EXISTS(SELECT * FROM sys.dm_exec_requests WHERE command LIKE 'BACKUP%' AND database_id = @dbid)
		BEGIN
			Select @dbfilename = name FROM sys.master_files
				WHERE type = 1 AND database_id = @dbid
			SET @dbstatement = N'
				USE [' + @dbname + ']
				DBCC SHRINKFILE (''' + @dbfilename + ''')
					'
			EXECUTE sp_executesql @dbstatement;
		END
	FETCH NEXT FROM curDatabases INTO
		@dbname,
		@dbid,
		@dbrec
END
CLOSE curDatabases
DEALLOCATE curDatabases