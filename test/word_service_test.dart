import 'package:flutter_test/flutter_test.dart';
import 'package:kroki/data/services/word_service.dart';
import 'package:kroki/data/services/weekly_challenge_service.dart';
import 'package:kroki/data/services/season_service.dart';

void main() {
  group('WordService', () {
    test('retourne un mot du pack Kinshasa', () {
      final word = WordService.getRandomWord(locale: 'fr', theme: 'kin');
      expect(word, isNotEmpty);
      expect(word, isNot(contains('null')));
    });

    test('retourne un mot du pack Lingala', () {
      final word = WordService.getRandomWord(locale: 'ln', theme: 'lingala');
      expect(word, isNotEmpty);
      expect(word.toUpperCase(), equals(word));
    });

    test('retombe sur le français pour une langue inconnue', () {
      expect(WordService.getRandomWord(locale: 'xx', theme: 'mix'), isNotEmpty);
    });
  });

  group('WeeklyChallengeService', () {
    test('calcule le défi hebdomadaire courant sans erreur', () {
      final service = WeeklyChallengeService();
      final challenge = service.current;
      expect(challenge.title, isNotEmpty);
      expect(challenge.target, greaterThan(0));
    });
  });

  group('SeasonService', () {
    test('génère un identifiant de saison valide', () {
      final service = SeasonService();
      expect(service.currentSeasonId, matches(r'^\d{4}-S[1-4]$'));
    });
  });
}
