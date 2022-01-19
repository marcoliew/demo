exec msdb.dbo.rds_restore_database 
	@restore_db_name='STAGING_Titanium', 
	@s3_arn_to_restore_from='arn:aws:s3:::sqlnativebackups/StagingforPOC.bak';

exec msdb.dbo.rds_backup_database 
@source_db_name='DBADB', @s3_arn_to_backup_to='arn:aws:s3:::nswh-provider-ap-southeast-2-inf-497427545767/SQL_POC/DBADB.bak', 
@overwrite_S3_backup_file=1;


exec msdb.dbo.rds_backup_database 
@source_db_name='STAGING_Titanium', 
@s3_arn_to_backup_to='arn:aws:s3:::nswh-provider-ap-southeast-2-inf-497427545767/SQL_POC/Staging_Titanium.bak', 
@overwrite_S3_backup_file=1;

exec msdb.dbo.rds_restore_database 
	@restore_db_name='STAGING_REST', 
	@s3_arn_to_restore_from='arn:aws:s3:::nswh-provider-ap-southeast-2-inf-497427545767/SQL_POC/StagingforPOC.bak'