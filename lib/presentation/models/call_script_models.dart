enum CallScriptTone { neutral, positive, negative, discovery, investment }

class CallScriptStep {
  final String title;
  final String content;
  final String instruction;
  final String? introduction;
  final List<CallScriptResponse> responses;
  final CallScriptTone tone;
  final bool showContinue;
  final CallScriptStep? nextStep;
  final List<String> bulletPoints;
  final List<String> benefits;

  const CallScriptStep({
    required this.title,
    required this.content,
    required this.instruction,
    this.introduction,
    this.responses = const [],
    this.tone = CallScriptTone.neutral,
    this.showContinue = false,
    this.nextStep,
    this.bulletPoints = const [],
    this.benefits = const [],
  });
}

enum CallScriptResponseIcon { investment, housing, rental }

class CallScriptResponse {
  final String label;
  final CallScriptStep? nextStep;
  final CallScriptResponseIcon? icon;

  const CallScriptResponse({required this.label, this.nextStep, this.icon});
}

class CallScript {
  final String title;
  final List<CallScriptStep> steps;

  const CallScript({required this.title, required this.steps});
}

const demoInvestmentTelchacCallStep = CallScriptStep(
  title: 'Telchac',
  content:
      'Pertenece al municipio de Telchac que es una localidad situada entre los '
      'principales puertos de la península de Yucatán. Formando parte de una de '
      'las zonas con mayor crecimiento y plusvalía en México.',
  instruction: '',
  tone: CallScriptTone.investment,
  showContinue: true,
);

const demoInvestmentLocationCallStep = CallScriptStep(
  title: 'Ubicación y plusvalía',
  content:
      'Nuestro acceso principal es por la Carretera Federal 172 Motul – Telchac '
      'Puerto, como le comenté hace un momento Runa Residencial tiene excelente '
      'ubicación y generará excelente plusvalía debido a estar en un estado de '
      'gran crecimiento, cercano a zonas turísticas, cenotes, playas, pueblos '
      'mágicos y zonas arqueológicas el cual atraerá turismo que a su vez '
      'generará mayor plusvalía y derrama económica.',
  instruction: '',
  tone: CallScriptTone.investment,
  showContinue: true,
  nextStep: demoInvestmentTelchacCallStep,
);

const demoInvestmentCallStep = CallScriptStep(
  title: 'Inversión',
  content:
      'Esa es una muy buena opción sr(a) {prospectName} ya que por la zona '
      'turística donde se encuentra - quiere decir es un producto que al momento '
      'de adquirirlo ya empieza a ganar plusvalía eso sin contar la dimensión '
      'que es excelente para cualquier proyecto, hablo desde 600 m² y hasta '
      'más de 1000 m² de nuestros terrenos.',
  instruction: '',
  tone: CallScriptTone.investment,
  showContinue: true,
  nextStep: demoInvestmentLocationCallStep,
);

const demoHousingLocationCallStep = CallScriptStep(
  title: 'Ubicación y playa',
  content:
      'Nuestro acceso principal es por la Carretera Federal 172 Motul – Telchac '
      'Puerto, como le comenté hace un momento Runa Residencial tiene excelente '
      'ubicación, a pocos minutos de su inversión se ubica el puerto de Telchac, '
      'una playa cálida con aguas cristalinas y arena fina,',
  instruction: '',
  tone: CallScriptTone.investment,
  showContinue: true,
);

const demoHousingCallStep = CallScriptStep(
  title: 'Vivienda',
  content:
      'Esa es una muy buena opción sr(a) {prospectName} ya que por las '
      'dimensiones desde los 600 metros cuadrados de nuestros terrenos y hasta '
      'más de 1000 m², cada Clúster es privado y con acceso controlado por lo '
      'que los 50 lotes le permitirán vivir de forma exclusiva, con alta '
      'plusvalía y en la tranquilidad de la naturaleza, sin el ajetreo de la '
      'ciudad, la contaminación, el ruido y usted puede construir la casa de '
      'descanso de sus sueños donde encontrará paz.',
  instruction: '',
  tone: CallScriptTone.investment,
  showContinue: true,
  nextStep: demoHousingLocationCallStep,
);

const demoRentalBenefitsCallStep = CallScriptStep(
  title: 'Inversión y atractivos de la zona',
  content:
      'Le confirmo que el 98 % de los inversionistas que adquieren su lote con '
      'nosotros son de otros estados de la república o del extranjero, por lo '
      'que no se encuentran físicamente aquí, debido a esto manejamos dos '
      'opciones para la inversión para que no pierdan la oportunidad de '
      'realizarla ganando excelentes ubicaciones y beneficios, de lanzamiento '
      'o preventas.\n\n'
      'Estamos seguros de que, como nosotros, quedará fascinado con la magia '
      'de esta ruta y que realmente es la inversión que está buscando, estará '
      'completamente satisfecho con su terreno. La tranquilidad que emana este '
      'lugar, le harán entender por qué fue tan importante, para la cultura '
      'maya y ahora podrá relajarse en su terreno, renovar tu mente, cargarse '
      'de Energía, vivir en tranquilidad y en compañía con la naturaleza, '
      'lejos del ruido y el tráfico de la ciudad.\n\n'
      '¿Si no es indiscreción señor(a) a qué se dedica?\n\n'
      'Sr(a) {prospectName} con nosotros tendrá la oportunidad de visitar '
      'playas todos los días, puesto que estamos en la mejor zona de la '
      'Península, adicional encontrará:',
  benefits: [
    'CENOTES',
    'TIROLESAS',
    'SELVA',
    'PLAYA',
    'SNORKELING',
    'ZONAS ARQUEOLÓGICAS',
    'RESERVAS ECOLÓGICAS',
  ],
  instruction: '',
  tone: CallScriptTone.discovery,
  showContinue: true,
);

const demoRentalCallStep = CallScriptStep(
  title: 'Renta',
  content:
      'Esa es una muy buena opción sr(a) {prospectName} ya que por la zona '
      'turística donde se encuentra - quiere decir es un producto que al momento '
      'de adquirirlo ya empieza a ganar plusvalía eso sin contar la dimensión '
      'que es excelente para cualquier proyecto, hablo desde 600 m² y hasta '
      'más de 1000 m² de nuestros terrenos.\n\n'
      'Nuestro acceso principal es por la Carretera Federal 172 Motul – Telchac '
      'Puerto, como le comenté hace un momento RUNA YUCATÁN tiene excelente '
      'ubicación y generará excelente plusvalía debido a estar en un estado de '
      'gran crecimiento, cercano a zonas turísticas, cenotes, playas, pueblos '
      'mágicos y zonas arqueológicas el cual atraerá turismo que a su vez '
      'generará mayor plusvalía y derrama económica.\n\n'
      'Pertenece al municipio de Telchac que es una localidad situada entre los '
      'principales puertos de la península de Yucatán. Formando parte de una de '
      'las zonas con mayor crecimiento y plusvalía en México.',
  instruction: '',
  tone: CallScriptTone.investment,
  showContinue: true,
  nextStep: demoRentalBenefitsCallStep,
);

const demoInvestmentPurposeCallStep = CallScriptStep(
  title: '¿Su terreno le interesa cómo?',
  bulletPoints: [
    'Retorno de inversión y dejar madurar su dinero',
    'Plan de negocio',
    'O como para construir algo de descanso en un futuro',
  ],
  content: '¿Qué es lo que quiere encontrar con esta inversión para que yo sepa cómo ayudarle?',
  instruction: '',
  responses: [
    CallScriptResponse(
      label: 'INVERSIÓN',
      icon: CallScriptResponseIcon.investment,
      nextStep: demoInvestmentCallStep,
    ),
    CallScriptResponse(
      label: 'VIVIENDA',
      icon: CallScriptResponseIcon.housing,
      nextStep: demoHousingCallStep,
    ),
    CallScriptResponse(
      label: 'RENTA',
      icon: CallScriptResponseIcon.rental,
      nextStep: demoRentalCallStep,
    ),
  ],
);

const demoDiscoveryCallStep = CallScriptStep(
  title: '¿Cuándo fue la última vez que vino?',
  instruction:
      '(Y haces plática esto te sirve para tu Discovery, SABRÁS CUÁNDO VINO POR '
      'ÚLTIMA VEZ, SI VIENE SEGUIDO, SI CONOCE, Y CON QUIÉN VIAJA, TRATA DE '
      'PREGUNTARLE, VINO CON SU FAMILIA, VINO DE NEGOCIOS, CUANDO VIENE DÓNDE '
      'SE QUEDA, cosas así, etc.)',
  content:
      'Le platico RUNA YUCATÁN es un desarrollo eco-sustentable en lotificación '
      'de 171 terrenos con fines de privada rústica dividido en 5 secciones '
      '(cuántos lotes por sección, tipo cluster), estratégicas. El proyecto se '
      'encuentra ubicado en el municipio de Telchac a 10 minutos del puerto, '
      'donde encontrará espacios turísticos enfocados al descanso, meditación, '
      'aventura en la selva, exploración y contacto con la naturaleza, de los '
      'cuales podrá disfrutar cada momento por su cercanía y que al mismo tiempo '
      'causarán una impactante plusvalía en la zona. De hecho, me encantaría '
      'enviarle información para que pueda apreciar el tipo de turismo que '
      'tenemos en esta zona.\n\n'
      '¿Sr. {prospectName}, esta es la primera inversión que hace en terrenos?\n\n'
      'Sí, excelente ¿y en dónde?\n\n'
      'Platíqueme ¿qué es lo que más le gusta o llama la atención de esta zona?',
  tone: CallScriptTone.discovery,
  showContinue: true,
  nextStep: demoInvestmentPurposeCallStep,
);

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
    CallScriptStep(
      title: 'Pregunta',
      introduction:
          '¡¡Súper bien!!, yo Customer Servise-Josue Escalante tendré el privilegio de ayudarle.\n'
          'Sr(a) {prospectName}',
      content:
          '¿Qué le llamó la atención de nuestra publicidad? Platíqueme, excelente Señor '
          '{prospectName} Sé que su tiempo, es lo más importante así que seré muy '
          'breve con la información a compartir para ayudarlo y posteriormente a esto '
          'le enviaré la información necesaria sobre nosotros para que usted pueda '
          'tomar la decisión más acertada con respecto a su inversión.\n\n'
          '¿Muy bien primero que nada quisiera preguntarle si está usted familiarizado '
          'con esta zona o es la primera vez que nos visitará?',
      instruction: '(Esperas respuesta, si te dice que sí).',
      responses: [
        CallScriptResponse(
          label: 'SI HA VIAJADO',
          nextStep: CallScriptStep(
            title: 'Sí ha viajado',
            content:
                'Perfecto ¿y qué es lo que más le gustó del estado?\n\n'
                'Bueno, ¿pero me imagino que conoce Yucatán, sus atractivos '
                'turísticos, gastronómicos y puertos?',
            instruction: '',
            tone: CallScriptTone.positive,
            showContinue: true,
            nextStep: demoDiscoveryCallStep,
          ),
        ),
        CallScriptResponse(
          label: 'NO HA VIAJADO',
          nextStep: CallScriptStep(
            title: 'No ha viajado',
            content:
                'Bueno sería una buena oportunidad para aprovechar y conocer, '
                'le garantizo que le va a encantar, debería tomar un viaje para '
                'conocer el destino, este es magnífico. Es un lugar de playas, '
                'reserva ecológica y zona arqueológica donde cualquiera que sea '
                'su interés por nuestros terrenos valdrá la pena ya que Yucatán '
                'es el estado más seguro de México.',
            instruction:
                '(Si te dice no, nunca ha viajado a esta parte de México).',
            tone: CallScriptTone.negative,
            showContinue: true,
            nextStep: demoDiscoveryCallStep,
          ),
        ),
      ],
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
