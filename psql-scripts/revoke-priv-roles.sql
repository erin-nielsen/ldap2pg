-- Drop user roles
drop role marketinguser1;
drop role marketinguser2;
drop role marketinguser3;

drop role hruser1;
drop role hruser2;

-- Revoke privileges on database for role groups
revoke all privileges on database bdrdb from hr;
revoke all privileges on database bdrdb from marketing;

-- Revoke privileges on tables used for role groups
DO $$
DECLARE
    table_name_var TEXT;
BEGIN
    -- Loop through all tables in the current schema
    FOR table_name_var IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public' 
    LOOP
        -- Revoke privileges on the table
        EXECUTE format('revoke all privileges on %I from hr;', table_name_var);
        RAISE NOTICE 'Revoked privileges on table %', table_name_var;
    END LOOP;
END $$;

DO $$
DECLARE
    table_name_var TEXT;
BEGIN
    -- Loop through all tables in the current schema
    FOR table_name_var IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public' 
    LOOP
        -- Revoke privileges on the table
        EXECUTE format('revoke all privileges on %I from marketing;', table_name_var);
        RAISE NOTICE 'Revoked privileges on table %', table_name_var;
    END LOOP;
END $$;

-- Revoke privileges on schema used for role groups 

revoke all privileges on schema public from hr;
revoke all privileges on schema public from marketing;

-- Drop role group
drop role hr;
drop role marketing;
