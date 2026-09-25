import 'dart:math';

/// Packs de mots séparés de la logique de partie.
class WordService {
  static const supportedLocales = <String>['fr', 'ln'];
  static const supportedThemes = <String>['mix', 'kin', 'animaux', 'objets', 'community'];

  static final Map<String, Map<String, List<String>>> _packs = {
    'fr': {
      'animaux': ['CANARD', 'LICORNE', 'DINOSAURE', 'MARMOTTE', 'LAMA', 'PENGUIN', 'PIEUVRE'],
      'objets': ['BANANE', 'PATATE', 'PIZZA', 'CACTUS', 'CHAUSSETTE', 'LUNETTES DE SOLEIL', 'AVION DE PAPIER'],
      'kin': ['MARCHÉ', 'TAXI JAUNE', 'SAPO', 'RUMBA', 'FOUFOU', 'MALWA', 'PARCELLE'],
    },
    'ln': {
      'animaux': ['MBWA', 'NTABA', 'NGANDO', 'NDOKI'],
      'objets': ['MOTO', 'MBONGO', 'BALLE', 'LIBANGA'],
      'kin': ['TAXI JAUNE', 'MARCHÉ', 'SAPO', 'RUMBA', 'MALWA', 'PARCELLE'],
    },
  };

  static String getRandomWord({String locale = 'fr', String theme = 'mix'}) {
    final languagePack = _packs[locale] ?? _packs['fr']!;
    final words = theme == 'mix'
        ? languagePack.values.expand((pack) => pack).toList()
        : (languagePack[theme] ?? languagePack['kin'] ?? languagePack.values.first);
    return words[Random().nextInt(words.length)].toUpperCase();
  }
}
