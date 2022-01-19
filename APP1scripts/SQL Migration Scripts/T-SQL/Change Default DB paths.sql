USE [master]

GO

 

— Change default location for data files

EXEC   xp_instance_regwrite

       N'HKEY_LOCAL_MACHINE',

       N'Software\Microsoft\MSSQLServer\MSSQLServer',

       N'DefaultData',

       REG_SZ,

       N'C:\MSSQL\Data'

GO

 

— Change default location for log files

EXEC   xp_instance_regwrite

       N'HKEY_LOCAL_MACHINE',

       N'Software\Microsoft\MSSQLServer\MSSQLServer',

       N'DefaultLog',

       REG_SZ,

       N'C:\MSSQL\Logs'

GO

 

— Change default location for backups

EXEC   xp_instance_regwrite

       N'HKEY_LOCAL_MACHINE',

       N'Software\Microsoft\MSSQLServer\MSSQLServer',

       N'BackupDirectory',

       REG_SZ,

       N'C:\MSSQL\Backups'

GO