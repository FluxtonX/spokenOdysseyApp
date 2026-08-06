import 'package:flutter/material.dart';

class ReactionBar extends StatelessWidget {
  final Function(String type) onReact;
  final String? currentReaction;

  const ReactionBar({
    super.key,
    required this.onReact,
    this.currentReaction,
  });

  static const List<Map<String, String>> reactions = [
    {'type': 'heart', 'emoji': '❤️'},
    {'type': 'like', 'emoji': '👍'},
    {'type': 'care', 'emoji': '🤗'},
    {'type': 'haha', 'emoji': '😂'},
    {'type': 'wow', 'emoji': '😮'},
    {'type': 'angry', 'emoji': '😡'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactions.map((r) {
          final isSelected = currentReaction == r['type'];
          return GestureDetector(
            onTap: () => onReact(r['type']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.purple.withOpacity(0.15) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Text(
                r['emoji']!,
                style: TextStyle(
                  fontSize: isSelected ? 26 : 22,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
