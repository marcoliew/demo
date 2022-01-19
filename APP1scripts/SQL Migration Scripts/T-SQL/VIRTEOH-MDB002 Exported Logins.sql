/* sp_help_revlogin script 
** Generated Dec  1 2021  9:44AM on VIRTAPP1-MDB002 */
 
 
 
-- Login: HEALTHTECH\GS-ADM-TSS Database Support Group
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'HEALTHTECH\GS-ADM-TSS Database Support Group')
                  BEGIN
CREATE LOGIN [HEALTHTECH\GS-ADM-TSS Database Support Group] FROM WINDOWS WITH DEFAULT_DATABASE = [master]

          exec master.dbo.sp_addsrvrolemember @loginame='HEALTHTECH\GS-ADM-TSS Database Support Group', @rolename='setupadmin'
		  exec master.dbo.sp_addsrvrolemember @loginame='HEALTHTECH\GS-ADM-TSS Database Support Group', @rolename='processadmin'
END
 
-- Login: HEALTHTECH\LS-RL-HSS-SQL Servers Administrators
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'HEALTHTECH\LS-RL-HSS-SQL Servers Administrators')
                  BEGIN
CREATE LOGIN [HEALTHTECH\LS-RL-HSS-SQL Servers Administrators] FROM WINDOWS WITH DEFAULT_DATABASE = [master]

          exec master.dbo.sp_addsrvrolemember @loginame='HEALTHTECH\LS-RL-HSS-SQL Servers Administrators', @rolename='setupadmin'
		  exec master.dbo.sp_addsrvrolemember @loginame='HEALTHTECH\LS-RL-HSS-SQL Servers Administrators', @rolename='processadmin'
END
 
-- Login: HEALTHTECH\TSS DBA
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'HEALTHTECH\TSS DBA')
                  BEGIN
CREATE LOGIN [HEALTHTECH\TSS DBA] FROM WINDOWS WITH DEFAULT_DATABASE = [master]

          exec master.dbo.sp_addsrvrolemember @loginame='HEALTHTECH\TSS DBA', @rolename='setupadmin'
		   exec master.dbo.sp_addsrvrolemember @loginame='HEALTHTECH\TSS DBA', @rolename='processadmin'
END
 
-- Login: NSWHEALTH\G-EHLH-ADM-IS-DBA
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'NSWHEALTH\G-EHLH-ADM-IS-DBA')
                  BEGIN
CREATE LOGIN [NSWHEALTH\G-EHLH-ADM-IS-DBA] FROM WINDOWS WITH DEFAULT_DATABASE = [master]

          exec master.dbo.sp_addsrvrolemember @loginame='NSWHEALTH\G-EHLH-ADM-IS-DBA', @rolename='setupadmin'
		   exec master.dbo.sp_addsrvrolemember @loginame='NSWHEALTH\G-EHLH-ADM-IS-DBA', @rolename='processadmin'
END
 
-- Login: NSWHEALTH\G-MHLH-COHS-OHIS-DBADMIN
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'NSWHEALTH\G-MHLH-COHS-OHIS-DBADMIN')
                  BEGIN
CREATE LOGIN [NSWHEALTH\G-MHLH-COHS-OHIS-DBADMIN] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
END
 
-- Login: NSWHEALTH\G-NSWH-Oral Health Vendor Administrators
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'NSWHEALTH\G-NSWH-Oral Health Vendor Administrators')
                  BEGIN
CREATE LOGIN [NSWHEALTH\G-NSWH-Oral Health Vendor Administrators] FROM WINDOWS WITH DEFAULT_DATABASE = [master]

          exec master.dbo.sp_addsrvrolemember @loginame='NSWHEALTH\G-NSWH-Oral Health Vendor Administrators', @rolename='setupadmin'
		  exec master.dbo.sp_addsrvrolemember @loginame='NSWHEALTH\G-NSWH-Oral Health Vendor Administrators', @rolename='processadmin'
END
 
-- Login: NSWHEALTH\L-NSWH-Oral Health FWLHD SRSS Admin
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'NSWHEALTH\L-NSWH-Oral Health FWLHD SRSS Admin')
                  BEGIN
CREATE LOGIN [NSWHEALTH\L-NSWH-Oral Health FWLHD SRSS Admin] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
END
 
-- Login: NSWHEALTH\L-NSWH-Oral Health M-SNSWLHD SRSS Admin
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'NSWHEALTH\L-NSWH-Oral Health M-SNSWLHD SRSS Admin')
                  BEGIN
CREATE LOGIN [NSWHEALTH\L-NSWH-Oral Health M-SNSWLHD SRSS Admin] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
END
 
-- Login: NSWHEALTH\L-NSWH-Oral Health branch1 SRSS Admin
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'NSWHEALTH\L-NSWH-Oral Health branch1 SRSS Admin')
                  BEGIN
CREATE LOGIN [NSWHEALTH\L-NSWH-Oral Health branch1 SRSS Admin] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
END
 
-- Login: NSWHEALTH\L-NSWH-SD-SQL-DatabaseTeamAccess
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'NSWHEALTH\L-NSWH-SD-SQL-DatabaseTeamAccess')
                  BEGIN
CREATE LOGIN [NSWHEALTH\L-NSWH-SD-SQL-DatabaseTeamAccess] FROM WINDOWS WITH DEFAULT_DATABASE = [master]

          exec master.dbo.sp_addsrvrolemember @loginame='NSWHEALTH\L-NSWH-SD-SQL-DatabaseTeamAccess', @rolename='setupadmin'
		  exec master.dbo.sp_addsrvrolemember @loginame='NSWHEALTH\L-NSWH-SD-SQL-DatabaseTeamAccess', @rolename='processadmin'
END
 
-- Login: NSWHEALTH\SRV-NSWH-Solarwinds
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'NSWHEALTH\SRV-NSWH-Solarwinds')
                  BEGIN
CREATE LOGIN [NSWHEALTH\SRV-NSWH-Solarwinds] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
END
 
-- Login: NSWHEALTH\SRV-WSYD-Titanium
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'NSWHEALTH\SRV-WSYD-Titanium')
                  BEGIN
CREATE LOGIN [NSWHEALTH\SRV-WSYD-Titanium] FROM WINDOWS WITH DEFAULT_DATABASE = [master]

          exec master.dbo.sp_addsrvrolemember @loginame='NSWHEALTH\SRV-WSYD-Titanium', @rolename='setupadmin'
		   exec master.dbo.sp_addsrvrolemember @loginame='NSWHEALTH\SRV-WSYD-Titanium', @rolename='processadmin'
END
 

 
