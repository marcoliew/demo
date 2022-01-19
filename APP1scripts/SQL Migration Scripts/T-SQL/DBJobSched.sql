USE msdb ;  
GO  
-- creates a schedule named DailyIndexOptimise.   
-- Jobs that use this schedule execute every day when the time on the server is 00:00.   
EXEC sp_add_schedule  
    @schedule_name = N'DailyIndexOptimize' ,  
    @freq_type = 4,  
    @freq_interval = 1, 
	@freq_recurrence_factor=1, 
    @active_start_time =  000000 ;  
GO  
-- attaches the schedule to the job IndexOptimise 
EXEC sp_attach_schedule  
   @job_name = N'DBMaint-IndexOptimize',  
   @schedule_name = N'DailyIndexOptimize' ;  
GO  

 -- creates a schedule named MonthlyCleanUp.   
-- Jobs that use this schedule execute every day when the time on the server is 04:00.   
EXEC sp_add_schedule  
    @schedule_name = N'MonthlyCleanUp' ,  
    @freq_type = 8,  
    @freq_interval = 0x1, 
	@freq_recurrence_factor=1,
	@freq_relative_interval=0x1,
    @active_start_time =  040000 ;  
GO  
-- attaches the schedule to the job DBmaintCleanup 
EXEC sp_attach_schedule  
   @job_name = N'DBMaint-CleanUp',  
   @schedule_name = N'MonthlyCleanUp' ;  
GO  
-- creates a schedule named WeeklyDBCC.   
-- Jobs that use this schedule execute every day when the time on the server is 03:00.   
EXEC sp_add_schedule  
    @schedule_name = N'WeeklyDBCC' ,  
    @freq_type = 8,  
    @freq_interval = 1, 
	@freq_recurrence_factor=1, 
    @active_start_time =  030000 ;  
GO  
-- attaches the schedule to the job DBMaint-IntegrityCheck  
EXEC sp_attach_schedule  
   @job_name = N'DBMaint-IntegrityCheck',  
   @schedule_name = N'WeeklyDBCC' ;  
GO  