import 'package:flutter/material.dart';

import '../../../../data/models/gift_card_template.dart';

/// Widget for selecting a gift card design template.
class GiftCardTemplateSelector extends StatelessWidget {
  const GiftCardTemplateSelector({
    required this.templates,
    required this.selectedTemplate,
    required this.onTemplateSelected,
    required this.primaryColor,
    super.key,
  });

  final List<GiftCardTemplate> templates;
  final GiftCardTemplate? selectedTemplate;
  final ValueChanged<GiftCardTemplate?> onTemplateSelected;
  final Color primaryColor;

  Color _parseColor(String hexColor) {
    if (hexColor.isEmpty) return Colors.grey;
    try {
      final hex = hexColor.replaceFirst('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
      return Colors.grey;
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.card_giftcard, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'Default Design',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: templates.length,
        separatorBuilder: (ctx, idx) => const SizedBox(width: 12),
        itemBuilder: (ctx, index) {
          final template = templates[index];
          final isSelected = selectedTemplate?.id == template.id;

          return GestureDetector(
            onTap: () => onTemplateSelected(template),
            child: Container(
              width: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.grey.shade300,
                  width: isSelected ? 3 : 1,
                ),
                color: _parseColor(template.backgroundColor),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (template.imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        template.imageUrl,
                        width: 80,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.card_giftcard,
                          size: 40,
                          color: _parseColor(template.textColor),
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.card_giftcard,
                      size: 40,
                      color: _parseColor(template.textColor),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    template.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: _parseColor(template.textColor),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
