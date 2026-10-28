import 'package:flutter/widgets.dart';

import 'app_config.dart';

class ConfigScope extends InheritedWidget {
  const ConfigScope({super.key, required this.config, required super.child});

  final AppConfig config;

  static AppConfig of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ConfigScope>();
    assert(scope != null, 'ConfigScope is missing in the tree');
    return scope!.config;
  }

  @override
  bool updateShouldNotify(ConfigScope oldWidget) => config != oldWidget.config;
}
