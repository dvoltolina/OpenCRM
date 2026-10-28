import 'package:flutter/material.dart';

/// Describes a navigable page/surface inside the shell UI.
class ModuleConfig {
  const ModuleConfig({
    required this.id,
    required this.label,
    required this.icon,
    required this.builder,
    required this.description,
  });

  final String id;
  final String label;
  final IconData icon;
  final WidgetBuilder builder;
  final String description;
}
