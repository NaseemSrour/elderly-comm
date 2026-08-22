/// The few fixed UI strings the elder actually sees (questions, nav labels).
/// Content strings live in the household config; these are chrome, kept tiny
/// and shown in the elder's own language. Every one is paired with an emoji in
/// the UI so text is never the only signal.
class UiStrings {
  final String back;
  final String home;
  final String whatDoYouWant;
  final String where;
  final String howMany;
  final String commonRequests;
  final String help;
  final String repeat;
  final String pleaseLook;
  final bool rtl;

  const UiStrings({
    required this.back,
    required this.home,
    required this.whatDoYouWant,
    required this.where,
    required this.howMany,
    required this.commonRequests,
    required this.help,
    required this.repeat,
    required this.pleaseLook,
    required this.rtl,
  });

  static const _en = UiStrings(
    back: 'Back',
    home: 'Home',
    whatDoYouWant: 'What do you want?',
    where: 'Where?',
    howMany: 'How many?',
    commonRequests: 'I need…',
    help: 'Help',
    repeat: 'Repeat',
    pleaseLook: 'Please look at this.',
    rtl: false,
  );

  static const _ar = UiStrings(
    back: 'رجوع',
    home: 'البيت',
    whatDoYouWant: 'شو بدك؟',
    where: 'وين؟',
    howMany: 'كم واحد؟',
    commonRequests: 'بدي…',
    help: 'مساعدة',
    repeat: 'كرّر',
    pleaseLook: 'تفضّل شوف.',
    rtl: true,
  );

  static const Map<String, UiStrings> _byLang = {'en': _en, 'ar': _ar};

  static UiStrings of(String lang) => _byLang[lang] ?? _en;
}
