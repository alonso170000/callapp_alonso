class CallScriptStep {
  final String title;
  final String content;
  final String instruction;

  const CallScriptStep({
    required this.title,
    required this.content,
    required this.instruction,
  });
}

class CallScript {
  final String title;
  final List<CallScriptStep> steps;

  const CallScript({required this.title, required this.steps});
}

const demoAlanCallScript = CallScript(
  title: 'Llamada 1',
  steps: [
    CallScriptStep(
      title: 'Saludo Inicial',
      content:
          'Hola buen día Alan Dorantes. ¿Cómo está?\n'
          'Soy Miguel Jurado\n\n'
          'Asesor de inversión de Sistema QA - Prod le marcó para ayudarlo '
          'con atención personalizada ya que usted se registró en nuestra '
          'página o en Facebook interesado en recibir información de nuestro '
          'proyecto ¿Es correcto?\n\n'
          '¿Soy el primer asesor de inversiones que se pone en contacto con '
          'Usted o ya recibió alguna llamada de alguno de mis compañeros?\n\n'
          'Para darle un correcto seguimiento, ¿quiero saber si usted es '
          'recomendado por alguna de nuestras propietarias o nos vio por '
          'publicidad?',
      instruction: 'Cuando termine de hablar contestas',
    ),
  ],
);

class CallScriptBenefitGroup {
  final String title;
  final List<String> items;

  const CallScriptBenefitGroup({required this.title, required this.items});
}

const demoFollowUpIncludes = CallScriptBenefitGroup(
  title: 'Incluye',
  items: [
    'Cenotes y Tirolesas',
    'Selva y Playa',
    'Snorkeling',
    'Zonas Arqueológicas',
    'Reservas Ecológicas',
  ],
);

const demoFollowUpBenefits = CallScriptBenefitGroup(
  title: 'Beneficios',
  items: [
    'Lotes Amplios',
    'Alta Plusvalía',
    'Tranquilidad Total',
    'Eco Hábitat',
    'Accesos Principales',
  ],
);

const demoFollowUpCategories = [
  CallScriptBenefitGroup(
    title: 'Holísticas',
    items: ['Laberinto', 'Temazcales', 'Yoga', 'Cuencos Tibetanos'],
  ),
  CallScriptBenefitGroup(
    title: 'Deportivas',
    items: ['Senderos', 'Ciclopista', 'Gimnasio al aire libre'],
  ),
  CallScriptBenefitGroup(
    title: 'Social',
    items: ['Piscina', 'Lago de los secretos', 'Solárium', 'Fogatero'],
  ),
];
