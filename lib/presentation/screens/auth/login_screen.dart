import 'package:callerapp_frontend/presentation/widgets/auth/login_illustration.dart';
import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/widgets/auth/login_field.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/home_screen.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';

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
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    // Conserva la navegación del prototipo hasta conectar la autenticación.
    context.goNamed(HomeScreen.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.loginBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final heroHeight = (constraints.maxHeight * 0.55)
                .clamp(220.0, 480.0)
                .toDouble();
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    children: [
                      LoginIllustration(height: heroHeight),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                        child: AutofillGroup(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                  child: Image.asset(
                                    'lib/resources/images/Hada Corp-Logo-2022-10.png',
                                    width: 70,
                                    height: 26,
                                    semanticLabel: 'HADA Corp',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Center(
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 5,
                                    children: [
                                      const Text(
                                        'INICIA',
                                        style: TextStyle(
                                          fontFamily: 'BebasNeue',
                                          fontSize: 34,
                                          height: 1.1,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryColor,
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
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
                                const SizedBox(height: 14),
                                LoginField(
                                  obscurePassword: _obscurePassword,
                                  onSubmitted: _submit,
                                  onTogglePassword: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  label: 'Usuario',
                                  controller: _emailController,
                                  icon: Iconsax.user_copy,
                                  password: false,
                                ),
                                const SizedBox(height: 14),
                                LoginField(
                                  obscurePassword: _obscurePassword,
                                  onSubmitted: _submit,
                                  onTogglePassword: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  label: 'Contraseña',
                                  controller: _passwordController,
                                  icon: Iconsax.lock_copy,
                                  password: true,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: (value) => setState(
                                          () => _rememberMe = value ?? false,
                                        ),
                                        activeColor: AppColors.primaryColor,
                                        checkColor: Colors.white,
                                        side: const BorderSide(
                                          color: AppColors.primaryColor,
                                          width: 1.6,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        semanticLabel: 'Recuérdame',
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: GestureDetector(
                                        onTap: () => setState(
                                          () => _rememberMe = !_rememberMe,
                                        ),
                                        child: const Text(
                                          'Recuérdame',
                                          style: TextStyle(
                                            fontFamily: 'SulphurPoint',
                                            fontSize: 16,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: _submit,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primaryColor,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    textStyle: const TextStyle(
                                      fontFamily: 'BebasNeue',
                                      fontSize: 24,
                                    ),
                                  ),
                                  child: const Text('INGRESAR'),
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
    );
  }
}
