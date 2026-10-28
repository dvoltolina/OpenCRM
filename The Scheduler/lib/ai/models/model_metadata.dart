import 'package:freezed_annotation/freezed_annotation.dart';

part 'model_metadata.freezed.dart';
part 'model_metadata.g.dart';

/// Supported ML model types for the AI prediction system
enum AIModelType {
  /// LightGBM gradient boosting model (no-show prediction)
  @JsonValue('lightgbm')
  lightgbm,

  /// XGBoost gradient boosting model
  @JsonValue('xgboost')
  xgboost,

  /// Large Language Model for sentiment analysis (Ollama)
  @JsonValue('llm')
  llm,

  /// OR-Tools constraint solver for route optimization
  @JsonValue('ortools')
  ortools,

  /// Unknown or custom model type
  @JsonValue('unknown')
  unknown,
}

/// Metadata about a trained ML model including version, performance metrics,
/// and feature schema information.
///
/// Used to track model versions and ensure feature compatibility between
/// training and inference.
@freezed
abstract class ModelMetadata with _$ModelMetadata {
  const factory ModelMetadata({
    /// Unique identifier for this model version
    required String modelId,

    /// Type of model (lightgbm, xgboost, llm, ortools)
    required AIModelType modelType,

    /// Semantic version string (e.g., '1.0.0')
    required String version,

    /// When the model was trained
    required DateTime trainedAt,

    /// Version of the feature schema this model expects
    required int featureSchemaVersion,

    /// Performance metrics from training/validation
    /// Common keys: 'auc', 'accuracy', 'precision', 'recall', 'f1'
    required Map<String, double> metrics,

    /// Ordered list of feature names the model expects
    required List<String> featureNames,

    /// Optional human-readable description
    String? description,

    /// Hyperparameters used during training
    Map<String, dynamic>? hyperparameters,

    /// Number of training samples used
    int? trainingSampleCount,

    /// Hash of training data for reproducibility verification
    String? trainingDataHash,

    /// Who/what initiated the training (user, scheduled, auto-retrain)
    String? trainedBy,

    /// Whether this is the currently active model for its type
    @Default(false) bool isActive,

    /// When this model was deployed to production
    DateTime? deployedAt,
  }) = _ModelMetadata;

  factory ModelMetadata.fromJson(Map<String, dynamic> json) =>
      _$ModelMetadataFromJson(json);

  const ModelMetadata._();

  /// Check if model has acceptable performance metrics
  bool get hasAcceptablePerformance {
    final auc = metrics['auc'];
    if (auc == null) return true; // Can't validate without AUC
    return auc >= 0.7; // Minimum AUC threshold
  }

  /// Get a specific metric value, returns null if not present
  double? getMetric(String key) => metrics[key];

  /// Check if model expects a specific feature
  bool hasFeature(String featureName) => featureNames.contains(featureName);

  /// Age of the model since training
  Duration get modelAge => DateTime.now().difference(trainedAt);

  /// Check if model is stale (older than specified duration)
  bool isOlderThan(Duration maxAge) => modelAge > maxAge;

  /// Format metrics for display
  String get metricsDisplay {
    return metrics.entries
        .map((e) => '${e.key}: ${(e.value * 100).toStringAsFixed(1)}%')
        .join(', ');
  }
}

/// Represents a collection of models currently loaded in the AI server
@freezed
abstract class LoadedModels with _$LoadedModels {
  const factory LoadedModels({
    /// No-show prediction model metadata
    ModelMetadata? predictionModel,

    /// Sentiment analysis model metadata (LLM info)
    ModelMetadata? sentimentModel,

    /// Route optimization model metadata
    ModelMetadata? routeModel,

    /// When models were last refreshed
    DateTime? lastRefreshed,
  }) = _LoadedModels;

  factory LoadedModels.fromJson(Map<String, dynamic> json) =>
      _$LoadedModelsFromJson(json);

  const LoadedModels._();

  /// Check if prediction model is loaded
  bool get hasPredictionModel => predictionModel != null;

  /// Check if sentiment model is loaded
  bool get hasSentimentModel => sentimentModel != null;

  /// Check if route model is loaded
  bool get hasRouteModel => routeModel != null;

  /// Check if all models are loaded
  bool get allModelsLoaded =>
      hasPredictionModel && hasSentimentModel && hasRouteModel;

  /// Get list of missing model types
  List<String> get missingModels {
    final missing = <String>[];
    if (!hasPredictionModel) missing.add('prediction');
    if (!hasSentimentModel) missing.add('sentiment');
    if (!hasRouteModel) missing.add('route');
    return missing;
  }
}
