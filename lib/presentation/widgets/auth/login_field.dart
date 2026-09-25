import 'package:callerapp_frontend/presentation/validators/login_validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';

class LoginField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool password;
  final bool obscurePassword;
  final VoidCallback onSubmitted;
  final VoidCallback onTogglePassword;

  const LoginField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    required this.password,
    required this.obscurePassword,
    required this.onSubmitted,
    required this.onTogglePassword,
  });

  @override
  Widget build(BuildContext context) {
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
          obscureText: password && obscurePassword,
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
            if (password) onSubmitted();
          },
          validator: (value) =>
              LoginValidators.field(value, password: password),
          cursorColor: Colors.white,
          style: const TextStyle(
            fontFamily: 'SulphurPoint',
            color: Colors.white,
            fontSize: 18,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.loginField,
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
                    tooltip: obscurePassword
                        ? 'Mostrar contraseña'
                        : 'Ocultar contraseña',
                    onPressed: onTogglePassword,
                    icon: Icon(
                      obscurePassword
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
