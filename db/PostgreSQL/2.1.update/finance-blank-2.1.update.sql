﻿-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.1.update/src/02.functions-and-logic/finance.get_journal_view.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_journal_view
(
    _user_id                        integer,
    _office_id                      integer,
    _from                           date,
    _to                             date,
    _tran_id                        bigint,
    _tran_code                      national character varying(50),
    _book                           national character varying(50),
    _reference_number               national character varying(50),
    _amount							numeric(30, 6),	
    _statement_reference            national character varying(50),
    _posted_by                      national character varying(50),
    _office                         national character varying(50),
    _status                         national character varying(12),
    _verified_by                    national character varying(50),
    _reason                         national character varying(128)
);

CREATE FUNCTION finance.get_journal_view
(
    _user_id                        integer,
    _office_id                      integer,
    _from                           date,
    _to                             date,
    _tran_id                        bigint,
    _tran_code                      national character varying(50),
    _book                           national character varying(50),
    _reference_number               national character varying(50),
	_amount							numeric(30, 6),
    _statement_reference            national character varying(50),
    _posted_by                      national character varying(50),
    _office                         national character varying(50),
    _status                         national character varying(12),
    _verified_by                    national character varying(50),
    _reason                         national character varying(128)
)
RETURNS TABLE
(
    transaction_master_id           bigint,
    transaction_code                text,
    book                            text,
    value_date                      date,
    book_date                      	date,
    reference_number                text,
    amount							numeric(30, 6),
    statement_reference             text,
    posted_by                       text,
    office                          text,
    status                          text,
    verified_by                     text,
    verified_on                     TIMESTAMP WITH TIME ZONE,
    reason                          text,
    transaction_ts                  TIMESTAMP WITH TIME ZONE
)
AS
$$
BEGIN
    RETURN QUERY
    WITH RECURSIVE office_cte(office_id) AS 
    (
        SELECT _office_id
        UNION ALL
        SELECT
            c.office_id
        FROM 
        office_cte AS p, 
        core.offices AS c 
        WHERE 
        parent_office_id = p.office_id
    )

    SELECT 
        finance.transaction_master.transaction_master_id, 
        finance.transaction_master.transaction_code::text,
        finance.transaction_master.book::text,
        finance.transaction_master.value_date,
        finance.transaction_master.book_date,
        finance.transaction_master.reference_number::text,
		SUM
		(
			CASE WHEN finance.transaction_details.tran_type = 'Cr' THEN 1 ELSE 0 END 
				* 
			finance.transaction_details.amount_in_local_currency
		),
        finance.transaction_master.statement_reference::text,
        account.get_name_by_user_id(finance.transaction_master.user_id)::text as posted_by,
        core.get_office_name_by_office_id(finance.transaction_master.office_id)::text as office,
        finance.get_verification_status_name_by_verification_status_id(finance.transaction_master.verification_status_id)::text as status,
        account.get_name_by_user_id(finance.transaction_master.verified_by_user_id)::text as verified_by,
        finance.transaction_master.last_verified_on AS verified_on,
        finance.transaction_master.verification_reason::text AS reason,    
        finance.transaction_master.transaction_ts
    FROM finance.transaction_master
	INNER JOIN finance.transaction_details
	ON finance.transaction_details.transaction_master_id = finance.transaction_master.transaction_master_id
    WHERE 1 = 1
    AND finance.transaction_master.value_date BETWEEN _from AND _to
    AND finance.transaction_master.office_id IN (SELECT office_id FROM office_cte)
    AND (_tran_id = 0 OR _tran_id  = finance.transaction_master.transaction_master_id)
    AND LOWER(finance.transaction_master.transaction_code) LIKE '%' || LOWER(_tran_code) || '%' 
    AND LOWER(finance.transaction_master.book) LIKE '%' || LOWER(_book) || '%' 
    AND COALESCE(LOWER(finance.transaction_master.reference_number), '') LIKE '%' || LOWER(_reference_number) || '%' 
    AND COALESCE(LOWER(finance.transaction_master.statement_reference), '') LIKE '%' || LOWER(_statement_reference) || '%' 
    AND COALESCE(LOWER(finance.transaction_master.verification_reason), '') LIKE '%' || LOWER(_reason) || '%' 
    AND LOWER(account.get_name_by_user_id(finance.transaction_master.user_id)) LIKE '%' || LOWER(_posted_by) || '%' 
    AND LOWER(core.get_office_name_by_office_id(finance.transaction_master.office_id)) LIKE '%' || LOWER(_office) || '%' 
    AND COALESCE(LOWER(finance.get_verification_status_name_by_verification_status_id(finance.transaction_master.verification_status_id)), '') LIKE '%' || LOWER(_status) || '%' 
    AND COALESCE(LOWER(account.get_name_by_user_id(finance.transaction_master.verified_by_user_id)), '') LIKE '%' || LOWER(_verified_by) || '%'    
    AND NOT finance.transaction_master.deleted
    GROUP BY 
		finance.transaction_master.transaction_master_id, 
        finance.transaction_master.transaction_code,
        finance.transaction_master.book,
        finance.transaction_master.value_date,
        finance.transaction_master.book_date,
        finance.transaction_master.reference_number,
		finance.transaction_master.statement_reference,
		finance.transaction_master.last_verified_on,
        finance.transaction_master.verification_reason,    
        finance.transaction_master.transaction_ts,
		finance.transaction_master.verified_by_user_id,
		finance.transaction_master.user_id,
		finance.transaction_master.office_id,
		finance.transaction_master.verification_status_id
	HAVING SUM
		(
			CASE WHEN finance.transaction_details.tran_type = 'Cr' THEN 1 ELSE 0 END 
				* 
			finance.transaction_details.amount_in_local_currency
		) = @amount
		OR @amount = 0
    ORDER BY value_date ASC, verification_status_id DESC;
END
$$
LANGUAGE plpgsql;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.1.update/src/05.scrud-views/empty.sql --<--<--


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.1.update/src/05.selector-views/empty.sql --<--<--


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.1.update/src/05.views/empty.sql --<--<--


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.1.update/src/06.report-views/empty.sql --<--<--


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.1.update/src/99.ownership.sql --<--<--
DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'frapid_db_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT * FROM pg_tables 
    WHERE NOT schemaname = ANY(ARRAY['pg_catalog', 'information_schema'])
    AND tableowner <> 'frapid_db_user'
    LOOP
        EXECUTE 'ALTER TABLE '|| this.schemaname || '.' || this.tablename ||' OWNER TO frapid_db_user;';
    END LOOP;
END
$$
LANGUAGE plpgsql;

DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'frapid_db_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT oid::regclass::text as mat_view
    FROM   pg_class
    WHERE  relkind = 'm'
    LOOP
        EXECUTE 'ALTER TABLE '|| this.mat_view ||' OWNER TO frapid_db_user;';
    END LOOP;
END
$$
LANGUAGE plpgsql;

DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'frapid_db_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT 'ALTER '
        || CASE WHEN p.proisagg THEN 'AGGREGATE ' ELSE 'FUNCTION ' END
        || quote_ident(n.nspname) || '.' || quote_ident(p.proname) || '(' 
        || pg_catalog.pg_get_function_identity_arguments(p.oid) || ') OWNER TO frapid_db_user;' AS sql
    FROM   pg_catalog.pg_proc p
    JOIN   pg_catalog.pg_namespace n ON n.oid = p.pronamespace
    WHERE  NOT n.nspname = ANY(ARRAY['pg_catalog', 'information_schema'])
    LOOP        
        EXECUTE this.sql;
    END LOOP;
END
$$
LANGUAGE plpgsql;


DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'frapid_db_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT * FROM pg_views
    WHERE NOT schemaname = ANY(ARRAY['pg_catalog', 'information_schema'])
    AND viewowner <> 'frapid_db_user'
    LOOP
        EXECUTE 'ALTER VIEW '|| this.schemaname || '.' || this.viewname ||' OWNER TO frapid_db_user;';
    END LOOP;
END
$$
LANGUAGE plpgsql;


DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'frapid_db_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT 'ALTER SCHEMA ' || nspname || ' OWNER TO frapid_db_user;' AS sql FROM pg_namespace
    WHERE nspname NOT LIKE 'pg_%'
    AND nspname <> 'information_schema'
    LOOP
        EXECUTE this.sql;
    END LOOP;
END
$$
LANGUAGE plpgsql;



DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'frapid_db_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT      'ALTER TYPE ' || n.nspname || '.' || t.typname || ' OWNER TO frapid_db_user;' AS sql
    FROM        pg_type t 
    LEFT JOIN   pg_catalog.pg_namespace n ON n.oid = t.typnamespace 
    WHERE       (t.typrelid = 0 OR (SELECT c.relkind = 'c' FROM pg_catalog.pg_class c WHERE c.oid = t.typrelid)) 
    AND         NOT EXISTS(SELECT 1 FROM pg_catalog.pg_type el WHERE el.oid = t.typelem AND el.typarray = t.oid)
    AND         typtype NOT IN ('b')
    AND         n.nspname NOT IN ('pg_catalog', 'information_schema')
    LOOP
        EXECUTE this.sql;
    END LOOP;
END
$$
LANGUAGE plpgsql;


DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'report_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT * FROM pg_tables 
    WHERE NOT schemaname = ANY(ARRAY['pg_catalog', 'information_schema'])
    AND tableowner <> 'report_user'
    LOOP
        EXECUTE 'GRANT SELECT ON TABLE '|| this.schemaname || '.' || this.tablename ||' TO report_user;';
    END LOOP;
END
$$
LANGUAGE plpgsql;

DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'report_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT oid::regclass::text as mat_view
    FROM   pg_class
    WHERE  relkind = 'm'
    LOOP
        EXECUTE 'GRANT SELECT ON TABLE '|| this.mat_view  ||' TO report_user;';
    END LOOP;
END
$$
LANGUAGE plpgsql;

DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'report_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT 'GRANT EXECUTE ON '
        || CASE WHEN p.proisagg THEN 'AGGREGATE ' ELSE 'FUNCTION ' END
        || quote_ident(n.nspname) || '.' || quote_ident(p.proname) || '(' 
        || pg_catalog.pg_get_function_identity_arguments(p.oid) || ') TO report_user;' AS sql
    FROM   pg_catalog.pg_proc p
    JOIN   pg_catalog.pg_namespace n ON n.oid = p.pronamespace
    WHERE  NOT n.nspname = ANY(ARRAY['pg_catalog', 'information_schema'])
    LOOP        
        EXECUTE this.sql;
    END LOOP;
END
$$
LANGUAGE plpgsql;


DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'report_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT * FROM pg_views
    WHERE NOT schemaname = ANY(ARRAY['pg_catalog', 'information_schema'])
    AND viewowner <> 'report_user'
    LOOP
        EXECUTE 'GRANT SELECT ON '|| this.schemaname || '.' || this.viewname ||' TO report_user;';
    END LOOP;
END
$$
LANGUAGE plpgsql;


DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'report_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT 'GRANT USAGE ON SCHEMA ' || nspname || ' TO report_user;' AS sql FROM pg_namespace
    WHERE nspname NOT LIKE 'pg_%'
    AND nspname <> 'information_schema'
    LOOP
        EXECUTE this.sql;
    END LOOP;
END
$$
LANGUAGE plpgsql;

