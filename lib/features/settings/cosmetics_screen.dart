import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/service_providers.dart';
import '../../data/models/cosmetic.dart';

class CosmeticsScreen extends ConsumerStatefulWidget {
  const CosmeticsScreen({super.key});

  @override
  ConsumerState<CosmeticsScreen> createState() => _CosmeticsScreenState();
}

class _CosmeticsScreenState extends ConsumerState<CosmeticsScreen> {
  final _selected = <CosmeticType, String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    for (final type in CosmeticType.values) {
      _selected[type] = await ref.read(cosmeticServiceProvider).selectedId(type);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('COSMÉTIQUES')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Personnalise ton style', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Ces éléments sont purement visuels et ne changent pas le gameplay.', style: TextStyle(color: Colors.white.withOpacity(0.65))),
          const SizedBox(height: 20),
          for (final type in CosmeticType.values) ...[
            Text(_label(type), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...CosmeticCatalog.items.where((item) => item.type == type).map(_tile),
            const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }

  String _label(CosmeticType type) => switch (type) {
        CosmeticType.brush => 'Pinceaux',
        CosmeticType.color => 'Couleurs',
        CosmeticType.avatar => 'Avatars',
      };

  Widget _tile(Cosmetic item) {
    final active = _selected[item.type] == item.id;
    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Color(item.color)),
        title: Text(item.name),
        trailing: active ? const Icon(Icons.check_circle, color: Colors.greenAccent) : null,
        onTap: () async {
          await ref.read(cosmeticServiceProvider).select(item);
          if (mounted) setState(() => _selected[item.type] = item.id);
        },
      ),
    );
  }
}
