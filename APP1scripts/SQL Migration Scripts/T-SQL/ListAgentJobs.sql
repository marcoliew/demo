use msdb
go

select distinct name, database_name
from sysjobs sj
INNER JOIN sysjobsteps sjt on sj.job_id = sjt.job_id
where database_name='TrakGeneProd'