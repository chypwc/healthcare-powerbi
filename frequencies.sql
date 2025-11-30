-- select * from ClinicalData;

-- select * from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME like 'ClinicalData';

------------------------------------------
-- Count Frequencies to get distribution
-------------------------------------------
declare @tableName nvarchar(30) = 'ClinicalData';

declare @i int = 1;
declare @sql nvarchar(max);
declare @n int;
set @n = (select max(ordinal_position) from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME like 'ClinicalData');

declare @columnName varchar(max);

while @i <= @n
begin
	set @columnName = (select column_name from INFORMATION_SCHEMA.COLUMNS 
					where TABLE_NAME like 'ClinicalData' and ORDINAL_POSITION = @i);

	set @sql = 'select ' + @columnName + ', count(*) as [Frequency] 
				from ' + @tableName + ' group by ' + @columnName + ' order by count(*) desc';

	exec sp_executesql @sql;

	set @i = @i + 1;
end;

--------------
declare @tableName nvarchar(30) = 'ClinicalData';
declare @columnName varchar(max) = 'Department';
declare @sql nvarchar(max);

set @sql = 'select ' + @columnName + ', count(*) as [Frequency] 
			from ' + @tableName + ' group by ' + @columnName + ' order by count(*) desc';

exec sp_executesql @sql;