import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static const _background = Color(0xFFE0FFF9);
  static const _fieldColor = Color(0xFF439D98);
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
      backgroundColor: _background,
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
                      _LoginIllustration(height: heroHeight),
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
                                _field(
                                  label: 'Usuario',
                                  controller: _emailController,
                                  icon: Iconsax.user_copy,
                                  password: false,
                                ),
                                const SizedBox(height: 14),
                                _field(
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

  Widget _field({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool password,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'SulphurPoint',
            fontSize: 20,
            height: 1.2,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 3),
        TextFormField(
          controller: controller,
          obscureText: password && _obscurePassword,
          autocorrect: false,
          enableSuggestions: !password,
          keyboardType: password
              ? TextInputType.visiblePassword
              : TextInputType.emailAddress,
          textInputAction: password
              ? TextInputAction.done
              : TextInputAction.next,
          autofillHints: [
            password ? AutofillHints.password : AutofillHints.username,
          ],
          inputFormatters: [
            LengthLimitingTextInputFormatter(password ? 64 : 100),
          ],
          onFieldSubmitted: (_) {
            if (password) _submit();
          },
          validator: (value) {
            final text = value ?? '';
            if (password) {
              if (text.isEmpty) return 'La contraseña es obligatoria.';
              if (text.length < 6) return 'Debe tener al menos 6 caracteres.';
            } else {
              if (text.trim().isEmpty) return 'El correo es obligatorio.';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                  .hasMatch(text.trim())) {
                return 'Ingresa un correo válido.';
              }
            }
            return null;
          },
          cursorColor: Colors.white,
          style: const TextStyle(
            fontFamily: 'SulphurPoint',
            color: Colors.white,
            fontSize: 18,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: _fieldColor,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            prefixIcon: Icon(icon, color: Colors.white, size: 21),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 44,
            ),
            suffixIcon: password
                ? IconButton(
                    tooltip: _obscurePassword
                        ? 'Mostrar contraseña'
                        : 'Ocultar contraseña',
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Iconsax.eye_copy
                          : Iconsax.eye_slash_copy,
                      color: Colors.white,
                      size: 21,
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.primaryColor,
                width: 2,
              ),
            ),
            errorMaxLines: 2,
          ),
        ),
      ],
    );
  }
}

class _LoginIllustration extends StatelessWidget {
  final double height;

  const _LoginIllustration({required this.height});

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
                colors: [Color(0x00E0FFF9), _LoginScreenState._background],
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
