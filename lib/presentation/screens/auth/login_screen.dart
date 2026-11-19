import 'package:callerapp_frontend/presentation/widgets/app_press_bounce.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/presentation/widgets/auth/login_illustration.dart';
import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/widgets/auth/login_field.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/home_screen.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/resources/styles/app_themes.dart';

class LoginScreen extends StatefulWidget {
  static const name = 'login';
  final bool showBiometric;

  const LoginScreen({super.key, this.showBiometric = true});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await AuthService.instance.login(
        _emailController.text,
        _passwordController.text,
      );
      if (mounted) context.goNamed(HomeScreen.name);
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No se pudo iniciar sesión. Intenta nuevamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppThemes.build(Brightness.light),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compactHeight = constraints.maxHeight < 650;
                final heroHeight =
                    (constraints.maxHeight * (compactHeight ? 0.33 : 0.55))
                        .clamp(120.0, 480.0)
                        .toDouble();
                final sectionGap = compactHeight ? 10.0 : 14.0;
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        children: [
                          LoginIllustration(height: heroHeight),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              24,
                              compactHeight ? 4 : 8,
                              24,
                              compactHeight ? 16 : 32,
                            ),
                            child: AutofillGroup(
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Center(
                                      child: Image.asset(
                                        'lib/resources/images/Hada Corp-Logo-2022-10.png',
                                        width: 70,
                                        height: 26,
                                        semanticLabel: 'HADA Corp',
                                      ),
                                    ),
                                    SizedBox(height: compactHeight ? 10 : 16),
                                    Center(
                                      child: Wrap(
                                        alignment: WrapAlignment.center,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 5,
                                        children: [
                                          Text(
                                            'INICIA',
                                            style: TextStyle(
                                              fontFamily: 'BebasNeue',
                                              fontSize: 34,
                                              height: 1.1,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryColor,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            child: const Text(
                                              'SESIÓN',
                                              style: TextStyle(
                                                fontFamily: 'BebasNeue',
                                                fontSize: 34,
                                                height: 1.1,
                                                color: AppColors.accentColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: sectionGap),
                                    LoginField(
                                      obscurePassword: _obscurePassword,
                                      onSubmitted: _submit,
                                      onTogglePassword: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                      label: 'Usuario',
                                      controller: _emailController,
                                      icon: Iconsax.user_copy,
                                      password: false,
                                    ),
                                    SizedBox(height: sectionGap),
                                    LoginField(
                                      obscurePassword: _obscurePassword,
                                      onSubmitted: _submit,
                                      onTogglePassword: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                      label: 'Contraseña',
                                      controller: _passwordController,
                                      icon: Iconsax.lock_copy,
                                      password: true,
                                    ),
                                    const SizedBox(height: 2),
                                    if (_error != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Text(
                                          _error!,
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                          ),
                                          semanticsLabel: _error,
                                        ),
                                      ),
                                    SizedBox(height: compactHeight ? 16 : 28),
                                    AppPressBounce(
                                      enabled: !_submitting,
                                      child: FilledButton(
                                        onPressed: _submitting ? null : _submit,
                                        style: FilledButton.styleFrom(
                                          backgroundColor:
                                              AppColors.primaryColor,
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size.fromHeight(
                                            50,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          textStyle: const TextStyle(
                                            fontFamily: 'BebasNeue',
                                            fontSize: 24,
                                          ),
                                        ),
                                        child: Text(
                                          _submitting
                                              ? 'CONECTANDO…'
                                              : 'INGRESAR',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
