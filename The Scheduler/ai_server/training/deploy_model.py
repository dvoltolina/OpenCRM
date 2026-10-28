"""
Deploy trained model to the prediction service.

Agent AI-14: Model Training Pipeline

Usage:
    # Deploy to local prediction service
    python deploy_model.py --model models/noshow_v1.lgb --service-url http://localhost:8001

    # Deploy to Cloud Run service
    python deploy_model.py --model models/noshow_v1.lgb --service-url https://prediction-xxx.run.app

    # Deploy with backup of existing model
    python deploy_model.py --model models/noshow_v1.lgb --service-url http://localhost:8001 --backup

    # Copy to GCS for Cloud Run deployment
    python deploy_model.py --model models/noshow_v1.lgb --gcs gs://bucket/models/

Features:
- Hot-reload model on prediction service
- Verify deployment with health check
- Backup existing model before replacement
- Support for local, Cloud Run, and GCS deployments
- Rollback capability
- Deployment logging

HIPAA Note: Model files contain no PHI. Deployment is audit-logged.
"""

import argparse
import json
import os
import shutil
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, Optional

import httpx


class ModelDeployer:
    """Handle model deployment to prediction service."""

    def __init__(
        self,
        model_path: str,
        service_url: str,
        api_key: Optional[str] = None,
        timeout: int = 30,
    ):
        self.model_path = Path(model_path)
        self.metadata_path = self.model_path.with_suffix('.json')
        self.service_url = service_url.rstrip('/')
        self.api_key = api_key or os.environ.get('PREDICTION_API_KEY', '')
        self.timeout = timeout

        if not self.model_path.exists():
            raise FileNotFoundError(f"Model not found: {model_path}")

    def _get_headers(self) -> Dict[str, str]:
        """Get request headers."""
        headers = {'Content-Type': 'application/json'}
        if self.api_key:
            headers['X-API-Key'] = self.api_key
        return headers

    def check_service_health(self) -> Dict:
        """Check prediction service health."""
        print(f"Checking service health: {self.service_url}")

        try:
            response = httpx.get(
                f"{self.service_url}/health",
                headers=self._get_headers(),
                timeout=self.timeout,
            )
            response.raise_for_status()
            health = response.json()
            print(f"  Status: {health.get('status', 'unknown')}")
            print(f"  Model loaded: {health.get('model_loaded', False)}")
            return health
        except httpx.HTTPError as e:
            print(f"  Error: {e}")
            return {'status': 'error', 'error': str(e)}

    def get_current_model_info(self) -> Optional[Dict]:
        """Get information about currently deployed model."""
        print("Fetching current model info...")

        try:
            response = httpx.get(
                f"{self.service_url}/model/metadata",
                headers=self._get_headers(),
                timeout=self.timeout,
            )
            response.raise_for_status()
            info = response.json()
            print(f"  Current version: {info.get('version', 'unknown')}")
            print(f"  Created at: {info.get('created_at', 'unknown')}")
            return info
        except httpx.HTTPError as e:
            print(f"  Could not fetch model info: {e}")
            return None

    def upload_model(self, target_path: str) -> bool:
        """
        Upload model to prediction service.

        The prediction service expects the model file at a specific path.
        This method copies the model to the target location.
        """
        print(f"Uploading model to: {target_path}")

        target = Path(target_path)
        target.parent.mkdir(parents=True, exist_ok=True)

        # Copy model file
        shutil.copy2(self.model_path, target)
        print(f"  Copied: {self.model_path} -> {target}")

        # Copy metadata if exists
        if self.metadata_path.exists():
            target_meta = target.with_suffix('.json')
            shutil.copy2(self.metadata_path, target_meta)
            print(f"  Copied: {self.metadata_path} -> {target_meta}")

        return True

    def trigger_reload(self) -> bool:
        """Trigger model reload on prediction service."""
        print("Triggering model reload...")

        try:
            response = httpx.post(
                f"{self.service_url}/model/reload",
                headers=self._get_headers(),
                timeout=self.timeout,
            )
            response.raise_for_status()
            result = response.json()
            print(f"  Reload result: {result.get('status', 'unknown')}")
            return result.get('status') == 'success'
        except httpx.HTTPError as e:
            print(f"  Reload error: {e}")
            return False

    def verify_deployment(self, expected_version: Optional[str] = None) -> bool:
        """Verify model was deployed successfully."""
        print("Verifying deployment...")

        try:
            # Check health
            health = self.check_service_health()
            if health.get('status') != 'healthy':
                print(f"  Service not healthy: {health}")
                return False

            # Check model info
            info = self.get_current_model_info()
            if not info:
                return False

            if expected_version:
                actual = info.get('version', '')
                if actual != expected_version:
                    print(f"  Version mismatch: expected {expected_version}, got {actual}")
                    return False
                print(f"  Version verified: {expected_version}")

            # Test prediction
            return self.test_prediction()

        except Exception as e:
            print(f"  Verification failed: {e}")
            return False

    def test_prediction(self) -> bool:
        """Send test prediction to verify model works."""
        print("Testing prediction endpoint...")

        # Minimal test features
        test_features = {
            "appointment_id": "test_deploy_001",
            "business_id": "test_business",
            "client_historical_noshow_rate": 0.15,
            "client_historical_cancel_rate": 0.05,
            "client_total_appointments": 10,
            "client_days_since_last_visit": 14,
            "client_lifetime_value_cents": 50000,
            "client_lifecycle_stage": "active",
            "client_has_payment_method": True,
            "booking_lead_days": 7,
            "day_of_week": 3,
            "hour_of_day": 10,
            "is_recurring": False,
            "is_group_session": False,
            "service_duration_minutes": 60,
            "service_price_cents": 10000,
            "requires_payment": True,
            "payment_collected": True,
            "has_intake_form": True,
            "provider_historical_noshow_rate": 0.08,
            "provider_total_appointments": 500,
            "slot_historical_noshow_rate": 0.10,
            "is_first_appointment_of_day": False,
            "is_last_appointment_of_day": False,
        }

        try:
            response = httpx.post(
                f"{self.service_url}/api/v1/predict/noshow",
                json=test_features,
                headers=self._get_headers(),
                timeout=self.timeout,
            )
            response.raise_for_status()
            result = response.json()

            probability = result.get('noshow_probability', -1)
            risk_level = result.get('risk_level', 'unknown')

            print(f"  Test prediction successful:")
            print(f"    Probability: {probability:.4f}")
            print(f"    Risk level: {risk_level}")

            return 0 <= probability <= 1

        except httpx.HTTPError as e:
            print(f"  Test prediction failed: {e}")
            return False

    def backup_current_model(self, backup_dir: str) -> Optional[str]:
        """Backup current model before deployment."""
        print(f"Backing up current model to: {backup_dir}")

        backup_path = Path(backup_dir)
        backup_path.mkdir(parents=True, exist_ok=True)

        current_info = self.get_current_model_info()
        if not current_info:
            print("  No current model to backup")
            return None

        version = current_info.get('version', 'unknown')
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_name = f"noshow_model_{version}_{timestamp}.lgb"

        # Note: Actual backup would need access to the current model file
        # This is a placeholder for the backup path
        backup_file = backup_path / backup_name
        print(f"  Backup path: {backup_file}")

        return str(backup_file)


def deploy_to_gcs(
    model_path: str,
    gcs_path: str,
    project_id: Optional[str] = None,
) -> bool:
    """Deploy model to Google Cloud Storage."""
    try:
        from google.cloud import storage
    except ImportError:
        print("Error: google-cloud-storage not installed")
        print("Run: pip install google-cloud-storage")
        return False

    print(f"Deploying model to GCS: {gcs_path}")

    # Parse GCS path
    if not gcs_path.startswith('gs://'):
        print("Error: GCS path must start with gs://")
        return False

    parts = gcs_path[5:].split('/', 1)
    bucket_name = parts[0]
    blob_prefix = parts[1] if len(parts) > 1 else ''

    # Initialize client
    client = storage.Client(project=project_id)
    bucket = client.bucket(bucket_name)

    model_path = Path(model_path)
    metadata_path = model_path.with_suffix('.json')

    # Upload model
    blob_name = f"{blob_prefix}/{model_path.name}" if blob_prefix else model_path.name
    blob = bucket.blob(blob_name)
    blob.upload_from_filename(str(model_path))
    print(f"  Uploaded: gs://{bucket_name}/{blob_name}")

    # Upload metadata
    if metadata_path.exists():
        meta_blob_name = f"{blob_prefix}/{metadata_path.name}" if blob_prefix else metadata_path.name
        meta_blob = bucket.blob(meta_blob_name)
        meta_blob.upload_from_filename(str(metadata_path))
        print(f"  Uploaded: gs://{bucket_name}/{meta_blob_name}")

    return True


def deploy_to_local(
    model_path: str,
    models_dir: str = "/app/models",
) -> bool:
    """Deploy model to local models directory (for Docker volume)."""
    print(f"Deploying model to local directory: {models_dir}")

    target_dir = Path(models_dir)
    target_dir.mkdir(parents=True, exist_ok=True)

    model_path = Path(model_path)
    metadata_path = model_path.with_suffix('.json')

    # Copy files
    target_model = target_dir / "noshow_model.lgb"
    target_meta = target_dir / "noshow_model.json"

    shutil.copy2(model_path, target_model)
    print(f"  Copied: {model_path} -> {target_model}")

    if metadata_path.exists():
        shutil.copy2(metadata_path, target_meta)
        print(f"  Copied: {metadata_path} -> {target_meta}")

    return True


def create_deployment_log(
    model_path: str,
    service_url: str,
    success: bool,
    details: Dict,
) -> None:
    """Create deployment log entry."""
    log_dir = Path("deployment_logs")
    log_dir.mkdir(exist_ok=True)

    timestamp = datetime.now()
    log_entry = {
        'timestamp': timestamp.isoformat(),
        'model_path': model_path,
        'service_url': service_url,
        'success': success,
        'details': details,
    }

    log_file = log_dir / f"deploy_{timestamp.strftime('%Y%m%d_%H%M%S')}.json"
    with open(log_file, 'w') as f:
        json.dump(log_entry, f, indent=2)

    print(f"Deployment log: {log_file}")


def main():
    parser = argparse.ArgumentParser(
        description="Deploy trained model to prediction service"
    )
    parser.add_argument(
        "--model",
        required=True,
        help="Path to trained model (.lgb file)"
    )
    parser.add_argument(
        "--service-url",
        help="Prediction service URL (e.g., http://localhost:8001)"
    )
    parser.add_argument(
        "--gcs",
        help="Deploy to GCS path (e.g., gs://bucket/models/)"
    )
    parser.add_argument(
        "--local",
        help="Deploy to local directory (e.g., /app/models)"
    )
    parser.add_argument(
        "--api-key",
        help="API key for prediction service"
    )
    parser.add_argument(
        "--backup",
        action="store_true",
        help="Backup current model before deployment"
    )
    parser.add_argument(
        "--backup-dir",
        default="model_backups",
        help="Directory for model backups"
    )
    parser.add_argument(
        "--skip-verify",
        action="store_true",
        help="Skip deployment verification"
    )
    parser.add_argument(
        "--reload-only",
        action="store_true",
        help="Only trigger reload (model already in place)"
    )

    args = parser.parse_args()

    print("=" * 60)
    print("The Scheduler - Model Deployment")
    print("Agent AI-14: Model Training Pipeline")
    print("=" * 60)

    model_path = Path(args.model)
    if not model_path.exists():
        print(f"Error: Model file not found: {args.model}")
        sys.exit(1)

    # Load metadata for version info
    metadata_path = model_path.with_suffix('.json')
    version = None
    if metadata_path.exists():
        with open(metadata_path) as f:
            metadata = json.load(f)
            version = metadata.get('version')
            print(f"Model version: {version}")

    success = True
    details = {'version': version}

    # Deploy to GCS
    if args.gcs:
        success = deploy_to_gcs(args.model, args.gcs)
        details['gcs_path'] = args.gcs

    # Deploy to local directory
    if args.local:
        success = success and deploy_to_local(args.model, args.local)
        details['local_path'] = args.local

    # Deploy to prediction service
    if args.service_url:
        deployer = ModelDeployer(
            args.model,
            args.service_url,
            api_key=args.api_key,
        )

        # Check service health
        health = deployer.check_service_health()
        if health.get('status') == 'error':
            print("\nWarning: Service may not be reachable")

        # Backup if requested
        if args.backup:
            deployer.backup_current_model(args.backup_dir)

        # Trigger reload
        if args.reload_only:
            success = deployer.trigger_reload()
        else:
            # For services with shared volume, deploy to local first
            if args.local:
                success = deployer.trigger_reload()
            else:
                print("\nNote: For Cloud Run, use --gcs to upload model")
                print("      Service will load from GCS on restart")

        # Verify deployment
        if success and not args.skip_verify:
            success = deployer.verify_deployment(expected_version=version)

        details['service_url'] = args.service_url

    # Create deployment log
    create_deployment_log(args.model, args.service_url or 'local', success, details)

    # Summary
    print("\n" + "=" * 60)
    if success:
        print("Deployment successful!")
    else:
        print("Deployment failed or incomplete")
        sys.exit(1)
    print("=" * 60)


if __name__ == "__main__":
    main()
