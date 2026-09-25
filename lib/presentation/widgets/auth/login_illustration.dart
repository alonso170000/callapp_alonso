import 'package:flutter/material.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';

class LoginIllustration extends StatelessWidget {
  final double height;

  const LoginIllustration({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'lib/resources/images/image 4.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            excludeFromSemantics: true,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.55, 1],
                colors: [Color(0x00E0FFF9), AppColors.loginBackground],
              ),
            ),
          ),
          Positioned(
            top: height * 0.075,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'lib/resources/images/Frame.png',
                height: height * 0.38,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
