/* sp_help_revlogin script 
** Generated Oct 18 2021  1:55PM on VIRTAPP1-MDB005 */
  
-- Login: NSWHEALTH\adm_20006027
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'NSWHEALTH\adm_20006027')
                  BEGIN
CREATE LOGIN [NSWHEALTH\adm_20006027] FROM WINDOWS WITH DEFAULT_DATABASE = [master]

          exec master.dbo.sp_addsrvrolemember @loginame='NSWHEALTH\adm_20006027', @rolename='setupadmin'
          exec master.dbo.sp_addsrvrolemember @loginame='NSWHEALTH\adm_20006027', @rolename='processadmin'
          
END
 
-- Login: NSWHEALTH\adm_56008960
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'NSWHEALTH\adm_56008960')
                  BEGIN
CREATE LOGIN [NSWHEALTH\adm_56008960] FROM WINDOWS WITH DEFAULT_DATABASE = [master]

          exec master.dbo.sp_addsrvrolemember @loginame='NSWHEALTH\adm_56008960', @rolename='setupadmin'
          exec master.dbo.sp_addsrvrolemember @loginame='NSWHEALTH\adm_56008960', @rolename='processadmin'
END
 
-- Login: NSWHEALTH\adm_60036595
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'NSWHEALTH\adm_60036595')
                  BEGIN
CREATE LOGIN [NSWHEALTH\adm_60036595] FROM WINDOWS WITH DEFAULT_DATABASE = [Titanium_WS_train]
 
END
 
-- Login: NSWHEALTH\adm_60090721
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'NSWHEALTH\adm_60090721')
                  BEGIN
CREATE LOGIN [NSWHEALTH\adm_60090721] FROM WINDOWS WITH DEFAULT_DATABASE = [master]

          exec master.dbo.sp_addsrvrolemember @loginame='NSWHEALTH\adm_60090721', @rolename='setupadmin'
          exec master.dbo.sp_addsrvrolemember @loginame='NSWHEALTH\adm_60090721', @rolename='processadmin'
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
 
-- Login: NSWHEALTH\U-STA-HIaaSLocalDBAadmins
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'NSWHEALTH\U-STA-HIaaSLocalDBAadmins')
                  BEGIN
CREATE LOGIN [NSWHEALTH\U-STA-HIaaSLocalDBAadmins] FROM WINDOWS WITH DEFAULT_DATABASE = [master]

          exec master.dbo.sp_addsrvrolemember @loginame='NSWHEALTH\U-STA-HIaaSLocalDBAadmins', @rolename='sysadmin'
		  exec master.dbo.sp_addsrvrolemember @loginame='NSWHEALTH\U-STA-HIaaSLocalDBAadmins', @rolename='processadmin'
END
 
-- Login: NT AUTHORITY\SYSTEM
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'NT AUTHORITY\SYSTEM')
                  BEGIN
CREATE LOGIN [NT AUTHORITY\SYSTEM] FROM WINDOWS WITH DEFAULT_DATABASE = [master]

          exec master.dbo.sp_addsrvrolemember @loginame='NT AUTHORITY\SYSTEM', @rolename='setupadmin'
		  exec master.dbo.sp_addsrvrolemember @loginame='NT AUTHORITY\SYSTEM', @rolename='processadmin'
END
 
 
-- Login: branch2_powerbi
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'branch2_powerbi')
                  BEGIN
CREATE LOGIN [branch2_powerbi] WITH PASSWORD = 0x0200E1041D583A874FF7FCC94E127B4CA27F7826B6FFBF6FAD74633CB69A2274BE81475CFDC61C48268DC19369AEFEDC2ABC7AF8331C849886A68704974231D9B785F9F093DC HASHED, SID = 0x20F05B5EBA84224A8C2D0DDA5E0F46B6, DEFAULT_DATABASE = [master], CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF
 
END
