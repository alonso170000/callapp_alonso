import 'package:flutter/material.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/resources/styles/styles.dart';

class ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const ProfileSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(title, style: profileHeading),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(children: children),
      ),
    ],
  );
}
