class UpdateAcceptDatacolumnValues < ActiveRecord::Migration
  def self.up
    execute <<-SQL

--
-- Name: insert_sheet_category(integer, integer, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE OR REPLACE FUNCTION insert_sheet_category(sheetcategory_id integer, datagroup_id integer, status_id integer, import_value text) RETURNS integer
LANGUAGE sql
AS $_$
  insert into categories (short, long, description, comment, created_at, updated_at, datagroup_id, user_id, status_id)
	(select short, long, description, comment, now() as created_at, now() as updated_at, $2 as datagroup_id, user_id, $3 as status_id
		from categories where id = $1);

  select id from categories where (short=$4 or long=$4) and datagroup_id = $2;$_$;



--
-- Name: accept_datacolumn_values(integer, integer, integer, integer, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE OR REPLACE FUNCTION accept_datacolumn_values(datatype_id integer, datacolumn_id integer, datagroup_id integer, system_datagroup_id integer, user_id integer, "comment" text) RETURNS boolean
    LANGUAGE sql
    AS $_$-- regardless of the data type we search for portal matches first
                update sheetcells
                set category_id= c.id,
                  updated_at = now(),
                  datatype_id = 5, -- whatever the original data type this is now a category data type
                  accepted_value = null,
                  status_id = 3
                from categories c
                where (sheetcells.import_value=c.short or sheetcells.import_value=c.long)
                and sheetcells.datacolumn_id=$2 and c.datagroup_id = $3;

                -- regardless of the data type we search for sheet matches next
                update sheetcells
                set category_id = insert_sheet_category(c.id, $3, 1, sheetcells.import_value),
                  updated_at = now(),
                  datatype_id = 5, -- whatever the original data type this is now a category data type
                  accepted_value=null,
                  status_id = 2
                from categories c inner join import_categories cv on c.id = cv.category_id
                where (sheetcells.import_value=c.short or sheetcells.import_value=c.long)
                and sheetcells.datacolumn_id=$2 and cv.datacolumn_id=$2
                and sheetcells.category_id is null and c.datagroup_id=$4;

                -- valid number, date & year
                update sheetcells
                  set category_id = null,
                  accepted_value = sheetcells.import_value,
                  updated_at = now(),
                  datatype_id = $1,
                  status_id = 4
                where sheetcells.datacolumn_id=$2
                and (($1 = 7 and isnumeric(sheetcells.import_value) = true)
                  or ($1 = 2 and isinteger(sheetcells.import_value) = true)
                  or (($1 = 3 or $1 = 4) and isdate(sheetcells.import_value) = true)
                  )
                and sheetcells.category_id is null;

                -- regardless of the data type any sheetcells left over are invalid and categories created for them
                -- this is a two step process to avoid duplicate categories being created

                -- 1. add a category for each unique invalid value, as long as one doesn't already exist in the data group
                insert into categories (short, long, description, datagroup_id, status_id, created_at, updated_at, user_id, comment)
                  (select distinct sheetcells.import_value, sheetcells.import_value, sheetcells.import_value, $3 as datagroup_id, 3 as status_id, now() as created_at, now() as updated_at,
                    1 as user_id, $6 as comment
                  from sheetcells
                  where sheetcells.datacolumn_id=$2 and sheetcells.category_id is null
                    and sheetcells.accepted_value is null and sheetcells.status_id = 1
                    and not exists (select 1 from categories where (short = sheetcells.import_value or long = sheetcells.import_value) and datagroup_id = $3));


                           -- 2. update the sheet cells with the correct category
                     update sheetcells
                set category_id= c.id,
                  updated_at = now(),
                  datatype_id = 5, -- whatever the original data type this is now a category data type
                  accepted_value = null,
                  status_id = 5 -- it is an invalid category
                from categories c
                where (sheetcells.import_value=c.short or sheetcells.import_value=c.long)
                and sheetcells.datacolumn_id=$2 and c.datagroup_id = $3 and sheetcells.category_id is null and sheetcells.accepted_value is null

                  returning true$_$;

    SQL
  end

  def self.down
  end
end
