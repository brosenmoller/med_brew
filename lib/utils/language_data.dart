class Lang {
  final String code;
  final String name;
  const Lang(this.code, this.name);
  String get display => '$name ($code)';
}

const kLanguages = <Lang>[
  Lang('af', 'Afrikaans'),
  Lang('ar', 'Arabic'),
  Lang('bg', 'Bulgarian'),
  Lang('bn', 'Bengali'),
  Lang('cs', 'Czech'),
  Lang('da', 'Danish'),
  Lang('de', 'German'),
  Lang('el', 'Greek'),
  Lang('en', 'English'),
  Lang('es', 'Spanish'),
  Lang('et', 'Estonian'),
  Lang('fa', 'Persian'),
  Lang('fi', 'Finnish'),
  Lang('fr', 'French'),
  Lang('he', 'Hebrew'),
  Lang('hi', 'Hindi'),
  Lang('hr', 'Croatian'),
  Lang('hu', 'Hungarian'),
  Lang('id', 'Indonesian'),
  Lang('it', 'Italian'),
  Lang('ja', 'Japanese'),
  Lang('ko', 'Korean'),
  Lang('lt', 'Lithuanian'),
  Lang('lv', 'Latvian'),
  Lang('ms', 'Malay'),
  Lang('nl', 'Dutch'),
  Lang('no', 'Norwegian'),
  Lang('pl', 'Polish'),
  Lang('pt', 'Portuguese'),
  Lang('ro', 'Romanian'),
  Lang('ru', 'Russian'),
  Lang('sk', 'Slovak'),
  Lang('sl', 'Slovenian'),
  Lang('sr', 'Serbian'),
  Lang('sv', 'Swedish'),
  Lang('sw', 'Swahili'),
  Lang('th', 'Thai'),
  Lang('tr', 'Turkish'),
  Lang('uk', 'Ukrainian'),
  Lang('ur', 'Urdu'),
  Lang('vi', 'Vietnamese'),
  Lang('zh', 'Chinese'),
];

String codeToDisplay(String? code) {
  if (code == null || code.isEmpty) return '';
  return kLanguages.where((l) => l.code == code).firstOrNull?.display ?? code;
}

String? displayToCode(String text) {
  final t = text.trim();
  if (t.isEmpty) return null;
  return kLanguages
          .where((l) =>
              l.display.toLowerCase() == t.toLowerCase() ||
              l.name.toLowerCase() == t.toLowerCase() ||
              l.code.toLowerCase() == t.toLowerCase())
          .firstOrNull
          ?.code ??
      t;
}
