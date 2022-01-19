Use master
GO

SELECT 
name AS [LogicalName]
,physical_name AS [Location]
,state_desc AS [Status]
FROM sys.master_files
WHERE database_id = DB_ID(N'tempdb');
GO

USE master;
GO

ALTER DATABASE tempdb 
MODIFY FILE (NAME = tempdev, FILENAME = 'F:\SQLTEMPDB\tempdb.mdf');
GO
ALTER DATABASE tempdb 
MODIFY FILE (NAME = temp2, FILENAME = 'F:\SQLTEMPDB\tempdb_mssql2.ndf');
GO
ALTER DATABASE tempdb 
MODIFY FILE (NAME = templog, FILENAME = 'F:\SQLTEMPDB\templog.ldf');
GO

ALTER DATABASE tempdb MODIFY FILE ( NAME = N'tempdev', SIZE = 8MB, FILEGROWTH = 10%)
ALTER DATABASE tempdb MODIFY FILE ( NAME = N'temp2', SIZE = 8MB, FILEGROWTH = 10%)
ALTER DATABASE tempdb ADD FILE ( NAME = N'temp3', FILENAME = N'F:\SQLTEMPDB\tempdb_mssql_3.ndf' , SIZE = 8MB , FILEGROWTH = 10%)
ALTER DATABASE tempdb ADD FILE ( NAME = N'temp4', FILENAME = N'F:\SQLTEMPDB\tempdb_mssql_4.ndf' , SIZE = 8MB , FILEGROWTH = 10%)
ALTER DATABASE tempdb ADD FILE ( NAME = N'temp5', FILENAME = N'F:\SQLTEMPDB\tempdb_mssql_5.ndf' , SIZE = 8MB , FILEGROWTH = 10%) 
ALTER DATABASE tempdb ADD FILE ( NAME = N'temp6', FILENAME = N'F:\SQLTEMPDB\tempdb_mssql_6.ndf' , SIZE = 8MB , FILEGROWTH = 10%)
ALTER DATABASE tempdb ADD FILE ( NAME = N'temp7', FILENAME = N'F:\SQLTEMPDB\tempdb_mssql_7.ndf' , SIZE = 8MB , FILEGROWTH = 10%)
ALTER DATABASE tempdb ADD FILE ( NAME = N'temp8', FILENAME = N'F:\SQLTEMPDB\tempdb_mssql_8.ndf' , SIZE = 8MB , FILEGROWTH = 10%) 