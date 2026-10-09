import 'package:flutter/material.dart';

import '../theme.dart';

/// One selectable look option (theme / stone style / wood).
class LookOption {
  final String id;
  final String name;
  final Color preview;
  final bool locked;
  const LookOption(
      {required this.id,
      required this.name,
      required this.preview,
      this.locked = false});
}

/// Horizontal picker of look options with PRO lock badges.
/// Tapping a locked option calls [onUnlock] (opens the Pro screen).
class LookPicker extends StatelessWidget {
  final String title;
  final String? kanji;
  final List<LookOption> options;
  final String current;
  final ValueChanged<String> onPick;
  final VoidCallback onUnlock;
  final Widget? trailing;

  const LookPicker({
    super.key,
    required this.title,
    this.kanji,
    required this.options,
    required this.current,
    required this.onPick,
    required this.onUnlock,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 3, height: 18, color: GoTheme.kayaDeep),
            const SizedBox(width: 8),
            Text(title,
                style: GoTheme.body(15,
                    weight: FontWeight.w600, color: GoTheme.sumi)),
            if (kanji case final k?) ...[
              const SizedBox(width: 8),
              Text(k, style: GoTheme.body(13, color: GoTheme.inkGrey)),
            ],
            const Spacer(),
            ...[?trailing],
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: options.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (ctx, i) {
              final o = options[i];
              final selected = o.id == current;
              return GestureDetector(
                onTap: () {
                  if (o.locked) {
                    onUnlock();
                  } else {
                    onPick(o.id);
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: o.preview,
                        border: Border.all(
                          color: selected
                              ? GoTheme.kayaDeep
                              : GoTheme.carved,
                          width: selected ? 3 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: GoTheme.woodShadow,
                              blurRadius: selected ? 8 : 4,
                              offset: const Offset(0, 3)),
                        ],
                      ),
                      child: o.locked
                          ? Icon(Icons.lock_outline_rounded,
                              size: 20,
                              color: GoTheme.inkGrey.withValues(alpha: 0.8))
                          : null,
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 64,
                      child: Text(
                        o.name,
                        style: GoTheme.label(10,
                            color: selected
                                ? GoTheme.kayaDeep
                                : GoTheme.inkGrey),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
