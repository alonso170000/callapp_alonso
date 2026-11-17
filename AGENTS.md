# AGENTS.md

App Flutter `callerapp_frontend` en `callapp_alonso/` (Android primero, UI y mensajes en español).
Guía extendida: skill `callapp-alonso-standards`.

## Comandos

- `flutter analyze`
- `flutter test`
- `dart format <archivos>`
- Ejecutar desde `callapp_alonso/`.

## Capas

- `lib/resources/` → colores, estilos y temas. Sin lógica.
- `lib/presentation/models/`, `validators/` → datos inmutables y reglas puras.
- `lib/presentation/widgets/<feature>/` → UI presentacional; sin HTTP ni servicios.
- `lib/presentation/screens/` → estado y orquestación; navegación con `go_router`.
- `lib/services/` → API, sesión, sync y reglas de integración. Sin `BuildContext`.
- `lib/repositories/` y `lib/data/` → caché y outbox.
- `test/` → una prueba por feature/servicio.

## Reglas de UI

- Colores solo desde `AppColors`, `ProspectTagColors` o `AppPalette`.
- Textos: `BebasNeue` para títulos, `SulphurPoint` para contenido.
- Reutilizar `CustomButton`, `LabelWidget`, `NavigationBarWidget` y widgets por feature.
- Usar `SafeArea`, scroll y ajustes para teclado, modo oscuro y textos grandes.
- Toda acción solo-icono lleva tooltip/Semantics; textos visibles en español.
- Navegación principal solo con `go_router`; no `Navigator` para rutas.

## Flujos clave

- **Mis prospectos:** `ProspectAction.resolve` elige el seguimiento pendiente/atrasado.
  - Con actividad: la tarjeta muestra el medio de la actividad.
  - Sin actividad: muestra botón de tres puntos → `ProspectContactOptionsSheet`.
  - El sheet explica el flujo, pide confirmación y permite Llamar, WhatsApp, Facebook o Correo.
  - Facebook se abre sin buscar perfil (redirección) desde tarjeta, detalle y agenda; el registro es manual.
- **Después del contacto:** se abre el detalle con el medio preseleccionado en
  `ProspectFollowUpForm`; allí se guarda el resultado y, opcionalmente, el siguiente seguimiento.
  En llamadas el seguimiento sigue siendo obligatorio.
- **Fechas de negocio:** usar `business_clock.dart`; no `DateTime.now()` crudo.
- **Llamadas:** `CallSessionController` + consentimiento de grabación + resultado.
- **Cambios locales:** repositorios con caché/outbox y `DataChangeBus` para refrescar.

## Pruebas

- Usar clientes y repositorios simulados; no depender de red.
- Mantener en verde `prospect_visual_consistency_test.dart` y las pruebas de tarjetas.
- Evitar duplicar widgets; extender propiedades con defaults.
