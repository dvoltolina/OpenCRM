import 'package:flutter/material.dart';

/// A radio group wrapper that provides groupValue and onChanged to descendants
/// via InheritedWidget pattern for Flutter 3.32+ compatibility.
class RadioGroup<T> extends StatelessWidget {
  const RadioGroup({
    required this.groupValue,
    required this.onChanged,
    required this.child,
    super.key,
  });

  final T groupValue;
  final ValueChanged<T?> onChanged;
  final Widget child;

  /// Access the nearest RadioGroup ancestor
  static RadioGroupData<T>? of<T>(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_RadioGroupScope<T>>();
    return scope != null ? RadioGroupData(scope.groupValue, scope.onChanged) : null;
  }

  @override
  Widget build(BuildContext context) {
    return _RadioGroupScope<T>(
      groupValue: groupValue,
      onChanged: onChanged,
      child: child,
    );
  }
}

/// Data container for radio group state
class RadioGroupData<T> {
  const RadioGroupData(this.groupValue, this.onChanged);
  final T groupValue;
  final ValueChanged<T?> onChanged;
}

/// InheritedWidget that provides radio group state to descendants
class _RadioGroupScope<T> extends InheritedWidget {
  const _RadioGroupScope({
    required this.groupValue,
    required this.onChanged,
    required super.child,
  });

  final T groupValue;
  final ValueChanged<T?> onChanged;

  @override
  bool updateShouldNotify(_RadioGroupScope<T> oldWidget) {
    return groupValue != oldWidget.groupValue || onChanged != oldWidget.onChanged;
  }
}
