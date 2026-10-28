import 'package:flutter/material.dart';

/// Color picker field for gift card templates.
///
/// Displays the current color with a hex value and allows
/// selecting a new color via a color picker dialog.
class ColorPickerField extends StatelessWidget {
  const ColorPickerField({
    required this.label,
    required this.color,
    required this.onColorChanged,
    super.key,
  });

  final String label;
  final Color color;
  final ValueChanged<Color> onColorChanged;

  String _colorToHexString(Color c) {
    final r = (c.r * 255).round();
    final g = (c.g * 255).round();
    final b = (c.b * 255).round();
    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showColorPicker(context),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _colorToHexString(color),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showColorPicker(BuildContext context) async {
    final selectedColor = await showDialog<Color>(
      context: context,
      builder: (context) => SimpleColorPickerDialog(initialColor: color),
    );
    if (selectedColor != null) {
      onColorChanged(selectedColor);
    }
  }
}

/// Simple color picker dialog with preset colors and hex input.
class SimpleColorPickerDialog extends StatefulWidget {
  const SimpleColorPickerDialog({
    required this.initialColor,
    super.key,
  });

  final Color initialColor;

  @override
  State<SimpleColorPickerDialog> createState() =>
      _SimpleColorPickerDialogState();
}

class _SimpleColorPickerDialogState extends State<SimpleColorPickerDialog> {
  late Color _selectedColor;
  final _hexController = TextEditingController();

  static const _presetColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
    Colors.white,
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    _updateHexController();
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _updateHexController() {
    final r = (_selectedColor.r * 255).round();
    final g = (_selectedColor.g * 255).round();
    final b = (_selectedColor.b * 255).round();
    _hexController.text = '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Color'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetColors.map((presetColor) {
              final isSelected = _selectedColor.toARGB32() == presetColor.toARGB32();
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedColor = presetColor;
                    _updateHexController();
                  });
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: presetColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _hexController,
            decoration: const InputDecoration(
              labelText: 'Hex Color',
              border: OutlineInputBorder(),
              hintText: '#FF5733',
            ),
            onChanged: (value) {
              if (value.length == 7 && value.startsWith('#')) {
                try {
                  final hexCode = value.replaceAll('#', '');
                  final color = Color(int.parse('FF$hexCode', radix: 16));
                  setState(() => _selectedColor = color);
                } catch (e) {
                  // Invalid hex, ignore
                }
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selectedColor),
          child: const Text('Select'),
        ),
      ],
    );
  }
}
