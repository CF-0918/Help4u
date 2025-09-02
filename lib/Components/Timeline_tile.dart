import 'package:timeline_tile/timeline_tile.dart';
import 'package:flutter/material.dart';

class MyStepTile extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final bool isPast;
  final String title;
  final String? subtitle;
  final String? icon;

  const MyStepTile({
    super.key,
    required this.isFirst,
    required this.isLast,
    required this.isPast,
    required this.title,
    this.subtitle,
    this.icon
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF9333EA);

    return TimelineTile(
      isFirst: isFirst,
      isLast: isLast,
      axis: TimelineAxis.vertical,
      alignment: TimelineAlign.manual,
      lineXY: 0.12, // rail closer to the left
      beforeLineStyle: LineStyle(color: isPast ? purple : Colors.grey.shade400, thickness: 2),
      afterLineStyle:  LineStyle(color: isPast ? purple : Colors.grey.shade400, thickness: 2),

      indicatorStyle: IndicatorStyle(
        width: 20,
        height: 20,
        indicatorXY: 0.5,
        padding: const EdgeInsets.all(2),
        color: isPast ? purple : Colors.white,
        iconStyle: isPast
            ?  IconStyle(
          iconData: Icons.check, // or Icons.add
          color: Colors.white,
          fontSize: 12,          // smaller than width/height
        )
            : null,
      ),


      startChild: const SizedBox(width: 0), // empty left gutter
      endChild: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0,horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isPast ? Colors.white : Colors.white.withOpacity(0.9),
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
