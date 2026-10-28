# =============================================================================
# The Scheduler - Model Training Pipeline
# Agent AI-14: Model Training Pipeline
# =============================================================================
"""
Model training pipeline for The Scheduler AI services.

This package provides tools for:
- Exporting training data from Firestore
- Training no-show prediction models with LightGBM
- Evaluating model performance
- Deploying models to the prediction service

Usage:
    # Export training data
    python -m training.export_training_data --business-id=<id> --output=data/

    # Train model
    python -m training.train_no_show_model --data=data/features.parquet

    # Evaluate model
    python -m training.evaluate_model --model=models/noshow_v1.lgb --test=data/test.parquet

    # Deploy model
    python -m training.deploy_model --model=models/noshow_v1.lgb --service-url=http://localhost:8001
"""

__version__ = "1.0.0"
__author__ = "The Scheduler AI Team"
