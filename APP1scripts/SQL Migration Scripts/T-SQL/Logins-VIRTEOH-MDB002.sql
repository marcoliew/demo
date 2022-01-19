/* sp_help_revlogin script 
** Generated Sep 28 2021  9:24AM on VIRTAPP1-MDB002 */
 
 
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

-- Login: NSWHEALTH\SRV-NSWH-Solarwinds
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'NSWHEALTH\SRV-NSWH-Solarwinds')
                  BEGIN
CREATE LOGIN [NSWHEALTH\SRV-NSWH-Solarwinds] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
END
 
-- Login: NSWHEALTH\SRV-WSYD-Titanium
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'NSWHEALTH\SRV-WSYD-Titanium')
                  BEGIN
CREATE LOGIN [NSWHEALTH\SRV-WSYD-Titanium] FROM WINDOWS WITH DEFAULT_DATABASE = [master]

          exec master.dbo.sp_addsrvrolemember @loginame='NSWHEALTH\SRV-WSYD-Titanium',@rolename='setupadmin'
		  exec master.dbo.sp_addsrvrolemember @loginame='NSWHEALTH\SRV-WSYD-Titanium',@rolename='processadmin'
END

-- Login: nswhealth\app1-poc-NSWH-aws-Administrators
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'nswhealth\app1-poc-NSWH-aws-Administrators')
                  BEGIN
CREATE LOGIN [nswhealth\app1-poc-NSWH-aws-Administrators] FROM WINDOWS WITH DEFAULT_DATABASE = [master]

          exec master.dbo.sp_addsrvrolemember @loginame='nswhealth\app1-poc-NSWH-aws-Administrators',@rolename='setupadmin'
		  exec master.dbo.sp_addsrvrolemember @loginame='nswhealth\app1-poc-NSWH-aws-Administrators',@rolename='processadmin'
END








