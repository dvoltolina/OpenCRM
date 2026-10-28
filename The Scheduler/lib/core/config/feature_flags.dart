/// Aggregates toggles so each client can enable/disable major capabilities
/// without hunting through UI code.
class FeatureFlags {
  const FeatureFlags({
    this.enableClientPortal = true,
    this.enableAutomatedReminders = true,
    this.enablePayments = false,
    this.enableMultiLocation = false,
    this.enableReporting = true,
    this.enableWaitlist = true,
    this.enableSessionNotes = true,
    this.enablePOS = false,
    this.enableRetailSales = false,
    this.enableTimesheets = true,
    this.enableProviderMode = false,
    this.requirePaidSubscription = false,
    this.enableClientSocialLogin = false,
    this.enableSalesVisits = false,
    // AI & Predictive Intelligence flags (default OFF until services ready)
    this.enableAIPredictions = false,
    this.enableAISentiment = false,
    this.enableAIRouteOptimization = false,
    this.enableAIAutomation = false,
  });

  final bool enableClientPortal;
  final bool enableAutomatedReminders;
  final bool enablePayments;
  final bool enableMultiLocation;
  final bool enableReporting;
  final bool enableWaitlist;
  final bool enableSessionNotes;
  final bool enablePOS;
  final bool enableRetailSales;
  final bool enableTimesheets;

  /// Legacy HomeShell toggle for showing Provider Mode as a module.
  ///
  /// The live authenticated provider/staff runtime now routes directly to
  /// `ProviderModePage` via `RoleRouter`.
  final bool enableProviderMode;

  /// Require an active/trialing subscription for business portal access
  final bool requirePaidSubscription;

  /// Enable client-facing Google/Apple auth buttons (default off for HIPAA safety)
  final bool enableClientSocialLogin;

  /// Enable sales visits tab for field/sales reps (route + maps launcher)
  final bool enableSalesVisits;

  /// Enable no-show prediction and risk scoring on appointments
  final bool enableAIPredictions;

  /// Enable sentiment analysis on client communications
  final bool enableAISentiment;

  /// Enable route optimization for mobile providers
  final bool enableAIRouteOptimization;

  /// Enable automated actions triggered by AI predictions
  final bool enableAIAutomation;

  /// Helper to check if any AI feature is enabled
  bool get hasAnyAIEnabled =>
      enableAIPredictions ||
      enableAISentiment ||
      enableAIRouteOptimization ||
      enableAIAutomation;

  FeatureFlags copyWith({
    bool? enableClientPortal,
    bool? enableAutomatedReminders,
    bool? enablePayments,
    bool? enableMultiLocation,
    bool? enableReporting,
    bool? enableWaitlist,
    bool? enableSessionNotes,
    bool? enablePOS,
    bool? enableRetailSales,
    bool? enableTimesheets,
    bool? enableProviderMode,
    bool? requirePaidSubscription,
    bool? enableClientSocialLogin,
    bool? enableSalesVisits,
    bool? enableAIPredictions,
    bool? enableAISentiment,
    bool? enableAIRouteOptimization,
    bool? enableAIAutomation,
  }) {
    return FeatureFlags(
      enableClientPortal: enableClientPortal ?? this.enableClientPortal,
      enableAutomatedReminders:
          enableAutomatedReminders ?? this.enableAutomatedReminders,
      enablePayments: enablePayments ?? this.enablePayments,
      enableMultiLocation: enableMultiLocation ?? this.enableMultiLocation,
      enableReporting: enableReporting ?? this.enableReporting,
      enableWaitlist: enableWaitlist ?? this.enableWaitlist,
      enableSessionNotes: enableSessionNotes ?? this.enableSessionNotes,
      enablePOS: enablePOS ?? this.enablePOS,
      enableRetailSales: enableRetailSales ?? this.enableRetailSales,
      enableTimesheets: enableTimesheets ?? this.enableTimesheets,
      enableProviderMode: enableProviderMode ?? this.enableProviderMode,
      requirePaidSubscription:
          requirePaidSubscription ?? this.requirePaidSubscription,
      enableClientSocialLogin:
          enableClientSocialLogin ?? this.enableClientSocialLogin,
      enableSalesVisits: enableSalesVisits ?? this.enableSalesVisits,
      enableAIPredictions: enableAIPredictions ?? this.enableAIPredictions,
      enableAISentiment: enableAISentiment ?? this.enableAISentiment,
      enableAIRouteOptimization:
          enableAIRouteOptimization ?? this.enableAIRouteOptimization,
      enableAIAutomation: enableAIAutomation ?? this.enableAIAutomation,
    );
  }
}
