import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:callerapp_frontend/presentation/screens/screens.dart';
import 'package:callerapp_frontend/presentation/validators/auth_validators.dart';

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


    setState(() => isLoadingEmail = true);

   
  }


  void _irAHome() {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (route) => false,
    );
  }


  String _limpiarError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^(Exception:\s*)+'), '');
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
          OutlinedAuthButton(
            text: isLoadingGoogle ? 'Conectando...' : 'Continuar con Google',
            icon: Image.asset(
              'lib/resources/images/google_logo.png',
              width: 18,
              height: 18,
            ),
            onPressed: null,
          ),
          const SizedBox(height: 18),
          const AuthDividerLabel(text: 'O inicia sesión con'),
          const SizedBox(height: 18),
          CustomTextField.auth(
            hintText: 'Correo electrónico',
            keyboardType: TextInputType.emailAddress,
            controller: _emailController,
            prefixIcon: Icons.alternate_email,
            helperText: 'Ejemplo: nombre@correo.com',
            errorText: _emailTocado || _intentoEnviar
                ? null
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
              Text(
                '¿Olvidaste tu contraseña?',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: AppColors.whiteColor,
                  fontSize: AppStyles.textLabel(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: AppStyles.spacingHuge(context)),
          
          SizedBox(height: AppStyles.spacingHuge(context)),
          
          SizedBox(height: AppStyles.spacingExtraLarge(context)),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 5,
            children: [
              Text(
                '¿No tienes una cuenta?',
                style: TextStyle(
                  color: AppColors.whiteColor,
                  fontSize: AppStyles.textLabel(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}