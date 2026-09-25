class DrawingPoint {
  final double x;
  final double y;

  DrawingPoint({required this.x, required this.y});

  Map<String, double> toMap() => {'x': x, 'y': y};

  factory DrawingPoint.fromMap(Map<String, dynamic> map) {
    return DrawingPoint(
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
    );
  }
}

class DrawingStroke {
  final String? id;
  final List<DrawingPoint> points;
  final int colorHex;
  final double strokeWidth;
  final bool isEraser;

  DrawingStroke({
    this.id,
    required this.points,
    this.colorHex = 0xFFFFFFFF, // Blanc par défaut
    this.strokeWidth = 4.0,
    this.isEraser = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'points': points.map((p) => p.toMap()).toList(),
      'color': colorHex,
      'width': strokeWidth,
      'eraser': isEraser,
    };
  }

  factory DrawingStroke.fromMap(Map<String, dynamic> map, {String? id}) {
    var pointsList = (map['points'] as List? ?? [])
        .map((p) => DrawingPoint.fromMap(Map<String, dynamic>.from(p)))
        .toList();

    return DrawingStroke(
      id: id,
      points: pointsList,
      colorHex: map['color'] ?? 0xFFFFFFFF,
      strokeWidth: (map['width'] as num? ?? 4.0).toDouble(),
      isEraser: map['eraser'] == true,
    );
  }
}
