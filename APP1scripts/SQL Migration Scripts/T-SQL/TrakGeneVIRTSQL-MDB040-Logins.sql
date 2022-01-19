/* sp_help_revlogin script 
** Generated Oct 13 2021 10:45AM on VIRTSQL-MDB040 */
 
-- Login: NSWHEALTH\ADM_60128477
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'NSWHEALTH\ADM_60128477')
                  BEGIN
CREATE LOGIN [NSWHEALTH\ADM_60128477] FROM WINDOWS WITH DEFAULT_DATABASE = [master]

          exec master.dbo.sp_addsrvrolemember @loginame='NSWHEALTH\ADM_60128477', @rolename='sysadmin'
END
 
-- Login: NSWHEALTH\adm_60135702
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'NSWHEALTH\adm_60135702')
                  BEGIN
CREATE LOGIN [NSWHEALTH\adm_60135702] FROM WINDOWS WITH DEFAULT_DATABASE = [master]

          exec master.dbo.sp_addsrvrolemember @loginame='NSWHEALTH\adm_60135702', @rolename='setupadmin'
		  exec master.dbo.sp_addsrvrolemember @loginame='NSWHEALTH\adm_60135702', @rolename='processadmin'
END
 
-- Login: NSWHEALTH\adm_60147731
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'NSWHEALTH\adm_60147731')
                  BEGIN
CREATE LOGIN [NSWHEALTH\adm_60147731] FROM WINDOWS WITH DEFAULT_DATABASE = [master]

          exec master.dbo.sp_addsrvrolemember @loginame='NSWHEALTH\adm_60147731', @rolename='setupadmin'
		  exec master.dbo.sp_addsrvrolemember @loginame='NSWHEALTH\adm_60147731', @rolename='processadmin'
END
 
-- Login: NSWHEALTH\L-NSWH-SD-SQL-DatabaseTeamAccess
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'NSWHEALTH\L-NSWH-SD-SQL-DatabaseTeamAccess')
                  BEGIN
CREATE LOGIN [NSWHEALTH\L-NSWH-SD-SQL-DatabaseTeamAccess] FROM WINDOWS WITH DEFAULT_DATABASE = [master]

          exec master.dbo.sp_addsrvrolemember @loginame='NSWHEALTH\L-NSWH-SD-SQL-DatabaseTeamAccess', @rolename='setupadmin'
		  exec master.dbo.sp_addsrvrolemember @loginame='NSWHEALTH\L-NSWH-SD-SQL-DatabaseTeamAccess', @rolename='processadmin'
END
 
-- Login: NSWHEALTH\L-SRES-TrakGeneAdminUsers
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'NSWHEALTH\L-SRES-TrakGeneAdminUsers')
                  BEGIN
CREATE LOGIN [NSWHEALTH\L-SRES-TrakGeneAdminUsers] FROM WINDOWS WITH DEFAULT_DATABASE = [master]

          exec master.dbo.sp_addsrvrolemember @loginame='NSWHEALTH\L-SRES-TrakGeneAdminUsers', @rolename='bulkadmin'
END
 
-- Login: NSWHEALTH\L-SRES-TrakGeneProdUsers
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'NSWHEALTH\L-SRES-TrakGeneProdUsers')
                  BEGIN
CREATE LOGIN [NSWHEALTH\L-SRES-TrakGeneProdUsers] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
END
 
-- Login: NSWHEALTH\L-SRES-TrakGeneTestUsers
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'NSWHEALTH\L-SRES-TrakGeneTestUsers')
                  BEGIN
CREATE LOGIN [NSWHEALTH\L-SRES-TrakGeneTestUsers] FROM WINDOWS WITH DEFAULT_DATABASE = [master]

          exec master.dbo.sp_addsrvrolemember @loginame='NSWHEALTH\L-SRES-TrakGeneTestUsers', @rolename='bulkadmin'
END
 
-- Login: NSWHEALTH\L-STA-HIaaSLocalDBAadmins
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'NSWHEALTH\L-STA-HIaaSLocalDBAadmins')
                  BEGIN
CREATE LOGIN [NSWHEALTH\L-STA-HIaaSLocalDBAadmins] FROM WINDOWS WITH DEFAULT_DATABASE = [master]

          exec master.dbo.sp_addsrvrolemember @loginame='NSWHEALTH\L-STA-HIaaSLocalDBAadmins', @rolename='setupadmin'
		  exec master.dbo.sp_addsrvrolemember @loginame='NSWHEALTH\L-STA-HIaaSLocalDBAadmins', @rolename='processadmin'
END
 
-- Login: NSWHEALTH\SRV-NSWH-Solarwinds
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'NSWHEALTH\SRV-NSWH-Solarwinds')
                  BEGIN
CREATE LOGIN [NSWHEALTH\SRV-NSWH-Solarwinds] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
END
 
-- Login: NSWHEALTH\SRV-NSWH-TrakGeneClu
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'NSWHEALTH\SRV-NSWH-TrakGeneClu')
                  BEGIN
CREATE LOGIN [NSWHEALTH\SRV-NSWH-TrakGeneClu] FROM WINDOWS WITH DEFAULT_DATABASE = [master]

          exec master.dbo.sp_addsrvrolemember @loginame='NSWHEALTH\SRV-NSWH-TrakGeneClu', @rolename='setupadmin'
		  exec master.dbo.sp_addsrvrolemember @loginame='NSWHEALTH\SRV-NSWH-TrakGeneClu', @rolename='processadmin'
END
 
-- Login: NSWHEALTH\U-SRES-TrakGenePowerUsers
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'NSWHEALTH\U-SRES-TrakGenePowerUsers')
                  BEGIN
CREATE LOGIN [NSWHEALTH\U-SRES-TrakGenePowerUsers] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
END


