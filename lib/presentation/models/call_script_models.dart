enum CallScriptTone { neutral, positive, negative, discovery, investment }

class CallScriptStep {
  final String title;
  final String content;
  final String instruction;
  final bool instructionAfterContent;
  final String? continuation;
  final String? finalInstruction;
  final String? introduction;
  final List<CallScriptResponse> responses;
  final CallScriptTone tone;
  final bool showContinue;
  final CallScriptStep? nextStep;
  final List<String> bulletPoints;
  final List<String> benefits;
  final String? servicesIntroduction;
  final List<CallScriptBenefitGroup> services;

  const CallScriptStep({
    required this.title,
    required this.content,
    required this.instruction,
    this.instructionAfterContent = false,
    this.continuation,
    this.finalInstruction,
    this.introduction,
    this.responses = const [],
    this.tone = CallScriptTone.neutral,
    this.showContinue = false,
    this.nextStep,
    this.bulletPoints = const [],
    this.benefits = const [],
    this.servicesIntroduction,
    this.services = const [],
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

const demoInvestmentCallStep = CallScriptStep(
  title: 'Inversión',
  content:
      'Esa es una muy buena opción sr(a) {prospectName} ya que por la zona '
      'turística donde se encuentra - quiere decir es un producto que al momento '
      'de adquirirlo ya empieza a ganar plusvalía eso sin contar la dimensión '
      'que es excelente para cualquier proyecto, hablo desde 600 m² y hasta '
      'más de 1000 m² de nuestros terrenos.\n\n'
      'Nuestro acceso principal es por la Carretera Federal 172 Motul – Telchac '
      'Puerto, como le comenté hace un momento Runa Residencial tiene excelente '
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

const demoHousingCallStep = CallScriptStep(
  title: 'Vivienda',
  content:
      'Esa es una muy buena opción sr(a) {prospectName} ya que por las '
      'dimensiones desde los 600 metros cuadrados de nuestros terrenos y hasta '
      'más de 1000 m², cada Clúster es privado y con acceso controlado por lo '
      'que los 50 lotes le permitirán vivir de forma exclusiva, con alta '
      'plusvalía y en la tranquilidad de la naturaleza, sin el ajetreo de la '
      'ciudad, la contaminación, el ruido y usted puede construir la casa de '
      'descanso de sus sueños donde encontrará paz.\n\n'
      'Nuestro acceso principal es por la Carretera Federal 172 Motul – Telchac '
      'Puerto, como le comenté hace un momento Runa Residencial tiene excelente '
      'ubicación, a pocos minutos de su inversión se ubica el puerto de Telchac, '
      'una playa cálida con aguas cristalinas y arena fina,\n\n'
      'cerca encontrará la playa de San Crisanto, la Laguna Rosada, el Club de '
      'Yates, por eso a su alrededor tendrá mucha naturaleza y atractivos.\n\n'
      'Nuestros terrenos cuentan con permisos y registros en régimen de '
      'condominio en catastro del municipio de Telchac Yucatán.\n\n'
      'Tenemos el beneficio de la tranquilidad, pero al mismo tiempo todas las '
      'zonas turísticas que nos gusta disfrutar a tan solo unos minutos en '
      'auto, sin estrés de ciudades grandes, sin tráfico, sin bullicio de '
      'ciudades grandes y en contacto con la naturaleza.',
  instruction: '',
  tone: CallScriptTone.investment,
  showContinue: true,
  nextStep: demoRentalBenefitsCallStep,
);

const demoUnableToViewCallStep = CallScriptStep(
  title: 'Revisión de información y seguimiento',
  content:
      'Entiendo que esté ocupado ahora y no tenga posibilidad de entrar conmigo '
      'a la página para revisar el brochure y el plan maestro, pero me interesa '
      'que vea la información que le estaré enviando.\n\n'
      'Lo voy a dar de alta por Whats para que guarde mi contacto. Después le '
      'enviaré el brochure con la información general. Básicamente lo que aquí '
      'hablamos pero con imágenes, también le enviaré la liga del plan maestro '
      'para que vea la distribución del proyecto y así mismo la disponibilidad, '
      'cuando haya revisado el brochure anote en una hoja las preguntas que '
      'quiera hacerme, para cuando hablemos de nuevo yo pueda responderlas y '
      'ayudarle. En el plan maestro verá un semáforo, los lotes verdes son '
      'disponibles, usted puede darle clic a la ubicación que le parezca mejor '
      'o más le guste y como es interactivo le saldrán los m² y el costo regular '
      'vigente.\n\n'
      'Al comunicarnos de nuevo y que me diga cuál le interesa yo podré '
      'explicarle la promoción y ayudarle con un ejercicio de ese lote para '
      'que usted pueda comparar el costo regular y la promoción y decidir '
      'cuál le conviene.\n\n'
      '¿En cuánto tiempo puede revisar esta información, le parece bien si '
      'agendo la llamada en un par de horas que esté más tranquilo y ya lo '
      'haya revisado?',
  instruction:
      '*Escuchas las preguntas y conforme a eso vas tomando nota de todo y '
      'recuerda dejar una cita bien hecha. Cuando cuelgues en breve mandar '
      'Whats — consulta con tu supervisor la forma correcta del envío de Whats*',
  instructionAfterContent: true,
  continuation:
      '¿Le parece bien que le devuelva la llamada hoy o mañana? '
      '¿A las ____ o a las _____?\n\n'
      'Perfecto he agendado la llamada para ser puntual y que usted en esa '
      'hora esté esperando mi llamada ¿de acuerdo?, de todos modos, cualquier '
      'duda va a tener mi contacto y mándeme mensaje y de inmediato lo ayudo. '
      'Le recuerdo que es un placer ayudarlo, quedo a sus órdenes -\n\n'
      'Sé que es una decisión importante por lo que le pido que lo revise '
      'bien y lo platique con su esposa (o) socios.\n\n'
      'Así mismo le puedo mandar por Whats unos videos y algunas imágenes '
      'de la zona, me interesa que pueda revisar esta información el día de '
      'hoy y me confirme su recepción.\n\n'
      'Un gusto platicar con usted SR {prospectName}. Mi nombre nuevamente '
      'es ____________ de Runa Yucatán y le estaré apoyando en esta decisión '
      'tan importante.',
  finalInstruction:
      '*Una vez que envíes la información al cliente, realiza el compromiso '
      'de que la lea en su PC o móvil; de no poder leer la información al '
      'momento di lo siguiente:\n'
      '*AGENDAS LA LLAMADA PARA ACLARAR PREGUNTAS',
  tone: CallScriptTone.discovery,
  responses: [CallScriptResponse(label: 'Agendar llamada para dudas')],
);
const demoClosingCallStep = CallScriptStep(
  title: 'Cierre y Agendamiento',
  content:
      'Sr(a) {prospectName} Todo lo que le he estado platicando se lo voy a '
      'mandar en un correo ahí le adjunto el máster plan para que vea cómo '
      'queda nuestra distribución y pueda elegir un lote y en base a ese lote '
      'trabajamos para que usted tenga bien claro cómo quedaría su inversión '
      'inicial y cómo quedarían sus mensualidades.\n\n'
      'También tengo información adicional muy importante para compartírsela '
      'por WhatsApp ¿me permite compartírsela?\n\n'
      'Perfecto, tiene oportunidad de revisar la información el día de hoy '
      '¿le parece si nos comunicamos el día__ para resolver las dudas o '
      'preguntas que le puedan surgir? Le pido que al revisar la información, '
      'tenga a la mano pluma y papel y anote lo que quiera preguntarme, para '
      'que podamos hablar particularmente de eso vale.\n\n'
      '¿Algo más en que le pueda ayudar?\n\n'
      'Perfecto le mando Whats para que me guarde le mando por Whats lo que '
      'quedamos y me comunico como quedamos a las ____ hrs del día. Le recuerdo '
      'mi nombre ______ para que guarde mi contacto y continúo ayudándole. '
      'Que tenga un día mágico.',
  instruction: '',
  tone: CallScriptTone.discovery,
  responses: [
    CallScriptResponse(
      label: '¿No puede entrar y ver los datos?',
      nextStep: demoUnableToViewCallStep,
    ),
    CallScriptResponse(label: 'Agendar llamada para dudas'),
  ],
);
const demoLotReservationCallStep = CallScriptStep(
  title: 'Bloqueo de lote y promoción',
  content:
      'Cualquier lote que le interese, tenemos opciones de bloqueo en donde lo '
      'importante es garantizar la ubicación que le guste ya que los lotes se '
      'encuentran sujetos a disponibilidad y por estar en PREVENTA esta cambia '
      'constantemente, usted mismo puede confirmarlo en nuestra página web en '
      'nuestro plan maestro en tiempo real, si ahorita se bloquea una ubicación '
      'inmediatamente cambia de color y así podemos verificar la disponibilidad '
      'en tiempo real.\n\n'
      'Para bloquear un lote solo necesitamos su identificación oficial y el '
      'número de lote elegido para que durante 24 horas en lo que revisa la '
      'información general y papelería, su lote no pueda elegirlo u ofrecerlo '
      'nadie más, en cuanto tenga claro entonces procedemos a el pago de la '
      'inversión inicial de su lote con lo que se garantiza el bloqueo de aquí '
      'a que venga a firmar su contrato original y conocer su inversión.\n\n'
      'Quiero comentarle que hasta la fecha ____ estamos manejando una promoción '
      'por ________________, donde le podemos aplicar al costo regular o costo '
      'web, mismo que ve en la página, un porcentaje o bono de descuento, tal '
      'vez pueda interesarle, me interesa que revisemos la información que le '
      'estoy mandando en este momento y que me vaya diciendo si tiene dudas '
      'para que pueda contestarlas, también si tiene una computadora a la mano '
      'podemos entrar al plan maestro para mostrarle la distribución del '
      'proyecto y las mejores ubicaciones, en caso de no tener una computadora '
      'ahora puede ponerse en altavoz y le voy mostrando.\n\n'
      'Primero quiero que vea nuestra distribución de proyecto, accesos y '
      'disponibilidad y que pueda ver las medidas, los costos de valor actual, '
      'que elijamos alguna ubicación para que pueda explicarle nuestra promoción '
      'y así mismo un ejercicio de ese lote aplicándola, para que pueda comparar '
      'con los costos regulares.',
  instruction:
      '(EN ESE MOMENTO SI ENTRA A LA PAG LE COMIENZAS A EXPLICAR TODO SOBRE LA '
      'DISTRIBUCIÓN DE PROYECTO, LOS LOTES, LAS AMENIDADES Y LE EXPLICAS QUE EL '
      'MÁSTER ES INTERACTIVO Y QUE LOS LOTES VERDES SON DISPONIBLES, deja que '
      'él te pregunte qué significan los otros colores con eso mides también '
      'su nivel de atención LO LLEVAS AL PUNTO DE ELEGIR UNA UBICACIÓN PARA QUE '
      'VEA EL PRECIO REGULAR Y LE EXPLICAS QUE LAS FORMAS DE PAGO SON CON '
      'INTERESES, PERO QUE TIENES LA PROMOCIÓN VÁLIDA A TAL FECHA Y QUE SI TE '
      'PERMITE LE EXPLICA CÓMO QUEDARÍA Y CÓMO FUNCIONA Y AHÍ PASAS LA LLAMADA).',
  instructionAfterContent: true,
  tone: CallScriptTone.discovery,
  showContinue: true,
  nextStep: demoClosingCallStep,
);
const demoFinancingCallStep = CallScriptStep(
  title: 'Preguntas y financiamiento',
  content:
      '¿Ahora no sé si tiene alguna pregunta sobre lo que le platiqué? '
      '¿Dígame si este proyecto se ajusta a lo que está buscando? Le mandaré '
      'en este momento un correo con la información general que platicamos '
      'y súper importante, el link de nuestra página web, donde se encuentra '
      'nuestro plan maestro con la distribución de los lotes, áreas verdes '
      'y amenidades.\n\n'
      'Estamos en etapa de preventa, por lo cual tenemos excelentes opciones '
      'de inversión, así como un excelente plan de financiamiento con beneficios '
      'directos con el desarrollo. Como apoyo a los inversionistas actualmente '
      'tenemos facilidades en las formas de pago, sin requisito de aval, ni '
      'buró de crédito, para otorgarle el financiamiento hasta por un 70%, '
      'con una inversión inicial del 30%.',
  instruction: '',
  tone: CallScriptTone.discovery,
  showContinue: true,
  nextStep: demoLotReservationCallStep,
);

const demoProjectServicesCallStep = CallScriptStep(
  title: 'Beneficios y servicios del proyecto',
  content: 'Dentro del proyecto te ofrecemos los siguientes beneficios:',
  instruction: '',
  benefits: [
    'LOTES AMPLIOS',
    'PLUSVALÍA',
    'TRANQUILIDAD',
    'NATURALEZA Y ECO HABITAT',
    'ACCESO A LA ZONA POR CARRETERAS IMPORTANTES',
  ],
  servicesIntroduction:
      'Los siguientes servicios, ya que no solo te ofrecemos invertir en un '
      'lote, sino hacer una inversión inteligente en un proyecto completo que incluye:',
  services: [
    CallScriptBenefitGroup(
      title: 'ÁREAS HOLÍSTICAS',
      items: [
        'Laberinto de meditación',
        'Templo ceremonial',
        'Temazcales de renacimiento',
        'Santuario de las artes',
        'Paraíso del Yoga',
        'Templo de los oráculos',
        'Fuente de los cuencos tibetanos',
      ],
    ),
    CallScriptBenefitGroup(
      title: 'ÁREAS DEPORTIVAS',
      items: [
        'Senderos para caminar y correr',
        'Ciclopista',
        'Gimnasio al aire libre',
      ],
    ),
    CallScriptBenefitGroup(
      title: 'ÁREA SOCIAL',
      items: [
        'Áreas de conexión',
        'Solárium frente a la piscina',
        'Lago de los secretos (Piscina)',
        'Área para fogata',
        'Área de asador',
      ],
    ),
  ],
  tone: CallScriptTone.discovery,
  showContinue: true,
  nextStep: demoFinancingCallStep,
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
  nextStep: demoProjectServicesCallStep,
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
          'Hola buen día {prospectName}. ¿Cómo está?\n'
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

// Texto de demostración de la segunda llamada.
const demoFollowUpGreeting =
    'Hola buen día Sr(a). {prospectName}, ¿Cómo está? '
    'Habla Miguel Jurado.\n\n'
    'Hablamos el día de ayer y le envié la información del desarrollo '
    'RUNA YUCATÁN, dígame... ¿Encontró alguna ubicación de su agrado?';

const demoFollowUpProjectIntroduction =
    'Me gustaría comentarle de nuevo que no solo es un terreno; la '
    'inversión le incluye un proyecto completo con alta plusvalía y '
    'en armonía con el medio ambiente:';

const demoFollowUpEcology =
    'Contamos con 0% impacto ecológico y cultura verde. El uso de '
    'suelo es habitacional con límite de construcción del 50%, '
    'garantizando plusvalía y cero contaminación visual.';

const demoFollowUpClosingQuestion =
    '¿Desea que comencemos a construir su sueño hoy mismo?';
