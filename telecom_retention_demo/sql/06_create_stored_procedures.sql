--------------------------------------------------------------------------------
-- TELECOM CUSTOMER RETENTION DEMO - CUSTOM TOOLS (STORED PROCEDURES)
-- Creates stored procedures for email sending and other agent tools
--------------------------------------------------------------------------------

USE DATABASE TELECOM_DEMO;
USE SCHEMA CUSTOMER_RETENTION;
USE ROLE ACCOUNTADMIN;

--------------------------------------------------------------------------------
-- TOOL 1: SEND_RETENTION_EMAIL
-- Sends promotional email to customer for retention
-- Uses Snowflake email notification to actually send the email
--------------------------------------------------------------------------------

-- First create notification integration for email (run once)
-- IMPORTANT: Replace '<YOUR_EMAIL>' with your actual email address
CREATE NOTIFICATION INTEGRATION IF NOT EXISTS TELECOM_EMAIL_INTEGRATION
    TYPE = EMAIL
    ENABLED = TRUE
    ALLOWED_RECIPIENTS = ('<YOUR_EMAIL>');

CREATE OR REPLACE PROCEDURE TELECOM_DEMO.CUSTOMER_RETENTION.SEND_EMAIL(
    P_SUBJECT VARCHAR,
    P_BODY VARCHAR,
    P_EMAIL_TYPE VARCHAR DEFAULT 'General'
)
RETURNS VARIANT
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
DECLARE
    v_email_log_id VARCHAR;
    -- IMPORTANT: Replace with your email address
    v_recipient_email VARCHAR DEFAULT '<YOUR_EMAIL>';
    v_html_body VARCHAR;
    v_formatted_body VARCHAR;
BEGIN
    -- Generate email log ID
    v_email_log_id := 'EMAIL-' || TO_VARCHAR(CURRENT_TIMESTAMP(), 'YYYYMMDDHH24MISS') || '-' || SUBSTR(UUID_STRING(), 1, 8);
    
    -- Format the body: convert markdown-style to HTML
    v_formatted_body := P_BODY;
    -- Convert **text** to bold
    v_formatted_body := REGEXP_REPLACE(v_formatted_body, '\\*\\*([^*]+)\\*\\*', '<strong>\\1</strong>');
    -- Convert bullet points
    v_formatted_body := REPLACE(v_formatted_body, '• ', '<li style=\"margin-left: 20px;\">');
    v_formatted_body := REPLACE(v_formatted_body, '- ', '<li style=\"margin-left: 20px;\">');
    -- Convert line breaks
    v_formatted_body := REPLACE(REPLACE(v_formatted_body, '\\n', '<br/>'), CHR(10), '<br/>');
    
    -- Construct HTML email body
    v_html_body := '<html><body style="font-family: Arial, sans-serif; line-height: 1.6;">' ||
        '<div style="max-width: 600px; margin: 0 auto; padding: 20px;">' ||
        '<h2 style="color: #0066cc; border-bottom: 2px solid #0066cc; padding-bottom: 10px;">Telecom Customer Retention - ' || P_EMAIL_TYPE || '</h2>' ||
        '<div style="padding: 15px 0;">' ||
        v_formatted_body ||
        '</div>' ||
        '<hr style="border: none; border-top: 1px solid #ccc; margin: 20px 0;"/>' ||
        '<p style="color: #666; font-size: 11px;">Sent via Snowflake Intelligence Agent<br/>' || CURRENT_TIMESTAMP()::VARCHAR || '</p>' ||
        '</div></body></html>';
    
    -- Send the email using Snowflake notification
    CALL SYSTEM$SEND_EMAIL(
        'TELECOM_EMAIL_INTEGRATION',
        :v_recipient_email,
        :P_SUBJECT,
        :v_html_body,
        'text/html'
    );
    
    -- Log the email
    INSERT INTO TELECOM_DEMO.CUSTOMER_RETENTION.EMAIL_LOG (
        EMAIL_LOG_ID,
        CUSTOMER_ID,
        EMAIL_ADDRESS,
        PROMOTION_ID,
        EMAIL_TYPE,
        SUBJECT_LINE,
        EMAIL_BODY,
        SENT_AT,
        SENT_BY,
        DELIVERY_STATUS
    ) VALUES (
        :v_email_log_id,
        NULL,
        :v_recipient_email,
        NULL,
        :P_EMAIL_TYPE,
        :P_SUBJECT,
        :P_BODY,
        CURRENT_TIMESTAMP(),
        'Snowflake Intelligence Agent',
        'Sent'
    );
    
    -- Return success result
    RETURN OBJECT_CONSTRUCT(
        'success', TRUE,
        'email_log_id', v_email_log_id,
        'sent_to', v_recipient_email,
        'subject', P_SUBJECT,
        'email_type', P_EMAIL_TYPE,
        'sent_at', CURRENT_TIMESTAMP()::VARCHAR
    );
    
EXCEPTION
    WHEN OTHER THEN
        RETURN OBJECT_CONSTRUCT(
            'success', FALSE,
            'error', SQLERRM
        );
END;
$$;

--------------------------------------------------------------------------------
-- TOOL 2: GET_RECOMMENDED_PROMOTIONS
-- Gets personalized promotion recommendations for a customer
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE TELECOM_DEMO.CUSTOMER_RETENTION.GET_RECOMMENDED_PROMOTIONS(
    P_CUSTOMER_ID VARCHAR
)
RETURNS VARIANT
LANGUAGE SQL
AS
$$
DECLARE
    v_result VARIANT;
BEGIN
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(
        'promotion_id', p.PROMOTION_ID,
        'promotion_name', p.PROMOTION_NAME,
        'promotion_type', p.PROMOTION_TYPE,
        'description', p.DESCRIPTION,
        'discount_pct', p.DISCOUNT_PCT,
        'free_months', p.FREE_MONTHS,
        'bonus_data_gb', p.BONUS_DATA_GB,
        'success_rate', p.SUCCESS_RATE,
        'match_score', 
            CASE 
                WHEN cp.CHURN_PROBABILITY >= p.MAX_CHURN_SCORE THEN 100
                ELSE ROUND((1 - ABS(cp.CHURN_PROBABILITY - p.MAX_CHURN_SCORE)) * 100, 0)
            END,
        'recommendation_reason',
            CASE p.PROMOTION_TYPE
                WHEN 'Winback' THEN 'High churn risk - aggressive retention needed'
                WHEN 'Discount' THEN 'Price-sensitive customer - discount offer recommended'
                WHEN 'Upgrade' THEN 'Underutilizing current plan - upgrade could add value'
                WHEN 'Loyalty' THEN 'Long-term customer - reward loyalty'
                WHEN 'Device' THEN 'Device aging - new device could improve experience'
                ELSE 'General retention offer'
            END
    )) INTO :v_result
    FROM TELECOM_DEMO.CUSTOMER_RETENTION.PROMOTIONS p
    JOIN TELECOM_DEMO.CUSTOMER_RETENTION.CUSTOMERS c ON c.CUSTOMER_ID = :P_CUSTOMER_ID
    LEFT JOIN TELECOM_DEMO.CUSTOMER_RETENTION.CHURN_PREDICTIONS cp ON c.CUSTOMER_ID = cp.CUSTOMER_ID
    WHERE p.IS_ACTIVE = TRUE
      AND CURRENT_DATE() BETWEEN p.VALID_FROM AND p.VALID_UNTIL
      AND (p.TARGET_SEGMENTS IS NULL OR ARRAY_CONTAINS(c.CUSTOMER_SEGMENT::VARIANT, p.TARGET_SEGMENTS))
      AND (p.MIN_TENURE_MONTHS IS NULL OR DATEDIFF('month', c.CUSTOMER_SINCE, CURRENT_DATE()) >= p.MIN_TENURE_MONTHS)
      AND (cp.CHURN_PROBABILITY IS NULL OR p.MAX_CHURN_SCORE >= cp.CHURN_PROBABILITY)
    ORDER BY p.SUCCESS_RATE DESC
    LIMIT 5;
    
    RETURN OBJECT_CONSTRUCT(
        'customer_id', P_CUSTOMER_ID,
        'recommendations', v_result,
        'generated_at', CURRENT_TIMESTAMP()::VARCHAR
    );
END;
$$;

--------------------------------------------------------------------------------
-- TOOL 3: UPDATE_CHURN_PREDICTION (Alternative without SPCS)
-- Rule-based churn prediction when SPCS is not available
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE TELECOM_DEMO.CUSTOMER_RETENTION.CALCULATE_CHURN_RISK(
    P_CUSTOMER_ID VARCHAR
)
RETURNS VARIANT
LANGUAGE SQL
AS
$$
DECLARE
    v_churn_probability FLOAT;
    v_risk_category VARCHAR;
    v_risk_factors ARRAY;
    v_recommended_actions ARRAY;
    v_avg_data_usage_pct FLOAT;
    v_avg_days_inactive FLOAT;
    v_avg_signal_strength FLOAT;
    v_total_dropped_calls INT;
    v_coverage_issues_count INT;
    v_complaint_count INT;
    v_negative_sentiment_count INT;
    v_avg_nps_score FLOAT;
    v_contract_months_remaining INT;
    v_tenure_months INT;
BEGIN
    -- Get all metrics in one query
    SELECT 
        DATEDIFF('month', c.CUSTOMER_SINCE, CURRENT_DATE()),
        DATEDIFF('month', CURRENT_DATE(), s.CONTRACT_END_DATE),
        COALESCE(u.avg_data_usage_pct, 50),
        COALESCE(u.avg_days_inactive, 0),
        COALESCE(n.avg_signal, -70),
        COALESCE(n.dropped_calls, 0),
        COALESCE(n.coverage_issues, 0),
        COALESCE(cc.complaint_count, 0),
        COALESCE(cc.neg_sentiment, 0),
        COALESCE(cc.avg_nps, 7)
    INTO 
        :v_tenure_months,
        :v_contract_months_remaining,
        :v_avg_data_usage_pct,
        :v_avg_days_inactive,
        :v_avg_signal_strength,
        :v_total_dropped_calls,
        :v_coverage_issues_count,
        :v_complaint_count,
        :v_negative_sentiment_count,
        :v_avg_nps_score
    FROM TELECOM_DEMO.CUSTOMER_RETENTION.CUSTOMERS c
    LEFT JOIN (
        SELECT CUSTOMER_ID, MONTHLY_FEE, CONTRACT_END_DATE,
               ROW_NUMBER() OVER (PARTITION BY CUSTOMER_ID ORDER BY CONTRACT_START_DATE DESC) AS rn
        FROM TELECOM_DEMO.CUSTOMER_RETENTION.SUBSCRIPTIONS
        WHERE STATUS = 'Active'
    ) s ON c.CUSTOMER_ID = s.CUSTOMER_ID AND s.rn = 1
    LEFT JOIN (
        SELECT CUSTOMER_ID, AVG(DATA_USAGE_PCT) AS avg_data_usage_pct, AVG(DAYS_SINCE_LAST_USAGE) AS avg_days_inactive
        FROM TELECOM_DEMO.CUSTOMER_RETENTION.USAGE_METRICS
        WHERE USAGE_MONTH >= DATEADD('month', -3, CURRENT_DATE())
        GROUP BY CUSTOMER_ID
    ) u ON c.CUSTOMER_ID = u.CUSTOMER_ID
    LEFT JOIN (
        SELECT CUSTOMER_ID, AVG(AVG_SIGNAL_STRENGTH_DBM) AS avg_signal, SUM(DROPPED_CALLS) AS dropped_calls,
               SUM(CASE WHEN COVERAGE_ISSUES_REPORTED THEN 1 ELSE 0 END) AS coverage_issues
        FROM TELECOM_DEMO.CUSTOMER_RETENTION.NETWORK_STATS
        WHERE STAT_DATE >= DATEADD('day', -30, CURRENT_DATE())
        GROUP BY CUSTOMER_ID
    ) n ON c.CUSTOMER_ID = n.CUSTOMER_ID
    LEFT JOIN (
        SELECT CUSTOMER_ID, COUNT(*) AS complaint_count, 
               SUM(CASE WHEN CUSTOMER_SENTIMENT IN ('Negative', 'Very Negative') THEN 1 ELSE 0 END) AS neg_sentiment,
               AVG(NPS_SCORE) AS avg_nps
        FROM TELECOM_DEMO.CUSTOMER_RETENTION.CALL_CENTER_LOGS
        WHERE INTERACTION_DATE >= DATEADD('month', -6, CURRENT_TIMESTAMP())
        GROUP BY CUSTOMER_ID
    ) cc ON c.CUSTOMER_ID = cc.CUSTOMER_ID
    WHERE c.CUSTOMER_ID = :P_CUSTOMER_ID;
    
    -- Calculate churn probability
    v_churn_probability := LEAST(1.0, GREATEST(0.0,
        0.1
        + CASE WHEN v_avg_data_usage_pct < 30 THEN 0.15 ELSE 0 END
        + CASE WHEN v_avg_days_inactive > 7 THEN 0.10 ELSE 0 END
        + CASE WHEN v_avg_signal_strength < -85 THEN 0.15 ELSE 0 END
        + CASE WHEN v_total_dropped_calls > 3 THEN 0.10 ELSE 0 END
        + CASE WHEN v_coverage_issues_count > 0 THEN 0.10 ELSE 0 END
        + CASE WHEN v_complaint_count > 2 THEN 0.10 ELSE 0 END
        + CASE WHEN v_negative_sentiment_count > 1 THEN 0.10 ELSE 0 END
        + CASE WHEN v_avg_nps_score < 5 THEN 0.10 ELSE 0 END
        + CASE WHEN v_contract_months_remaining < 3 THEN 0.10 ELSE 0 END
        - CASE WHEN v_tenure_months > 24 THEN 0.05 ELSE 0 END
    ));
    
    -- Determine risk category
    v_risk_category := CASE 
        WHEN v_churn_probability >= 0.60 THEN 'High'
        WHEN v_churn_probability >= 0.30 THEN 'Medium'
        ELSE 'Low'
    END;
    
    -- Build risk factors array
    v_risk_factors := ARRAY_CONSTRUCT();
    IF (v_avg_data_usage_pct < 30) THEN
        v_risk_factors := ARRAY_APPEND(v_risk_factors, 'Low data usage');
    END IF;
    IF (v_avg_days_inactive > 7) THEN
        v_risk_factors := ARRAY_APPEND(v_risk_factors, 'Extended inactivity');
    END IF;
    IF (v_avg_signal_strength < -85) THEN
        v_risk_factors := ARRAY_APPEND(v_risk_factors, 'Poor network signal');
    END IF;
    IF (v_total_dropped_calls > 3) THEN
        v_risk_factors := ARRAY_APPEND(v_risk_factors, 'Frequent dropped calls');
    END IF;
    IF (v_coverage_issues_count > 0) THEN
        v_risk_factors := ARRAY_APPEND(v_risk_factors, 'Network coverage complaints');
    END IF;
    IF (v_complaint_count > 2) THEN
        v_risk_factors := ARRAY_APPEND(v_risk_factors, 'Multiple support complaints');
    END IF;
    IF (v_negative_sentiment_count > 1) THEN
        v_risk_factors := ARRAY_APPEND(v_risk_factors, 'Negative sentiment');
    END IF;
    IF (v_avg_nps_score < 5) THEN
        v_risk_factors := ARRAY_APPEND(v_risk_factors, 'Low NPS score');
    END IF;
    IF (v_contract_months_remaining < 3) THEN
        v_risk_factors := ARRAY_APPEND(v_risk_factors, 'Contract ending soon');
    END IF;
    
    -- Determine recommended actions
    v_recommended_actions := CASE 
        WHEN v_churn_probability >= 0.60 THEN 
            ARRAY_CONSTRUCT('Immediate retention call', 'Offer Win-Back Special (PROMO-002)', 'Escalate to retention specialist')
        WHEN v_churn_probability >= 0.30 THEN 
            ARRAY_CONSTRUCT('Proactive outreach', 'Offer loyalty discount (PROMO-001)', 'Send engagement campaign')
        ELSE 
            ARRAY_CONSTRUCT('Continue monitoring', 'Include in loyalty program')
    END;
    
    -- Update churn predictions table
    MERGE INTO TELECOM_DEMO.CUSTOMER_RETENTION.CHURN_PREDICTIONS t
    USING (SELECT 
        'PRED-' || :P_CUSTOMER_ID || '-' || TO_CHAR(CURRENT_DATE(), 'YYYYMMDD') AS prediction_id,
        :P_CUSTOMER_ID AS customer_id,
        CURRENT_DATE() AS prediction_date,
        :v_churn_probability AS churn_probability,
        :v_risk_category AS risk_category,
        :v_risk_factors AS risk_factors,
        :v_recommended_actions AS actions
    ) s
    ON t.CUSTOMER_ID = s.customer_id AND t.PREDICTION_DATE = s.prediction_date
    WHEN MATCHED THEN UPDATE SET
        CHURN_PROBABILITY = s.churn_probability,
        CHURN_RISK_CATEGORY = s.risk_category,
        TOP_CHURN_FACTORS = s.risk_factors,
        RECOMMENDED_ACTIONS = s.actions,
        MODEL_VERSION = 'v2.0.0-rules'
    WHEN NOT MATCHED THEN INSERT (
        PREDICTION_ID, CUSTOMER_ID, PREDICTION_DATE, CHURN_PROBABILITY,
        CHURN_RISK_CATEGORY, TOP_CHURN_FACTORS, RECOMMENDED_ACTIONS, MODEL_VERSION,
        CONFIDENCE_SCORE, DAYS_UNTIL_LIKELY_CHURN
    ) VALUES (
        s.prediction_id, s.customer_id, s.prediction_date, s.churn_probability,
        s.risk_category, s.risk_factors, s.actions, 'v2.0.0-rules',
        0.85, CASE WHEN s.risk_category = 'High' THEN 14 WHEN s.risk_category = 'Medium' THEN 45 ELSE 180 END
    );
    
    RETURN OBJECT_CONSTRUCT(
        'customer_id', P_CUSTOMER_ID,
        'churn_probability', v_churn_probability,
        'churn_risk_category', v_risk_category,
        'top_churn_factors', v_risk_factors,
        'recommended_actions', v_recommended_actions,
        'model_version', 'v2.0.0-rules',
        'prediction_date', CURRENT_DATE()::VARCHAR
    );
END;
$$;

--------------------------------------------------------------------------------
-- Grant permissions
--------------------------------------------------------------------------------
GRANT USAGE ON PROCEDURE TELECOM_DEMO.CUSTOMER_RETENTION.SEND_EMAIL(VARCHAR, VARCHAR, VARCHAR) 
    TO ROLE ACCOUNTADMIN;
GRANT USAGE ON PROCEDURE TELECOM_DEMO.CUSTOMER_RETENTION.GET_RECOMMENDED_PROMOTIONS(VARCHAR) 
    TO ROLE ACCOUNTADMIN;
GRANT USAGE ON PROCEDURE TELECOM_DEMO.CUSTOMER_RETENTION.CALCULATE_CHURN_RISK(VARCHAR) 
    TO ROLE ACCOUNTADMIN;

--------------------------------------------------------------------------------
-- TOOL 5: WEB_SEARCH (Simulated for Demo)
-- Returns realistic competitor and industry data for telecom retention scenarios
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE TELECOM_DEMO.CUSTOMER_RETENTION.WEB_SEARCH(
    P_QUERY VARCHAR
)
RETURNS VARIANT
LANGUAGE SQL
AS
$$
DECLARE
    v_results ARRAY;
    v_query_lower VARCHAR;
BEGIN
    v_query_lower := LOWER(P_QUERY);
    v_results := ARRAY_CONSTRUCT();
    
    -- Competitor retention offers
    IF (v_query_lower LIKE '%competitor%' OR v_query_lower LIKE '%retention%offer%' OR v_query_lower LIKE '%rival%') THEN
        v_results := ARRAY_CAT(v_results, ARRAY_CONSTRUCT(
            OBJECT_CONSTRUCT(
                'title', 'Verizon Launches Aggressive Retention Program',
                'source', 'TelecomNews.com',
                'date', '2025-01-10',
                'snippet', 'Verizon is offering up to 40% discount for 12 months to customers who call to cancel. The program also includes free device upgrades for premium tier customers and waived early termination fees.',
                'url', 'https://telecomnews.com/verizon-retention-2025'
            ),
            OBJECT_CONSTRUCT(
                'title', 'AT&T Customer Win-Back Strategy Revealed',
                'source', 'MobileWorldLive',
                'date', '2025-01-08',
                'snippet', 'AT&T is targeting churned customers with $200 bill credits and free HBO Max subscription for 24 months. Sources indicate a 35% success rate in winning back departed customers.',
                'url', 'https://mobileworldlive.com/att-winback'
            ),
            OBJECT_CONSTRUCT(
                'title', 'T-Mobile Un-carrier Retention Benefits',
                'source', 'FierceWireless',
                'date', '2025-01-05',
                'snippet', 'T-Mobile offers loyalty customers free international roaming, priority customer service, and annual device upgrade credits worth up to $500. Churn rate decreased 15% after program launch.',
                'url', 'https://fiercewireless.com/tmobile-loyalty'
            )
        ));
    END IF;
    
    -- Churn statistics and benchmarks
    IF (v_query_lower LIKE '%churn%rate%' OR v_query_lower LIKE '%benchmark%' OR v_query_lower LIKE '%industry%average%' OR v_query_lower LIKE '%statistic%') THEN
        v_results := ARRAY_CAT(v_results, ARRAY_CONSTRUCT(
            OBJECT_CONSTRUCT(
                'title', '2025 Telecom Churn Benchmarks Report',
                'source', 'Gartner Research',
                'date', '2025-01-15',
                'snippet', 'Average monthly churn in US telecom: Postpaid 1.2%, Prepaid 3.8%. Top churn drivers: Network quality (32%), Price (28%), Customer service (22%), Better competitor offer (18%).',
                'url', 'https://gartner.com/telecom-churn-2025'
            ),
            OBJECT_CONSTRUCT(
                'title', 'Customer Retention Cost Analysis',
                'source', 'McKinsey Telecom',
                'date', '2025-01-12',
                'snippet', 'Acquiring new telecom customer costs 5-7x more than retention. Average customer acquisition cost: $315. Average retention cost: $52. ROI on retention programs: 300-400%.',
                'url', 'https://mckinsey.com/telecom-retention-roi'
            )
        ));
    END IF;
    
    -- Network quality and coverage
    IF (v_query_lower LIKE '%network%' OR v_query_lower LIKE '%coverage%' OR v_query_lower LIKE '%5g%' OR v_query_lower LIKE '%signal%') THEN
        v_results := ARRAY_CAT(v_results, ARRAY_CONSTRUCT(
            OBJECT_CONSTRUCT(
                'title', 'Network Quality Impact on Customer Retention',
                'source', 'J.D. Power',
                'date', '2025-01-14',
                'snippet', 'Customers experiencing more than 3 dropped calls per month are 4x more likely to churn. Poor indoor coverage is the #1 complaint leading to cancellation requests.',
                'url', 'https://jdpower.com/network-churn-study'
            ),
            OBJECT_CONSTRUCT(
                'title', '5G Coverage Expansion Plans 2025',
                'source', 'RCR Wireless',
                'date', '2025-01-11',
                'snippet', 'Major carriers plan 40% 5G coverage expansion in suburban areas. Network improvement investments correlate with 20% reduction in churn among affected customers.',
                'url', 'https://rcrwireless.com/5g-expansion-2025'
            )
        ));
    END IF;
    
    -- Customer experience and NPS
    IF (v_query_lower LIKE '%nps%' OR v_query_lower LIKE '%satisfaction%' OR v_query_lower LIKE '%customer experience%' OR v_query_lower LIKE '%service%') THEN
        v_results := ARRAY_CAT(v_results, ARRAY_CONSTRUCT(
            OBJECT_CONSTRUCT(
                'title', 'Telecom NPS Benchmarks 2025',
                'source', 'Bain & Company',
                'date', '2025-01-13',
                'snippet', 'Industry average NPS: 32. Leaders (T-Mobile): 45. Customers with NPS < 5 have 68% higher churn probability. Each 10-point NPS improvement reduces churn by 7%.',
                'url', 'https://bain.com/telecom-nps-2025'
            ),
            OBJECT_CONSTRUCT(
                'title', 'Digital Customer Service Trends',
                'source', 'Forrester',
                'date', '2025-01-09',
                'snippet', 'Self-service app users show 25% lower churn. AI chatbot resolution reduces call center costs by 40%. Proactive outreach to dissatisfied customers recovers 45% of at-risk accounts.',
                'url', 'https://forrester.com/telecom-digital-cx'
            )
        ));
    END IF;
    
    -- Pricing and promotions
    IF (v_query_lower LIKE '%price%' OR v_query_lower LIKE '%discount%' OR v_query_lower LIKE '%promotion%' OR v_query_lower LIKE '%deal%' OR v_query_lower LIKE '%offer%') THEN
        v_results := ARRAY_CAT(v_results, ARRAY_CONSTRUCT(
            OBJECT_CONSTRUCT(
                'title', 'Effective Retention Offer Strategies',
                'source', 'Harvard Business Review',
                'date', '2025-01-07',
                'snippet', 'Most effective retention offers: 1) Bill credits (45% acceptance), 2) Plan upgrades at same price (38%), 3) Device discounts (32%), 4) Free premium features (28%). Personalized offers outperform generic by 3x.',
                'url', 'https://hbr.org/telecom-retention-offers'
            ),
            OBJECT_CONSTRUCT(
                'title', 'Competitor Pricing Comparison Q1 2025',
                'source', 'WhistleOut',
                'date', '2025-01-16',
                'snippet', 'Average unlimited plan: Verizon $80, AT&T $75, T-Mobile $70. Family plan savings range 20-35%. Contract vs no-contract price gap narrowing to 5-10%.',
                'url', 'https://whistleout.com/telecom-pricing-2025'
            )
        ));
    END IF;
    
    -- Default results if no specific match
    IF (ARRAY_SIZE(v_results) = 0) THEN
        v_results := ARRAY_CONSTRUCT(
            OBJECT_CONSTRUCT(
                'title', 'Telecom Industry Trends 2025',
                'source', 'Deloitte Insights',
                'date', '2025-01-14',
                'snippet', 'Key trends: AI-driven customer service, 5G monetization, bundled services growth, and intensified focus on customer retention as market saturates. Customer experience now #1 differentiator.',
                'url', 'https://deloitte.com/telecom-trends-2025'
            ),
            OBJECT_CONSTRUCT(
                'title', 'Mobile Customer Behavior Study',
                'source', 'PwC Strategy&',
                'date', '2025-01-10',
                'snippet', 'Average customer tenure: 4.2 years. Contract renewal is highest churn risk period. 67% of customers research competitors before renewal. Proactive retention contact increases renewal rate by 23%.',
                'url', 'https://strategyand.pwc.com/mobile-behavior'
            )
        );
    END IF;
    
    RETURN OBJECT_CONSTRUCT(
        'query', P_QUERY,
        'results_count', ARRAY_SIZE(v_results),
        'results', v_results,
        'search_timestamp', CURRENT_TIMESTAMP()::VARCHAR,
        'note', 'Simulated web search results for demo purposes'
    );
END;
$$;

GRANT USAGE ON PROCEDURE TELECOM_DEMO.CUSTOMER_RETENTION.WEB_SEARCH(VARCHAR) 
    TO ROLE ACCOUNTADMIN;

--------------------------------------------------------------------------------
-- Test the procedures
--------------------------------------------------------------------------------
-- CALL TELECOM_DEMO.CUSTOMER_RETENTION.GET_RECOMMENDED_PROMOTIONS('CUST-000001');
-- CALL TELECOM_DEMO.CUSTOMER_RETENTION.CALCULATE_CHURN_RISK('CUST-000001');
-- CALL TELECOM_DEMO.CUSTOMER_RETENTION.SEND_EMAIL('Test Subject', 'Test Body', 'Test');
-- CALL TELECOM_DEMO.CUSTOMER_RETENTION.WEB_SEARCH('competitor retention offers');
