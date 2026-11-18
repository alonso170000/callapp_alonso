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
- Textos: `BebasNeue` para títulos de pantalla y botones; `SulphurPoint` para contenido y cabeceras
  de bottom sheet.
- Reutilizar `CustomButton`, `LabelWidget`, `NavigationBarWidget` y widgets por feature.
- Usar `SafeArea`, scroll y ajustes para teclado, modo oscuro y textos grandes.
- Toda acción solo-icono lleva tooltip/Semantics; textos visibles en español.
- Navegación principal solo con `go_router`; no `Navigator` para rutas.

## Bottom sheets

### Animación de pulsación

Todo botón nuevo se envuelve en `AppPressBounce`. No se animan chips, tarjetas, `ListTile`,
navegación ni pickers nativos. Los botones deshabilitados no rebotan y siempre se respeta
`MediaQuery.disableAnimations`.

Todas las hojas modales de la app comparten un único diseño. No crear variantes visuales nuevas ni
reimplementar cabecera, handle, paddings, scroll o botones dentro de una pantalla.

- **Apertura:** usar `showAppBottomSheet` de
  `lib/presentation/widgets/app_bottom_sheet.dart` (junto con `AppBottomSheet`, `AppSheetActions` y
  `AppSheetSectionTitle`). Si esos componentes aún no existen, créalos primero con este mismo estándar;
  no los sustituyas por otra variante. Nunca llamar `showModalBottomSheet` directamente ni usar
  `showDialog`/`AlertDialog`/`SimpleDialog` para UI propia. Si el flujo necesita un diálogo, se
  convierte en bottom sheet. Los selectores nativos de fecha, hora y rango no son hojas y se quedan.
- **Cromo:** `isScrollControlled: true`, `useSafeArea: true`, `showDragHandle: true`, superficie del
  tema, radio superior `AppStyles.sheetRadius` (24), `Clip.antiAlias` y barrera con
  `colorScheme.scrim` al 54 %. No dibujar handles a mano.
- **Cabecera:** título centrado en `SulphurPoint 22`, `FontWeight.w700`, máximo 2 líneas con
  `ellipsis`; espaciador izquierdo de 48; `IconButton` de cerrar a la derecha con icono 28 y tooltip
  `Cerrar`. Se reutiliza el texto de título existente; no se inventan títulos. Sin título no se
  pinta cabecera.
- **Interior:** `SafeArea(top: false)`, padding horizontal 24, superior 4/8 e inferior 18 más
  `MediaQuery.viewInsetsOf(context).bottom`; alto máximo 90 % de la pantalla; scroll con
  `ScrollViewKeyboardDismissBehavior.onDrag`. No duplicar `SafeArea` ni `viewInsets`.
- **Acciones:** secundaria `TextButton` y primaria `FilledButton`, altura mínima 44, radio 8,
  `BebasNeue 18`, separación de 12 y `FittedBox` para etiquetas largas. Conservar etiquetas, orden,
  callbacks, `ValueKey` y el valor exacto de `Navigator.pop`.
- **Secciones:** títulos con `SulphurPoint 19`, `FontWeight.w700`. No rediseñar campos, tarjetas,
  chips ni listas dentro del sheet.
- **Contenido:** el cambio de diseño nunca altera textos, campos, validaciones, estados ni lógica.
- **Pruebas:** toda hoja nueva debe cubrirse en `test/` y mantenerse correcta en 320/390 px, teclado
  abierto, modo claro y oscuro.

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
