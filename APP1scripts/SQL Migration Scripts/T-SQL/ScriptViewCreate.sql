DECLARE @definition varchar(max)
DECLARE @view CURSOR
SET @view = CURSOR FOR
SELECT m.definition FROM sys.views v INNER JOIN sys.sql_modules m ON m.object_id = v.object_id
OPEN @view
FETCH NEXT FROM @view INTO @definition
WHILE @@FETCH_STATUS = 0 BEGIN
    PRINT @definition
    PRINT 'GO'
    FETCH NEXT FROM @view INTO @definition
END CLOSE @view DEALLOCATE @view

DECLARE @definition varchar(max)
SELECT m.definition FROM sys.views