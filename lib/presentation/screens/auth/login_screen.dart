import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:callerapp_frontend/presentation/screens/screens.dart';

class LoginScreen extends StatefulWidget {
  static const name = 'login';
  final bool showBiometric;

  const LoginScreen({super.key, this.showBiometric = true});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool rememberMe = false;
  bool isLoadingGoogle = false;
  bool isLoadingEmail = false;
  bool isLoadingBiometric = false;
  bool _intentoEnviar = false;
  bool _emailTocado = false;
  bool _passwordTocado = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> loginConEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _intentoEnviar = true);

    if (_validarEmail(email) != null || _validarPassword(password) != null) {
      return;
    }

    setState(() => isLoadingEmail = true);
    _irAHome();
  }

  void _irAHome() {
    context.goNamed(HomeScreen.name);
  }

  String? _validarEmail(String value) {
    if (value.isEmpty) return 'El correo es obligatorio.';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value)) return 'Ingresa un correo válido.';
    return null;
  }

  String? _validarPassword(String value) {
    if (value.isEmpty) return 'La contraseña es obligatoria.';
    if (value.length < 6) return 'Debe tener al menos 6 caracteres.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final loading = isLoadingGoogle || isLoadingEmail;
    final bloqueoAcciones = loading || isLoadingBiometric;

    return AuthScreenLayout(
      title: 'Inicia\nsesión',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 18),
          CustomTextField.auth(
            hintText: 'Correo electrónico',
            keyboardType: TextInputType.emailAddress,
            controller: _emailController,
            prefixIcon: Icons.alternate_email,
            helperText: 'Ejemplo: nombre@correo.com',
            errorText: _emailTocado || _intentoEnviar
                ? _validarEmail(_emailController.text.trim())
                : null,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'\s')),
              LengthLimitingTextInputFormatter(100),
            ],
            onChanged: (_) => setState(() => _emailTocado = true),
          ),
          SizedBox(height: AppStyles.spacingLarge(context)),
          CustomTextField.auth(
            hintText: 'Contraseña',
            isPassword: true,
            controller: _passwordController,
            prefixIcon: Icons.lock_outline,
            helperText: 'Ingresa al menos 6 caracteres.',
            errorText: _passwordTocado || _intentoEnviar
                ? _validarPassword(_passwordController.text)
                : null,
            inputFormatters: [LengthLimitingTextInputFormatter(64)],
            onChanged: (_) => setState(() => _passwordTocado = true),
          ),
          SizedBox(height: AppStyles.spacingHuge(context)),
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: rememberMe,
                  onChanged: (value) {
                    setState(() => rememberMe = value ?? false);
                  },
                  activeColor: AppColors.authCyan,
                  checkColor: Colors.black,
                  side: const BorderSide(
                    color: AppColors.whiteColor,
                    width: 1.1,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Recuérdame',
                  style: TextStyle(
                    color: AppColors.whiteColor,
                    fontSize: AppStyles.textLabel(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppStyles.spacingHuge(context)),
          CustomButton.auth(
            texto: isLoadingEmail ? 'Entrando...' : 'Entrar',
            accion: bloqueoAcciones ? null : loginConEmail,
          ),

          SizedBox(height: AppStyles.spacingHuge(context)),

          SizedBox(height: AppStyles.spacingExtraLarge(context)),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 5,
          ),
        ],
      ),
    );
  }
}
