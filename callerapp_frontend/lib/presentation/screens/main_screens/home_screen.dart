import 'dart:async';

import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/screens/screens.dart';

class HomeScreen extends StatefulWidget {
  static const name = 'home-screen';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {



  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.homeScreenGradient),
        child: Stack(
          children: [

          ],
        ),
      ),
    );
  }

}
