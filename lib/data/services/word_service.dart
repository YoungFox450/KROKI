import 'dart:math';

class WordService {
  static final List<String> _words = [
    // Animaux & Personnages marrants
    'CANARD EN PLASTIQUE',
    'LICORNE',
    'DINOSAURE',
    'MARMOTTE',
    'LAMA',
    'ZOMBIE',
    'VAMPIRE',
    'FANTÔME',
    'EXTRATERRESTRE',
    'NINJA',
    'PENGOUIN',
    'PIEUVRE',
    'POUSSIN',
    'PIRATE',

    // Nourriture & Objets simples/rigolos
    'BANANE',
    'PATATE',
    'PIZZA',
    'DONUT',
    'POPCORN',
    'TACO',
    'SAUCISSE',
    'ANANAS',
    'CACTUS',
    'SLIP',
    'CHAUSSETTE TROUÉE',
    'CROTTE',
    'GLACE AU CHOCOLAT',
    'CHAMPIGNON',

    // Éléments du quotidien & Symboles faciles
    'SUPER HÉROS',
    'ROBOT',
    'SQUELETTE',
    'VOLCAN',
    'AVION DE PAPIER',
    'CHAPEAU MAGIQUE',
    'LUNETTES DE SOLEIL',
    'DENT',
    'AMPOULE',
    'SOLEIL AVEC LUNETTES',
  ];

  static String getRandomWord() {
    final random = Random();
    return _words[random.nextInt(_words.length)];
  }
}
