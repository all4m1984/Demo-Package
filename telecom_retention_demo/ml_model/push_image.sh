#!/bin/bash
################################################################################
# Push Docker Image to Snowflake Registry
# Edit the variables below to match your Snowflake setup
################################################################################

# REQUIRED: Set these to match your Snowflake setup
# Get REGISTRY_HOST from: SHOW IMAGE REPOSITORIES IN SCHEMA TELECOM_DEMO.SPCS;
REGISTRY_HOST="<YOUR_ORG>-<YOUR_ACCOUNT>.registry.snowflakecomputing.com"  # e.g., myorg-myacct.registry.snowflakecomputing.com
SNOWFLAKE_USER="<YOUR_USERNAME>"  # Your Snowflake username

# Repository path (should match your image repository)
REPO_PATH="telecom_demo/spcs/churn_model_repo"
IMAGE_NAME="churn-predictor"
IMAGE_TAG="latest"

# Derived values
FULL_IMAGE="$REGISTRY_HOST/$REPO_PATH/$IMAGE_NAME:$IMAGE_TAG"

################################################################################
# Validation
################################################################################
if [[ "$REGISTRY_HOST" == *"<"* ]]; then
    echo "ERROR: Please edit this script and set REGISTRY_HOST"
    echo "       Get the value from: SHOW IMAGE REPOSITORIES IN SCHEMA TELECOM_DEMO.SPCS;"
    exit 1
fi

if [[ "$SNOWFLAKE_USER" == *"<"* ]]; then
    echo "ERROR: Please edit this script and set SNOWFLAKE_USER"
    exit 1
fi

################################################################################
# Execution
################################################################################
echo "=============================================="
echo "Snowflake Registry Push Script"
echo "=============================================="
echo ""
echo "Registry Host: $REGISTRY_HOST"
echo "Full Image:    $FULL_IMAGE"
echo ""

# Login to Snowflake registry
echo "[1/3] Logging into Snowflake registry..."
docker login $REGISTRY_HOST -u $SNOWFLAKE_USER
if [ $? -ne 0 ]; then
    echo "ERROR: Login failed. Check your username and password."
    exit 1
fi
echo ""

# Tag the image
echo "[2/3] Tagging image..."
docker tag $IMAGE_NAME:$IMAGE_TAG $FULL_IMAGE
if [ $? -ne 0 ]; then
    echo "ERROR: Tagging failed. Make sure the local image exists:"
    echo "       docker images | grep $IMAGE_NAME"
    exit 1
fi
echo "Tagged: $FULL_IMAGE"
echo ""

# Push the image
echo "[3/3] Pushing image to Snowflake..."
docker push $FULL_IMAGE
if [ $? -ne 0 ]; then
    echo "ERROR: Push failed. Check your permissions and repository exists."
    exit 1
fi

echo ""
echo "=============================================="
echo "SUCCESS! Image pushed to Snowflake registry"
echo "=============================================="
echo ""
echo "Next steps - run in Snowflake:"
echo "  SHOW IMAGES IN IMAGE REPOSITORY TELECOM_DEMO.SPCS.CHURN_MODEL_REPO;"
echo "  -- Then run sql/05_deploy_spcs.sql to create the service"
