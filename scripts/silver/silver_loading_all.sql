CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
DECLARE
    v_start_time     timestamp;
    v_end_time       timestamp;
    v_batch_start    timestamp;
    v_batch_end      timestamp;
BEGIN
    v_batch_start := clock_timestamp();
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Silver Layer';
    RAISE NOTICE '================================================';

    -- crm_cust_info
    BEGIN
        v_start_time := clock_timestamp();
        RAISE NOTICE '>> Truncating Table: silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;

        RAISE NOTICE '>> Inserting Data Into: silver.crm_cust_info';
        INSERT INTO silver.crm_cust_info(
            cst_id, cst_key, cst_firstname, cst_lastname,
            cst_marital_status, cst_gndr, cst_create_date
        )
        SELECT 
            cst_id,
            cst_key,
            trim(cst_firstname) AS cst_firstname,
            trim(cst_lastname) AS cst_lastname,
            CASE WHEN upper(trim(cst_marital_status)) = 'S' THEN 'Single'
                 WHEN upper(trim(cst_marital_status)) = 'M' THEN 'Married'
                 ELSE 'n/a'
            END AS cst_marital_status,
            CASE WHEN upper(trim(cst_gndr)) = 'F' THEN 'Female'
                 WHEN upper(trim(cst_gndr)) = 'M' THEN 'Male'
                 ELSE 'n/a'
            END AS cst_gndr,
            cst_create_date
        FROM (
            SELECT *,
                row_number() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
        ) t
        WHERE flag_last = 1;

        v_end_time := clock_timestamp();
        RAISE NOTICE '>> Load Duration: % seconds', round(extract(epoch FROM (v_end_time - v_start_time))::numeric, 2);
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '!! ERROR loading silver.crm_cust_info: %', SQLERRM;
    END;

    -- crm_prd_info
