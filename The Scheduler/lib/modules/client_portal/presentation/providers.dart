import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/reference_data_cache.dart';
import '../../../data/models/location.dart';
import '../../../data/models/provider.dart' as provider_model;
import '../../../data/models/security_context.dart';
import '../../../data/models/service.dart';

/// Shared Riverpod providers for client-portal reference data. These wrap the
/// existing [ReferenceDataCache] streams so UI can consume them with `ref.watch`
/// instead of nesting `StreamBuilder` widgets.

final portalServicesProvider =
    StreamProvider.family<List<Service>, SecurityContext>(
  (ref, context) => ReferenceDataCache.instance.watchServices(context),
);

final portalProvidersProvider =
    StreamProvider.family<List<provider_model.Provider>, SecurityContext>(
  (ref, context) => ReferenceDataCache.instance.watchProviders(context),
);

final portalLocationsProvider =
    StreamProvider.family<List<Location>, SecurityContext>(
  (ref, context) => ReferenceDataCache.instance.watchLocations(context),
);
