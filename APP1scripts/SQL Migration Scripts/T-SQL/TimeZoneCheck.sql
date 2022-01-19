select current_timestamp; -- date and time, standard ANSI SQL so compatible across DBs
select getdate();  -- date and time, specific to SQL Server
select getutcdate(); -- returns UTC timestamp
select sysdatetime(); -- returns 7 digits of precision

SELECT 
    SYSDATETIMEOFFSET() AS 'System Date Time Offset', 
    FORMAT(SYSDATETIMEOFFSET(), 'zz') AS 'zz', 
    FORMAT(SYSDATETIMEOFFSET(), 'zzz') AS 'zzz';