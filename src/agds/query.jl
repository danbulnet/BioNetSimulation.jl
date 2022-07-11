const pkquerypg = """
    SELECT tc.table_name, kc.column_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kc
    ON kc.table_name = tc.table_name and kc.constraint_name = tc.constraint_name
    WHERE tc.constraint_type = 'PRIMARY KEY'
    AND kc.ordinal_position is not null
    ORDER BY tc.table_name, kc.position_in_unique_constraint;
"""

const fkquerypg = """
    SELECT
        tc.table_name, kcu.column_name,
        ccu.table_name AS foreign_table_name,
        ccu.column_name AS foreign_column_name
    FROM
        information_schema.table_constraints AS tc
    JOIN information_schema.key_column_usage
    AS kcu ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage
    AS ccu ON ccu.constraint_name = tc.constraint_name
    WHERE constraint_type = 'FOREIGN KEY';
"""

const fkquerym = """
    select fks.table_name as foreign_table, '->' as rel,
    fks.referenced_table_name as primary_table,
    fks.constraint_name,
    group_concat(kcu.column_name
        order by position_in_unique_constraint separator ', ') 
        as fk_columns
    from information_schema.referential_constraints fks
    join information_schema.key_column_usage kcu
    on fks.constraint_schema = kcu.table_schema
    and fks.table_name = kcu.table_name
    and fks.constraint_name = kcu.constraint_name
    -- where fks.constraint_schema = 'database name'
    group by fks.constraint_schema,
    fks.table_name,
    fks.unique_constraint_schema,
    fks.referenced_table_name,
    fks.constraint_name
    order by fks.constraint_schema,
    fks.table_name;
"""

macro colsquery(table)
    :(string("SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_NAME = '",  $(esc(table)), "';"))
end

macro rowsquery(table)
    :(string("SELECT * FROM ",  $(esc(table)), ";"))
end

function typesquery(table::Symbol)
    """
        SELECT COLUMN_NAME, DATA_TYPE
        from INFORMATION_SCHEMA.COLUMNS 
        where table_name='$table';
    """
end
