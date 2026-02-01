#!/bin/bash
################################################################################
# SPCS Deployment Script for Churn Prediction Model
# Run this script from the telecom_retention_demo directory
################################################################################

set -e

# Configuration - UPDATE THESE VALUES
# Get REGISTRY_HOST from: SHOW IMAGE REPOSITORIES IN SCHEMA TELECOM_DEMO.SPCS;
# The repository_url column shows: <orgname>-<accountname>.registry.snowflakecomputing.com/telecom_demo/spcs/churn_model_repo
SNOWFLAKE_ORG=""               # Your Snowflake org name (e.g., "myorg")
SNOWFLAKE_ACCOUNT=""           # Your Snowflake account name (e.g., "myaccount")
SNOWFLAKE_USER=""              # Your Snowflake username (e.g., "YOUR_USERNAME")

# Image settings
IMAGE_NAME="churn-predictor"
IMAGE_TAG="latest"
REPOSITORY_PATH="telecom_demo/spcs/churn_model_repo"

# Derived values - construct registry URL
if [ -n "$SNOWFLAKE_ORG" ] && [ -n "$SNOWFLAKE_ACCOUNT" ]; then
    REGISTRY_HOST="${SNOWFLAKE_ORG}-${SNOWFLAKE_ACCOUNT}.registry.snowflakecomputing.com"
elif [ -n "$SNOWFLAKE_ACCOUNT" ]; then
    REGISTRY_HOST="${SNOWFLAKE_ACCOUNT}.registry.snowflakecomputing.com"
else
    REGISTRY_HOST=""
fi
FULL_IMAGE_PATH="${REGISTRY_HOST}/${REPOSITORY_PATH}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "=============================================="
echo "SPCS Deployment Script for Churn Predictor"
echo "=============================================="
echo ""

# Check prerequisites
check_prerequisites() {
    echo "[1/6] Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        echo "ERROR: Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        echo "ERROR: Docker daemon is not running. Please start Docker."
        exit 1
    fi
    
    echo "✓ Docker is available"
    echo ""
}

# Build Docker image
build_image() {
    echo "[2/6] Building Docker image..."
    echo "    Image: ${IMAGE_NAME}:${IMAGE_TAG}"
    echo ""
    
    cd ml_model
    
    docker build \
        --platform linux/amd64 \
        -t ${IMAGE_NAME}:${IMAGE_TAG} \
        .
    
    cd ..
    
    echo "✓ Image built successfully"
    echo ""
}

# Test image locally (optional)
test_image_locally() {
    echo "[3/6] Testing image locally..."
    echo ""
    
    # Start container
    docker run -d --name churn-test -p 8000:8000 ${IMAGE_NAME}:${IMAGE_TAG}
    
    # Wait for startup
    echo "    Waiting for service to start..."
    sleep 5
    
    # Test health endpoint
    if curl -s http://localhost:8000/health | grep -q "healthy"; then
        echo "✓ Health check passed"
    else
        echo "WARNING: Health check did not return expected response"
    fi
    
    # Test prediction endpoint
    echo "    Testing prediction endpoint..."
    RESPONSE=$(curl -s -X POST http://localhost:8000/predict \
        -H "Content-Type: application/json" \
        -d '{
            "customer_id": "CUST-TEST",
            "avg_data_usage_pct": 25,
            "data_usage_trend": -0.3,
            "avg_voice_usage_pct": 40,
            "avg_days_inactive": 8,
            "avg_signal_strength": -92,
            "total_dropped_calls": 5,
            "coverage_issues_count": 2,
            "complaint_count": 3,
            "negative_sentiment_count": 2,
            "avg_nps_score": 4,
            "tenure_months": 18,
            "monthly_fee": 75,
            "payment_issues_count": 1,
            "customer_segment": "Standard",
            "contract_months_remaining": 2
        }')
    
    if echo "$RESPONSE" | grep -q "churn_probability"; then
        echo "✓ Prediction endpoint working"
        echo "    Sample response: $(echo $RESPONSE | head -c 200)..."
    else
        echo "WARNING: Prediction test did not return expected response"
    fi
    
    # Cleanup
    docker stop churn-test && docker rm churn-test
    
    echo ""
}

# Login to Snowflake registry
login_to_registry() {
    echo "[4/6] Logging into Snowflake Container Registry..."
    echo "    Registry: ${REGISTRY_HOST}"
    echo ""
    
    if [ -z "$SNOWFLAKE_USER" ]; then
        read -p "    Enter your Snowflake username: " SNOWFLAKE_USER
    fi
    
    echo "    Please enter your Snowflake password when prompted..."
    docker login ${REGISTRY_HOST} -u ${SNOWFLAKE_USER}
    
    echo "✓ Logged into registry"
    echo ""
}

# Tag and push image
push_image() {
    echo "[5/6] Tagging and pushing image to Snowflake..."
    echo "    Target: ${FULL_IMAGE_PATH}"
    echo ""
    
    # Tag for Snowflake
    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${FULL_IMAGE_PATH}
    
    # Push to registry
    echo "    Pushing image (this may take a few minutes)..."
    docker push ${FULL_IMAGE_PATH}
    
    echo "✓ Image pushed successfully"
    echo ""
}

# Print next steps
print_next_steps() {
    echo "[6/6] Deployment Complete!"
    echo ""
    echo "=============================================="
    echo "NEXT STEPS - Run these SQL commands in Snowflake:"
    echo "=============================================="
    echo ""
    echo "-- 1. Verify the image is in the repository:"
    echo "SHOW IMAGES IN IMAGE REPOSITORY TELECOM_DEMO.SPCS.CHURN_MODEL_REPO;"
    echo ""
    echo "-- 2. Create/start the compute pool:"
    echo "CREATE COMPUTE POOL IF NOT EXISTS TELECOM_CHURN_POOL"
    echo "    MIN_NODES = 1"
    echo "    MAX_NODES = 2"
    echo "    INSTANCE_FAMILY = CPU_X64_XS"
    echo "    AUTO_RESUME = TRUE"
    echo "    AUTO_SUSPEND_SECS = 300;"
    echo ""
    echo "-- 3. Create the service:"
    echo "CREATE SERVICE IF NOT EXISTS TELECOM_DEMO.SPCS.CHURN_PREDICTION_SERVICE"
    echo "    IN COMPUTE POOL TELECOM_CHURN_POOL"
    echo "    FROM SPECIFICATION \$\$"
    echo "spec:"
    echo "  containers:"
    echo "  - name: churn-predictor"
    echo "    image: /${REPOSITORY_PATH}/${IMAGE_NAME}:${IMAGE_TAG}"
    echo "    resources:"
    echo "      requests:"
    echo "        memory: 1Gi"
    echo "        cpu: 0.5"
    echo "      limits:"
    echo "        memory: 2Gi"
    echo "        cpu: 1"
    echo "    readinessProbe:"
    echo "      path: /health"
    echo "      port: 8000"
    echo "  endpoints:"
    echo "  - name: predict"
    echo "    port: 8000"
    echo "    public: false"
    echo "\$\$"
    echo "    MIN_INSTANCES = 1"
    echo "    MAX_INSTANCES = 2;"
    echo ""
    echo "-- 4. Check service status:"
    echo "CALL SYSTEM\$GET_SERVICE_STATUS('TELECOM_DEMO.SPCS.CHURN_PREDICTION_SERVICE');"
    echo ""
    echo "-- 5. View logs if needed:"
    echo "CALL SYSTEM\$GET_SERVICE_LOGS('TELECOM_DEMO.SPCS.CHURN_PREDICTION_SERVICE', 0, 'churn-predictor', 100);"
    echo ""
    echo "=============================================="
}

# Main execution
main() {
    echo ""
    echo "This script will:"
    echo "  1. Check prerequisites"
    echo "  2. Build the Docker image"
    echo "  3. Test the image locally"
    echo "  4. Login to Snowflake Container Registry"
    echo "  5. Push the image to Snowflake"
    echo "  6. Provide next steps for SPCS deployment"
    echo ""
    
    # Validate configuration
    if [ -z "$SNOWFLAKE_ACCOUNT" ] && [ -z "$SNOWFLAKE_ORG" ]; then
        echo "ERROR: Please edit this script and set SNOWFLAKE_ORG and SNOWFLAKE_ACCOUNT"
        echo ""
        echo "  How to find these values:"
        echo "  1. Run in Snowflake: SHOW IMAGE REPOSITORIES IN SCHEMA TELECOM_DEMO.SPCS;"
        echo "  2. Look at repository_url column, e.g.:"
        echo "     myorg-myaccount.registry.snowflakecomputing.com/telecom_demo/spcs/churn_model_repo"
        echo "       ^^^^^ ^^^^^^^^^"
        echo "       ORG   ACCOUNT"
        echo ""
        exit 1
    fi
    
    echo "Configuration:"
    echo "  Registry: ${REGISTRY_HOST}"
    echo "  User:     ${SNOWFLAKE_USER:-<will prompt>}"
    echo "  Image:    ${IMAGE_NAME}:${IMAGE_TAG}"
    echo ""
    
    read -p "Continue? (y/n): " CONFIRM
    if [ "$CONFIRM" != "y" ]; then
        echo "Aborted."
        exit 0
    fi
    
    echo ""
    
    check_prerequisites
    build_image
    
    read -p "Test image locally before pushing? (y/n): " TEST_LOCAL
    if [ "$TEST_LOCAL" == "y" ]; then
        test_image_locally
    fi
    
    login_to_registry
    push_image
    print_next_steps
}

# Run main function
main
