USE [msdb]
GO

/****** Object:  Job [AWS_Titanium_WNSW_Train_RestoreJob]    Script Date: 06/10/2021 16:36:14 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 06/10/2021 16:36:14 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'AWS_Titanium_WNSW_Train_RestoreJob', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DB Backup]    Script Date: 06/10/2021 16:36:14 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DB Backup', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE [master]
ALTER DATABASE [AWS_Titanium_WNSW_Train] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
RESTORE DATABASE [AWS_Titanium_WNSW_Train] 
FROM  
DISK = N''\\virtnas-fas150\EhInfrSqlLogsSv01\MSSQL\Titanium_WNSW_train_AWSCloud_Backup\branch1_Titanium1.bak'',  
DISK = N''\\virtnas-fas150\EhInfrSqlLogsSv01\MSSQL\Titanium_WNSW_train_AWSCloud_Backup\branch1_Titanium2.bak'',  
DISK = N''\\virtnas-fas150\EhInfrSqlLogsSv01\MSSQL\Titanium_WNSW_train_AWSCloud_Backup\branch1_Titanium3.bak'',  
DISK = N''\\virtnas-fas150\EhInfrSqlLogsSv01\MSSQL\Titanium_WNSW_train_AWSCloud_Backup\branch1_Titanium4.bak''
WITH FILE = 1,  
MOVE N''Exact_Data'' TO N''E:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\AWS_Titanium_WNSW_Train.mdf'',
MOVE N''Exact_Log'' TO N''D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Log\AWS_Titanium_WNSW_Train_log.ldf'',  NOUNLOAD,  REPLACE,  STATS = 5
ALTER DATABASE [AWS_Titanium_WNSW_Train] SET MULTI_USER

GO

USE master ;  
ALTER DATABASE [AWS_Titanium_WNSW_Train] SET RECOVERY SIMPLE ; 

ALTER AUTHORIZATION ON DATABASE::[AWS_Titanium_WNSW_Train] TO sa

use [AWS_Titanium_WNSW_Train] 
go

DBCC SHRINKDATABASE(N''AWS_Titanium_WNSW_Train'' )
go', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Create User]    Script Date: 06/10/2021 16:36:14 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Create User', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE [AWS_Titanium_WNSW_Train]
GO
CREATE USER [NSWHEALTH\G-NSWH-TitaniumWarehouse]
GO
EXEC sp_addrolemember ''db_datareader'', ''NSWHEALTH\G-NSWH-TitaniumWarehouse''; 
go', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [UpdateStats]    Script Date: 06/10/2021 16:36:14 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'UpdateStats', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'UPDATE STATISTICS dbo.chart5 with fullscan
GO
dbcc updateusage (0)
GO', 
		@database_name=N'AWS_Titanium_WNSW_Train', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20190802, 
		@active_end_date=99991231, 
		@active_start_time=20000, 
		@active_end_time=235959, 
		@schedule_uid=N'9b9d7757-e95d-4dba-994f-37ee4dd2fd67'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


