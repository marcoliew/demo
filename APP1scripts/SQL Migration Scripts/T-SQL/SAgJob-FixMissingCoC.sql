USE [msdb]
GO

/****** Object:  Job [Titanium_WNSW_prod fix missing CoC]    Script Date: 29/09/2021 10:23:28 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 29/09/2021 10:23:28 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Titanium_WNSW_prod fix missing CoC', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'c:7206003', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'admin', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run script]    Script Date: 29/09/2021 10:23:29 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run script', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'begin tran
begin try
--get all the chart5 appointment records that don''t have a CoC line
;with CoCs as (select uidCOT from chart5 with (nolock)
where (CAST(linternal AS BIGINT) & CAST(0x800 AS BIGINT)) > 0), --treatment plan
appts as (
select uidcot,clinic from chart5 with (nolock)
where CAST(linternal AS BIGINT) & CAST(0x800 AS BIGINT) = 0) -- any chart item that isn''t a treatment plan

select distinct a.uidCOT into #apptswithoutcoc from appts a where not exists (select null from CoCs c where a.uidcot = c.uidcot)
and LEN(a.uidcot) > 0
order by a.uidcot

DECLARE @newchartrec as varchar(25);
declare @newaudit as varchar(25);
DECLARE @siteID AS NUMERIC(10, 0);
DECLARE @createddate AS DATETIME;
DECLARE @createdtime AS DATETIME;
DECLARE @createdauditdate AS DATETIME;
DECLARE @createdaudittime AS DATETIME;
declare @curruid as varchar(25);
declare @clinic as varchar(64);
declare @provider as varchar(11);
declare @ridpatient as varchar(25);
declare @pvcode as varchar(11);
declare @uniquecode as numeric(10,0);

while ((select count(uidcot) from #apptswithoutcoc) > 0)
begin
set @curruid = (select top 1 uidcot from #apptswithoutcoc);
set @clinic = (select top 1 clinic from chart5 where uidcot = @curruid);
set @provider = (select top 1 provider from chart5 where uidcot = @curruid);
set @ridpatient = (select top 1 ridpatient from chart5 where uidcot = @curruid);
set @pvcode = (select top 1 pvcode from chart5 where uidcot = @curruid);
exec dbo.spTitanium_GetNextChartUnique  @ridpatient, @uniquecode output;

exec dbo.spSpark_GetNewRecordHeader ''CHART5'',@newchartrec output,@siteid output,@createddate output,@createdtime output;

insert into chart5
values(
@newchartrec,@siteid,
0,--deleted
0,--updatecount
@createddate,@createdtime,
@createddate,@createdtime,--updated date/time
0,--locid
@uniquecode,
null,--dtbooked
null, --dtcomplete
@createddate, --dtplanned
0,--numlines
'''',--service
0, --wgraphic
0,--wtn
0,--lsurface
2048,--linternal
0,--lcolour
''Course of Care '' + REPLACE(LTRIM(REPLACE(substring(@curruid,0,11),''0'','' '')),'' '',''0''), --usercomment
0,--cufee
0,--cuorigamount
0,--cupatientamount
0,--timetaken
0,--timeexpected
0,--wpricecode
'''','''','''','''','''','''','''','''','''','''',--extraservs 0-9
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,--xy_0-15
0,--lcommentnum
0,--lcot,
0,--wappointnnum
0,--wruleresults
0,--wfeeresults
null,--dtcachepayorfees
@provider,
0,--cucost
0,--wlocation
0,--wsupercode
@createddate,--dtfirstattendance
null,--dtedsprocessed
0,--ldatapointer
0,--wlinenum
0,--cufeegst
0,--cupatientgst
0,--wrepairstatus
0,--wdentatestate
0,--wsadscoctype 
0,--wriskstatus
16711680,--lplannedcolour
0,--wcount
'''',--adacode
null,--condition
0,--lattach
0,--lattachdata
0,--wtimecomplete
null,--sfee
0,--worder 
@clinic, 
@ridpatient, 
@pvcode, 
0,--cuscalefee
0,--cuscalepatientamt
0,--cuscalefeegst
0,--cuscalepatientgst
0,--wclassyear
0,--wstudentyear
0,--wcocprereopened
0,--winternal2
0,--ldhsvclaim
0,--lrecoupedclaim
null,--dtpaid
null,--dtauthorised
'''',--school
'''',--adhlaboperator
'''',--referralsource
0,--dquantity
'''',--ridparent
'''',--ridtrns
'''',--ridgoldrec
0,--lgoldrecptr
'''',--hospitalcode
0,--winpatient
0,--wemergencypatient
'''',--servicecode
'''',--cliniccode
'''',--eligibilitycatcode
0,--cusadsamount
0,--cuextpatamount
'''',--studentgrade
null,--dtgradechanged
'''',--tmgradechanged
'''',--providerchanged
0,--lgradingnote
'''',--ridwaitlist
'''',--ridadminssionlink
'''',--dhsvclinic
'''',--dhsvmdhtype
0,--dgrams
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,--f3d etc
0,--linvoicenotes
65535,--worder2
0,--bvisitcopay
null,--uidtoothdrawing
@clinic, --entryclinic
0,--leruptperm
0,--leruptdecid
'''',--ridratlink
'''',--referrer
null,--dtconsentgiven
'''',--ridgradechartinstance
'''',--apptcat
'''',--uidcomment
@curruid,
'''',--uidattach
'''',--uiddhsvclaim
'''',--uidgradingnote
'''',--uidinvoicenotes
'''',--ridtrackingorder
'''',--ridstocktrans
null,--cuwhicsmemberbenefit
'''',--stocklink
0,--wtimechargeapproved
'''',--closingapprover
null,--dtclosingapproved
0,--utimeclosingapproved
'''',--treatmentapprover
null,--dttreatmentapproved
0,--utimetreatmentapproved
null,--dtcharged
'''',--easyclaimtransactionid
'''',--medicareclaimingdentist
0,--lexfoldecid
'''',--medicareitemcode
0,--bapproved
0,--cuvoucherlimit
'''',--ridvoucherbudget
''00000000-0000-0000-0000-000000000000'',--guidattach
'''',--premedicarepayorcode
'''',--uidlinkedapptid
null,--dtvoided
'''',--uservoided
null,--refprovider
null,--dtreferraldate
'''',--servicingprovider
0,--cuhfundmemberbenefit
'''',--healthfundid
'''',--healthfundtransactionid
'''',--uidreportnotes
0,--medicareitemclaim
0,--bretreatment
null --eformcode
)



print ''added COC '' + REPLACE(LTRIM(REPLACE(substring(@curruid,0,11),''0'','' '')),'' '',''0'') + '' for patient '' + @ridpatient + '' with unique '' + cast(@uniquecode as varchar)

exec dbo.spSpark_GetNewRecordHeader ''AUDITEVT2'',@newaudit output,@siteid output,@createdauditdate output,@createdaudittime output;
insert into AUDITEVT2
values(
@newaudit,@siteid
,0 --deleted
,0 --updatecount
,@createdauditdate
,@createdaudittime
,@createdauditdate
,@createdaudittime
,0--[LocID]
,@createdauditdate--[dtAudit]
,(cast(FORMAT(GETDATE(), ''HH'') as int) * 60) + cast(FORMAT(GETDATE(), ''mm'') as int) --titanium time, amirite
,''ADMIN'' --usercode
,''CoC '' + REPLACE(LTRIM(REPLACE(substring(@curruid,0,11),''0'','' '')),'' '',''0'') + '' fixed by script'' --description
,@ridpatient
,3--[wType] (add treatment)
,4--[wAction] (add CoC)
,left((select lastname + '', '' + firstname + '', '' + title from debtor4 where recordnum = @ridpatient),40) --name, truncated to make sure it''s not too long
,''VIRTAPP1-MDB004''--[computername]
,@provider--[provider]
,@createddate--[dtTreatmentDate]
,''''--[treatmentcode]
,@clinic--[location]
,''''--[uidNotes]
,''''--[uidNotesPrevious]
)
print ''added audit record '' + @newaudit
	
delete from #apptswithoutcoc where uidCOT = @curruid

end
drop table #apptswithoutcoc
print ''Done!''
commit tran --change to commit
end try
begin catch
print ''an error occurred, the transaction will be rolled back''
 DECLARE
   @ErMessage NVARCHAR(2048),
   @ErSeverity INT,
   @ErState INT
 
 SELECT
   @ErMessage = ERROR_MESSAGE(),
   @ErSeverity = ERROR_SEVERITY(),
   @ErState = ERROR_STATE()
 
 RAISERROR (@ErMessage,
             @ErSeverity,
             @ErState )
rollback tran
end catch', 
		@database_name=N'Titanium_WNSW_prod', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Weekdays at 1:30pm', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=62, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20180720, 
		@active_end_date=99991231, 
		@active_start_time=133000, 
		@active_end_time=235959, 
		@schedule_uid=N'ba3df1b0-ec08-417a-9015-c3db393a9dd2'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Weekdays at 5:00pm', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=54, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20180720, 
		@active_end_date=99991231, 
		@active_start_time=170000, 
		@active_end_time=235959, 
		@schedule_uid=N'3049e598-a933-441e-9113-ee376ad03607'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


