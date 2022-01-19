USE [master]
GO

GRANT VIEW SERVER STATE TO [NSWHEALTH\NSWH-Titanium86-NonProd-AWS-TEST-Administrators];
GRANT VIEW ANY DEFINITION TO [NSWHEALTH\NSWH-Titanium86-NonProd-AWS-TEST-Administrators];

GRANT CREATE ANY DATABASE TO [NSWHEALTH\NSWH-Titanium86-NonProd-AWS-TEST-Administrators] WITH GRANT OPTION;
GRANT VIEW ANY DATABASE TO [NSWHEALTH\NSWH-Titanium86-NonProd-AWS-TEST-Administrators] WITH GRANT OPTION;

ALTER SERVER ROLE processadmin ADD MEMBER [NSWHEALTH\NSWH-Titanium86-NonProd-AWS-TEST-Administrators];
GRANT VIEW ANY DATABASE TO [NSWHEALTH\NSWH-Titanium86-NonProd-AWS-TEST-Administrators];
GRANT VIEW ANY definition to [NSWHEALTH\NSWH-Titanium86-NonProd-AWS-TEST-Administrators];
GRANT VIEW server state to [NSWHEALTH\NSWH-Titanium86-NonProd-AWS-TEST-Administrators];

GRANT ALTER TRACE TO [NSWHEALTH\NSWH-Titanium86-NonProd-AWS-TEST-Administrators];

USE [msdb]
GO

CREATE USER [NSWHEALTH\NSWH-Titanium86-NonProd-AWS-TEST-Administrators] FOR LOGIN [NSWHEALTH\NSWH-Titanium86-NonProd-AWS-TEST-Administrators];
GO

GRANT EXECUTE ON msdb.dbo.rds_backup_database TO [NSWHEALTH\NSWH-Titanium86-NonProd-AWS-TEST-Administrators];
GRANT EXECUTE ON msdb.dbo.rds_restore_database TO [NSWHEALTH\NSWH-Titanium86-NonProd-AWS-TEST-Administrators];
GRANT EXECUTE ON msdb.dbo.rds_task_status TO [NSWHEALTH\NSWH-Titanium86-NonProd-AWS-TEST-Administrators];
GRANT EXECUTE ON msdb.dbo.rds_cancel_task TO [NSWHEALTH\NSWH-Titanium86-NonProd-AWS-TEST-Administrators];

GRANT SELECT ON dbo.sysjobs TO [NSWHEALTH\NSWH-Titanium86-NonProd-AWS-TEST-Administrators];
GRANT SELECT ON dbo.sysjobhistory TO [NSWHEALTH\NSWH-Titanium86-NonProd-AWS-TEST-Administrators];
GRANT SELECT ON msdb.dbo.sysjobactivity TO [NSWHEALTH\NSWH-Titanium86-NonProd-AWS-TEST-Administrators];

go
