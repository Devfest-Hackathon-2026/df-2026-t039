import 'package:flutter/material.dart';
import 'package:flutter_ui_travelling/services/service_locator.dart';

class SavedPlacesPage extends StatefulWidget {
  const SavedPlacesPage({super.key});

  @override
  State<SavedPlacesPage> createState() => _SavedPlacesPageState();
}

class _SavedPlacesPageState extends State<SavedPlacesPage> {
  late Future<dynamic> _savedPlaces;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _savedPlaces = ServiceLocator.savedPlacesRepository.listSavedPlaces();
  }

  Future<void> _confirmDelete(Map<String, dynamic> place) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('保存した場所の削除'),
        content: const Text('この保存した場所を削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('削除する'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted || _isDeleting) return;

    final placeId = place['id']?.toString();
    if (placeId == null || placeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('場所を削除できませんでした。IDが見つかりません。')),
      );
      return;
    }

    setState(() => _isDeleting = true);
    try {
      await ServiceLocator.savedPlacesRepository.deleteSavedPlace(placeId);
      if (!mounted) return;
      setState(() {
        _savedPlaces = ServiceLocator.savedPlacesRepository.listSavedPlaces();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存した場所を削除しました。')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('場所を削除できませんでした: $error')),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved places')),
      body: FutureBuilder(
        future: _savedPlaces,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading trips: ${snapshot.error}'));
          }

          final savedPlaces = snapshot.data['places'];

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _SavedPlacesSection(
                title: '保存した場所',
                emptyMessage: '保存した場所はありません.',
                savedPlaces: savedPlaces,
                onPlaceTap: _confirmDelete,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SavedPlacesSection extends StatelessWidget {
  const _SavedPlacesSection({
    required this.title,
    required this.emptyMessage,
    required this.savedPlaces,
    required this.onPlaceTap,
  });

  final String title;
  final String emptyMessage;
  final List<dynamic> savedPlaces;
  final ValueChanged<Map<String, dynamic>> onPlaceTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (savedPlaces.isEmpty)
          Text(emptyMessage)
        else
          for (final place in savedPlaces)
            Card(
              child: ListTile(
                title: Text('${place['name']} '),
                subtitle: Text('${place['location']}'),
                trailing: const Icon(Icons.favorite),
                onTap: () => onPlaceTap(Map<String, dynamic>.from(place as Map)),
              ),
            ),
      ],
    );
  }
}
