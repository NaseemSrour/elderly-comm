import '../models/models.dart';

/// A realistic sample household. In Phase 2 this exact shape is what SQLite
/// will populate; the family will edit it via Admin Mode (Phase 3).
///
/// Convention: caregiver-language (English) object names carry the article
/// ("a bowl", "the window") so rendered sentences read naturally; the
/// elder-language (Arabic) names stay plain for the recognition cards.
HouseholdConfig buildSampleConfig() {
  const ar = 'ar';
  const en = 'en';

  final languages = <Language>[
    Language(code: en, label: 'English'),
    Language(code: ar, label: 'العربية', rtl: true),
  ];

  final actions = <ActionDef>[
    ActionDef(
      id: 'BRING',
      label: {en: 'Bring', ar: 'جيب'},
      emoji: '🫴',
      colorKey: 'bring',
      requiresDestination: true,
      templates: {en: 'Bring {destination} {object}.', ar: 'جيب{destination} {object}.'},
    ),
    ActionDef(
      id: 'TAKE',
      label: {en: 'Take away', ar: 'خذ'},
      emoji: '↩️',
      colorKey: 'take',
      templates: {en: 'Take {object} away.', ar: 'خذ {object}.'},
    ),
    ActionDef(
      id: 'PUT',
      label: {en: 'Put', ar: 'حط'},
      emoji: '📥',
      colorKey: 'put',
      requiresDestination: true,
      templates: {en: 'Put {object} {destination}.', ar: 'حط {object} {destination}.'},
    ),
    ActionDef(
      id: 'WASH',
      label: {en: 'Wash', ar: 'اغسل'},
      emoji: '🧼',
      colorKey: 'wash',
      templates: {en: 'Wash {object}, please.', ar: 'اغسل {object}.'},
    ),
    ActionDef(
      id: 'OPEN',
      label: {en: 'Open', ar: 'افتح'},
      emoji: '📂',
      colorKey: 'open',
      templates: {en: 'Open {object}.', ar: 'افتح {object}.'},
    ),
    ActionDef(
      id: 'CLOSE',
      label: {en: 'Close', ar: 'سكّر'},
      emoji: '🚫',
      colorKey: 'close',
      templates: {en: 'Close {object}.', ar: 'سكّر {object}.'},
    ),
    ActionDef(
      id: 'TURN_ON',
      label: {en: 'Turn on', ar: 'شغّل'},
      emoji: '🔆',
      colorKey: 'open',
      templates: {en: 'Turn on {object}.', ar: 'شغّل {object}.'},
    ),
    ActionDef(
      id: 'TURN_OFF',
      label: {en: 'Turn off', ar: 'طفّي'},
      emoji: '🌑',
      colorKey: 'close',
      templates: {en: 'Turn off {object}.', ar: 'طفّي {object}.'},
    ),
  ];

  final locations = <LocationDef>[
    LocationDef(
      id: 'TO_ME',
      label: {en: 'Me', ar: 'أنا'},
      phrase: {en: 'me', ar: 'لي'},
      emoji: '👵',
      isSelf: true,
      order: 0,
    ),
    LocationDef(
      id: 'TABLE',
      label: {en: 'Table', ar: 'الطاولة'},
      phrase: {en: 'on the table', ar: 'عالطاولة'},
      emoji: '🍽️',
      order: 1,
    ),
    LocationDef(
      id: 'REFRIGERATOR',
      label: {en: 'Refrigerator', ar: 'الثلاجة'},
      phrase: {en: 'in the refrigerator', ar: 'بالثلاجة'},
      emoji: '🧊',
      order: 2,
    ),
    LocationDef(
      id: 'KITCHEN',
      label: {en: 'Kitchen', ar: 'المطبخ'},
      phrase: {en: 'to the kitchen', ar: 'عالمطبخ'},
      emoji: '🍳',
      order: 3,
    ),
    LocationDef(
      id: 'BEDROOM',
      label: {en: 'Bedroom', ar: 'الغرفة'},
      phrase: {en: 'to the bedroom', ar: 'عالغرفة'},
      emoji: '🛏️',
      order: 4,
    ),
  ];

  final situations = <Situation>[
    Situation(id: 'kitchen', label: {en: 'Kitchen', ar: 'المطبخ'}, emoji: '🍳', colorKey: 'put', order: 0),
    Situation(id: 'living_room', label: {en: 'Living Room', ar: 'الصالون'}, emoji: '🛋️', colorKey: 'take', order: 1),
    Situation(id: 'bedroom', label: {en: 'Bedroom', ar: 'غرفة النوم'}, emoji: '🛏️', colorKey: 'self', order: 2),
    Situation(id: 'bathroom', label: {en: 'Bathroom', ar: 'الحمّام'}, emoji: '🚿', colorKey: 'open', order: 3),
    Situation(id: 'medicine', label: {en: 'Medicine', ar: 'الدوا'}, emoji: '💊', colorKey: 'close', order: 4),
  ];

  final objects = <CommunicationObject>[
    // --- Kitchen ---
    CommunicationObject(id: 'bowl', name: {en: 'a bowl', ar: 'جاط'}, emoji: '🥣', situationId: 'kitchen', actionIds: ['BRING', 'TAKE', 'WASH', 'PUT'], order: 0),
    CommunicationObject(id: 'water', name: {en: 'water', ar: 'مي'}, emoji: '💧', situationId: 'kitchen', actionIds: ['BRING'], order: 1),
    CommunicationObject(id: 'plate', name: {en: 'a plate', ar: 'صحن'}, emoji: '🍽️', situationId: 'kitchen', actionIds: ['BRING', 'TAKE', 'WASH', 'PUT'], order: 2),
    CommunicationObject(id: 'glass', name: {en: 'a glass', ar: 'كباية'}, emoji: '🥛', situationId: 'kitchen', actionIds: ['BRING', 'TAKE', 'WASH'], order: 3),
    CommunicationObject(id: 'cup', name: {en: 'a cup', ar: 'فنجان'}, emoji: '☕', situationId: 'kitchen', actionIds: ['BRING', 'TAKE', 'WASH'], order: 4),
    CommunicationObject(id: 'spoon', name: {en: 'a spoon', ar: 'معلقة'}, emoji: '🥄', situationId: 'kitchen', actionIds: ['BRING', 'TAKE', 'WASH'], order: 5),
    CommunicationObject(id: 'fork', name: {en: 'a fork', ar: 'شوكة'}, emoji: '🍴', situationId: 'kitchen', actionIds: ['BRING', 'TAKE', 'WASH'], order: 6),
    CommunicationObject(id: 'knife', name: {en: 'a knife', ar: 'سكينة'}, emoji: '🔪', situationId: 'kitchen', actionIds: ['BRING', 'TAKE', 'WASH'], order: 7),
    CommunicationObject(id: 'bread', name: {en: 'bread', ar: 'خبز'}, emoji: '🍞', situationId: 'kitchen', actionIds: ['BRING', 'TAKE'], order: 8),
    CommunicationObject(id: 'kettle', name: {en: 'the kettle', ar: 'الغلاية'}, emoji: '🫖', situationId: 'kitchen', actionIds: ['BRING', 'TURN_ON', 'TURN_OFF'], order: 9),

    // --- Living room ---
    CommunicationObject(id: 'tv', name: {en: 'the TV', ar: 'التلفزيون'}, emoji: '📺', situationId: 'living_room', actionIds: ['TURN_ON', 'TURN_OFF'], order: 0),
    CommunicationObject(id: 'lr_window', name: {en: 'the window', ar: 'الشباك'}, emoji: '🪟', situationId: 'living_room', actionIds: ['OPEN', 'CLOSE'], order: 1),
    CommunicationObject(id: 'ac', name: {en: 'the air conditioner', ar: 'المكيّف'}, emoji: '❄️', situationId: 'living_room', actionIds: ['TURN_ON', 'TURN_OFF'], order: 2),
    CommunicationObject(id: 'lr_light', name: {en: 'the light', ar: 'الضو'}, emoji: '💡', situationId: 'living_room', actionIds: ['TURN_ON', 'TURN_OFF'], order: 3),

    // --- Bedroom ---
    CommunicationObject(id: 'bedroom_window', name: {en: 'the window', ar: 'الشباك'}, emoji: '🪟', situationId: 'bedroom', actionIds: ['OPEN', 'CLOSE'], order: 0),
    CommunicationObject(id: 'bedroom_light', name: {en: 'the light', ar: 'الضو'}, emoji: '💡', situationId: 'bedroom', actionIds: ['TURN_ON', 'TURN_OFF'], order: 1),
    CommunicationObject(id: 'blanket', name: {en: 'a blanket', ar: 'حرام'}, emoji: '🛏️', situationId: 'bedroom', actionIds: ['BRING', 'TAKE'], order: 2),

    // --- Bathroom ---
    CommunicationObject(id: 'towel', name: {en: 'a towel', ar: 'منشفة'}, emoji: '🧺', situationId: 'bathroom', actionIds: ['BRING', 'TAKE'], order: 0),
    CommunicationObject(id: 'soap', name: {en: 'soap', ar: 'صابون'}, emoji: '🧼', situationId: 'bathroom', actionIds: ['BRING'], order: 1),

    // --- Medicine ---
    CommunicationObject(id: 'medicine', name: {en: 'medicine', ar: 'الدوا'}, emoji: '💊', situationId: 'medicine', actionIds: ['BRING', 'TAKE'], order: 0),
    CommunicationObject(id: 'water_glass', name: {en: 'a glass of water', ar: 'كباية مي'}, emoji: '🥛', situationId: 'medicine', actionIds: ['BRING'], order: 1),
  ];

  final commonRequests = <CommonRequest>[
    CommonRequest(id: 'cr_water', label: {en: 'Bring me water', ar: 'جيبلي مي'}, emoji: '💧', order: 0, intent: SemanticIntent(objectId: 'water', actionId: 'BRING', destinationId: 'TO_ME')),
    CommonRequest(id: 'cr_bowl', label: {en: 'Bring me a bowl', ar: 'جيبلي جاط'}, emoji: '🥣', order: 1, intent: SemanticIntent(objectId: 'bowl', actionId: 'BRING', destinationId: 'TO_ME')),
    CommonRequest(id: 'cr_medicine', label: {en: 'Bring my medicine', ar: 'جيبلي الدوا'}, emoji: '💊', order: 2, intent: SemanticIntent(objectId: 'medicine', actionId: 'BRING', destinationId: 'TO_ME')),
    CommonRequest(id: 'cr_bread', label: {en: 'Bring me bread', ar: 'جيبلي خبز'}, emoji: '🍞', order: 3, intent: SemanticIntent(objectId: 'bread', actionId: 'BRING', destinationId: 'TO_ME')),
  ];

  final routines = <Routine>[
    Routine(id: 'morning', label: {en: 'Morning', ar: 'الصبح'}, emoji: '🌅', order: 0, steps: [
      SemanticIntent(objectId: 'bedroom_window', actionId: 'OPEN'),
      SemanticIntent(objectId: 'lr_window', actionId: 'OPEN'),
      SemanticIntent(objectId: 'water', actionId: 'BRING', destinationId: 'TO_ME'),
      SemanticIntent(objectId: 'medicine', actionId: 'BRING', destinationId: 'TO_ME'),
    ]),
    Routine(id: 'night', label: {en: 'Night', ar: 'الليل'}, emoji: '🌙', order: 1, steps: [
      SemanticIntent(objectId: 'bedroom_window', actionId: 'CLOSE'),
      SemanticIntent(objectId: 'lr_window', actionId: 'CLOSE'),
      SemanticIntent(objectId: 'lr_light', actionId: 'TURN_OFF'),
      SemanticIntent(objectId: 'tv', actionId: 'TURN_OFF'),
    ]),
  ];

  final helpRequests = <HelpRequest>[
    HelpRequest(id: 'help_walk', phrase: {en: 'Help me walk.', ar: 'ساعدني أمشي.'}, emoji: '🚶', order: 0),
    HelpRequest(id: 'help_sit', phrase: {en: 'Help me sit down.', ar: 'ساعدني أقعد.'}, emoji: '🪑', order: 1),
    HelpRequest(id: 'help_bed', phrase: {en: 'Help me get into bed.', ar: 'ساعدني أنام بالسرير.'}, emoji: '🛏️', order: 2),
    HelpRequest(id: 'help_bathroom', phrase: {en: 'Help me to the bathroom.', ar: 'ساعدني عالحمّام.'}, emoji: '🚿', order: 3),
    HelpRequest(id: 'help_cook', phrase: {en: 'Help me cook.', ar: 'ساعدني أطبخ.'}, emoji: '🍳', order: 4),
    HelpRequest(id: 'help_medicine', phrase: {en: 'Help me with my medicine.', ar: 'ساعدني بالدوا.'}, emoji: '💊', order: 5),
  ];

  return HouseholdConfig(
    householdName: 'Home',
    elderLang: ar,
    caregiverLang: en,
    languages: languages,
    situations: situations,
    objects: objects,
    actions: actions,
    locations: locations,
    commonRequests: commonRequests,
    routines: routines,
    helpRequests: helpRequests,
  );
}
