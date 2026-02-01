"""
FastAPI service for Churn Prediction Model
Deployed on Snowpark Container Services (SPCS)
"""

from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
import logging
from churn_predictor import predict_churn_handler, predict_batch_handler, get_model

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Telecom Churn Prediction API",
    description="ML-powered customer churn prediction for telecom customer retention",
    version="2.0.0"
)

# Field names in order for Snowflake service function calls
SNOWFLAKE_FIELD_ORDER = [
    "customer_id",
    "avg_data_usage_pct",
    "data_usage_trend",
    "avg_voice_usage_pct",
    "avg_days_inactive",
    "avg_signal_strength",
    "total_dropped_calls",
    "coverage_issues_count",
    "complaint_count",
    "negative_sentiment_count",
    "avg_nps_score",
    "tenure_months",
    "monthly_fee",
    "payment_issues_count",
    "customer_segment",
    "contract_months_remaining"
]


class CustomerFeatures(BaseModel):
    """Input schema for customer features."""
    customer_id: str = Field(..., description="Unique customer identifier")
    avg_data_usage_pct: float = Field(50, ge=0, le=200, description="Average data usage as percentage of limit")
    data_usage_trend: float = Field(0, ge=-1, le=1, description="Usage trend (-1 to 1, negative = declining)")
    avg_voice_usage_pct: float = Field(50, ge=0, le=200, description="Average voice usage percentage")
    avg_days_inactive: int = Field(1, ge=0, description="Average days since last usage")
    avg_signal_strength: int = Field(-70, ge=-120, le=-30, description="Signal strength in dBm")
    total_dropped_calls: int = Field(0, ge=0, description="Total dropped calls in period")
    coverage_issues_count: int = Field(0, ge=0, description="Number of coverage complaints")
    complaint_count: int = Field(0, ge=0, description="Total support complaints")
    negative_sentiment_count: int = Field(0, ge=0, description="Interactions with negative sentiment")
    avg_nps_score: float = Field(7, ge=0, le=10, description="Average NPS score")
    tenure_months: int = Field(12, ge=0, description="Customer tenure in months")
    monthly_fee: float = Field(50, ge=0, description="Monthly subscription fee")
    payment_issues_count: int = Field(0, ge=0, description="Number of payment issues")
    customer_segment: str = Field("Standard", description="Customer segment (Premium/Standard/Budget)")
    contract_months_remaining: int = Field(12, ge=0, description="Months until contract ends")

    class Config:
        json_schema_extra = {
            "example": {
                "customer_id": "CUST-000001",
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
            }
        }


class PredictionResponse(BaseModel):
    """Output schema for churn prediction."""
    customer_id: str
    churn_probability: float = Field(..., ge=0, le=1, description="Probability of churn (0-1)")
    churn_risk_category: str = Field(..., description="Risk category: High, Medium, or Low")
    top_churn_factors: List[str] = Field(..., description="Top contributing factors")
    recommended_actions: List[str] = Field(..., description="Recommended retention actions")
    model_version: str
    confidence_score: float
    days_until_likely_churn: int
    prediction_timestamp: str


class BatchPredictionRequest(BaseModel):
    """Request schema for batch predictions."""
    customers: List[CustomerFeatures]


class BatchPredictionResponse(BaseModel):
    """Response schema for batch predictions."""
    predictions: List[PredictionResponse]
    total_processed: int
    high_risk_count: int
    medium_risk_count: int
    low_risk_count: int


class HealthResponse(BaseModel):
    """Health check response."""
    status: str
    model_loaded: bool
    model_version: str


def parse_snowflake_request(data: List[List]) -> List[Dict]:
    """
    Parse Snowflake service function format into feature dictionaries.
    
    Snowflake sends: {"data": [[row_idx, param1, param2, ...], ...]}
    """
    results = []
    for row in data:
        # First element is the row index from Snowflake
        row_idx = row[0]
        values = row[1:]  # Actual parameter values
        
        # Map values to field names
        features = {}
        for i, field_name in enumerate(SNOWFLAKE_FIELD_ORDER):
            if i < len(values):
                features[field_name] = values[i]
        
        features['_row_idx'] = row_idx  # Keep row index for response
        results.append(features)
    
    return results


def format_snowflake_response(results: List[Dict]) -> Dict:
    """
    Format response for Snowflake service function.
    
    Snowflake expects: {"data": [[row_idx, result], ...]}
    """
    data = []
    for result in results:
        row_idx = result.pop('_row_idx', 0)
        data.append([row_idx, result])
    
    return {"data": data}


@app.on_event("startup")
async def startup_event():
    """Initialize model on startup."""
    logger.info("Starting Churn Prediction API...")
    get_model()
    logger.info("Model initialized successfully")


@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Check API health and model status."""
    try:
        model = get_model()
        return HealthResponse(
            status="healthy",
            model_loaded=model.model is not None,
            model_version=model.model_version
        )
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return HealthResponse(
            status="unhealthy",
            model_loaded=False,
            model_version="unknown"
        )


@app.post("/predict")
async def predict_churn(request: Request):
    """
    Predict churn probability for a single customer.
    
    Supports both:
    - Direct JSON object with named fields (for testing)
    - Snowflake service function format: {"data": [[row_idx, ...], ...]}
    """
    try:
        body = await request.json()
        
        # Check if this is Snowflake format (has "data" array)
        if "data" in body and isinstance(body["data"], list):
            logger.info(f"Received Snowflake format request with {len(body['data'])} rows")
            
            # Parse Snowflake format
            customers = parse_snowflake_request(body["data"])
            
            # Process each row
            results = []
            for features in customers:
                row_idx = features.pop('_row_idx', 0)
                result = predict_churn_handler(features)
                result['_row_idx'] = row_idx
                results.append(result)
            
            # Return in Snowflake format
            return format_snowflake_response(results)
        
        else:
            # Direct JSON format (for local testing)
            logger.info("Received direct JSON format request")
            features = CustomerFeatures(**body)
            result = predict_churn_handler(features.model_dump())
            return PredictionResponse(**result)
            
    except Exception as e:
        logger.error(f"Prediction error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/predict/batch", response_model=BatchPredictionResponse)
async def predict_churn_batch(request: BatchPredictionRequest):
    """
    Predict churn probability for multiple customers.
    
    Returns predictions for all customers along with summary statistics.
    """
    try:
        customers_data = [c.model_dump() for c in request.customers]
        results = predict_batch_handler(customers_data)
        
        predictions = [PredictionResponse(**r) for r in results]
        
        high_risk = sum(1 for p in predictions if p.churn_risk_category == "High")
        medium_risk = sum(1 for p in predictions if p.churn_risk_category == "Medium")
        low_risk = sum(1 for p in predictions if p.churn_risk_category == "Low")
        
        return BatchPredictionResponse(
            predictions=predictions,
            total_processed=len(predictions),
            high_risk_count=high_risk,
            medium_risk_count=medium_risk,
            low_risk_count=low_risk
        )
    except Exception as e:
        logger.error(f"Batch prediction error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/model/info")
async def model_info():
    """Get model information and feature requirements."""
    model = get_model()
    return {
        "model_version": model.model_version,
        "feature_names": model.feature_names,
        "risk_thresholds": {
            "high": "probability >= 0.60",
            "medium": "0.30 <= probability < 0.60",
            "low": "probability < 0.30"
        },
        "description": "Gradient Boosting classifier for telecom customer churn prediction"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
