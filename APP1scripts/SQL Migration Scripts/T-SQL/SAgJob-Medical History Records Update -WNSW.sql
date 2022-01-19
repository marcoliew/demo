USE [msdb]
GO

/****** Object:  Job [Medical History Records Update for Titanium_WNSW_train]    Script Date: 11/10/2021 15:38:54 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 11/10/2021 15:38:54 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Medical History Records Update for Titanium_WNSW_train', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'admin', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Update Debtor4 dtlastmedupdate from most recent Medical History Questionnaire]    Script Date: 11/10/2021 15:38:54 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Update Debtor4 dtlastmedupdate from most recent Medical History Questionnaire', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'update DEBTOR4
	set dtlastmedupdate = mh.PatientLastMedHistoryQuestionnaireDate
from 
	(
		select 
			d.recordnum as PatientRecordnum
			, d.code as PatientCode
			, dtlastmedupdate as PatientLastMedUpdate
			, q.createddate as PatientLastMedHistoryQuestionnaireDate
		 FROM debtor4 d
		 cross apply
			(  
			select top 1 qpa.createddate 
			from questionnairepatact qpa
				INNER JOIN questionnairepat 
					ON qpa.ridquestionnairepatient = questionnairepat.recordnum and questionnairepat.riddebtor = d.recordnum 
				INNER JOIN QUESTIONNAIREACT 
					on qpa.lQuestionnaireAction = QUESTIONNAIREACT.lUniqueActionNum and QUESTIONNAIREACT.actionTypeCode = ''MHXRESET''
			WHERE QUESTIONNAIREACT.Deleted = 0
				AND qpa.deleted = 0 
				AND questionnairepat.deleted = 0 
			ORDER BY qpa.createddate DESC
			) as q							
		WHERE d.deleted = 0 
			AND ( 
					d.dtlastmedupdate < q.createddate 
					OR dtlastmedupdate IS NULL 
				) 
	) mh
where 
	RecordNum = mh.PatientRecordNum', 
		@database_name=N'Titanium_WNSW_train', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every morning at 1am (before the IIS reset for web services at 2am)', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180315, 
		@active_end_date=99991231, 
		@active_start_time=10000, 
		@active_end_time=235959, 
		@schedule_uid=N'44e07d2d-8e7f-4205-9de6-edc81a0e7ace'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


