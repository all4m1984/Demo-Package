--------------------------------------------------------------------------------
-- TELECOM CUSTOMER RETENTION DEMO - SYNTHETIC DATA GENERATION
-- Run this script after 01_setup_database.sql
--------------------------------------------------------------------------------

USE DATABASE TELECOM_DEMO;
USE SCHEMA CUSTOMER_RETENTION;
USE WAREHOUSE TELECOM_DEMO_WH;

--------------------------------------------------------------------------------
-- CUSTOMERS - Generate 1000 customers
--------------------------------------------------------------------------------
INSERT INTO CUSTOMERS (
    CUSTOMER_ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE_NUMBER, DATE_OF_BIRTH,
    GENDER, ADDRESS, CITY, STATE, ZIP_CODE, CUSTOMER_SINCE, CUSTOMER_SEGMENT,
    CREDIT_SCORE, LIFETIME_VALUE, PREFERRED_CONTACT_METHOD, OPT_IN_MARKETING
)
WITH base_data AS (
    SELECT
        SEQ4() AS row_num,
        ARRAY_CONSTRUCT('James','John','Robert','Michael','William','David','Richard','Joseph','Thomas','Charles',
                        'Mary','Patricia','Jennifer','Linda','Barbara','Elizabeth','Susan','Jessica','Sarah','Karen')[UNIFORM(0,19,RANDOM())]::VARCHAR AS first_name,
        ARRAY_CONSTRUCT('Smith','Johnson','Williams','Brown','Jones','Garcia','Miller','Davis','Rodriguez','Martinez',
                        'Hernandez','Lopez','Gonzalez','Wilson','Anderson','Thomas','Taylor','Moore','Jackson','Martin')[UNIFORM(0,19,RANDOM())]::VARCHAR AS last_name,
        DATEADD(DAY, -UNIFORM(30, 2555, RANDOM()), CURRENT_DATE()) AS customer_since,
        ARRAY_CONSTRUCT('Premium','Premium','Standard','Standard','Standard','Standard','Budget','Budget')[UNIFORM(0,7,RANDOM())]::VARCHAR AS customer_segment
    FROM TABLE(GENERATOR(ROWCOUNT => 1000))
)
SELECT
    'CUST-' || LPAD(row_num::VARCHAR, 6, '0') AS CUSTOMER_ID,
    first_name AS FIRST_NAME,
    last_name AS LAST_NAME,
    LOWER(first_name || '.' || last_name || UNIFORM(1,999,RANDOM())::VARCHAR || '@' ||
          ARRAY_CONSTRUCT('gmail.com','yahoo.com','outlook.com','icloud.com','hotmail.com')[UNIFORM(0,4,RANDOM())]::VARCHAR) AS EMAIL,
    '+1' || UNIFORM(200,999,RANDOM())::VARCHAR || UNIFORM(200,999,RANDOM())::VARCHAR || LPAD(UNIFORM(1000,9999,RANDOM())::VARCHAR, 4, '0') AS PHONE_NUMBER,
    DATEADD(DAY, -UNIFORM(6570, 25550, RANDOM()), CURRENT_DATE()) AS DATE_OF_BIRTH,
    ARRAY_CONSTRUCT('Male','Female','Other')[UNIFORM(0,2,RANDOM())]::VARCHAR AS GENDER,
    UNIFORM(100,9999,RANDOM())::VARCHAR || ' ' || 
    ARRAY_CONSTRUCT('Oak','Maple','Pine','Cedar','Elm','Main','Park','Lake','Hill','River')[UNIFORM(0,9,RANDOM())]::VARCHAR || ' ' ||
    ARRAY_CONSTRUCT('St','Ave','Blvd','Dr','Ln','Way','Ct','Rd')[UNIFORM(0,7,RANDOM())]::VARCHAR AS ADDRESS,
    ARRAY_CONSTRUCT('New York','Los Angeles','Chicago','Houston','Phoenix','Philadelphia','San Antonio','San Diego',
                    'Dallas','San Jose','Austin','Jacksonville','Fort Worth','Columbus','Charlotte','Seattle',
                    'Denver','Boston','Portland','Atlanta')[UNIFORM(0,19,RANDOM())]::VARCHAR AS CITY,
    ARRAY_CONSTRUCT('NY','CA','TX','FL','IL','PA','OH','GA','NC','MI','NJ','VA','WA','AZ','MA',
                    'TN','IN','MO','MD','WI')[UNIFORM(0,19,RANDOM())]::VARCHAR AS STATE,
    LPAD(UNIFORM(10001,99999,RANDOM())::VARCHAR, 5, '0') AS ZIP_CODE,
    customer_since AS CUSTOMER_SINCE,
    customer_segment AS CUSTOMER_SEGMENT,
    UNIFORM(580, 850, RANDOM()) AS CREDIT_SCORE,
    ROUND(UNIFORM(100, 15000, RANDOM()) + UNIFORM(0, 100, RANDOM()), 2) AS LIFETIME_VALUE,
    ARRAY_CONSTRUCT('Email','Email','SMS','SMS','Phone')[UNIFORM(0,4,RANDOM())]::VARCHAR AS PREFERRED_CONTACT_METHOD,
    IFF(UNIFORM(0,10,RANDOM()) > 2, TRUE, FALSE) AS OPT_IN_MARKETING
FROM base_data;

--------------------------------------------------------------------------------
-- SUBSCRIPTIONS - One subscription per customer
--------------------------------------------------------------------------------
INSERT INTO SUBSCRIPTIONS (
    SUBSCRIPTION_ID, CUSTOMER_ID, PLAN_NAME, PLAN_TYPE, MONTHLY_FEE, DATA_LIMIT_GB,
    VOICE_MINUTES_LIMIT, SMS_LIMIT, CONTRACT_START_DATE, CONTRACT_END_DATE,
    CONTRACT_LENGTH_MONTHS, EARLY_TERMINATION_FEE, DEVICE_FINANCING,
    DEVICE_MONTHLY_PAYMENT, INTERNATIONAL_ROAMING, HOTSPOT_ENABLED, STATUS
)
WITH plan_data AS (
    SELECT 
        c.CUSTOMER_ID,
        c.CUSTOMER_SEGMENT,
        c.CUSTOMER_SINCE,
        ROW_NUMBER() OVER (ORDER BY c.CUSTOMER_ID) AS row_num,
        CASE c.CUSTOMER_SEGMENT
            WHEN 'Premium' THEN ARRAY_CONSTRUCT('Unlimited Max','Unlimited Plus','Family Unlimited')[UNIFORM(0,2,RANDOM())]::VARCHAR
            WHEN 'Standard' THEN ARRAY_CONSTRUCT('Essential Plus','Family Share 10GB','Unlimited Starter')[UNIFORM(0,2,RANDOM())]::VARCHAR
            ELSE ARRAY_CONSTRUCT('Basic 5GB','Pay As You Go','Prepaid Monthly')[UNIFORM(0,2,RANDOM())]::VARCHAR
        END AS plan_name,
        UNIFORM(12, 24, RANDOM()) AS contract_months,
        IFF(UNIFORM(0,10,RANDOM()) > 6, TRUE, FALSE) AS device_financing,
        UNIFORM(0,100,RANDOM()) AS status_rand
    FROM CUSTOMERS c
)
SELECT
    'SUB-' || LPAD(row_num::VARCHAR, 6, '0') AS SUBSCRIPTION_ID,
    CUSTOMER_ID,
    plan_name AS PLAN_NAME,
    CASE WHEN plan_name IN ('Pay As You Go', 'Prepaid Monthly') THEN 'Prepaid' ELSE 'Postpaid' END AS PLAN_TYPE,
    CASE plan_name
        WHEN 'Unlimited Max' THEN 85.00
        WHEN 'Unlimited Plus' THEN 75.00
        WHEN 'Family Unlimited' THEN 120.00
        WHEN 'Essential Plus' THEN 55.00
        WHEN 'Family Share 10GB' THEN 80.00
        WHEN 'Unlimited Starter' THEN 45.00
        WHEN 'Basic 5GB' THEN 35.00
        WHEN 'Pay As You Go' THEN 25.00
        ELSE 30.00
    END AS MONTHLY_FEE,
    CASE WHEN plan_name LIKE '%Unlimited%' THEN -1 
         WHEN plan_name = 'Basic 5GB' THEN 5
         WHEN plan_name = 'Family Share 10GB' THEN 10
         ELSE 3 END AS DATA_LIMIT_GB,
    CASE WHEN plan_name LIKE '%Unlimited%' THEN -1 ELSE UNIFORM(300, 1000, RANDOM()) END AS VOICE_MINUTES_LIMIT,
    CASE WHEN plan_name LIKE '%Unlimited%' THEN -1 ELSE UNIFORM(500, 2000, RANDOM()) END AS SMS_LIMIT,
    DATEADD(DAY, UNIFORM(0, 30, RANDOM()), CUSTOMER_SINCE) AS CONTRACT_START_DATE,
    DATEADD(MONTH, contract_months, DATEADD(DAY, UNIFORM(0, 30, RANDOM()), CUSTOMER_SINCE)) AS CONTRACT_END_DATE,
    contract_months AS CONTRACT_LENGTH_MONTHS,
    CASE WHEN plan_name NOT IN ('Pay As You Go', 'Prepaid Monthly') THEN UNIFORM(150, 350, RANDOM()) ELSE 0 END AS EARLY_TERMINATION_FEE,
    device_financing AS DEVICE_FINANCING,
    CASE WHEN device_financing THEN ROUND(UNIFORM(15, 60, RANDOM()) + UNIFORM(0, 10, RANDOM()), 2) ELSE 0 END AS DEVICE_MONTHLY_PAYMENT,
    IFF(CUSTOMER_SEGMENT = 'Premium', IFF(UNIFORM(0,10,RANDOM()) > 3, TRUE, FALSE), FALSE) AS INTERNATIONAL_ROAMING,
    IFF(plan_name LIKE '%Unlimited%', IFF(UNIFORM(0,10,RANDOM()) > 5, TRUE, FALSE), FALSE) AS HOTSPOT_ENABLED,
    CASE 
        WHEN status_rand < 5 THEN 'Cancelled'
        WHEN status_rand < 8 THEN 'Suspended'
        ELSE 'Active'
    END AS STATUS
FROM plan_data;

--------------------------------------------------------------------------------
-- USAGE_METRICS - 12 months of usage data per customer
--------------------------------------------------------------------------------
INSERT INTO USAGE_METRICS (
    USAGE_ID, CUSTOMER_ID, SUBSCRIPTION_ID, USAGE_MONTH, DATA_USED_GB, DATA_LIMIT_GB,
    DATA_USAGE_PCT, VOICE_MINUTES_USED, VOICE_MINUTES_LIMIT, VOICE_USAGE_PCT,
    SMS_SENT, SMS_LIMIT, SMS_USAGE_PCT, INTERNATIONAL_DATA_GB, INTERNATIONAL_VOICE_MINUTES,
    OVERAGE_CHARGES, TOTAL_BILL_AMOUNT, PAYMENT_STATUS, DAYS_SINCE_LAST_USAGE,
    APP_SESSIONS, APP_TIME_MINUTES
)
WITH usage_base AS (
    SELECT
        c.CUSTOMER_ID,
        s.SUBSCRIPTION_ID,
        s.DATA_LIMIT_GB,
        s.VOICE_MINUTES_LIMIT,
        s.SMS_LIMIT,
        s.MONTHLY_FEE,
        s.DEVICE_MONTHLY_PAYMENT,
        s.INTERNATIONAL_ROAMING,
        m.USAGE_MONTH,
        MOD(ABS(HASH(c.CUSTOMER_ID)), 10) AS customer_type,
        DATEDIFF(MONTH, m.USAGE_MONTH, CURRENT_DATE()) AS months_ago
    FROM CUSTOMERS c
    JOIN SUBSCRIPTIONS s ON c.CUSTOMER_ID = s.CUSTOMER_ID
    CROSS JOIN (
        SELECT DATEADD(MONTH, -seq4(), DATE_TRUNC('MONTH', CURRENT_DATE())) AS USAGE_MONTH
        FROM TABLE(GENERATOR(ROWCOUNT => 12))
    ) m
    WHERE s.STATUS IN ('Active', 'Suspended')
),
usage_calculated AS (
    SELECT
        *,
        ROUND(
            CASE 
                WHEN customer_type < 2 THEN GREATEST(0.5, 15 - (months_ago * 0.8) + UNIFORM(0, 3, RANDOM()))
                WHEN customer_type < 5 THEN 10 + UNIFORM(0, 8, RANDOM())
                ELSE 8 + (months_ago * 0.2) + UNIFORM(0, 10, RANDOM())
            END, 3
        ) AS data_used,
        UNIFORM(50, 800, RANDOM()) + UNIFORM(0, 200, RANDOM()) AS voice_used,
        UNIFORM(20, 500, RANDOM()) + UNIFORM(0, 100, RANDOM()) AS sms_count,
        CASE WHEN INTERNATIONAL_ROAMING THEN ROUND(UNIFORM(0, 200, RANDOM()) / 100.0, 3) ELSE 0 END AS intl_data,
        CASE WHEN INTERNATIONAL_ROAMING THEN UNIFORM(0, 60, RANDOM()) ELSE 0 END AS intl_voice,
        CASE WHEN customer_type < 2 THEN UNIFORM(5, 20, RANDOM()) ELSE UNIFORM(0, 3, RANDOM()) END AS days_inactive
    FROM usage_base
)
SELECT
    'USG-' || CUSTOMER_ID || '-' || TO_CHAR(USAGE_MONTH, 'YYYYMM') AS USAGE_ID,
    CUSTOMER_ID,
    SUBSCRIPTION_ID,
    USAGE_MONTH,
    data_used AS DATA_USED_GB,
    DATA_LIMIT_GB,
    CASE WHEN DATA_LIMIT_GB = -1 THEN NULL ELSE ROUND((data_used / NULLIF(DATA_LIMIT_GB, 0)) * 100, 2) END AS DATA_USAGE_PCT,
    ROUND(voice_used) AS VOICE_MINUTES_USED,
    VOICE_MINUTES_LIMIT,
    CASE WHEN VOICE_MINUTES_LIMIT = -1 THEN NULL ELSE ROUND((voice_used / NULLIF(VOICE_MINUTES_LIMIT, 0)) * 100, 2) END AS VOICE_USAGE_PCT,
    ROUND(sms_count) AS SMS_SENT,
    SMS_LIMIT,
    CASE WHEN SMS_LIMIT = -1 THEN NULL ELSE ROUND((sms_count / NULLIF(SMS_LIMIT, 0)) * 100, 2) END AS SMS_USAGE_PCT,
    intl_data AS INTERNATIONAL_DATA_GB,
    intl_voice AS INTERNATIONAL_VOICE_MINUTES,
    ROUND(UNIFORM(0, 20, RANDOM()), 2) AS OVERAGE_CHARGES,
    ROUND(MONTHLY_FEE + DEVICE_MONTHLY_PAYMENT + UNIFORM(0, 20, RANDOM()) + (intl_data * 10) + (intl_voice * 0.50), 2) AS TOTAL_BILL_AMOUNT,
    CASE 
        WHEN UNIFORM(0,100,RANDOM()) < 3 THEN 'Overdue'
        WHEN UNIFORM(0,100,RANDOM()) < 5 THEN 'Partial'
        WHEN UNIFORM(0,100,RANDOM()) < 8 THEN 'Pending'
        ELSE 'Paid'
    END AS PAYMENT_STATUS,
    days_inactive AS DAYS_SINCE_LAST_USAGE,
    UNIFORM(10, 200, RANDOM()) AS APP_SESSIONS,
    UNIFORM(30, 600, RANDOM()) AS APP_TIME_MINUTES
FROM usage_calculated;

--------------------------------------------------------------------------------
-- NETWORK_STATS - Daily network stats for last 90 days
--------------------------------------------------------------------------------
INSERT INTO NETWORK_STATS (
    STAT_ID, CUSTOMER_ID, STAT_DATE, PRIMARY_CELL_TOWER, AVG_SIGNAL_STRENGTH_DBM,
    SIGNAL_QUALITY, AVG_DOWNLOAD_SPEED_MBPS, AVG_UPLOAD_SPEED_MBPS, LATENCY_MS,
    PACKET_LOSS_PCT, DROPPED_CALLS, FAILED_CONNECTIONS, NETWORK_TYPE,
    COVERAGE_ISSUES_REPORTED, DATA_THROTTLED, ROAMING_PCT, INDOOR_USAGE_PCT
)
WITH network_base AS (
    SELECT
        c.CUSTOMER_ID,
        d.STAT_DATE,
        MOD(ABS(HASH(c.CUSTOMER_ID)), 10) AS customer_type,
        CASE 
            WHEN MOD(ABS(HASH(c.CUSTOMER_ID)), 10) < 2 THEN UNIFORM(-100, -85, RANDOM())
            WHEN MOD(ABS(HASH(c.CUSTOMER_ID)), 10) < 4 THEN UNIFORM(-85, -75, RANDOM())
            ELSE UNIFORM(-75, -55, RANDOM())
        END AS signal_strength
    FROM CUSTOMERS c
    CROSS JOIN (
        SELECT DATEADD(DAY, -seq4(), CURRENT_DATE()) AS STAT_DATE
        FROM TABLE(GENERATOR(ROWCOUNT => 90))
    ) d
    WHERE MOD(ABS(HASH(c.CUSTOMER_ID || d.STAT_DATE::VARCHAR)), 3) = 0
),
network_with_quality AS (
    SELECT
        *,
        CASE 
            WHEN signal_strength > -65 THEN 'Excellent'
            WHEN signal_strength > -75 THEN 'Good'
            WHEN signal_strength > -85 THEN 'Fair'
            ELSE 'Poor'
        END AS sig_quality
    FROM network_base
)
SELECT
    'NET-' || CUSTOMER_ID || '-' || TO_CHAR(STAT_DATE, 'YYYYMMDD') AS STAT_ID,
    CUSTOMER_ID,
    STAT_DATE,
    'TOWER-' || LPAD(UNIFORM(1,500,RANDOM())::VARCHAR, 4, '0') AS PRIMARY_CELL_TOWER,
    signal_strength AS AVG_SIGNAL_STRENGTH_DBM,
    sig_quality AS SIGNAL_QUALITY,
    CASE sig_quality
        WHEN 'Excellent' THEN ROUND(UNIFORM(100, 300, RANDOM()) + UNIFORM(0, 50, RANDOM()), 2)
        WHEN 'Good' THEN ROUND(UNIFORM(50, 150, RANDOM()) + UNIFORM(0, 30, RANDOM()), 2)
        WHEN 'Fair' THEN ROUND(UNIFORM(15, 60, RANDOM()) + UNIFORM(0, 15, RANDOM()), 2)
        ELSE ROUND(UNIFORM(2, 20, RANDOM()) + UNIFORM(0, 5, RANDOM()), 2)
    END AS AVG_DOWNLOAD_SPEED_MBPS,
    CASE sig_quality
        WHEN 'Excellent' THEN ROUND(UNIFORM(30, 90, RANDOM()) + UNIFORM(0, 15, RANDOM()), 2)
        WHEN 'Good' THEN ROUND(UNIFORM(15, 45, RANDOM()) + UNIFORM(0, 10, RANDOM()), 2)
        WHEN 'Fair' THEN ROUND(UNIFORM(5, 18, RANDOM()) + UNIFORM(0, 5, RANDOM()), 2)
        ELSE ROUND(UNIFORM(1, 6, RANDOM()) + UNIFORM(0, 2, RANDOM()), 2)
    END AS AVG_UPLOAD_SPEED_MBPS,
    CASE sig_quality
        WHEN 'Excellent' THEN UNIFORM(10, 30, RANDOM())
        WHEN 'Good' THEN UNIFORM(25, 50, RANDOM())
        WHEN 'Fair' THEN UNIFORM(45, 80, RANDOM())
        ELSE UNIFORM(70, 150, RANDOM())
    END AS LATENCY_MS,
    CASE sig_quality
        WHEN 'Excellent' THEN ROUND(UNIFORM(0, 50, RANDOM()) / 100.0, 2)
        WHEN 'Good' THEN ROUND(UNIFORM(0, 150, RANDOM()) / 100.0, 2)
        WHEN 'Fair' THEN ROUND(UNIFORM(0, 300, RANDOM()) / 100.0, 2)
        ELSE ROUND(UNIFORM(0, 800, RANDOM()) / 100.0, 2)
    END AS PACKET_LOSS_PCT,
    CASE sig_quality
        WHEN 'Poor' THEN UNIFORM(0, 5, RANDOM())
        WHEN 'Fair' THEN UNIFORM(0, 2, RANDOM())
        ELSE UNIFORM(0, 1, RANDOM())
    END AS DROPPED_CALLS,
    CASE sig_quality
        WHEN 'Poor' THEN UNIFORM(0, 10, RANDOM())
        WHEN 'Fair' THEN UNIFORM(0, 4, RANDOM())
        ELSE UNIFORM(0, 2, RANDOM())
    END AS FAILED_CONNECTIONS,
    CASE 
        WHEN sig_quality = 'Excellent' THEN ARRAY_CONSTRUCT('5G','5G','5G','4G')[UNIFORM(0,3,RANDOM())]::VARCHAR
        WHEN sig_quality = 'Good' THEN ARRAY_CONSTRUCT('5G','4G','4G')[UNIFORM(0,2,RANDOM())]::VARCHAR
        ELSE ARRAY_CONSTRUCT('4G','4G','3G')[UNIFORM(0,2,RANDOM())]::VARCHAR
    END AS NETWORK_TYPE,
    sig_quality = 'Poor' AND UNIFORM(0,10,RANDOM()) > 6 AS COVERAGE_ISSUES_REPORTED,
    FALSE AS DATA_THROTTLED,
    ROUND(UNIFORM(0, 1500, RANDOM()) / 100.0, 2) AS ROAMING_PCT,
    ROUND(40 + UNIFORM(0, 4000, RANDOM()) / 100.0, 2) AS INDOOR_USAGE_PCT
FROM network_with_quality;

--------------------------------------------------------------------------------
-- CALL_CENTER_LOGS - Support interactions with rich text for search
--------------------------------------------------------------------------------
INSERT INTO CALL_CENTER_LOGS (
    INTERACTION_ID, CUSTOMER_ID, INTERACTION_DATE, CHANNEL, AGENT_ID, AGENT_NAME,
    CATEGORY, SUBCATEGORY, ISSUE_DESCRIPTION, RESOLUTION_DESCRIPTION,
    RESOLUTION_STATUS, CUSTOMER_SENTIMENT, NPS_SCORE, CALL_DURATION_MINUTES,
    WAIT_TIME_MINUTES, FIRST_CONTACT_RESOLUTION, ESCALATED, ESCALATION_REASON,
    COMPENSATION_OFFERED, RETENTION_OFFER_MADE, RETENTION_OFFER_ACCEPTED,
    TRANSCRIPT_SUMMARY
)
WITH ISSUE_TEMPLATES AS (
    SELECT * FROM VALUES
    ('Billing', 'Overcharge', 'Customer reports being overcharged on their monthly bill. They noticed unexpected charges and fees that were not part of their original plan agreement.', 'Reviewed billing statement and identified the discrepancy. Applied credit to account and explained the charges. Customer satisfied with resolution.', 'Resolved', 'Neutral', TRUE),
    ('Billing', 'Payment Issue', 'Customer unable to make payment through the app. Payment keeps getting rejected despite having sufficient funds in their account.', 'Identified technical issue with payment gateway. Processed payment manually and escalated to tech team for app fix. Customer thanked us for the help.', 'Resolved', 'Positive', TRUE),
    ('Billing', 'Dispute', 'Customer disputing charges for international roaming that they claim they did not use. Very frustrated about the unexpected high bill.', 'Investigated usage records and found roaming charges were valid. Offered one-time courtesy credit of 50% as goodwill gesture. Customer accepted but remained unhappy.', 'Resolved', 'Negative', FALSE),
    ('Technical', 'Network Coverage', 'Customer experiencing poor signal strength at home. Calls are frequently dropping and data speeds are very slow. Has been ongoing for several weeks.', 'Checked network coverage maps and confirmed known issue in area. Scheduled network tower maintenance. Offered temporary signal booster. Customer expressed frustration with wait time.', 'Pending', 'Negative', FALSE),
    ('Technical', 'Data Speed', 'Customer complaining about extremely slow data speeds. They are paying for unlimited data but speeds are much lower than advertised.', 'Ran diagnostics on account and found throttling was applied after reaching fair usage threshold. Explained policy and offered plan upgrade with higher priority data.', 'Resolved', 'Neutral', TRUE),
    ('Technical', 'Device Issue', 'Customer phone not connecting to network after software update. Shows no signal bars and cannot make or receive calls.', 'Walked through network reset steps. Issue resolved after resetting network settings and updating carrier settings. Customer very relieved and appreciative.', 'Resolved', 'Positive', TRUE),
    ('Technical', '5G Connection', 'Customer purchased a 5G plan but phone keeps dropping to 4G even in 5G coverage areas. Very disappointed with the service quality.', 'Confirmed device is 5G capable. Identified nearby tower congestion issue. Escalated to network team. Offered temporary bill credit for inconvenience.', 'Escalated', 'Negative', FALSE),
    ('Plan Change', 'Upgrade Request', 'Customer interested in upgrading to unlimited plan. Currently on limited data plan and running out of data each month.', 'Explained available plans and recommended Unlimited Plus based on usage patterns. Customer agreed to upgrade starting next billing cycle.', 'Resolved', 'Positive', TRUE),
    ('Plan Change', 'Downgrade Request', 'Customer wants to downgrade plan due to financial constraints. Currently paying more than they can afford each month.', 'Reviewed options and found a plan that would save customer 30 dollars per month while meeting their basic needs. Customer grateful for the savings.', 'Resolved', 'Positive', TRUE),
    ('Plan Change', 'Add Line', 'Customer wants to add a new line for family member. Asking about family plan options and any available promotions.', 'Explained Family Share plan benefits and current promotion offering free device with new line. Customer excited about the deal and added new line.', 'Resolved', 'Positive', TRUE),
    ('Cancellation', 'Service Cancellation', 'Customer threatening to cancel due to ongoing network issues. Has called multiple times about poor coverage with no improvement.', 'Acknowledged ongoing frustrations and apologized for poor experience. Offered 3 months free service plus waived early termination fee if willing to stay. Customer said they would think about it.', 'Pending', 'Very Negative', FALSE),
    ('Cancellation', 'Competitor Offer', 'Customer received better offer from competitor. Wants to know if we can match their pricing or offer any incentives to stay.', 'Reviewed customer loyalty and tenure. Authorized retention offer of 25 percent discount for 12 months plus free device upgrade. Customer decided to stay with us.', 'Resolved', 'Neutral', TRUE),
    ('Cancellation', 'Moving Away', 'Customer moving to area where we do not have coverage. Inquiring about early termination process and any fees involved.', 'Explained ETF waiver program for customers moving to non-coverage areas. Processed waiver and helped port number to new carrier. Customer appreciated smooth transition.', 'Resolved', 'Positive', TRUE),
    ('Cancellation', 'Dissatisfied', 'Customer extremely unhappy with overall service quality and customer support experience. Has had multiple issues in past 6 months.', 'Escalated to retention specialist. Offered comprehensive package including bill credits, plan upgrade, and new device. Customer still considering options.', 'Escalated', 'Very Negative', FALSE),
    ('General', 'Account Info', 'Customer calling to verify account information and update contact email address for billing notifications.', 'Verified customer identity and updated email address in system. Confirmed change would take effect immediately for all communications.', 'Resolved', 'Neutral', TRUE),
    ('General', 'Feature Inquiry', 'Customer asking about international roaming options for upcoming trip. Wants to understand costs and available packages.', 'Explained international roaming packages and day pass options. Recommended TravelPass add-on and helped activate for trip dates. Customer satisfied with options.', 'Resolved', 'Positive', TRUE)
    AS t(CATEGORY, SUBCATEGORY, ISSUE_DESC, RESOLUTION_DESC, STATUS, SENTIMENT, FCR)
),
CUSTOMER_ISSUES AS (
    SELECT 
        c.CUSTOMER_ID,
        ROW_NUMBER() OVER (PARTITION BY c.CUSTOMER_ID ORDER BY RANDOM()) AS ISSUE_NUM,
        i.CATEGORY,
        i.SUBCATEGORY,
        i.ISSUE_DESC,
        i.RESOLUTION_DESC,
        i.STATUS,
        i.SENTIMENT,
        i.FCR
    FROM CUSTOMERS c
    CROSS JOIN ISSUE_TEMPLATES i
    WHERE UNIFORM(0, 10, RANDOM()) > 6
),
interaction_data AS (
    SELECT
        ci.*,
        ARRAY_CONSTRUCT('Phone','Chat','Email','App','Store')[UNIFORM(0,4,RANDOM())]::VARCHAR AS channel,
        CASE ci.SENTIMENT
            WHEN 'Positive' THEN UNIFORM(8, 10, RANDOM())
            WHEN 'Neutral' THEN UNIFORM(5, 7, RANDOM())
            WHEN 'Negative' THEN UNIFORM(2, 5, RANDOM())
            ELSE UNIFORM(0, 3, RANDOM())
        END AS nps
    FROM CUSTOMER_ISSUES ci
    WHERE ci.ISSUE_NUM <= 5
)
SELECT
    'INT-' || CUSTOMER_ID || '-' || LPAD(ISSUE_NUM::VARCHAR, 3, '0') AS INTERACTION_ID,
    CUSTOMER_ID,
    DATEADD(DAY, -UNIFORM(1, 365, RANDOM()), CURRENT_TIMESTAMP()) AS INTERACTION_DATE,
    channel AS CHANNEL,
    'AGT-' || LPAD(UNIFORM(1,50,RANDOM())::VARCHAR, 3, '0') AS AGENT_ID,
    ARRAY_CONSTRUCT('Sarah Johnson','Mike Chen','Lisa Rodriguez','David Kim','Jennifer Taylor',
                    'Chris Brown','Amanda Davis','Ryan Wilson','Emily Martinez','Tom Anderson')[UNIFORM(0,9,RANDOM())]::VARCHAR AS AGENT_NAME,
    CATEGORY,
    SUBCATEGORY,
    ISSUE_DESC AS ISSUE_DESCRIPTION,
    RESOLUTION_DESC AS RESOLUTION_DESCRIPTION,
    STATUS AS RESOLUTION_STATUS,
    SENTIMENT AS CUSTOMER_SENTIMENT,
    nps AS NPS_SCORE,
    UNIFORM(5, 45, RANDOM()) AS CALL_DURATION_MINUTES,
    UNIFORM(1, 20, RANDOM()) AS WAIT_TIME_MINUTES,
    FCR AS FIRST_CONTACT_RESOLUTION,
    STATUS = 'Escalated' AS ESCALATED,
    CASE WHEN STATUS = 'Escalated' THEN 'Customer requested supervisor' ELSE NULL END AS ESCALATION_REASON,
    CASE WHEN SENTIMENT IN ('Negative', 'Very Negative') THEN ROUND(UNIFORM(10, 100, RANDOM()), 2) ELSE 0 END AS COMPENSATION_OFFERED,
    CATEGORY = 'Cancellation' AS RETENTION_OFFER_MADE,
    CASE WHEN CATEGORY = 'Cancellation' AND STATUS = 'Resolved' THEN TRUE ELSE NULL END AS RETENTION_OFFER_ACCEPTED,
    'Customer ' || CUSTOMER_ID || ' contacted support via ' || channel || ' regarding ' || SUBCATEGORY || '. ' ||
    'Issue: ' || ISSUE_DESC || ' ' ||
    'Resolution: ' || RESOLUTION_DESC || ' ' ||
    'Sentiment: ' || SENTIMENT || '. NPS: ' || nps::VARCHAR || '/10.' AS TRANSCRIPT_SUMMARY
FROM interaction_data;

--------------------------------------------------------------------------------
-- PROMOTIONS - Available retention offers
--------------------------------------------------------------------------------
INSERT INTO PROMOTIONS (
    PROMOTION_ID, PROMOTION_NAME, PROMOTION_TYPE, DESCRIPTION, DISCOUNT_PCT,
    DISCOUNT_AMOUNT, BONUS_DATA_GB, BONUS_MINUTES, FREE_MONTHS, DEVICE_DISCOUNT_PCT,
    VALID_FROM, VALID_UNTIL, MIN_TENURE_MONTHS, MAX_CHURN_SCORE,
    TARGET_SEGMENTS, ELIGIBILITY_CRITERIA, TERMS_AND_CONDITIONS, IS_ACTIVE, SUCCESS_RATE
)
SELECT 'PROMO-001', 'Loyalty Reward 20% Off', 'Discount', 
     'Exclusive 20% discount on monthly plan for loyal customers showing signs of disengagement. Designed to retain valuable long-term customers.',
     20.00, NULL, NULL, NULL, NULL, NULL,
     '2024-01-01'::DATE, '2025-12-31'::DATE, 12, 0.70,
     PARSE_JSON('["Premium", "Standard"]'),
     'Customer tenure 12+ months, churn risk score above 0.5',
     'Discount applies to base plan only. Not combinable with other offers. Valid for 12 months.',
     TRUE, 68.5
UNION ALL
SELECT 'PROMO-002', 'Win-Back Special', 'Winback',
     'Aggressive offer to prevent imminent churn. Includes 3 free months plus waived ETF for customers with very high churn probability.',
     NULL, NULL, NULL, NULL, 3, NULL,
     '2024-01-01'::DATE, '2025-12-31'::DATE, 6, 0.85,
     PARSE_JSON('["Premium", "Standard", "Budget"]'),
     'Customer showing high intent to cancel or switch carrier',
     'Free months applied after account reactivation. ETF waiver requires 12-month commitment.',
     TRUE, 45.2
UNION ALL
SELECT 'PROMO-003', 'Data Boost Upgrade', 'Upgrade',
     'Free data upgrade for customers underutilizing their current plan. Encourages engagement and demonstrates value.',
     NULL, NULL, 10, NULL, NULL, NULL,
     '2024-01-01'::DATE, '2025-12-31'::DATE, 3, 0.60,
     PARSE_JSON('["Standard", "Budget"]'),
     'Current data usage below 50% of plan limit for 3+ months',
     'Bonus data valid for 6 months. Automatically reverts to standard allocation after.',
     TRUE, 72.3
UNION ALL
SELECT 'PROMO-004', 'Premium Device Deal', 'Device',
     'Up to 50% off latest flagship devices for customers considering upgrade. Includes trade-in bonus.',
     NULL, NULL, NULL, NULL, NULL, 50.00,
     '2024-01-01'::DATE, '2025-12-31'::DATE, 12, 0.50,
     PARSE_JSON('["Premium"]'),
     'Device age 2+ years, on Premium plan',
     'Requires 24-month financing agreement. Trade-in value varies by device condition.',
     TRUE, 55.8
UNION ALL
SELECT 'PROMO-005', 'Family Add-On Free', 'Loyalty',
     'Add a family line free for 6 months. Increases stickiness by expanding service footprint.',
     NULL, NULL, NULL, NULL, 6, NULL,
     '2024-01-01'::DATE, '2025-12-31'::DATE, 6, 0.65,
     PARSE_JSON('["Standard", "Premium"]'),
     'Single line account, 6+ month tenure',
     'Free line limited to basic plan. After 6 months, standard rates apply.',
     TRUE, 61.0
UNION ALL
SELECT 'PROMO-006', 'Network Issue Compensation', 'Discount',
     'Special discount for customers experiencing documented network issues in their area.',
     15.00, NULL, 5, NULL, NULL, NULL,
     '2024-01-01'::DATE, '2025-12-31'::DATE, 1, 0.80,
     PARSE_JSON('["Premium", "Standard", "Budget"]'),
     'Located in area with known network coverage issues',
     'Discount and bonus data valid until network improvements completed.',
     TRUE, 58.7
UNION ALL
SELECT 'PROMO-007', 'Bill Credit Recovery', 'Discount',
     '50 dollar bill credit for customers with payment issues who commit to autopay enrollment.',
     NULL, 50.00, NULL, NULL, NULL, NULL,
     '2024-01-01'::DATE, '2025-12-31'::DATE, 3, 0.55,
     PARSE_JSON('["Budget", "Standard"]'),
     'Payment history shows late payments, agrees to autopay',
     'Credit applied after first successful autopay transaction.',
     TRUE, 49.5
UNION ALL
SELECT 'PROMO-008', 'Unlimited Upgrade Trial', 'Upgrade',
     'Try unlimited plan for 1 month free. If customer keeps it, locked in at promotional rate.',
     25.00, NULL, NULL, NULL, 1, NULL,
     '2024-01-01'::DATE, '2025-12-31'::DATE, 6, 0.45,
     PARSE_JSON('["Budget"]'),
     'Currently on limited data plan',
     'After trial, customer can downgrade without penalty or keep at 25% discount for 12 months.',
     TRUE, 42.1;

--------------------------------------------------------------------------------
-- CHURN_PREDICTIONS - Initial ML predictions (will be updated by SPCS model)
--------------------------------------------------------------------------------
INSERT INTO CHURN_PREDICTIONS (
    PREDICTION_ID, CUSTOMER_ID, PREDICTION_DATE, CHURN_PROBABILITY, CHURN_RISK_CATEGORY,
    TOP_CHURN_FACTORS, RECOMMENDED_ACTIONS, MODEL_VERSION, CONFIDENCE_SCORE,
    DAYS_UNTIL_LIKELY_CHURN
)
WITH churn_base AS (
    SELECT
        c.CUSTOMER_ID,
        MOD(ABS(HASH(c.CUSTOMER_ID)), 10) AS customer_type,
        ROUND(
            CASE
                WHEN MOD(ABS(HASH(c.CUSTOMER_ID)), 10) < 2 THEN 0.70 + (UNIFORM(0, 25, RANDOM()) / 100.0)
                WHEN MOD(ABS(HASH(c.CUSTOMER_ID)), 10) < 5 THEN 0.35 + (UNIFORM(0, 30, RANDOM()) / 100.0)
                ELSE 0.05 + (UNIFORM(0, 25, RANDOM()) / 100.0)
            END, 4
        ) AS churn_prob
    FROM CUSTOMERS c
    WHERE EXISTS (SELECT 1 FROM SUBSCRIPTIONS s WHERE s.CUSTOMER_ID = c.CUSTOMER_ID AND s.STATUS = 'Active')
)
SELECT
    'PRED-' || CUSTOMER_ID || '-' || TO_CHAR(CURRENT_DATE(), 'YYYYMMDD') AS PREDICTION_ID,
    CUSTOMER_ID,
    CURRENT_DATE() AS PREDICTION_DATE,
    churn_prob AS CHURN_PROBABILITY,
    CASE 
        WHEN churn_prob >= 0.60 THEN 'High'
        WHEN churn_prob >= 0.30 THEN 'Medium'
        ELSE 'Low'
    END AS CHURN_RISK_CATEGORY,
    CASE 
        WHEN churn_prob >= 0.60 THEN PARSE_JSON('["Declining usage trend", "Multiple support complaints", "Poor network experience", "Payment issues"]')
        WHEN churn_prob >= 0.30 THEN PARSE_JSON('["Moderate usage decline", "Occasional complaints", "Contract ending soon"]')
        ELSE PARSE_JSON('["Stable engagement", "Good network experience"]')
    END AS TOP_CHURN_FACTORS,
    CASE 
        WHEN churn_prob >= 0.60 THEN PARSE_JSON('["Immediate retention call", "Offer Win-Back Special (PROMO-002)", "Network issue compensation if applicable"]')
        WHEN churn_prob >= 0.30 THEN PARSE_JSON('["Proactive outreach", "Loyalty discount offer", "Usage engagement campaign"]')
        ELSE PARSE_JSON('["Continue monitoring", "Loyalty program enrollment"]')
    END AS RECOMMENDED_ACTIONS,
    'v1.0.0' AS MODEL_VERSION,
    ROUND(0.75 + (UNIFORM(0, 20, RANDOM()) / 100.0), 4) AS CONFIDENCE_SCORE,
    CASE 
        WHEN churn_prob >= 0.60 THEN UNIFORM(7, 30, RANDOM())
        WHEN churn_prob >= 0.30 THEN UNIFORM(30, 90, RANDOM())
        ELSE UNIFORM(90, 365, RANDOM())
    END AS DAYS_UNTIL_LIKELY_CHURN
FROM churn_base;

COMMIT;

SELECT 'Synthetic data generation complete!' AS STATUS;

-- Verify data counts
SELECT 'CUSTOMERS' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM CUSTOMERS
UNION ALL SELECT 'SUBSCRIPTIONS', COUNT(*) FROM SUBSCRIPTIONS
UNION ALL SELECT 'USAGE_METRICS', COUNT(*) FROM USAGE_METRICS
UNION ALL SELECT 'NETWORK_STATS', COUNT(*) FROM NETWORK_STATS
UNION ALL SELECT 'CALL_CENTER_LOGS', COUNT(*) FROM CALL_CENTER_LOGS
UNION ALL SELECT 'PROMOTIONS', COUNT(*) FROM PROMOTIONS
UNION ALL SELECT 'CHURN_PREDICTIONS', COUNT(*) FROM CHURN_PREDICTIONS;
