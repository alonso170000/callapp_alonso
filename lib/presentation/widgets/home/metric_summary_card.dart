import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/home_models.dart';

import 'home_card_components.dart';

class MetricSummaryCard extends StatelessWidget {
  final DashboardMetric metric;
  final VoidCallback? onTap;

  const MetricSummaryCard({super.key, required this.metric, this.onTap});

  @override
  Widget build(BuildContext context) {
    return HomeTappableCard(
      color: metric.backgroundColor,
      height: 154,
      onTap: onTap,
      child: Stack(
        children: [
          const Positioned(top: 8, right: 8, child: HomeCardArrow()),
          Positioned.fill(
            left: 12,
            right: 12,
            bottom: 14,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.value.toString(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontFamily: 'SulphurPoint',
                    fontSize: 54,
                    fontWeight: FontWeight.w700,
                    height: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  metric.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontFamily: 'SulphurPoint',
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    height: 0.9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
