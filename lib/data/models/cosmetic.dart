enum CosmeticType { brush, color, avatar }

class Cosmetic {
  final String id;
  final String name;
  final CosmeticType type;
  final int color;

  const Cosmetic({required this.id, required this.name, required this.type, this.color = 0xFFFFFFFF});
}

class CosmeticCatalog {
  static const items = <Cosmetic>[
    Cosmetic(id: 'brush_basic', name: 'Classique', type: CosmeticType.brush),
    Cosmetic(id: 'brush_neon', name: 'Néon', type: CosmeticType.brush),
    Cosmetic(id: 'color_cyan', name: 'Cyan', type: CosmeticType.color, color: 0xFF00BCD4),
    Cosmetic(id: 'color_amber', name: 'Ambre', type: CosmeticType.color, color: 0xFFFFB300),
    Cosmetic(id: 'avatar_kintambo', name: 'Kintambo', type: CosmeticType.avatar),
  ];
}
