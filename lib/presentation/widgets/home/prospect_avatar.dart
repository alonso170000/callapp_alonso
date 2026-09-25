import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/home_models.dart';

class ProspectAvatar extends StatelessWidget {
  final ProspectItem item;

  const ProspectAvatar({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.avatarColor,
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: 3,
            child: Container(width: 34, height: 64, color: item.accentColor),
          ),
          Positioned.fill(
            child: Center(
              child: Text(
                item.name.characters.first.toUpperCase(),
                style: const TextStyle(
                  color: Colors.black,
                  fontFamily: 'SulphurPoint',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const Positioned(
            left: 17,
            top: 29,
            child: Icon(Icons.sentiment_satisfied_alt, size: 25),
          ),
        ],
      ),
    );
  }
}
