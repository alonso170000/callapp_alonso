import 'package:flutter/material.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/resources/styles/styles.dart';

/// Estructura visual compartida por inicio de sesión y creación de cuenta.
class AuthScreenLayout extends StatefulWidget {
  final String title;
  final Widget child;

  const AuthScreenLayout({super.key, required this.title, required this.child});

  @override
  State<AuthScreenLayout> createState() => _AuthScreenLayoutState();
}

class _AuthScreenLayoutState extends State<AuthScreenLayout> {
  final ScrollController _scrollController = ScrollController();
  bool _keyboardWasOpen = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _restoreScrollWhenKeyboardCloses(double keyboardHeight) {
    if (keyboardHeight > 0) _keyboardWasOpen = true;

    if (keyboardHeight == 0 && _keyboardWasOpen) {
      _keyboardWasOpen = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(child: _AuthBackground()),
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
                _restoreScrollWhenKeyboardCloses(keyboardHeight);

                return SingleChildScrollView(
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: keyboardHeight > 0
                      ? const BouncingScrollPhysics()
                      : const ClampingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    0,
                    8,
                    0,
                    keyboardHeight > 0 ? keyboardHeight + 24 : 0,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: constraints.maxHeight - 8,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 0,
                          right: 0,
                          top: AppStyles.authContentTop,
                          bottom: 0,
                          child: AuthCard(child: widget.child),
                        ),
                        Positioned(
                          left: 16,
                          top: 18,
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              color: AppColors.whiteColor,
                              fontFamily: 'Oswald',
                              fontSize: AppStyles.authHeaderFontSize,
                              fontWeight: FontWeight.w500,
                              height: 0.92,
                              shadows: [
                                Shadow(
                                  color: Color(0xAA8D1CFF),
                                  blurRadius: 18,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Panel con borde neón usado por los formularios de autenticación.
class AuthCard extends StatelessWidget {
  final Widget child;

  const AuthCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        gradient: AppColors.authPanelBorderGradient,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppStyles.authPanelRadius),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppStyles.authPanelPadding,
          28,
          AppStyles.authPanelPadding,
          AppStyles.authPanelPadding,
        ),
        decoration: BoxDecoration(
          gradient: AppColors.authPanelGradient,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: AppColors.authCyan.withValues(alpha: 0.24),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            top: 12,
            bottom: MediaQuery.paddingOf(context).bottom + 16,
          ),
          child: child,
        ),
      ),
    );
  }
}



class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: AppColors.authBackgroundGradient,
      ),
      child: const Stack(
        children: [
          Positioned(
            top: 18,
            right: -30,
            child: _AuthGlow(size: 170, color: Color(0xFF00D9FF)),
          ),
          Positioned(
            top: 34,
            right: 32,
            child: _AuthGlow(size: 105, color: Color(0xFF9B20FF)),
          ),
          Positioned(
            top: 8,
            left: 80,
            child: _AuthGlow(size: 74, color: Color(0xFF2858FF)),
          ),
        ],
      ),
    );
  }
}

class _AuthGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _AuthGlow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.74),
              color.withValues(alpha: 0.18),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}