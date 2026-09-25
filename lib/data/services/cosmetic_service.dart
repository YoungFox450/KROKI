import 'package:shared_preferences/shared_preferences.dart';
import '../models/cosmetic.dart';

class CosmeticService {
  Future<String> selectedId(CosmeticType type) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('cosmetic_${type.name}') ?? CosmeticCatalog.items.firstWhere((item) => item.type == type).id;
  }

  Future<void> select(Cosmetic cosmetic) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cosmetic_${cosmetic.type.name}', cosmetic.id);
  }
}
