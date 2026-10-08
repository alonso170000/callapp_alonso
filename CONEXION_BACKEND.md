# Login con CRM-hada en Render

La app usa https://api-crm-mx9l.onrender.com por defecto. Para probarla, ejecuta `flutter run` desde CallerApp y reinicia por completo la app si estaba abierta. Puedes sobrescribir la URL pública del servicio (sin /api/v1):

```sh
flutter run --dart-define=API_BASE_URL=https://api-crm-mx9l.onrender.com
```

Para generar el APK:

```sh
flutter build apk --dart-define=API_BASE_URL=https://api-crm-mx9l.onrender.com
```

Inicia sesión con el **username** y contraseña de un usuario activo de Aiven que tenga un desarrollo activo asignado. La app envía POST /api/v1/auth/login; solo entra al recibir status success y un token. El token y desarrollo activo quedan en memoria y se eliminan al cerrar sesión o reiniciar la app. Las demás pantallas conservan sus datos de demostración.

Las credenciales de Aiven y JWT_SECRET se configuran únicamente en Render. Nunca se incluyen en Flutter. Un error 500 requiere revisar los registros del backend y su conexión a la base de datos. La configuración de URL requiere reiniciar la ejecución; hot reload no actualiza dart-define.

## Datos de perfil

El login de CRM-hada ahora devuelve usuario con id, username, nombre_completo y email. Vuelve a desplegar el backend en Render y cierra e inicia sesión en la app para recibir el correo. El teléfono se muestra como No disponible mientras el backend no lo proporcione. Las ediciones del perfil siguen siendo locales y no actualizan Aiven.
