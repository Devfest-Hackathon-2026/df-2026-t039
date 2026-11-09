import 'package:flutter/material.dart';

import '../services/service_locator.dart';
import '../services/repositories/messages_repository.dart';
import '../widgets/trip_details.dart';
import 'home_page.dart';

class _ChatMessage {
  _ChatMessage({required this.role, required this.text, this.places = const []});

  final String role;
  final String text;
  final List<Map<String, dynamic>> places;

  bool get isUser => role == 'user';
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, this.tripId, this.title});

  final String? tripId;
  final String? title;
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final List<_ChatMessage> _messages = [];
  String? _tripId;
  Map<String, dynamic>? _trip;
  bool _accepting = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _loadingHistory = false;
  bool _sending = false;
  String? _retryText;
  String? _retryId;

  @override
  void initState() {
    super.initState();
    _tripId = widget.tripId;
    if (_tripId != null) {
      _loadHistory();
      _loadTrip();
    }
  }

  Future<void> _loadTrip() async {
    try {
      final data = await ServiceLocator.tripRepository.getTrip(
        _tripId!,
        forceRefresh: true,
      );
      if (!mounted) return;
      setState(() => _trip = data['trip'] as Map<String, dynamic>?);
    } catch (e) {
      _showError('旅程の読み込みに失敗しました: $e');
    }
  }

  Future<void> _acceptItinerary() async {
    final tripId = _tripId;
    if (tripId == null || _accepting) return;
    setState(() => _accepting = true);
    try {
      final data = await ServiceLocator.tripRepository.updateTrip(tripId, {
        'status': 'planned',
      });
      if (!mounted) return;
      setState(() => _trip = data['trip'] as Map<String, dynamic>?);
      HomePage.refreshSignal.value++;
      _scaffoldKey.currentState?.closeEndDrawer();
      _showError('旅程を確定しました');
    } catch (e) {
      _showError('更新に失敗しました: $e');
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  Widget _buildItineraryDrawer() {
    final trip = _trip;
    final hasItinerary =
        trip != null && ((trip['itinerary'] as List?)?.isNotEmpty ?? false);
    final isPlanned = trip?['status'] == 'planned';

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.92,
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              title: const Text(
                '現在の旅程',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => _scaffoldKey.currentState?.closeEndDrawer(),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: hasItinerary
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(8),
                      child: TripDetails(trip: trip),
                    )
                  : const Center(child: Text('まだ旅程がありません')),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: hasItinerary && !isPlanned && !_accepting
                      ? _acceptItinerary
                      : null,
                  icon: _accepting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(isPlanned ? '確定済み' : 'この旅程で確定する'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final data = await ServiceLocator.messagesRepository.listMessages(
        _tripId!,
      );
      final list = (data['messages'] as List?) ?? const [];
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(
            list.map(
              (m) => _ChatMessage(
                role: m['role'] as String,
                text: m['text'] as String,
              ),
            ),
          );
      });
    } catch (e) {
      _showError('履歴の読み込みに失敗しました: $e');
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  /// Reuses an existing empty draft instead of piling up new ones.
  Future<String> _resolveTripId() async {
    final existing = _tripId;
    if (existing != null) return existing;

    final trips = ServiceLocator.tripRepository;
    final drafts = await trips.listTrips(status: 'draft', forceRefresh: true);
    for (final draft in (drafts['trips'] as List?) ?? const []) {
      final id = draft['id'].toString();
      final history = await ServiceLocator.messagesRepository.listMessages(id);
      if (((history['messages'] as List?) ?? const []).isEmpty) {
        return _tripId = id;
      }
    }
    final created = await trips.createTrip({});
    return _tripId = created['trip']['id'].toString();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _sending) return;

    final clientId = _retryText == message
        ? _retryId!
        : MessagesRepository.newClientMessageId();

    setState(() {
      _sending = true;
      _messages.add(_ChatMessage(role: 'user', text: message));
      _messageController.clear();
    });

    try {
      final tripId = await _resolveTripId();
      final response = await ServiceLocator.messagesRepository.sendMessage(
        tripId,
        message,
        clientMessageId: clientId,
      );
      final reply = response['message'] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _trip = response['trip'] as Map<String, dynamic>?;
        _retryText = null;
        _retryId = null;
        _messages.add(
          _ChatMessage(
            role: 'assistant',
            text: reply['text'] as String,
            places: ((response['suggested_places'] as List?) ?? const [])
                .cast<Map<String, dynamic>>(),
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _retryText = message;
        _retryId = clientId;
        _messages.removeLast();
        _messageController.text = message;
      });
      _showError('送信に失敗しました: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Suggested places come without an address; fill it in from a search match.
  Future<void> _fillLocation(Map<String, dynamic> place) async {
    final googleId = place['google_place_id'];
    final location = place['location']?.toString() ?? '';
    if (googleId == null || location.isNotEmpty) return;
    try {
      final data = await ServiceLocator.placesRepository.searchPlaces(
        q: place['name'].toString(),
      );
      final found = ((data['places'] as List?) ?? const []).firstWhere(
        (p) => p['google_place_id'] == googleId,
        orElse: () => null,
      );
      if (found == null) return;
      await ServiceLocator.placesRepository.createPlace(
        googlePlaceId: googleId.toString(),
        name: place['name'].toString(),
        location: found['location']?.toString() ?? '',
        latitude: (found['latitude'] as num?)?.toDouble(),
        longitude: (found['longitude'] as num?)?.toDouble(),
      );
    } catch (_) {
      // Saving still works without the address.
    }
  }

  Future<void> _savePlace(Map<String, dynamic> place) async {
    if (place['is_saved'] == true) {
      _showError('すでに保存済みです');
      return;
    }
    try {
      await _fillLocation(place);
      await ServiceLocator.savedPlacesRepository.createSavedPlace({
        'place_id': place['id'],
      });
      if (!mounted) return;
      setState(() => place['is_saved'] = true);
      _showError('保存しました');
    } catch (e) {
      _showError('保存に失敗しました: $e');
    }
  }

  void _showError(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FB),
      endDrawer: _buildItineraryDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FB),
        title: Text(
          widget.title ?? 'Travel assistant',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: '現在の旅程',
            icon: const Icon(Icons.map_outlined),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: colors.primaryContainer,
                            child: Icon(
                              Icons.auto_awesome,
                              color: colors.onPrimaryContainer,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Plan your next trip',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ask about destinations, activities, or travel plans.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[_messages.length - 1 - index];
                      return Align(
                        alignment: message.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.only(
                            bottom: 12,
                            left: message.isUser ? 48 : 0,
                            right: message.isUser ? 0 : 48,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: message.isUser
                                ? Colors.transparent
                                : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.text,
                                style: TextStyle(
                                  color: colors.onPrimaryContainer,
                                  fontSize: 14,
                                ),
                              ),
                              if (message.places.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      for (final place in message.places)
                                        ActionChip(
                                          avatar: Icon(
                                            place['is_saved'] == true
                                                ? Icons.favorite
                                                : Icons.place,
                                            size: 16,
                                            color: place['is_saved'] == true
                                                ? Colors.red
                                                : null,
                                          ),
                                          label: Text('${place['name']}'),
                                          onPressed: () => _savePlace(place),
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_loadingHistory || _sending)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(_sending ? '考え中...' : '読み込み中...'),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !_sending,
                      onChanged: (_) => setState(() {}),
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Ask about your trip...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _messageController.text.trim().isEmpty || _sending
                        ? null
                        : _sendMessage,
                    tooltip: 'Send message',
                    icon: const Icon(Icons.arrow_upward),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
