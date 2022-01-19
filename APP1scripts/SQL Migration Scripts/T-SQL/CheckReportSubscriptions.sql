USE ReportServer

SELECT
	cat.Name,
	cat.Path,
	sub.Description,
	sch.ScheduleID AS AgentJobID,
	sch.LastRunTime,
	'EXEC msdb.dbo.sp_start_job N''' + CAST(sch.ScheduleID as nvarchar(36)) + ''';' AS StartJob,
	'EXEC msdb.dbo.sp_update_job @job_name = N''' + CAST(sch.ScheduleID as nvarchar(36)) + ''', @enabled = 1 ;' AS EnableJob,
	'EXEC msdb.dbo.sp_update_job @job_name = N''' + CAST(sch.ScheduleID as nvarchar(36)) + ''', @enabled = 0 ;' AS DisableJob
FROM
	dbo.Schedule sch
INNER JOIN
	dbo.ReportSchedule rsch
ON sch.ScheduleID = rsch.ScheduleID
INNER JOIN
	dbo.Catalog cat
ON rsch.ReportID = cat.ItemID
INNER JOIN
	dbo.Subscriptions sub
ON rsch.SubscriptionID = sub.SubscriptionID