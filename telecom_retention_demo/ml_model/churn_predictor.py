"""
Telecom Customer Churn Prediction Model
Deployed to Snowpark Container Services (SPCS)

This model predicts customer churn probability based on:
- Usage metrics (data, voice, SMS usage trends)
- Network experience (signal quality, dropped calls)
- Support interactions (sentiment, complaint frequency)
- Subscription details (plan type, tenure, payment history)
"""

import os
import json
import logging
from datetime import datetime
from typing import Dict, Any, List
import numpy as np
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.preprocessing import StandardScaler
import joblib

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ChurnPredictor:
    """
    Churn prediction model for telecom customers.
    Uses gradient boosting classifier trained on customer features.
    """
    
    def __init__(self, model_path: str = None):
        self.model_path = model_path or "/app/model/churn_model.joblib"
        self.scaler_path = model_path.replace(".joblib", "_scaler.joblib") if model_path else "/app/model/churn_scaler.joblib"
        self.model = None
        self.scaler = None
        self.feature_names = [
            'avg_data_usage_pct',
            'data_usage_trend',
            'avg_voice_usage_pct',
            'avg_days_inactive',
            'avg_signal_strength',
            'total_dropped_calls',
            'coverage_issues_count',
            'complaint_count',
            'negative_sentiment_count',
            'avg_nps_score',
            'tenure_months',
            'monthly_fee',
            'payment_issues_count',
            'is_premium_segment',
            'contract_months_remaining'
        ]
        self.model_version = "v2.0.0"
        
    def load_model(self):
        """Load the trained model and scaler from disk."""
        try:
            if os.path.exists(self.model_path):
                self.model = joblib.load(self.model_path)
                self.scaler = joblib.load(self.scaler_path)
                logger.info(f"Model loaded from {self.model_path}")
            else:
                logger.warning("Model not found, initializing with default model")
                self._initialize_default_model()
        except Exception as e:
            logger.error(f"Error loading model: {e}")
            self._initialize_default_model()
    
    def _initialize_default_model(self):
        """Initialize a default model for demo purposes."""
        np.random.seed(42)
        n_samples = 1000
        X = np.random.randn(n_samples, len(self.feature_names))
        y = (X[:, 0] < -0.5) | (X[:, 3] > 1) | (X[:, 5] > 1) | (X[:, 7] > 1)
        y = y.astype(int)
        
        self.scaler = StandardScaler()
        X_scaled = self.scaler.fit_transform(X)
        
        self.model = GradientBoostingClassifier(
            n_estimators=100,
            max_depth=5,
            learning_rate=0.1,
            random_state=42
        )
        self.model.fit(X_scaled, y)
        logger.info("Default model initialized")
    
    def save_model(self):
        """Save model and scaler to disk."""
        os.makedirs(os.path.dirname(self.model_path), exist_ok=True)
        joblib.dump(self.model, self.model_path)
        joblib.dump(self.scaler, self.scaler_path)
        logger.info(f"Model saved to {self.model_path}")
    
    def predict(self, features: Dict[str, Any]) -> Dict[str, Any]:
        """
        Predict churn probability for a single customer.
        
        Args:
            features: Dictionary with customer features
            
        Returns:
            Dictionary with churn probability and risk category
        """
        if self.model is None:
            self.load_model()
        
        feature_vector = self._extract_features(features)
        feature_array = np.array(feature_vector).reshape(1, -1)
        feature_scaled = self.scaler.transform(feature_array)
        
        churn_prob = self.model.predict_proba(feature_scaled)[0][1]
        risk_category = self._get_risk_category(churn_prob)
        top_factors = self._get_top_churn_factors(features, feature_vector)
        recommended_actions = self._get_recommended_actions(risk_category, features)
        days_until_churn = self._estimate_days_until_churn(churn_prob, features)
        
        return {
            "customer_id": features.get("customer_id", "unknown"),
            "churn_probability": round(float(churn_prob), 4),
            "churn_risk_category": risk_category,
            "top_churn_factors": top_factors,
            "recommended_actions": recommended_actions,
            "model_version": self.model_version,
            "confidence_score": round(float(max(churn_prob, 1 - churn_prob)), 4),
            "days_until_likely_churn": days_until_churn,
            "prediction_timestamp": datetime.utcnow().isoformat()
        }
    
    def predict_batch(self, customers: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Predict churn for multiple customers."""
        return [self.predict(customer) for customer in customers]
    
    def _extract_features(self, features: Dict[str, Any]) -> List[float]:
        """Extract feature vector from customer data."""
        return [
            features.get('avg_data_usage_pct', 50) / 100,
            features.get('data_usage_trend', 0),
            features.get('avg_voice_usage_pct', 50) / 100,
            features.get('avg_days_inactive', 1),
            (features.get('avg_signal_strength', -70) + 110) / 60,
            features.get('total_dropped_calls', 0),
            features.get('coverage_issues_count', 0),
            features.get('complaint_count', 0),
            features.get('negative_sentiment_count', 0),
            features.get('avg_nps_score', 7) / 10,
            features.get('tenure_months', 12) / 60,
            features.get('monthly_fee', 50) / 100,
            features.get('payment_issues_count', 0),
            1 if features.get('customer_segment', 'Standard') == 'Premium' else 0,
            features.get('contract_months_remaining', 12) / 24
        ]
    
    def _get_risk_category(self, probability: float) -> str:
        """Categorize churn risk based on probability."""
        if probability >= 0.60:
            return "High"
        elif probability >= 0.30:
            return "Medium"
        return "Low"
    
    def _get_top_churn_factors(self, features: Dict[str, Any], feature_vector: List[float]) -> List[str]:
        """Identify top contributing factors to churn risk."""
        factors = []
        
        if features.get('avg_data_usage_pct', 100) < 30:
            factors.append("Low data usage (< 30% of plan)")
        
        if features.get('data_usage_trend', 0) < -0.2:
            factors.append("Declining usage trend")
        
        if features.get('avg_signal_strength', -70) < -85:
            factors.append("Poor network signal quality")
        
        if features.get('total_dropped_calls', 0) > 3:
            factors.append("Frequent dropped calls")
        
        if features.get('coverage_issues_count', 0) > 0:
            factors.append("Network coverage complaints")
        
        if features.get('complaint_count', 0) > 2:
            factors.append("Multiple support complaints")
        
        if features.get('negative_sentiment_count', 0) > 1:
            factors.append("Negative customer sentiment")
        
        if features.get('avg_nps_score', 7) < 5:
            factors.append("Low NPS score")
        
        if features.get('payment_issues_count', 0) > 0:
            factors.append("Payment issues")
        
        if features.get('contract_months_remaining', 12) < 3:
            factors.append("Contract ending soon")
        
        if features.get('avg_days_inactive', 0) > 7:
            factors.append("Extended inactivity period")
        
        return factors[:5] if factors else ["No significant risk factors identified"]
    
    def _get_recommended_actions(self, risk_category: str, features: Dict[str, Any]) -> List[str]:
        """Generate recommended retention actions."""
        actions = []
        
        if risk_category == "High":
            actions.append("Immediate retention call from specialized agent")
            
            if features.get('avg_signal_strength', -70) < -85:
                actions.append("Offer network issue compensation (PROMO-006)")
                actions.append("Schedule network assessment for customer location")
            
            actions.append("Offer Win-Back Special (PROMO-002) - 3 free months")
            actions.append("Escalate to retention specialist")
            
        elif risk_category == "Medium":
            actions.append("Proactive customer outreach within 7 days")
            
            if features.get('avg_data_usage_pct', 100) < 30:
                actions.append("Offer Data Boost Upgrade (PROMO-003)")
            
            actions.append("Offer Loyalty Reward 20% discount (PROMO-001)")
            actions.append("Send personalized engagement campaign")
            
        else:
            actions.append("Continue regular monitoring")
            actions.append("Include in loyalty program communications")
            actions.append("Offer referral incentives")
        
        if features.get('customer_segment') == 'Premium':
            actions.append("Consider Premium Device Deal (PROMO-004)")
        
        return actions
    
    def _estimate_days_until_churn(self, probability: float, features: Dict[str, Any]) -> int:
        """Estimate days until likely churn based on probability and features."""
        base_days = int((1 - probability) * 180)
        
        if features.get('contract_months_remaining', 12) < 3:
            base_days = min(base_days, features.get('contract_months_remaining', 3) * 30)
        
        if features.get('negative_sentiment_count', 0) > 2:
            base_days = int(base_days * 0.7)
        
        return max(7, min(365, base_days))


def create_model_instance():
    """Factory function to create and initialize the model."""
    predictor = ChurnPredictor()
    predictor.load_model()
    return predictor


MODEL_INSTANCE = None

def get_model():
    """Get or create the singleton model instance."""
    global MODEL_INSTANCE
    if MODEL_INSTANCE is None:
        MODEL_INSTANCE = create_model_instance()
    return MODEL_INSTANCE


def predict_churn_handler(features: Dict[str, Any]) -> Dict[str, Any]:
    """
    Handler function for churn prediction API endpoint.
    
    Args:
        features: Customer features dictionary
        
    Returns:
        Prediction result dictionary
    """
    model = get_model()
    return model.predict(features)


def predict_batch_handler(customers: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Handler function for batch churn prediction API endpoint.
    
    Args:
        customers: List of customer feature dictionaries
        
    Returns:
        List of prediction result dictionaries
    """
    model = get_model()
    return model.predict_batch(customers)


if __name__ == "__main__":
    test_customer = {
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
    
    result = predict_churn_handler(test_customer)
    print(json.dumps(result, indent=2))
