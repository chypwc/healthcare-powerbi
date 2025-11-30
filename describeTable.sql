-- Replace table name 
-- select * from ClinicalData

select * from INFORMATION_SCHEMA.columns where TABLE_NAME like 'ClinicalData'

-- Drop if it already exists
drop table if exists #1;

select column_name, ordinal_position, data_type, character_maximum_length
into #1
from INFORMATION_SCHEMA.columns where  TABLE_NAME like 'ClinicalData'

select * from #1

alter table #1 add maximum nvarchar(max)
alter table #1 add minimum nvarchar(max)
alter table #1 add nulls int
alter table #1 add distinct_count int
alter table #1 add mean float
alter table #1 add median float
alter table #1 add mode nvarchar(max)
alter table #1 add SD float
alter table #1 add Zero_Values int


--------------------------------------
declare @tableName nvarchar(max) = 'ClinicalData';

declare @i int = 1;
declare @n int;

set @n = (select max(ordinal_position) from #1) -- number of fields / columns

declare @columnName nvarchar(max)
declare @dataType nvarchar(max)

declare @sql nvarchar(max) -- sql query string

while @i <= @n
begin
	
	select @columnName = COLUMN_NAME, @dataType = DATA_TYPE from #1 where ORDINAL_POSITION = @i;

	-- Handle numeric columns
	if @dataType in ('int', 'float', 'real', 'decimal', 'numeric', 'money', 'smallint', 'tinyint')
	begin
		-- maximum
		set @sql = 'update #1 set maximum = (select max(' + quotename(@columnName) 
											+ ') from ' + quotename(@tableName) + ') '
				+ 'where ORDINAL_POSITION = ' + cast(@i as varchar(max));
		exec sp_executesql @sql;

		-- minimum
		set @sql = 'update #1 set minimum = (select min(' + quotename(@columnName) 
											+ ') from ' + quotename(@tableName) + ') '
				+ 'where ORDINAL_POSITION = ' + cast(@i as varchar(max));
		exec sp_executesql @sql;

		-- mean
		set @sql = 'update #1 set mean = (select avg(cast(' + quotename(@columnName) + '  as decimal(18,2)))
										from ' + quotename(@tableName) + ') '
				+ 'where ORDINAL_POSITION = ' + cast(@i as varchar(max));
		exec sp_executesql @sql;

		-- Standard Deviation
		set @sql = 'update #1 set SD = (select stdev(' + quotename(@columnName) 
									+ ') from ' + quotename(@tableName) + ') '
				+ 'where ORDINAL_POSITION = ' + cast(@i as varchar(max));
		exec sp_executesql @sql;

		-- Zero Count
		set @sql = 'update #1 set Zero_Values = (select count(*) from ' + quotename(@tableName) 
											+ ' where ' + quotename(@columnName) + ' = 0 ) '
				+ 'where ORDINAL_POSITION = ' + cast(@i as varchar(max));
		exec sp_executesql @sql;

		-- Nulls (null count)
		set @sql = 'update #1 set nulls = (select count(*) from ' + quotename(@tableName)
										+ ' where ' + quotename(@columnName) + ' is null ) '
				+ 'where ORDINAL_POSITION = ' + cast(@i as varchar(max));
		exec sp_executesql @sql;

		-- Distinct Count
		set @sql = 'update #1 set distinct_count = (select count(distinct ' + quotename(@columnName) 
										+ ') from ' + quotename(@tableName) + ') '
				+ 'where ORDINAL_POSITION = ' + cast(@i as varchar(max));
		exec sp_executesql @sql;

		-- mode
		set @sql = 'update #1 set mode = (
				select string_agg(' + quotename(@columnName) + ', '','') as mode
				from (
					select ' + quotename(@columnName) + ',
						   dense_rank() over(order by [countAll] desc) as DenseRank
					from (
						select ' + quotename(@columnName) + ', count(*) as [countAll] 
						from ' + quotename(@tableName) + '
						group by ' + quotename(@columnName) + '
					) as x
				) as y
				where DenseRank = 1
				) where ORDINAL_POSITION = ' + cast(@i as varchar(max)) + ';';
		
		exec sp_executesql @sql; 

		-- median
		
		set @sql = '
			select ' + quotename(@columnName) + ',
			   ROW_NUMBER() over(order by ' + quotename(@columnName) + ' asc) as [RowNum] 
			into #2 
			from  ' + quotename(@tableName) + ';

			declare @TotalRecords int;
			declare @Remainder int;
			declare @HalfIndex int;
			declare @medianValue float;
			set @TotalRecords = (select max(RowNum) from #2);

			-- Remainder when divided by 2 (to check even/odd)
			set @Remainder = @TotalRecords % 2;

			-- Integer division result (halfway point)
			set @HalfIndex = @TotalRecords / 2;

			-- Even number of records
			if @Remainder = 0
			begin
				set @medianValue =  (select avg(' + quotename(@columnName) + ') 
								from #2
								where RowNum in (@HalfIndex, @HalfIndex + 1)
								);
			end

			-- Odd number of records
			if @Remainder <> 0
			begin
				set @medianValue =  (select ' + quotename(@columnName) + '
								from #2
								where RowNum = @HalfIndex + 1
								);
			end;

			update #1 set median = @medianValue where ORDINAL_POSITION = ' + cast(@i as varchar(max)) + ';';

		exec sp_executesql @sql; 
	end; -- End of numerical columns

	-- Handle date columns
	if @dataType in ('date', 'datetime', 'datetime2', 'smalldatetime', 'time')
	begin
		-- maximum
		set @sql = 'update #1 set maximum = (select max(' + quotename(@columnName) 
											+ ') from ' + quotename(@tableName) + ') '
				+ 'where ORDINAL_POSITION = ' + cast(@i as varchar(max));
		exec sp_executesql @sql;

		-- minimum
		set @sql = 'update #1 set minimum = (select min(' + quotename(@columnName) 
											+ ') from ' + quotename(@tableName) + ') '
				+ 'where ORDINAL_POSITION = ' + cast(@i as varchar(max));
		exec sp_executesql @sql;

		-- Zero Count
		set @sql = 'update #1 set Zero_Values = (select count(*) from ' + quotename(@tableName) 
											+ ' where ' + quotename(@columnName) + ' = ''1900-01-01'' ) '
				+ 'where ORDINAL_POSITION = ' + cast(@i as varchar(max));
		exec sp_executesql @sql;

		-- Nulls (null count)
		set @sql = 'update #1 set nulls = (select count(*) from ' + quotename(@tableName)
										+ ' where ' + quotename(@columnName) + ' is null ) '
				+ 'where ORDINAL_POSITION = ' + cast(@i as varchar(max));
		exec sp_executesql @sql;

		-- Distinct Count
		set @sql = 'update #1 set distinct_count = (select count(distinct ' + quotename(@columnName) 
										+ ') from ' + quotename(@tableName) + ') '
				+ 'where ORDINAL_POSITION = ' + cast(@i as varchar(max));
		exec sp_executesql @sql;

		-- mode
		--set @sql = '
		--	update #1
		--	set mode = (
		--		select string_agg(cast(' + quotename(@ColumnName) + ' as nvarchar(30)), '','')
		--		from (
		--			select ' + quotename(@ColumnName) + ',
		--				   count(*) as CountAll,
		--				   dense_rank() over(order by count(*) desc) as DenseRank
		--			from ' + quotename(@TableName) + '
		--			where ' + quotename(@ColumnName) + ' is not null
		--			group by ' + quotename(@ColumnName) + '
		--		) as x
		--		where DenseRank = 1
		--	)
		--	where ORDINAL_POSITION = ' + cast(@i as varchar(max)) + ';
		--';
		--exec sp_executesql @sql;

	end; -- End of date columns


	-- Handle non-numeric columns
	if @dataType in ('varchar', 'nvarchar', 'text', 'char', 'nchar')
	begin
		-- maximum
		set @sql = 'update #1 set maximum = (select max(' + quotename(@columnName) 
											+ ') from ' + quotename(@tableName) + ') '
				+ 'where ORDINAL_POSITION = ' + cast(@i as varchar(max));
		exec sp_executesql @sql;

		-- minimum
		set @sql = 'update #1 set minimum = (select min(' + quotename(@columnName) 
											+ ') from ' + quotename(@tableName) + ') '
				+ 'where ORDINAL_POSITION = ' + cast(@i as varchar(max));
		exec sp_executesql @sql;

		-- Zero Count
		set @sql = 'update #1 set Zero_Values = (select count(*) from ' + quotename(@tableName) 
											+ ' where ' + quotename(@columnName) + ' = ''0'' ) ' -- string '0'
				+ 'where ORDINAL_POSITION = ' + cast(@i as varchar(max));
		exec sp_executesql @sql;

		-- Nulls (null count)
		set @sql = 'update #1 set nulls = (select count(*) from ' + quotename(@tableName)
										+ ' where ' + quotename(@columnName) + ' is null ) '
				+ 'where ORDINAL_POSITION = ' + cast(@i as varchar(max));
		exec sp_executesql @sql;

		-- Distinct Count
		set @sql = 'update #1 set distinct_count = (select count(distinct ' + quotename(@columnName) 
										+ ') from ' + quotename(@tableName) + ') '
				+ 'where ORDINAL_POSITION = ' + cast(@i as varchar(max));
		exec sp_executesql @sql;


		-- mode
		set @sql = 'update #1 set mode = (
				select string_agg(' + quotename(@columnName) + ', '','') as mode
				from (
					select ' + quotename(@columnName) + ',
						   dense_rank() over(order by [countAll] desc) as DenseRank
					from (
						select ' + quotename(@columnName) + ', count(*) as [countAll] 
						from ' + quotename(@tableName) + '
						group by ' + quotename(@columnName) + '
					) as x
				) as y
				where DenseRank = 1
				) where ORDINAL_POSITION = ' + cast(@i as varchar(max)) + ';';
		
		exec sp_executesql @sql; 


	end; -- End of non-numeric columns

	-- Handle bit columns
	if @dataType in ('bit')
	begin

		-- mean: proportion of 1s in the column
		-- nullif(expression, 0) : returns 0 if expression = 0
		-- If count(columnName) = 0 → nullif(0,0) = NULL.
		-- If count(columnName) > 0 → returns that count.
		set @sql = '
			update #1
			set Mean = (
				select cast(sum(cast(' + quotename(@columnName) + ' as int)) as float) 
					   / nullif(count(' + quotename(@columnName) + '),0)
				from ' + quotename(@tableName) + '
			)
			where ORDINAL_POSITION = ' + cast(@i as varchar(max)) + ';
		';
		exec sp_executesql @sql;


		-- Zero count
		set @sql = 'update #1 set Zero_Values = (
			select count(*) from ' + quotename(@tableName) + '
			where ' + quotename(@columnName) + ' = 0
		) where ORDINAL_POSITION = ' + cast(@i as varchar(max));
		exec sp_executesql @sql;

		-- One count
		--set @sql = 'update #1 set One_Values = (
		--	select count(*) from ' + quotename(@tableName) + '
		--	where ' + quotename(@columnName) + ' = 1
		--) where ORDINAL_POSITION = ' + cast(@i as varchar(max));
		--exec sp_executesql @sql;

		-- Nulls (null count)
		set @sql = 'update #1 set nulls = (select count(*) from ' + quotename(@tableName)
										+ ' where ' + quotename(@columnName) + ' is null ) '
				+ 'where ORDINAL_POSITION = ' + cast(@i as varchar(max));
		exec sp_executesql @sql;

		-- Distinct Count
		set @sql = 'update #1 set distinct_count = (select count(distinct ' + quotename(@columnName) 
										+ ') from ' + quotename(@tableName) + ') '
				+ 'where ORDINAL_POSITION = ' + cast(@i as varchar(max));
		exec sp_executesql @sql;


		-- mode
		set @sql = '
			update #1 set mode = (
				select cast(val as varchar(1))
				from (
					select ' + quotename(@columnName) + ' as val,
						   count(*) as CountAll,
						   dense_rank() over(order by count(*) desc) as DenseRank
					from ' + quotename(@tableName) + '
					group by ' + quotename(@columnName) + '
				) as x
				where DenseRank = 1
			)
			where ORDINAL_POSITION = ' + cast(@i as varchar(max)) + ';
		';
		exec sp_executesql @sql;; 


	end; -- End of non-numeric columns

	set @i = @i + 1;
end;


select 

from #1;




