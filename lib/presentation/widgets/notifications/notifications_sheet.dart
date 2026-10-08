import 'package:flutter/material.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/resources/styles/styles.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

Future<void> showNotificationsSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.homeBackground,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('NOTIFICACIONES', style: profileHeading),
                  ),
                  IconButton(
                    tooltip: 'Cerrar notificaciones',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Icon(
                Iconsax.notification_copy,
                size: 66,
                color: AppColors.homeDeepTeal,
              ),
              const SizedBox(height: 16),
              const Text(
                'No tienes notificaciones',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SulphurPoint',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Aún no hay avisos disponibles para mostrar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SulphurPoint',
                  fontSize: 16,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
