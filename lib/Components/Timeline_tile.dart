import 'package:timeline_tile/timeline_tile.dart';
import 'package:flutter/material.dart';

class MyStepTile extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final bool isPast;
  final bool isCurrent; // 👈 NEW
  final String title;
  final String? subtitle;

  const MyStepTile({
    super.key,
    required this.isFirst,
    required this.isLast,
    required this.isPast,
    required this.isCurrent, // 👈 NEW
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF9333EA);
    const yellow = Color(0xFFFFD54F);

    // line colors
    final beforeColor = (isPast || isCurrent) ? purple : Colors.grey.shade400;
    final afterColor  = isPast ? purple : Colors.grey.shade400;

    // indicator color
    final indicatorColor = isPast ? purple : (isCurrent ? yellow : Colors.white);

    // title color
    final titleColor = isPast ? Colors.white70 : (isCurrent ? yellow : Colors.white);

    return TimelineTile(
      isFirst: isFirst,
      isLast: isLast,
      axis: TimelineAxis.vertical,
      alignment: TimelineAlign.manual,
      lineXY: 0.12,

      beforeLineStyle: LineStyle(color: beforeColor, thickness: 2),
      afterLineStyle:  LineStyle(color: afterColor,  thickness: 2),

      indicatorStyle: IndicatorStyle(
        width: 22,
        height: 22,
        indicatorXY: 0.5,
        padding: const EdgeInsets.all(2),
        color: indicatorColor,
        iconStyle: isPast
            ?  IconStyle(iconData: Icons.check, color: Colors.white, fontSize: 13)
            : (isCurrent
            ?  IconStyle(iconData: Icons.play_arrow_rounded, color: Colors.black, fontSize: 14)
            : null),
      ),

      startChild: const SizedBox(width: 0),
      endChild: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                )),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: const TextStyle(fontSize: 13, color: Colors.white70)),
            ],
          ],
        ),
      ),
    );
  }
}
