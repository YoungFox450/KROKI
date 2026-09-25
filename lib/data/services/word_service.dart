import 'dart:math';

/// Packs de mots localisés pour KROKI (Français, Lingala, Argot Kinois, Thèmes culturel).
class WordService {
  static const supportedLocales = <String>['fr', 'ln'];
  static const supportedThemes = <String>['mix', 'kin', 'lingala', 'animaux', 'objets', 'musique', 'community'];

  static final Map<String, Map<String, List<String>>> _packs = {
    'fr': {
      'kin': [
        'TAXI JAUNE', 'FLEUVE CONGO', 'TOUR ECHANGEUR', 'SAPE', 'FOUFOU', 'PONDU',
        'BEIGNET MIKATE', 'BISSAP', 'PARCELLE', 'MARCHE ZANDO', 'RUMBA', 'MATANGA',
        'NGANDA', 'LIBANGA', 'CHIKWANGUE', 'CHAGUE', 'LIBOKE', 'MALWA', 'KETING',
      ],
      'animaux': [
        'OKAPI', 'GORILLE', 'ELEPHANT', 'HIPPOPOTAME', 'LEOPARD', 'CROCODILE',
        'CHIMPANZE', 'LION', 'SERPENT', 'AIGLE', 'LICORNE', 'DINOSAURE', 'PIEUVRE',
      ],
      'objets': [
        'TAMBOUR', 'LIKEMBE', 'MARMITE', 'PANIER', 'SAPATU', 'LAMPION',
        'BALAI', 'AVION', 'RADIO', 'TELEPHONE', 'MOTO', 'LUNETTES', 'PIZZA',
      ],
      'musique': [
        'GUITARE', 'RUMBA', 'CONGA', 'TAMBOUR', 'LIKEMBE', 'MICRO',
        'SAXOPHONE', 'CHANTEUR', 'DANSEUR', 'DISQUE', 'CASSETTE',
      ],
    },
    'ln': {
      'lingala': [
        'MBWA', 'NTABA', 'NGANDO', 'NDOKI', 'LISO', 'MOTO', 'MBOKA',
        'LIBANGA', 'LOKOLE', 'MPANGI', 'KOKO', 'BOLINGO', 'ELENGI', 'LISAPO',
        'NZAMBE', 'SAKASAKA', 'MAKAYABO', 'LIBOKE', 'NZOTO', 'MWASI', 'MOBALI',
      ],
      'kin': [
        'TAXI JAUNE', 'MARCHE', 'SAPO', 'RUMBA', 'MALWA', 'PARCELLE',
        'FOUFOU', 'PONDU', 'MIKATE', 'CHIKWANGUE', 'BISSAP', 'NGANDA',
      ],
      'animaux': [
        'MBWA', 'NTABA', 'NGANDO', 'NDOKI', 'NYOKA', 'NDEKE', 'NYAMA',
      ],
      'objets': [
        'MOTO', 'MBONGO', 'BALLE', 'LIBANGA', 'SAPATU', 'KITI', 'TETI',
      ],
    },
  };

  static String getRandomWord({String locale = 'fr', String theme = 'mix'}) {
    final languagePack = _packs[locale] ?? _packs['fr']!;
    final List<String> words;

    if (theme == 'mix') {
      words = languagePack.values.expand((pack) => pack).toList();
    } else {
      words = languagePack[theme] ?? languagePack['kin'] ?? languagePack.values.first;
    }

    if (words.isEmpty) return 'KROKI';
    return words[Random().nextInt(words.length)].toUpperCase();
  }
}
