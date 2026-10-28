"""
Export prediction features and actual outcomes from Firestore for model training.

Usage:
    python export_training_data.py --business-id BUSINESS_ID --output training_data.parquet

This script:
1. Connects to Firebase using service account credentials
2. Queries the featureStore collection for a business
3. Exports features + actual outcomes to Parquet format
4. Handles multi-tenant data isolation

Agent AI-3: Python Prediction Server
"""
import argparse
import os
from datetime import datetime, timedelta
from pathlib import Path

import pandas as pd

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    FIREBASE_AVAILABLE = True
except ImportError:
    FIREBASE_AVAILABLE = False
    firebase_admin = None
    credentials = None
    firestore = None


def export_features(
    business_id: str,
    output_path: str,
    start_date: datetime = None,
    end_date: datetime = None,
    credentials_path: str = "service-account.json",
) -> pd.DataFrame:
    """
    Export training data from Firestore.

    Args:
        business_id: Business to export data for
        output_path: Where to save the Parquet file
        start_date: Start of date range (default: 90 days ago)
        end_date: End of date range (default: today)
        credentials_path: Path to Firebase service account JSON

    Returns:
        DataFrame with exported training data
    """
    if not FIREBASE_AVAILABLE:
        raise ImportError(
            "firebase-admin not installed. "
            "Run: pip install firebase-admin"
        )

    # Default date range
    if end_date is None:
        end_date = datetime.now()
    if start_date is None:
        start_date = end_date - timedelta(days=90)

    print(f"Exporting training data for business: {business_id}")
    print(f"Date range: {start_date.date()} to {end_date.date()}")

    # Initialize Firebase
    if not firebase_admin._apps:
        cred = credentials.Certificate(credentials_path)
        firebase_admin.initialize_app(cred)
    db = firestore.client()

    # Query feature store
    features_ref = (
        db.collection('businesses')
        .document(business_id)
        .collection('featureStore')
    )
    query = (
        features_ref
        .where('extractedAt', '>=', start_date)
        .where('extractedAt', '<=', end_date)
    )

    # Fetch all documents
    docs = query.stream()
    records = []

    for doc in docs:
        data = doc.to_dict()

        # Only include completed appointments (with outcomes)
        if 'actualOutcome' not in data or data['actualOutcome'] is None:
            continue

        # Extract features
        features = data.get('features', {})

        # Build training record
        record = {
            # Target variable
            'noshow': 1 if data['actualOutcome'] == 'noShow' else 0,
            'cancelled': 1 if data['actualOutcome'] == 'cancelled' else 0,
            'completed': 1 if data['actualOutcome'] == 'completed' else 0,

            # Features (match Flutter schema - camelCase)
            'clientHistoricalNoshowRate': features.get('clientHistoricalNoshowRate', 0.0),
            'clientHistoricalCancelRate': features.get('clientHistoricalCancelRate', 0.0),
            'clientTotalAppointments': features.get('clientTotalAppointments', 0),
            'clientDaysSinceLastVisit': features.get('clientDaysSinceLastVisit', 9999),
            'clientLifetimeValueCents': features.get('clientLifetimeValueCents', 0),
            'clientLifecycleStage': features.get('clientLifecycleStage', 'newClient'),
            'clientHasPaymentMethod': features.get('clientHasPaymentMethod', False),
            'bookingLeadDays': features.get('bookingLeadDays', 0),
            'dayOfWeek': features.get('dayOfWeek', 1),
            'hourOfDay': features.get('hourOfDay', 9),
            'isRecurring': features.get('isRecurring', False),
            'isGroupSession': features.get('isGroupSession', False),
            'serviceDurationMinutes': features.get('serviceDurationMinutes', 60),
            'servicePriceCents': features.get('servicePriceCents', 0),
            'requiresPayment': features.get('requiresPayment', False),
            'paymentCollected': features.get('paymentCollected', False),
            'hasIntakeForm': features.get('hasIntakeForm', False),
            'providerHistoricalNoshowRate': features.get('providerHistoricalNoshowRate', 0.0),
            'providerTotalAppointments': features.get('providerTotalAppointments', 0),
            'slotHistoricalNoshowRate': features.get('slotHistoricalNoshowRate', 0.0),
            'isFirstAppointmentOfDay': features.get('isFirstAppointmentOfDay', False),
            'isLastAppointmentOfDay': features.get('isLastAppointmentOfDay', False),

            # Metadata
            'appointmentId': data.get('appointmentId'),
            'extractedAt': data.get('extractedAt'),
            'businessId': business_id,
        }

        records.append(record)

    # Convert to DataFrame
    df = pd.DataFrame(records)

    if len(df) == 0:
        print("Warning: No records found with outcomes. Returning empty DataFrame.")
        return df

    print(f"Exported {len(df)} records")
    print(f"No-show rate: {df['noshow'].mean():.2%}")
    print(f"Cancellation rate: {df['cancelled'].mean():.2%}")
    print(f"Completion rate: {df['completed'].mean():.2%}")

    # Save to Parquet
    output_dir = Path(output_path).parent
    if output_dir and not output_dir.exists():
        output_dir.mkdir(parents=True, exist_ok=True)

    df.to_parquet(output_path, index=False)
    print(f"Saved to: {output_path}")

    return df


def generate_synthetic_data(
    output_path: str,
    num_records: int = 1000,
    noshow_rate: float = 0.15,
    seed: int = 42,
) -> pd.DataFrame:
    """
    Generate synthetic training data for development/testing.

    Args:
        output_path: Where to save the Parquet file
        num_records: Number of records to generate
        noshow_rate: Target no-show rate
        seed: Random seed for reproducibility

    Returns:
        DataFrame with synthetic training data
    """
    import numpy as np

    np.random.seed(seed)

    print(f"Generating {num_records} synthetic training records...")

    records = []
    for i in range(num_records):
        # Generate correlated features
        is_high_risk = np.random.random() < noshow_rate * 2

        client_noshow_rate = (
            np.random.beta(3, 2) if is_high_risk
            else np.random.beta(1, 5)
        )
        client_cancel_rate = client_noshow_rate * 0.5 + np.random.random() * 0.1
        has_payment_method = np.random.random() > (0.3 if is_high_risk else 0.1)
        payment_collected = has_payment_method and np.random.random() > 0.3
        booking_lead_days = (
            int(np.random.exponential(14)) if is_high_risk
            else int(np.random.exponential(5))
        )

        # Calculate outcome based on features
        noshow_prob = (
            client_noshow_rate * 0.4
            + (booking_lead_days / 30) * 0.2
            + (0.2 if not payment_collected else 0)
            + np.random.random() * 0.2
        )
        is_noshow = np.random.random() < noshow_prob
        is_cancelled = not is_noshow and np.random.random() < client_cancel_rate

        record = {
            'noshow': 1 if is_noshow else 0,
            'cancelled': 1 if is_cancelled else 0,
            'completed': 1 if not is_noshow and not is_cancelled else 0,

            'clientHistoricalNoshowRate': min(1.0, client_noshow_rate),
            'clientHistoricalCancelRate': min(1.0, client_cancel_rate),
            'clientTotalAppointments': int(np.random.exponential(10)),
            'clientDaysSinceLastVisit': int(np.random.exponential(30)),
            'clientLifetimeValueCents': int(np.random.exponential(500) * 100),
            'clientLifecycleStage': np.random.choice(
                ['newClient', 'active', 'inactive', 'churned'],
                p=[0.2, 0.5, 0.2, 0.1]
            ),
            'clientHasPaymentMethod': has_payment_method,
            'bookingLeadDays': min(365, booking_lead_days),
            'dayOfWeek': np.random.randint(1, 8),
            'hourOfDay': np.random.randint(8, 20),
            'isRecurring': np.random.random() > 0.7,
            'isGroupSession': np.random.random() > 0.9,
            'serviceDurationMinutes': np.random.choice([30, 45, 60, 90, 120]),
            'servicePriceCents': int(np.random.choice([5000, 7500, 10000, 15000])),
            'requiresPayment': np.random.random() > 0.2,
            'paymentCollected': payment_collected,
            'hasIntakeForm': np.random.random() > 0.6,
            'providerHistoricalNoshowRate': np.random.beta(1, 10),
            'providerTotalAppointments': int(np.random.exponential(100)),
            'slotHistoricalNoshowRate': np.random.beta(1, 8),
            'isFirstAppointmentOfDay': np.random.random() > 0.85,
            'isLastAppointmentOfDay': np.random.random() > 0.85,

            'appointmentId': f"synthetic_appt_{i}",
            'extractedAt': datetime.now() - timedelta(days=np.random.randint(0, 90)),
            'businessId': 'synthetic_business',
        }
        records.append(record)

    df = pd.DataFrame(records)

    print(f"Generated {len(df)} records")
    print(f"No-show rate: {df['noshow'].mean():.2%}")
    print(f"Cancellation rate: {df['cancelled'].mean():.2%}")

    # Save to Parquet
    output_dir = Path(output_path).parent
    if output_dir and not output_dir.exists():
        output_dir.mkdir(parents=True, exist_ok=True)

    df.to_parquet(output_path, index=False)
    print(f"Saved to: {output_path}")

    return df


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Export training data from Firestore or generate synthetic data"
    )
    parser.add_argument(
        "--business-id",
        help="Business ID to export (required for Firestore export)"
    )
    parser.add_argument(
        "--output",
        default="training_data.parquet",
        help="Output file path"
    )
    parser.add_argument(
        "--credentials",
        default="service-account.json",
        help="Firebase credentials file"
    )
    parser.add_argument(
        "--days",
        type=int,
        default=90,
        help="Days of history to export"
    )
    parser.add_argument(
        "--synthetic",
        action="store_true",
        help="Generate synthetic data instead of exporting from Firestore"
    )
    parser.add_argument(
        "--num-records",
        type=int,
        default=1000,
        help="Number of synthetic records to generate"
    )

    args = parser.parse_args()

    if args.synthetic:
        generate_synthetic_data(
            output_path=args.output,
            num_records=args.num_records,
        )
    else:
        if not args.business_id:
            parser.error("--business-id is required for Firestore export")

        end_date = datetime.now()
        start_date = end_date - timedelta(days=args.days)

        export_features(
            business_id=args.business_id,
            output_path=args.output,
            start_date=start_date,
            end_date=end_date,
            credentials_path=args.credentials,
        )
