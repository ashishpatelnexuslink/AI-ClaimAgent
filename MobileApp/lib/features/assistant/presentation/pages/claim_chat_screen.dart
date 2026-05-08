import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:claim_ai/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:claim_ai/core/navigation/app_routes.dart';
import 'package:claim_ai/core/storage/chat_transcript_writer.dart';
import 'package:claim_ai/services/chat_service.dart';
import 'package:claim_ai/features/assistant/presentation/widgets/sample_images_dialog.dart';
import 'package:claim_ai/features/claims/data/datasources/claims_remote_datasource.dart';
import 'package:claim_ai/injection_container.dart' as di;

const _kDark = Color(0xFF1A1D3B);
const _kBlue = Color(0xFF2A6FDB);
const _kBg = Color(0xFFF0F2F7);
const _kUserInitialsBg = Color(0xFFE8E4FF);
const _kUserInitialsText = Color(0xFF6C5CE7);

class ClaimChatScreen extends StatefulWidget {
  /// Optional seed messages carried over from voice mode.
  /// Each map must have keys `text` (String) and `isUser` (bool).
  final List<Map<String, dynamic>>? initialMessages;

  const ClaimChatScreen({super.key, this.initialMessages});

  @override
  State<ClaimChatScreen> createState() => _ClaimChatScreenState();
}

class _ClaimChatScreenState extends State<ClaimChatScreen> {
  final _controller = TextEditingController();
  final _locationController = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocusNode = FocusNode();
  final _imagePicker = ImagePicker();
  final List<_ChatMsg> _messages = [];
  final List<_ChatMsg> _pendingBotMessages = [];
  bool _isAnimating = false;
  bool _botTyping = false;
  bool _fetchingLocation = false;
  bool _uploadingFiles = false;
  late final String _threadId;
  String? _submittedClaimId;
  // True once the claim/docs/conversation have been persisted server-side.
  // Set when the bot streams a `save_summary` message; the Close button uses
  // this to skip its own save and only write the local transcript file.
  bool _savedOnSummary = false;
  // Tracks the in-flight auto-save so the Close button can await it before
  // deciding whether to run a fallback save (prevents a duplicate claim if
  // the user taps Close while auto-save is still uploading).
  Future<void>? _autoSaveFuture;
  // Tracks docs uploaded during this chat thread, paired with the category
  // they were uploaded under. Category is needed so re-uploads for the same
  // AI prompt (e.g. a second batch of damage photos) can wipe the prior batch.
  final List<({String id, String category})> _uploadedDocumentIds = [];

  // Per-GET_DOCUMENT-trigger upload progress. Lets the user satisfy `min_count`
  // across multiple separate uploads instead of picking everything at once.
  // Keyed by the bot message that owns the trigger; cleared after the bot
  // advances. Holds a running count plus the names/paths to use for the final
  // cumulative user bubble.
  final Map<_ChatMsg, _DocTriggerProgress> _docTriggerProgress = {};

  // Per-(category, angle) thumbnail of the most recently uploaded image, used
  // by the final-summary card to render uploaded photos inline. Documents go
  // under angle == "" so the same map covers both flows.
  final Map<String, _UploadedAsset> _uploadedAssetsByKey = {};

  final List<DateTime> _messageTimestamps = [];
  final ChatTranscriptWriter _transcriptWriter = di.sl<ChatTranscriptWriter>();

  // GET_DATE_TIME inline picker state.
  DateTime? _dtDate;
  TimeOfDay? _dtTime;

  // GET_IMAGE state.
  // Legacy single-bucket flow (no `allowed_angles` in payload).
  final List<File> _pickedImages = [];
  final int _maxImages = 4;
  // Dynamic per-angle flow driven by `payload.allowed_angles` — keyed by
  // angle name (e.g. "front_left"). Cleared after each successful submit.
  final Map<String, File> _angleImages = {};
  // For each angle that `/validate-images` flagged as invalid, the path of
  // the image at the time of failure. Used to decide whether the user has
  // since picked a different image (enabling re-submit). Cleared on a
  // successful validate + upload pass.
  final Map<String, String> _failedAnglePaths = {};
  // group_keys that have already validated + uploaded successfully in this
  // thread. Used to disable Submit on any older failure card whose group is
  // done so the user can't accidentally re-validate an already-stored group.
  final Set<String> _uploadedGroupKeys = {};

  // GET_DOCUMENT state.
  final List<PlatformFile> _pickedDocuments = [];
  final int _maxDocuments = 10;
  final List<String> _allowedDocExtensions = const [
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'doc',
    'docx',
  ];

  @override
  void initState() {
    super.initState();
    _threadId = const Uuid().v4();

    if (widget.initialMessages != null && widget.initialMessages!.isNotEmpty) {
      // Seed with messages carried over from voice mode
      for (final m in widget.initialMessages!) {
        _messages.add(
          _ChatMsg(text: m['text'] as String, isUser: m['isUser'] as bool),
        );
      }
    } else {
      // Fetch a real greeting from the API
      _initGreeting();
    }
  }

  /// Send a silent "hello" to the streaming API and show the response as greeting.
  Future<void> _initGreeting() async {
    setState(() => _botTyping = true);
    await _streamBotReply('hello');
  }

  /// Composite key for `_uploadedAssetsByKey`. Empty-string angle covers the
  /// document flow (no per-angle dimension).
  String _assetKey(String category, String angle) => '$category::$angle';

  void _recordUploadedAsset({
    required String category,
    required String angle,
    required String kind,
    required String? id,
    required String? localPath,
  }) {
    _uploadedAssetsByKey[_assetKey(category, angle)] = _UploadedAsset(
      id: id,
      localPath: localPath,
      kind: kind,
    );
  }

  void _clearUploadedAssetsForCategory(String category) {
    _uploadedAssetsByKey.removeWhere((k, _) => k.startsWith('$category::'));
  }

  @override
  void dispose() {
    _controller.dispose();
    _locationController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || _botTyping) return;

    setState(() {
      _messages.add(_ChatMsg(text: text, isUser: true));
      _botTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    _streamBotReply(text);
  }

  /// Streams bot response from `/chat/stream`.
  /// Each message in the SSE payload becomes its own bubble.
  Future<void> _streamBotReply(String userMessage) async {
    // `AUTO_GET_LOCATION` is delivered mid-stream; defer the actual fetch
    // until after the stream finishes so the location reply doesn't race
    // with remaining queued bot messages.
    bool autoFetchLocation = false;
    try {
      await for (final msg in ChatService.sendMessage(
        userMessage,
        threadId: _threadId,
      )) {
        if (!mounted) return;
        _pendingBotMessages.add(
          _ChatMsg(
            text: msg.content,
            isUser: false,
            animate: true,
            messageType: msg.messageType,
            suggestions: msg.suggestions,
            triggers: msg.triggers,
            claimData: msg.claimData,
            payloadType: msg.payloadType,
            payload: msg.payload,
          ),
        );
        // Bot has streamed the final summary — fire-and-forget the save
        // (claim row + doc attach + conversation transcript) right away so
        // the Close button only has to write the local transcript file.
        if (msg.payloadType == 'save_summary') {
          _triggerAutoSaveOnSummary(msg.payload, msg.content);
        }
        if (msg.triggers.contains('AUTO_GET_LOCATION')) {
          autoFetchLocation = true;
        }
      }
    } catch (_) {
      if (!mounted) return;
      _pendingBotMessages.add(
        const _ChatMsg(
          text: 'Sorry, something went wrong. Please try again.',
          isUser: false,
        ),
      );
    }
    if (!mounted) return;
    _showNextPendingMessage();

    if (autoFetchLocation) {
      unawaited(_onUseCurrentLocation(auto: true));
    }
  }

  /// Shows the next queued bot message and animates it.
  /// Called again via [_TypewriterText.onComplete] when animation finishes.
  void _showNextPendingMessage() {
    if (!mounted) return;

    // Mark the last animated message as done so it can render as a card
    _clearLastAnimation();

    if (_pendingBotMessages.isEmpty) {
      setState(() {
        _isAnimating = false;
        _botTyping = false;
      });
      _scrollToBottom();
      _persistTranscript();
      return;
    }
    final next = _pendingBotMessages.removeAt(0);
    setState(() {
      _isAnimating = true;
      _messages.add(next);
    });
    _scrollToBottom();
    _persistTranscript();
  }

  /// Writes the current chat to `<app docs>/chat_transcripts/<threadId>.json`.
  /// Fire-and-forget; masks vehicle / VIN / policy identifiers before writing.
  void _persistTranscript() {
    final now = DateTime.now();
    while (_messageTimestamps.length < _messages.length) {
      _messageTimestamps.add(now);
    }
    final snapshot = <TranscriptMessage>[
      for (var i = 0; i < _messages.length; i++)
        TranscriptMessage(
          role: _messages[i].isUser ? 'user' : 'bot',
          text: _messages[i].text,
          timestamp: _messageTimestamps[i],
          messageType: _messages[i].messageType,
          triggers: _messages[i].triggers,
          claimData: _messages[i].claimData,
        ),
    ];
    unawaited(_writeTranscriptSilently(snapshot));
  }

  Future<void> _writeTranscriptSilently(
    List<TranscriptMessage> snapshot,
  ) async {
    try {
      await _transcriptWriter.writeTranscript(
        threadId: _threadId,
        claimId: _submittedClaimId,
        messages: snapshot,
      );
    } catch (_) {
      // A disk hiccup shouldn't break the chat.
    }
  }

  /// Replace the last animated message with animate=false so structured
  /// widgets (like policy card) can render instead of plain markdown.
  void _clearLastAnimation() {
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].animate && !_messages[i].isUser) {
        _messages[i] = _ChatMsg(
          text: _messages[i].text,
          isUser: false,
          animate: false,
          messageType: _messages[i].messageType,
          suggestions: _messages[i].suggestions,
          triggers: _messages[i].triggers,
          claimData: _messages[i].claimData,
          payloadType: _messages[i].payloadType,
          payload: _messages[i].payload,
        );
        break;
      }
    }
  }

  /// Handle suggestion chip tap — send it as a user message.
  void _onSuggestionTap(String suggestion) {
    if (_botTyping) return;
    setState(() {
      _messages.add(_ChatMsg(text: suggestion, isUser: true));
      _botTyping = true;
    });
    _scrollToBottom();
    _streamBotReply(suggestion);
  }

  /// GET_DATE_TIME — inline picker handlers.
  Future<void> _pickIncidentDate() async {
    if (_botTyping) return;
    _inputFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final initial = _dtDate ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _kBlue)),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    setState(() => _dtDate = date);
  }

  Future<void> _pickIncidentTime() async {
    if (_botTyping) return;
    _inputFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    final initial = _dtTime ?? TimeOfDay.fromDateTime(DateTime.now());
    final time = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _kBlue)),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;
    setState(() => _dtTime = time);
  }

  void _confirmIncidentDateTime() {
    if (_botTyping) return;
    final now = DateTime.now();
    final date = _dtDate ?? now;
    final time = _dtTime ?? TimeOfDay.fromDateTime(now);
    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final formatted = DateFormat('dd MMM yyyy, hh:mm a').format(selected);

    _inputFocusNode.unfocus();

    setState(() {
      _dtDate = null;
      _dtTime = null;
      _messages.add(_ChatMsg(text: formatted, isUser: true));
      _botTyping = true;
    });
    _scrollToBottom();
    _streamBotReply(formatted);
  }

  // ── GET_LOCATION trigger handlers ─────────────────────────────────────

  void _onSubmitLocation() {
    final text = _locationController.text.trim();
    if (text.isEmpty || _botTyping) return;
    _locationController.clear();
    _sendLocationReply(text);
  }

  Future<void> _onUseCurrentLocation({bool auto = false}) async {
    if (_fetchingLocation) return;
    if (!auto && _botTyping) return;
    setState(() => _fetchingLocation = true);

    try {
      // 1. Check if location services (GPS) are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enable location services (GPS) in device settings',
            ),
          ),
        );
        // Send the user to settings, then wait (with a timeout) for the OS
        // to broadcast that location services are now enabled. Without this,
        // `openLocationSettings()` returns immediately and the fetch silently
        // gives up, leaving the chat stuck on "Fetching your current
        // location…".
        await Geolocator.openLocationSettings();
        try {
          await Geolocator.getServiceStatusStream()
              .firstWhere((s) => s == ServiceStatus.enabled)
              .timeout(const Duration(seconds: 60));
        } on TimeoutException {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location services were not enabled. Please try again.',
              ),
            ),
          );
          return;
        }
        if (!mounted) return;
        // Re-check in case the stream emitted but the user toggled off again.
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) return;
      }

      // 2. Check & request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required')),
        );
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission is permanently denied. Please enable it in app settings.',
            ),
          ),
        );
        await Geolocator.openAppSettings();
        return;
      }

      // 3. Get GPS position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      // 4. Reverse geocode to readable address
      String address;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = <String>[
            if (p.subLocality != null && p.subLocality!.isNotEmpty)
              p.subLocality!,
            if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
            if (p.administrativeArea != null &&
                p.administrativeArea!.isNotEmpty)
              p.administrativeArea!,
          ];
          address = parts.isNotEmpty
              ? parts.join(', ')
              : '${position.latitude}, ${position.longitude}';
        } else {
          address = '${position.latitude}, ${position.longitude}';
        }
      } catch (_) {
        // Geocoding failed — fall back to raw coordinates
        address = '${position.latitude}, ${position.longitude}';
      }

      if (!mounted) return;
      _sendLocationReply(address);
    } on LocationServiceDisabledException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled')),
      );
    } on PermissionDeniedException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission was denied')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not get location: $e')));
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  void _sendLocationReply(String location) {
    setState(() {
      _messages.add(_ChatMsg(text: location, isUser: true));
      _botTyping = true;
    });
    _scrollToBottom();
    _streamBotReply(location);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: _kDark,
              ),
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: const AssetImage(
                'assets/images/avatar_assistant.png',
              ),
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(width: 10),
            const Text(
              'Claim Assistant',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _kDark,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount:
                  _messages.length + (_botTyping && !_isAnimating ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _botTyping && !_isAnimating) {
                  return _buildTypingIndicator();
                }
                return _buildBubble(_messages[index]);
              },
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _inputFocusNode,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: _kBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      style: const TextStyle(fontSize: 14, color: _kDark),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _send,
                    icon: const Icon(Icons.send_rounded, color: _kBlue),
                    splashRadius: 24,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Policy detail detection ──────────────────────────────────────────────

  /// Payload types that should render as a table card.
  static const _tablePayloadTypes = {
    'initial_summary',
    'verified_summary',
    'final_summary',
    'save_summary',
  };

  /// Extracts ordered key/value fields from a structured summary payload.
  /// Any message whose `payload_type` is one of [_tablePayloadTypes] is
  /// rendered as a table card, regardless of the `SHOW_TABLE` trigger.
  Map<String, String>? _tableFields(_ChatMsg msg) {
    if (!_tablePayloadTypes.contains(msg.payloadType)) return null;
    final payload = msg.payload;
    if (payload == null || payload.isEmpty) return null;

    final fields = <String, String>{};
    payload.forEach((key, value) {
      if (value == null) return;
      fields[key] = _formatFieldValue(key, value);
    });
    return fields.isEmpty ? null : fields;
  }

  String _cardTitleFor(String? payloadType) {
    switch (payloadType) {
      case 'initial_summary':
        return 'Initial Summary';
      case 'final_summary':
        return 'Claim Summary';
      case 'save_summary':
        return 'Saved Claim Summary';
      case 'verified_summary':
      default:
        return 'Policy Verified';
    }
  }

  String _formatFieldValue(String key, dynamic value) {
    final raw = value.toString().trim();
    if (raw.isEmpty) return '';

    // Format ISO-like dates (e.g. "2026-12-31") to "10 Aug, 2026".
    final iso = RegExp(r'^\d{4}-\d{2}-\d{2}').firstMatch(raw);
    if (iso != null) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        return DateFormat('d MMM, yyyy').format(parsed);
      }
    }
    return raw;
  }

  static final _policyFieldPattern = RegExp(r'\*\*(.+?):\*\*\s*(.+)');

  /// Returns parsed policy fields if the message contains policy details.
  Map<String, String>? _parsePolicyFields(String text) {
    final matches = _policyFieldPattern.allMatches(text).toList();
    if (matches.length < 4) return null;

    final fields = <String, String>{};
    for (final m in matches) {
      fields[m.group(1)!.trim()] = m.group(2)!.trim();
    }

    // Must contain at least Policy Holder + Policy Number to qualify
    final keys = fields.keys.map((k) => k.toLowerCase()).toSet();
    if (!keys.contains('policy holder') && !keys.contains('policyholder')) {
      return null;
    }
    if (!keys.any((k) => k.contains('policy') && k.contains('number'))) {
      return null;
    }
    return fields;
  }

  /// Extracts intro text before the first bold field line.
  String _policyIntroText(String text) {
    final lines = text.split('\n');
    final buffer = StringBuffer();
    for (final line in lines) {
      if (_policyFieldPattern.hasMatch(line)) break;
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) {
        if (buffer.isNotEmpty) buffer.write(' ');
        buffer.write(trimmed);
      }
    }
    return buffer.toString();
  }

  /// Extracts the trailing question text after the last bold field line.
  String _policyTrailingText(String text) {
    final lines = text.split('\n');
    final buffer = StringBuffer();
    bool pastFields = false;
    for (final line in lines.reversed) {
      final trimmed = line.trim();
      if (_policyFieldPattern.hasMatch(line)) {
        pastFields = true;
        break;
      }
      if (trimmed.isNotEmpty) {
        buffer.write(trimmed);
      }
    }
    return pastFields ? buffer.toString() : '';
  }

  // ─── Review Your Claim card (payload_type == "final_summary") ───────────
  /// Lowercased keys that should appear under the INCIDENT DETAILS section.
  static const _incidentKeys = {
    'incident date',
    'incident time',
    'incident location',
    'incident description',
    'damage details',
    'date',
    'time',
    'location',
    'description',
  };

  /// Lowercased keys that should appear under the DOCUMENTS section.
  static const _documentKeys = {
    'vehicle photos',
    'damage photos',
    'driver license',
    'driving license',
    'license photos',
    'supporting docs',
    'supporting documents',
    'police report',
    'bill invoice',
    'repair bill',
    'invoice',
    'vehicle photos count',
    'damage photos count',
    'license photos count',
    'police report count',
    'repair bill count',
    'invoice count',
  };

  String _humanizeDocLabel(String key) {
    final k = key.toLowerCase().trim();
    switch (k) {
      case 'vehicle photos':
      case 'vehicle photos count':
        return 'Vehicle Photos';
      case 'damage photos':
      case 'damage photos count':
        return 'Damage Vehicle Photos';
      case 'driver license':
      case 'driving license':
      case 'license photos':
      case 'license photos count':
        return 'Driving License';
      case 'supporting docs':
      case 'supporting documents':
        return 'Uploaded Documents';
      case 'police report':
      case 'police report count':
        return 'Police Report';
      case 'bill invoice':
      case 'invoice':
      case 'invoice count':
        return 'Invoice';
      case 'repair bill':
      case 'repair bill count':
        return 'Repair Bill';
      default:
        return key.replaceAll(' Count', '');
    }
  }

  /// Extracts a leading integer from values like "4 uploaded" or "2 Files".
  /// Falls back to `_asInt` for plain numeric values.
  int _extractCount(dynamic value) {
    if (value is num) return value.toInt();
    final raw = value.toString();
    final match = RegExp(r'\d+').firstMatch(raw);
    if (match != null) return int.parse(match.group(0)!);
    return _asInt(value);
  }

  Widget _buildFinalSummaryCard({
    required _ChatMsg msg,
    required bool isLastBot,
  }) {
    final payload = msg.payload!;
    final basic = <MapEntry<String, String>>[];
    final incident = <MapEntry<String, String>>[];
    final documents = <MapEntry<String, String>>[];

    payload.forEach((key, value) {
      if (value == null) return;
      final formatted = _formatFieldValue(key, value);
      if (formatted.isEmpty) return;
      final keyLc = key.toLowerCase().trim();
      if (_documentKeys.contains(keyLc)) {
        final count = _extractCount(value);
        documents.add(MapEntry(_humanizeDocLabel(key), '$count Files'));
      } else if (_incidentKeys.contains(keyLc)) {
        incident.add(MapEntry(key, formatted));
      } else {
        basic.add(MapEntry(key, formatted));
      }
    });

    final maxCardWidth = MediaQuery.of(context).size.width * 0.86;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bot avatar + intro bubble.
        if (msg.text.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBotAvatar(),
                const SizedBox(width: 10),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      msg.text,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _kDark,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Blue review card.
        Padding(
          padding: const EdgeInsets.only(left: 46, bottom: 10),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxCardWidth),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2A6FDB), Color(0xFF1E5BC2)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _kBlue.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header.
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Review Your Claim',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ..._reviewRows(basic),
                  if (incident.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _reviewSectionHeader('INCIDENT DETAILS'),
                    const SizedBox(height: 10),
                    ..._reviewRows(incident, multiline: true),
                  ],
                  if (documents.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _reviewSectionHeader('DOCUMENTS'),
                    const SizedBox(height: 10),
                    ..._reviewRows(documents),
                  ],
                  ..._buildUploadCountRows(),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          (!isLastBot || _confirmingFinalSummary || _botTyping)
                          ? null
                          : () => _onConfirmFinalSummary(msg),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _kBlue,
                        disabledBackgroundColor: Colors.white.withValues(
                          alpha: 0.7,
                        ),
                        disabledForegroundColor: _kBlue.withValues(alpha: 0.6),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: _confirmingFinalSummary
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(_kBlue),
                              ),
                            )
                          : const Text(
                              'Confirm & Submit Claim',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _reviewSectionHeader(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  List<Widget> _reviewRows(
    List<MapEntry<String, String>> rows, {
    bool multiline = false,
  }) {
    return [
      for (final r in rows)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  '${r.key}:',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  r.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                  textAlign: multiline ? TextAlign.left : TextAlign.right,
                  maxLines: multiline ? null : 2,
                  overflow: multiline
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
    ];
  }

  // ─── Upload counts in the review card ───────────────────────────────────

  /// Two rows showing total photos and total documents the user has uploaded
  /// in this thread. Skipped entirely when nothing has been uploaded yet.
  List<Widget> _buildUploadCountRows() {
    var photos = 0;
    var documents = 0;
    for (final asset in _uploadedAssetsByKey.values) {
      if (asset.kind == 'Image') {
        photos++;
      } else if (asset.kind == 'Document') {
        documents++;
      }
    }
    if (photos == 0 && documents == 0) return const [];
    return [
      const SizedBox(height: 14),
      _reviewSectionHeader('UPLOADS'),
      const SizedBox(height: 10),
      ..._reviewRows([
        MapEntry('Photos', photos.toString()),
        MapEntry('Documents', documents.toString()),
      ]),
    ];
  }

  // ─── Policy Verified Card ────────────────────────────────────────────────
  Widget _buildPolicyCard({
    required _ChatMsg msg,
    required String title,
    required Map<String, String> fields,
    required String introText,
    required String trailingText,
    required bool showSuggestions,
    required bool showTriggers,
  }) {
    // Determine status for coloring
    final statusValue = fields.entries
        .where((e) => e.key.toLowerCase() == 'status')
        .map((e) => e.value)
        .firstOrNull;
    final isActive =
        statusValue != null && statusValue.toLowerCase().contains('active');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Intro text bubble
        if (introText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBotAvatar(),
                const SizedBox(width: 10),
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.70,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      introText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _kDark,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Policy card
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.82,
            ),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified,
                        color: Color(0xFF34A853),
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _kDark,
                        ),
                      ),
                    ],
                  ),
                ),

                // Fields
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Column(
                    children: List.generate(fields.length, (i) {
                      final entry = fields.entries.elementAt(i);
                      final isStatus = entry.key.toLowerCase() == 'status';
                      final isLast = i == fields.length - 1;
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: isLast
                              ? null
                              : Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 110,
                              child: Text(
                                '${entry.key}:',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isStatus && isActive
                                      ? const Color(0xFF34A853)
                                      : _kDark,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),

                // Confirm / Not Correct buttons
                if (showSuggestions)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: msg.suggestions.map((s) {
                        final isConfirm =
                            s.toLowerCase().contains('correct') ||
                            s.toLowerCase().contains('yes') ||
                            s.toLowerCase().contains('confirm');
                        return GestureDetector(
                          onTap: () => _onSuggestionTap(s),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isConfirm ? _kBlue : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isConfirm ? _kBlue : _kDark,
                              ),
                            ),
                            child: Text(
                              s,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isConfirm ? Colors.white : _kDark,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Trigger actions (if any, outside the card)
        if (showTriggers)
          Padding(
            padding: const EdgeInsets.only(left: 46, bottom: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _effectiveTriggers(msg)
                  .map((t) => _buildTriggerButton(t, msg))
                  .toList(),
            ),
          ),
      ],
    );
  }

  /// Returns `msg.triggers` plus an implicit `SKIP` when the AI flags the
  /// question as skippable via `payload.is_skippable` but didn't emit the
  /// trigger itself. De-duplicated.
  List<String> _effectiveTriggers(_ChatMsg msg) {
    if (!_isSkippable(msg) || msg.triggers.contains('SKIP')) {
      return msg.triggers;
    }
    return [...msg.triggers, 'SKIP'];
  }

  Widget _buildBotAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(color: _kBlue, shape: BoxShape.circle),
      child: ClipOval(
        child: Image.asset(
          'assets/images/avatar_assistant.png',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(
            Icons.smart_toy_outlined,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    final user = context.watch<AuthCubit>().state.user;
    final avatarUrl = user?.avatarUrl;
    final initials = (user?.fullName ?? '')
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    final fallback = CircleAvatar(
      radius: 18,
      backgroundColor: _kUserInitialsBg,
      child: Text(
        initials.isNotEmpty ? initials : '?',
        style: const TextStyle(
          color: _kUserInitialsText,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    return SizedBox(
      width: 36,
      height: 36,
      child: ClipOval(
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                width: 36,
                height: 36,
                errorBuilder: (_, _, _) => fallback,
              )
            : fallback,
      ),
    );
  }

  // ─── Chat Bubble ─────────────────────────────────────────────────────────
  Widget _buildBubble(_ChatMsg msg) {
    final isUser = msg.isUser;
    final isLastBot = !isUser && _messages.last == msg && !_botTyping;
    final showSuggestions = isLastBot && msg.suggestions.isNotEmpty;
    final showTriggers = msg.triggers.isNotEmpty || _isSkippable(msg);
    final showCloseButton = isLastBot && msg.messageType == 'done';

    // Check if this is a policy detail message
    if (!isUser && !msg.animate) {
      // Final summary uses the dedicated "Review Your Claim" card with a
      // "Confirm & Submit Claim" CTA that persists to the database.
      if (msg.payloadType == 'final_summary' &&
          msg.payload != null &&
          msg.payload!.isNotEmpty) {
        return _buildFinalSummaryCard(msg: msg, isLastBot: isLastBot);
      }
      // Structured payload (triggers: SHOW_TABLE + verified_summary / final_summary)
      final structured = _tableFields(msg);
      if (structured != null) {
        return _buildPolicyCard(
          msg: msg,
          title: _cardTitleFor(msg.payloadType),
          fields: structured,
          introText: msg.text,
          trailingText: '',
          showSuggestions: showSuggestions,
          showTriggers: showTriggers,
        );
      }

      // Fallback: parse from markdown text
      final policyFields = _parsePolicyFields(msg.text);
      if (policyFields != null) {
        return _buildPolicyCard(
          msg: msg,
          title: 'Policy Verified',
          fields: policyFields,
          introText: _policyIntroText(msg.text),
          trailingText: _policyTrailingText(msg.text),
          showSuggestions: showSuggestions,
          showTriggers: showTriggers,
        );
      }
    }

    final hasAttachments =
        isUser && (msg.imagePaths.isNotEmpty || msg.documentNames.isNotEmpty);

    return Column(
      crossAxisAlignment: isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (hasAttachments)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildUserAttachments(msg),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[_buildBotAvatar(), const SizedBox(width: 10)],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.70,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? _kBlue : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isUser
                      ? Text(
                          msg.text,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            msg.animate
                                ? _TypewriterText(
                                    text: msg.text,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: _kDark,
                                      height: 1.4,
                                    ),
                                    onComplete: _showNextPendingMessage,
                                  )
                                : MarkdownBody(
                                    data: msg.text,
                                    selectable: true,
                                    fitContent: true,
                                    shrinkWrap: true,
                                    styleSheet: _botMarkdownStyle,
                                  ),
                            if (_showSampleOf(msg)) _buildSeeSampleLink(msg),
                            if (msg.validationFailedAngles.isNotEmpty)
                              _buildValidationFailureList(
                                msg,
                                msg.validationFailedAngles,
                              ),
                            if (msg.validationFailedLegacy)
                              _buildLegacyValidationFailure(),
                          ],
                        ),
                ),
              ),
              if (isUser) ...[const SizedBox(width: 10), _buildUserAvatar()],
            ],
          ),
        ),
        // Suggestion chips
        if (showSuggestions)
          Padding(
            padding: const EdgeInsets.only(left: 46, bottom: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: msg.suggestions
                  .where(
                    (s) =>
                        // Hide the "Skip" chip when Skip is already rendered
                        // as a trigger pill (skippable GET_DOCUMENT /
                        // GET_IMAGE turn) to avoid showing it twice.
                        s.trim().toLowerCase() != 'skip' ||
                        !_isSkippable(msg),
                  )
                  .map((s) {
                    return GestureDetector(
                      onTap: () => _onSuggestionTap(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _kBlue),
                        ),
                        child: Text(
                          s,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _kBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
        // Trigger actions
        if (showTriggers)
          Padding(
            padding: const EdgeInsets.only(left: 46, bottom: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _effectiveTriggers(msg)
                  .map((t) => _buildTriggerButton(t, msg))
                  .toList(),
            ),
          ),
        // Close button — appears on `message_type == 'done'`
        if (showCloseButton)
          Padding(
            padding: const EdgeInsets.only(left: 46, bottom: 10),
            child: _buildCloseButton(msg),
          ),
      ],
    );
  }

  // ── GET_IMAGE handlers ────────────────────────────────────────────────

  Future<void> _onPickImages() async {
    if (_pickedImages.length >= _maxImages) return;

    final remaining = _maxImages - _pickedImages.length;

    // Android's photo picker misbehaves with pickMultiImage(limit: 1) — it can
    // refuse to open or return an empty list. Fall back to single pickImage
    // when only one slot is left.
    final List<XFile> images;
    if (remaining == 1) {
      final single = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      images = single == null ? <XFile>[] : <XFile>[single];
    } else {
      images = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        limit: remaining,
      );
    }
    if (images.isEmpty || !mounted) return;

    setState(() {
      for (final img in images) {
        if (_pickedImages.length >= _maxImages) break;
        _pickedImages.add(File(img.path));
      }
    });
    _scrollToBottom();
  }

  void _onRemoveImage(int index) {
    setState(() => _pickedImages.removeAt(index));
  }

  // ── Per-angle GET_IMAGE handlers (driven by `payload.allowed_angles`) ──

  Future<void> _onPickAngleImage(String angle) async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _angleImages[angle] = File(picked.path);
      _failedAnglePaths.remove(angle);
    });
    _scrollToBottom();
  }

  void _onRemoveAngleImage(String angle) {
    setState(() => _angleImages.remove(angle));
  }

  Future<void> _onSubmitAngleImages({_ChatMsg? originatingMsg}) async {
    if (_angleImages.isEmpty || _botTyping || _uploadingFiles) return;

    // Resolve the group_key for THIS submission. Priority:
    //   1. validationGroupKey on the originating failure card (echoed back by
    //      the previous /validate-images response).
    //   2. Keyword scan over the originating GET_IMAGE trigger's bot text.
    //   3. Walk-back inference over the chat history (legacy fallback).
    // The previous flow always took option 3, which mis-fired after a failed
    // validation because the failure bubble has empty text — `_inferCategory`
    // then fell through to its `vehicle_photos` default and re-validated an
    // already-completed group.
    String category;
    if (originatingMsg?.validationGroupKey != null &&
        originatingMsg!.validationGroupKey!.isNotEmpty) {
      category = originatingMsg.validationGroupKey!;
    } else if (originatingMsg != null && originatingMsg.text.isNotEmpty) {
      category = _inferCategoryFromText(originatingMsg.text, isImage: true);
    } else {
      category = _inferCategory(isImage: true);
    }

    // Stale failure cards are guarded at the UI layer (their Submit button is
    // disabled when the group is in `_uploadedGroupKeys`). The fresh GET_IMAGE
    // trigger card must remain submittable because the AI can re-ask for the
    // same group after a "No, re-upload" — so no early return here.

    // Scope the entries to the full allowed-angles set for this card. On a
    // retry, the failure card carries `validationAllowedAngles` (forwarded
    // from the original GET_IMAGE trigger) so we always send the complete
    // batch — newly replaced angles + previously valid ones — to
    // `/validate-images`. Sending only failed angles would have the AI
    // re-validate a partial set, which the agent rejects.
    final List<String> allowedAngles =
        (originatingMsg?.validationAllowedAngles.isNotEmpty ?? false)
        ? originatingMsg!.validationAllowedAngles
        : (originatingMsg != null ? _allowedAnglesOf(originatingMsg) : const []);
    final List<String>? scopedAngles =
        allowedAngles.isEmpty ? null : allowedAngles;
    final entries = scopedAngles == null
        ? _angleImages.entries.toList(growable: false)
        : _angleImages.entries
              .where((e) => scopedAngles.contains(e.key))
              .toList(growable: false);
    if (entries.isEmpty) return;
    setState(() => _uploadingFiles = true);

    // Read bytes once; reused for both upload + validation.
    final List<({String angle, String name, List<int> bytes, String path})>
        prepared = [];
    for (final entry in entries) {
      final bytes = await entry.value.readAsBytes();
      final name = entry.value.path.split(RegExp(r'[\\/]')).last;
      prepared.add((
        angle: entry.key,
        name: name.isEmpty ? 'image.jpg' : name,
        bytes: bytes,
        path: entry.value.path,
      ));
    }

    // ── Validate first (AI image validation) ───────────────────────────
    // `vehicle_photos`, `damage_photos`, and `driver_license` go through
    // `/validate-images` — every other group (supporting_docs, …) uploads
    // directly.
    // Only forward the originating msg for removal if it's a failure card
    // (not the original GET_IMAGE trigger card — that one stays in chat).
    final _ChatMsg? failureCardToReplace =
        (originatingMsg != null &&
                (originatingMsg.validationFailedAngles.isNotEmpty ||
                    originatingMsg.validationFailedLegacy))
            ? originatingMsg
            : null;
    if (category == 'vehicle_photos' ||
        category == 'damage_photos' ||
        category == 'driver_license') {
      final validation = await _runImageValidation(
        questionLabel: category,
        images: {
          for (final p in prepared) p.angle: base64Encode(p.bytes),
        },
        allowedAngles: allowedAngles,
        previousFailureMsg: failureCardToReplace,
      );
      if (!validation.valid) {
        if (!mounted) return;
        setState(() => _uploadingFiles = false);
        return;
      }
    }

    int uploadedCount = 0;
    try {
      final ds = di.sl<ClaimsRemoteDataSource>();
      // Re-upload semantics: a fresh batch replaces any prior unattached
      // uploads in this thread under the same category.
      await _replacePriorUploads(category);
      for (final p in prepared) {
        final response = await ds.uploadClaimDocument(
          bytes: Uint8List.fromList(p.bytes),
          fileName: p.name,
          kind: 'Image',
          groupKey: category,
          chatThreadId: _threadId,
          angle: p.angle,
        );
        final id = (response['id'] ?? '').toString();
        if (id.isNotEmpty) {
          _uploadedDocumentIds.add((id: id, category: category));
          uploadedCount++;
        }
        _recordUploadedAsset(
          category: category,
          angle: p.angle,
          kind: 'Image',
          id: id.isEmpty ? null : id,
          localPath: p.path,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
      }
      debugPrint('[Upload] angle image upload failed: $e');
    }

    if (!mounted) return;
    final count = uploadedCount == 0 ? entries.length : uploadedCount;
    final bubble = '$count photo${count > 1 ? 's' : ''} uploaded';
    final paths = prepared.map((p) => p.path).toList();
    setState(() {
      // Drop only the angles we just uploaded — preserves any picks the user
      // may have made for a different group's still-open card.
      for (final p in prepared) {
        _angleImages.remove(p.angle);
      }
      _uploadedGroupKeys.add(category);
      _uploadingFiles = false;
      _messages.add(_ChatMsg(text: bubble, isUser: true, imagePaths: paths));
      _botTyping = true;
    });
    _scrollToBottom();
    _streamBotReply(count.toString());
  }

  /// Calls `/validate-images` and renders a transient "validating…" bot
  /// bubble that's swapped out for either nothing (on success) or the
  /// failure reason (on failure). Returns the validation outcome so callers
  /// can decide whether to continue with the upload + chat flow.
  Future<ImageValidationResult> _runImageValidation({
    required String questionLabel,
    required Map<String, String> images,
    bool isLegacy = false,
    List<String> allowedAngles = const [],
    _ChatMsg? previousFailureMsg,
  }) async {
    final waitingMsg = _ChatMsg(
      text: 'Please wait while we validate your images...',
      isUser: false,
    );
    setState(() => _messages.add(waitingMsg));
    _scrollToBottom();

    ImageValidationResult result;
    try {
      result = await ChatService.validateImages(
        groupKey: questionLabel,
        threadId: _threadId,
        images: images,
      );
    } catch (e) {
      debugPrint('[Validate] image validation failed: $e');
      result = ImageValidationResult(
        valid: false,
        failureReason: 'Could not validate images. Please try again.',
      );
    }

    if (!mounted) return result;

    final failedAngles = result.invalidAngles;

    setState(() {
      _messages.remove(waitingMsg);
      // Drop the previous failure card for this group so retries don't stack
      // multiple "Some images need to be re-uploaded" cards in the chat.
      if (previousFailureMsg != null) {
        _messages.remove(previousFailureMsg);
      }
      if (!result.valid) {
        // The AI has re-opened this group (fresh GET_IMAGE → user submitted →
        // validation failed). Any prior success entry is stale — without this,
        // the new failure card's Submit would be frozen by `groupAlreadyDone`
        // because the previous successful cycle's group_key is still in the
        // set, and the user could never re-submit replacements.
        if (result.groupKey != null && result.groupKey!.isNotEmpty) {
          _uploadedGroupKeys.remove(result.groupKey);
        }
        // When the API didn't return any invalid_angles (e.g., timeout or
        // network failure caught above), fall back to flagging every angle
        // we sent so the angle-wise re-upload card still renders instead of
        // the single-button legacy widget. The legacy widget is reserved
        // for true legacy (no allowed_angles) GET_IMAGE flows.
        final effectiveFailedAngles =
            (failedAngles.isEmpty && !isLegacy && allowedAngles.isNotEmpty)
                ? allowedAngles
                : failedAngles;
        // Snapshot the rejected images' paths so the failure card can detect
        // when the user picks a replacement (and re-enable Submit). The
        // images themselves stay in `_angleImages` so their thumbnails
        // remain visible alongside the per-angle error status.
        _failedAnglePaths.clear();
        for (final a in effectiveFailedAngles) {
          final f = _angleImages[a];
          if (f != null) _failedAnglePaths[a] = f.path;
        }
        final useLegacy = isLegacy || effectiveFailedAngles.isEmpty;
        _messages.add(
          _ChatMsg(
            text: result.failureReason?.trim().isNotEmpty == true
                ? result.failureReason!
                : 'Image validation failed. Please re-upload.',
            isUser: false,
            validationFailedAngles:
                useLegacy ? const [] : List<String>.from(effectiveFailedAngles),
            validationFailedLegacy: useLegacy,
            validationGroupKey: result.groupKey,
            validationAllowedAngles: allowedAngles,
          ),
        );
      } else {
        _failedAnglePaths.clear();
      }
    });
    _scrollToBottom();
    return result;
  }

  /// Re-renders the same legacy GET_IMAGE trigger card inside the failure
  /// bubble so the user can remove rejected images, add more, and resubmit.
  /// `_pickedImages` is preserved on validation failure, so the originally
  /// rejected thumbnails stay visible until the user edits them.
  Widget _buildLegacyValidationFailure() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: _buildLegacyImageTrigger(),
    );
  }

  /// Renders the validation-failure card: header, one row per failed angle
  /// (thumbnail of the re-picked image when present, angle label, status,
  /// Upload/Replace button), and a Submit button that re-runs the validate +
  /// upload flow. Self-contained because the original GET_IMAGE trigger card
  /// is no longer the "last bot message" once this bubble is added.
  /// Re-upload card shown after `/validate-images` returns invalid angles.
  /// Mirrors [_buildImageTrigger]'s card layout (same title, counter,
  /// per-angle rows, DONE pill) so the user sees the same upload component
  /// they used initially — with a red banner up top carrying the AI's
  /// failure reason.
  Widget _buildValidationFailureList(_ChatMsg msg, List<String> angles) {
    bool isStillRejected(String a) =>
        _failedAnglePaths[a] != null &&
        _angleImages[a]?.path == _failedAnglePaths[a];
    final allReplaced = angles.every((a) => !isStillRejected(a));
    // Once this card's group has been validated + uploaded successfully,
    // freeze Submit so a stale card can't re-fire validation against an
    // already-stored group.
    final groupAlreadyDone =
        msg.validationGroupKey != null &&
        _uploadedGroupKeys.contains(msg.validationGroupKey);
    final canSubmit =
        allReplaced && !_uploadingFiles && !_botTyping && !groupAlreadyDone;
    final filledCount = angles.where(_angleImages.containsKey).length;
    final reason = msg.text.trim();
    return Container(
      margin: const EdgeInsets.only(top: 6),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Upload Photos',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _kDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$filledCount of ${angles.length} uploaded · min ${angles.length}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFDECEC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Some images need to be re-uploaded',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB00020),
                  ),
                ),
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    reason,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB00020),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < angles.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _buildAngleRow(angles[i], angles.length),
          ],
          const SizedBox(height: 12),
          GestureDetector(
            onTap: canSubmit
                ? () => _onSubmitAngleImages(originatingMsg: msg)
                : null,
            child: Opacity(
              opacity: canSubmit ? 1.0 : 0.5,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _kBlue,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_uploadingFiles)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    else
                      const Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: Colors.white,
                      ),
                    const SizedBox(width: 8),
                    const Text(
                      'DONE',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openImageViewer(List<String> paths, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, _, _) =>
            _ImageViewerPage(paths: paths, initialIndex: initialIndex),
      ),
    );
  }

  /// Wipes prior unattached uploads for this thread+category before a fresh
  /// batch — implements the "re-upload replaces the previous image" flow when
  /// the AI prompts the user to retake/re-attach a document of the same kind.
  Future<void> _replacePriorUploads(String category) async {
    final hadPrior = _uploadedDocumentIds.any((d) => d.category == category);
    if (!hadPrior) return;
    try {
      final deleted = await di
          .sl<ClaimsRemoteDataSource>()
          .deleteClaimDocumentsByThread(
            threadId: _threadId,
            groupKey: category,
          );
      if (deleted.isNotEmpty) {
        final deletedSet = deleted.toSet();
        _uploadedDocumentIds.removeWhere((d) => deletedSet.contains(d.id));
      } else {
        _uploadedDocumentIds.removeWhere((d) => d.category == category);
      }
      _clearUploadedAssetsForCategory(category);
    } catch (e) {
      debugPrint('[Upload] failed to clear prior $category uploads: $e');
    }
  }

  Future<void> _onSubmitImages() async {
    if (_pickedImages.isEmpty || _botTyping || _uploadingFiles) return;

    final files = List<File>.from(_pickedImages);
    setState(() => _uploadingFiles = true);

    final category = _inferCategory(isImage: true);

    // Read bytes once so we can both validate and upload.
    final List<({String name, Uint8List bytes, String path})> prepared = [];
    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final bytes = await file.readAsBytes();
      final name = file.path.split(RegExp(r'[\\/]')).last;
      prepared.add((
        name: name.isEmpty ? 'image.jpg' : name,
        bytes: bytes,
        path: file.path,
      ));
    }

    // `vehicle_photos`, `damage_photos`, and `driver_license` run through
    // AI validation; every other group uploads directly.
    if (category == 'vehicle_photos' ||
        category == 'damage_photos' ||
        category == 'driver_license') {
      final validation = await _runImageValidation(
        questionLabel: category,
        images: {
          for (var i = 0; i < prepared.length; i++)
            'image_$i': base64Encode(prepared[i].bytes),
        },
        isLegacy: true,
      );
      if (!validation.valid) {
        if (!mounted) return;
        setState(() => _uploadingFiles = false);
        return;
      }
    }

    int uploadedCount = 0;
    try {
      final ds = di.sl<ClaimsRemoteDataSource>();
      // Re-upload semantics: a fresh batch for this category replaces any
      // prior unattached uploads in this thread under the same category.
      await _replacePriorUploads(category);
      for (var i = 0; i < prepared.length; i++) {
        final p = prepared[i];
        final response = await ds.uploadClaimDocument(
          bytes: p.bytes,
          fileName: p.name,
          kind: 'Image',
          groupKey: category,
          chatThreadId: _threadId,
        );
        final id = (response['id'] ?? '').toString();
        if (id.isNotEmpty) {
          _uploadedDocumentIds.add((id: id, category: category));
          uploadedCount++;
        }
        // Legacy bucket has no per-angle dimension — bucket each upload under
        // a synthetic angle so multiple files in the same category don't
        // overwrite each other in `_uploadedAssetsByKey`.
        _recordUploadedAsset(
          category: category,
          angle: 'item_$i',
          kind: 'Image',
          id: id.isEmpty ? null : id,
          localPath: p.path,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
      }
      debugPrint('[Upload] image upload failed: $e');
    }

    if (!mounted) return;
    final count = uploadedCount == 0 ? prepared.length : uploadedCount;
    final bubble = '$count photo${count > 1 ? 's' : ''} uploaded';
    final paths = files.map((f) => f.path).toList();
    setState(() {
      _pickedImages.clear();
      _uploadingFiles = false;
      _messages.add(_ChatMsg(text: bubble, isUser: true, imagePaths: paths));
      _botTyping = true;
    });
    _scrollToBottom();
    _streamBotReply(count.toString());
  }

  // ── GET_DOCUMENT handlers ───────────────────────────────────────────────

  Future<void> _onPickDocuments() async {
    if (_pickedDocuments.length >= _maxDocuments) return;

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: _allowedDocExtensions,
    );
    if (result == null || !mounted) return;

    setState(() {
      for (final file in result.files) {
        if (_pickedDocuments.length >= _maxDocuments) break;
        _pickedDocuments.add(file);
      }
    });
    _scrollToBottom();
  }

  void _onRemoveDocument(int index) {
    setState(() => _pickedDocuments.removeAt(index));
  }

  Future<void> _onSubmitDocuments(_ChatMsg msg) async {
    if (_pickedDocuments.isEmpty || _botTyping || _uploadingFiles) return;

    final docs = List<PlatformFile>.from(_pickedDocuments);
    final progress = _docTriggerProgress.putIfAbsent(
      msg,
      () => _DocTriggerProgress(),
    );
    final isFirstBatch = progress.count == 0;
    final minCount = _payloadInt(msg, 'min_count') ?? 1;

    setState(() => _uploadingFiles = true);

    int uploadedCount = 0;
    try {
      final ds = di.sl<ClaimsRemoteDataSource>();
      final category = _inferCategory(isImage: false);
      // Re-upload semantics — see _onSubmitImages. Only on the first batch:
      // subsequent batches in the same trigger ADD to the prior uploads to
      // satisfy `min_count`, so we must not delete what we just uploaded.
      if (isFirstBatch) {
        await _replacePriorUploads(category);
      }
      for (var i = 0; i < docs.length; i++) {
        final doc = docs[i];
        // `bytes` is populated when file_picker is used with withData: true
        // or on web. For mobile path, read the file from disk.
        List<int> bytes;
        if (doc.bytes != null) {
          bytes = doc.bytes!;
        } else if (doc.path != null) {
          bytes = await File(doc.path!).readAsBytes();
        } else {
          continue;
        }
        final response = await ds.uploadClaimDocument(
          bytes: bytes,
          fileName: doc.name,
          kind: 'Document',
          groupKey: category,
          chatThreadId: _threadId,
        );
        final id = (response['id'] ?? '').toString();
        if (id.isNotEmpty) {
          _uploadedDocumentIds.add((id: id, category: category));
          uploadedCount++;
        }
        _recordUploadedAsset(
          category: category,
          angle: 'item_${progress.count + i}',
          kind: 'Document',
          id: id.isEmpty ? null : id,
          localPath: doc.path,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Document upload failed: $e')));
      }
      debugPrint('[Upload] document upload failed: $e');
    }

    if (!mounted) return;
    final batchCount = uploadedCount == 0 ? docs.length : uploadedCount;
    for (final d in docs) {
      final ext = d.extension?.toLowerCase() ?? '';
      final isImage = const {'jpg', 'jpeg', 'png'}.contains(ext);
      if (isImage && d.path != null) {
        progress.imagePaths.add(d.path!);
      } else {
        progress.docNames.add(d.name);
      }
    }
    progress.count += batchCount;

    // Below `min_count` — stay on the trigger card so the user can upload
    // another batch. No user bubble yet; the trigger UI shows running progress.
    if (progress.count < minCount) {
      setState(() {
        _pickedDocuments.clear();
        _uploadingFiles = false;
      });
      _scrollToBottom();
      return;
    }

    // `min_count` reached — emit a single cumulative user bubble covering
    // every batch and let the bot advance.
    final total = progress.count;
    final imagePaths = List<String>.from(progress.imagePaths);
    final docNames = List<String>.from(progress.docNames);
    if (imagePaths.isEmpty && docNames.isEmpty) {
      docNames.addAll(docs.map((d) => d.name));
    }
    final bubble = '$total document${total > 1 ? 's' : ''} uploaded';
    _docTriggerProgress.remove(msg);
    setState(() {
      _pickedDocuments.clear();
      _uploadingFiles = false;
      _messages.add(
        _ChatMsg(
          text: bubble,
          isUser: true,
          imagePaths: imagePaths,
          documentNames: docNames,
        ),
      );
      _botTyping = true;
    });
    _scrollToBottom();
    _streamBotReply(total.toString());
  }

  // ─── Trigger Widgets ─────────────────────────────────────────────────────
  Widget _buildTriggerButton(String trigger, _ChatMsg msg) {
    switch (trigger) {
      case 'GET_DATE_TIME':
        return _buildDateTimeTrigger();
      case 'GET_LOCATION':
        return _buildLocationTrigger();
      case 'GET_IMAGE':
        return _buildImageTrigger(msg);
      case 'GET_DOCUMENT':
        return _buildDocumentTrigger(msg);
      case 'SUBMIT_CLAIM':
        return _buildSubmitClaimTrigger();
      case 'SKIP':
        return _buildSkipTrigger();
      default:
        return const SizedBox.shrink();
    }
  }

  // Helpers to read GET_IMAGE constraints from a message payload.
  List<String> _allowedAnglesOf(_ChatMsg msg) {
    final raw = msg.payload?['allowed_angles'];
    if (raw is List)
      return raw.map((e) => e.toString()).toList(growable: false);
    return const [];
  }

  /// Whether the bot's `GET_IMAGE` payload requested showing the bundled
  /// sample-photos affordance (`payload.show_sample == true`).
  bool _showSampleOf(_ChatMsg msg) {
    if (!msg.triggers.contains('GET_IMAGE')) return false;
    final raw = msg.payload?['show_sample'];
    if (raw is bool) return raw;
    if (raw is String) return raw.toLowerCase() == 'true';
    return false;
  }

  /// Whether the bot's payload marks this question as skippable
  /// (`payload.is_skippable == true`). Drives an inline Skip pill alongside
  /// GET_IMAGE / GET_DOCUMENT trigger cards when the AI didn't already emit
  /// a standalone `SKIP` trigger.
  bool _isSkippable(_ChatMsg msg) {
    final raw = msg.payload?['is_skippable'];
    if (raw is bool && raw) return true;
    if (raw is num && raw != 0) return true;
    if (raw is String) {
      final v = raw.trim().toLowerCase();
      if (v == 'true' || v == '1' || v == 'yes') return true;
    }
    // Some AI turns advertise skippability only via a "Skip" suggestion
    // chip (e.g. GET_DOCUMENT for supporting_docs). Treat that as skippable
    // so the inline Skip pill renders alongside the trigger card.
    if (msg.suggestions.any((s) => s.trim().toLowerCase() == 'skip')) {
      return true;
    }
    return false;
  }

  Widget _buildSeeSampleLink(_ChatMsg msg) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: GestureDetector(
        onTap: () => _openSampleImagesViewer(msg),
        child: const Text(
          '(See sample)',
          style: TextStyle(
            fontSize: 13,
            color: _kBlue,
            decoration: TextDecoration.underline,
            decorationColor: _kBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _openSampleImagesViewer(_ChatMsg msg) {
    if (!_showSampleOf(msg)) return;
    showSampleImagesDialog(
      context: context,
      assetPaths: const ['assets/images/damage_photos_sample.png'],
      labels: const [],
    );
  }

  int? _payloadInt(_ChatMsg msg, String key) {
    final raw = msg.payload?[key];
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  /// "front_left" → "Front Left" for display.
  String _humanizeAngle(String angle) {
    return angle
        .split(RegExp(r'[_\s]+'))
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');
  }

  // ── SUBMIT_CLAIM trigger ─────────────────────────────────────────────────

  bool _submittingClaim = false;
  bool _closingConversation = false;
  bool _confirmingFinalSummary = false;

  static final _claimRefPattern = RegExp(
    r'([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})',
  );

  /// Extracts a claim reference UUID from the final "done" bot message, if any.
  String? _extractClaimReference(String text) {
    final match = _claimRefPattern.firstMatch(text);
    return match?.group(1);
  }

  /// Picks up the most recent `claim_data` payload we received during the chat.
  Map<String, dynamic>? _latestClaimData() {
    for (int i = _messages.length - 1; i >= 0; i--) {
      final data = _messages[i].claimData;
      if (data != null && data.isNotEmpty) return data;
    }
    return null;
  }

  /// Picks up the last `save_summary` payload from a `message_type == 'done'`
  /// bubble. This is the authoritative final summary the bot shows just before
  /// the Close button, and contains human-readable keys like "Policy Number".
  Map<String, dynamic>? _latestSaveSummaryPayload() {
    for (int i = _messages.length - 1; i >= 0; i--) {
      final m = _messages[i];
      if (m.messageType == 'done' &&
          m.payloadType == 'save_summary' &&
          m.payload != null &&
          m.payload!.isNotEmpty) {
        return m.payload;
      }
    }
    return null;
  }

  /// Translates the human-readable keys from a `save_summary` payload into the
  /// camelCase property names expected by `CreateClaimFromChatDto` on the
  /// backend. Unknown keys are kept verbatim — `[JsonExtensionData]` on the
  /// DTO captures them into the `AdditionalData` JSON blob.
  Map<String, dynamic> _mapSaveSummaryToDto(Map<String, dynamic> summary) {
    final mapped = <String, dynamic>{};
    String? incidentDateRaw;
    String? incidentTimeRaw;

    summary.forEach((key, value) {
      if (value == null) return;
      // Match keys case-insensitively so the bot can vary casing without
      // silently dropping fields onto AdditionalData.
      switch (key.toLowerCase().trim()) {
        case 'policy number':
          mapped['policyNumber'] = value;
          break;
        case 'policy holder':
        case 'policyholder':
        case 'full name':
        case 'name':
          mapped['fullName'] = value;
          break;
        case 'claimant type':
        case 'claimant':
          mapped['claimantType'] = value.toString();
          break;
        case 'plat number':
        case 'plate number':
        case 'vehicle number':
        case 'vehicle registration number':
        case 'registration number':
          mapped['vehicleRegistrationNumber'] = value;
          break;
        case 'vin':
        case 'vin number':
        case 'vehicle identification number':
          mapped['vinNumber'] = value;
          break;
        case 'vehicle':
        case 'vehicle model':
          mapped['vehicleModel'] = value;
          break;
        case 'status':
        case 'policy status':
          mapped['policyStatus'] = value;
          break;
        case 'valid until':
        case 'policy valid until':
          {
            final parsed = DateTime.tryParse(value.toString());
            if (parsed != null) {
              mapped['policyValidUntil'] = parsed.toUtc().toIso8601String();
            } else {
              mapped[key] = value;
            }
          }
          break;
        case 'claim type':
          mapped['claimType'] = value.toString();
          break;
        case 'incident date':
        case 'date':
          incidentDateRaw = value.toString();
          break;
        case 'incident time':
        case 'time':
          incidentTimeRaw = value.toString();
          break;
        case 'incident location':
        case 'location':
          mapped['incidentLocation'] = value;
          break;
        case 'incident description':
        case 'damage details':
        case 'description':
          mapped['incidentDescription'] = value;
          break;
        case 'claim amount':
        case 'amount':
          if (value is num) {
            mapped['amount'] = value;
          } else {
            final parsed = num.tryParse(value.toString());
            if (parsed != null) mapped['amount'] = parsed;
          }
          break;
        default:
          // Keep unrecognised keys so the server stores them under AdditionalData.
          mapped[key] = value;
      }
    });

    final combinedIncident = _combineIncidentDateTime(
      incidentDateRaw,
      incidentTimeRaw,
    );
    if (combinedIncident != null) {
      mapped['incidentDate'] = combinedIncident.toUtc().toIso8601String();
    } else {
      // Preserve the raw strings as extras so nothing is silently dropped.
      if (incidentDateRaw != null) mapped['Incident Date'] = incidentDateRaw;
      if (incidentTimeRaw != null) mapped['Incident Time'] = incidentTimeRaw;
    }

    return mapped;
  }

  /// Infers the document category for an upload from the most recent bot
  /// prompt. The chatbot's trigger messages don't carry an explicit category,
  /// so we fall back to keyword matching on the latest bot text.
  String _inferCategory({required bool isImage}) {
    // Walk back to the most recent bot message that actually carries content
    // — skip empty validation-failure bubbles and any blank assistant turn so
    // the inference doesn't get pulled to its default by the failure card.
    String text = '';
    for (int i = _messages.length - 1; i >= 0; i--) {
      final m = _messages[i];
      if (m.isUser) continue;
      if (m.validationFailedAngles.isNotEmpty || m.validationFailedLegacy) {
        continue;
      }
      if (m.text.trim().isEmpty) continue;
      text = m.text;
      break;
    }
    return _inferCategoryFromText(text, isImage: isImage);
  }

  String _inferCategoryFromText(String raw, {required bool isImage}) {
    final text = raw.toLowerCase();
    // `supporting` must be checked first: the supporting-docs prompt enumerates
    // examples ("insurance policy, accident photos, or police reports") that
    // would otherwise match the police_report / bill_invoice branches and route
    // the upload to the wrong groupKey, leaving the Claim Summary's
    // "Supporting Documents" section empty.
    if (text.contains('supporting')) return 'supporting_docs';
    if (text.contains('damage')) return 'damage_photos';
    if (text.contains('license') || text.contains('licence')) {
      return 'driver_license';
    }
    if (text.contains('police')) return 'police_report';
    if (text.contains('repair') ||
        text.contains('bill') ||
        text.contains('invoice')) {
      return 'bill_invoice';
    }
    if (text.contains('vehicle') || text.contains('car')) {
      return isImage ? 'vehicle_photos' : 'supporting_docs';
    }
    return isImage ? 'vehicle_photos' : 'supporting_docs';
  }

  /// Coerces a payload value to an `int` (best-effort). Returns 0 on failure
  /// so counts always round-trip as a number, never null.
  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value.toString());
    return parsed ?? 0;
  }

  /// Parses the "dd-MM-yyyy" date + "hh:mm a" time pair that the chat summary
  /// uses. Returns null on any parse failure so the caller can fall back to
  /// keeping the raw strings.
  DateTime? _combineIncidentDateTime(String? dateRaw, String? timeRaw) {
    if (dateRaw == null || dateRaw.trim().isEmpty) return null;
    DateTime? date;
    for (final pattern in const ['dd-MM-yyyy', 'd-M-yyyy', 'yyyy-MM-dd']) {
      try {
        date = DateFormat(pattern).parseStrict(dateRaw.trim());
        break;
      } catch (_) {
        // try next pattern
      }
    }
    date ??= DateTime.tryParse(dateRaw.trim());
    if (date == null) return null;

    if (timeRaw == null || timeRaw.trim().isEmpty) return date;
    for (final pattern in const ['hh:mm a', 'h:mm a', 'HH:mm']) {
      try {
        final t = DateFormat(pattern).parseStrict(timeRaw.trim());
        return DateTime(date.year, date.month, date.day, t.hour, t.minute);
      } catch (_) {
        // try next pattern
      }
    }
    return date;
  }

  /// Handler for the Close button shown on the `message_type == 'done'` bubble.
  /// Always runs end-to-end (try/finally) and surfaces real errors via SnackBar
  /// so failures are visible instead of silently swallowed.
  /// Fire-and-forget auto-save invoked the moment the bot streams a message
  /// with `payload_type == "save_summary"`. Idempotent — only the first call
  /// per chat session does any work; the rest short-circuit. The Close button
  /// awaits [_autoSaveFuture] so it can decide whether to retry on failure.
  void _triggerAutoSaveOnSummary(
    Map<String, dynamic>? saveSummaryPayload,
    String doneText,
  ) {
    if (_savedOnSummary || _autoSaveFuture != null) return;
    final externalRef = _extractClaimReference(doneText);
    final future = _runSaveClaimAndConversation(
      saveSummaryPayload: saveSummaryPayload,
      externalRef: externalRef,
    );
    _autoSaveFuture = future;
    future
        .then((_) {
          _savedOnSummary = true;
        })
        .catchError((Object e) {
          debugPrint(
            '[AutoSave] save_summary save failed (will retry on Close): $e',
          );
          // Clear the future so the Close-button fallback can run a fresh attempt.
          _autoSaveFuture = null;
        });
  }

  /// Performs the full server-side save: create claim row (if not already
  /// created via SUBMIT_CLAIM) and attach uploaded documents. Throws on any
  /// step failure so the caller can decide whether to retry or surface the
  /// error.
  Future<void> _runSaveClaimAndConversation({
    Map<String, dynamic>? saveSummaryPayload,
    String? externalRef,
  }) async {
    String? finalClaimId = _submittedClaimId;

    if (finalClaimId == null || finalClaimId.isEmpty) {
      final claimData = _latestClaimData() ?? <String, dynamic>{};
      final saveSummary = saveSummaryPayload ?? _latestSaveSummaryPayload();
      final summaryFields = saveSummary != null
          ? _mapSaveSummaryToDto(saveSummary)
          : <String, dynamic>{};
      // save_summary is the authoritative final payload from the bot, so its
      // values take precedence over any earlier claim_data snapshot.
      final payload = <String, dynamic>{
        ...claimData,
        ...summaryFields,
        'chatThreadId': _threadId,
        'externalReference': ?externalRef,
      };
      final response = await di
          .sl<ClaimsRemoteDataSource>()
          .createClaimFromChat(payload);
      final created = (response['id'] ?? response['claimId'] ?? '').toString();
      if (created.isEmpty) {
        throw Exception('Claim created but backend returned no id.');
      }
      finalClaimId = created;
      _submittedClaimId = finalClaimId;
      debugPrint('[AutoSave] claim created: $finalClaimId');
    }

    if (_uploadedDocumentIds.isNotEmpty) {
      final result = await di.sl<ClaimsRemoteDataSource>().attachClaimDocuments(
        claimId: finalClaimId,
        documentIds: _uploadedDocumentIds.map((d) => d.id).toList(),
      );
      debugPrint(
        '[AutoSave] attached ${result['attachedCount']} document(s) to $finalClaimId',
      );
    }
  }

  Future<void> _onCloseConversation(_ChatMsg doneMsg) async {
    if (_closingConversation) return;
    setState(() => _closingConversation = true);

    String? errorMessage;

    try {
      // Always write the local transcript file. The server-side save (claim
      // row + doc attach + Conversations row) is normally already done from
      // the `save_summary` streaming hook above; this method only retries it
      // when that auto-save failed or never fired.
      _persistTranscript();

      // Wait for any in-flight auto-save so we don't race-create a duplicate
      // claim, then fall back to a fresh save if it never succeeded.
      if (_autoSaveFuture != null) {
        try {
          await _autoSaveFuture;
        } catch (_) {
          // Swallowed — _savedOnSummary check below decides whether to retry.
        }
      }

      if (!_savedOnSummary) {
        try {
          await _runSaveClaimAndConversation(
            externalRef: _extractClaimReference(doneMsg.text),
          );
          _savedOnSummary = true;
        } catch (e) {
          errorMessage = 'Failed to save claim: $e';
          debugPrint('[Close] fallback save failed: $e');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _closingConversation = false);

        if (errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 4),
            ),
          );
        }

        // 4. Always clear the stack and land on the Claims tab inside the
        //    HomePage shell so the bottom nav is preserved.
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.home,
          (route) => false,
          arguments: {'initialTab': 1},
        );
      }
    }
  }

  Widget _buildCloseButton(_ChatMsg msg) {
    return _buildPillButton(
      icon: Icons.check_circle_outline,
      label: 'Close',
      onTap: () => _onCloseConversation(msg),
      isLoading: _closingConversation,
    );
  }

  /// Tapped from the `final_summary` review card. Persists the claim +
  /// documents + conversation to the database, then sends "Yes Confirm" to
  /// the bot so the conversation can continue.
  Future<void> _onConfirmFinalSummary(_ChatMsg msg) async {
    if (_confirmingFinalSummary || _botTyping) return;
    setState(() => _confirmingFinalSummary = true);

    String? errorMessage;
    try {
      // Treat the final_summary payload as the authoritative source so
      // _runSaveClaimAndConversation maps the human-readable keys via
      // _mapSaveSummaryToDto and creates a proper claim row.
      await _runSaveClaimAndConversation(saveSummaryPayload: msg.payload);
      _savedOnSummary = true;
    } catch (e) {
      errorMessage = 'Failed to save claim: $e';
      debugPrint('[ConfirmFinalSummary] save failed: $e');
    }

    if (!mounted) return;
    setState(() => _confirmingFinalSummary = false);

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }
    // Send "Yes Confirm" to the bot so the conversation continues.
    const reply = 'Yes Confirm';
    setState(() {
      _messages.add(const _ChatMsg(text: reply, isUser: true));
      _botTyping = true;
    });
    _scrollToBottom();
    _streamBotReply(reply);
  }

  Widget _buildSubmitClaimTrigger() {
    // Find the message that has claim_data
    final claimMsg = _messages.lastWhere(
      (m) => m.claimData != null && m.claimData!.isNotEmpty,
      orElse: () => const _ChatMsg(text: '', isUser: false),
    );

    if (claimMsg.claimData == null || claimMsg.claimData!.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildPillButton(
      icon: Icons.check_circle_outline,
      label: 'Submit Claim',
      onTap: () => _onSubmitClaim(claimMsg.claimData!),
      isLoading: _submittingClaim,
    );
  }

  Future<void> _onSubmitClaim(Map<String, dynamic> claimData) async {
    if (_submittingClaim) return;
    setState(() => _submittingClaim = true);

    try {
      // Add the chat thread ID so the claim is linked to this conversation
      final payload = {...claimData, 'chatThreadId': _threadId};

      final dataSource = di.sl<ClaimsRemoteDataSource>();
      final response = await dataSource.createClaim(payload);

      if (!mounted) return;

      final claimNumber = response['claimNumber'] as String? ?? '';
      _submittedClaimId = (response['id'] ?? response['claimId'] ?? claimNumber)
          .toString();

      setState(() {
        _messages.add(
          _ChatMsg(
            text: 'Claim **$claimNumber** has been submitted successfully!',
            isUser: false,
            animate: true,
          ),
        );
        _submittingClaim = false;
      });
      _scrollToBottom();
      _persistTranscript();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMsg(
            text: 'Failed to submit claim. Please try again.',
            isUser: false,
          ),
        );
        _submittingClaim = false;
      });
      _scrollToBottom();
    }
  }

  // ── User attachments (images / documents) rendered above user bubble ──
  Widget _buildUserAttachments(_ChatMsg msg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (msg.imagePaths.isNotEmpty)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 6,
              runSpacing: 6,
              children: msg.imagePaths.asMap().entries.map((entry) {
                final index = entry.key;
                final path = entry.value;
                return GestureDetector(
                  onTap: () => _openImageViewer(msg.imagePaths, index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(path),
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 88,
                        height: 88,
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.grey.shade400,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        if (msg.documentNames.isNotEmpty) ...[
          if (msg.imagePaths.isNotEmpty) const SizedBox(height: 6),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: msg.documentNames.map((name) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.insert_drive_file_outlined,
                        size: 18,
                        color: _kBlue,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _kDark,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  // ── GET_DATE_TIME inline picker widget ───────────────────────────────
  Widget _buildDateTimeTrigger() {
    final now = DateTime.now();
    final date = _dtDate ?? now;
    final time = _dtTime ?? TimeOfDay.fromDateTime(now);
    final dateLabel = DateFormat('d MMM yyyy').format(date);
    final timeLabel = time.format(context);

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Incident Date & Time',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _dateTimeField(
                  icon: Icons.calendar_today_outlined,
                  value: dateLabel,
                  onTap: _pickIncidentDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dateTimeField(
                  icon: Icons.access_time,
                  value: timeLabel,
                  onTap: _pickIncidentTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _confirmIncidentDateTime,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _kBlue,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: _kBlue.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Confirm Date & Time',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateTimeField({
    required IconData icon,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _kBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: _kDark,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  /// Reusable pill-shaped action button for triggers.
  Widget _buildPillButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kBlue),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: _kBlue),
              )
            else
              Icon(icon, size: 16, color: _kBlue),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: _kBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Location trigger: address input + "Use Current Location".
  Widget _buildLocationTrigger() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _locationController,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _onSubmitLocation(),
          style: const TextStyle(fontSize: 13, color: _kDark),
          decoration: InputDecoration(
            hintText: 'Enter street, city or zip code',
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            prefixIcon: Icon(
              Icons.location_on_outlined,
              size: 18,
              color: Colors.grey.shade400,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 0,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: _kBlue),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildPillButton(
          icon: Icons.my_location,
          label: 'Use Current Location',
          onTap: _onUseCurrentLocation,
          isLoading: _fetchingLocation,
        ),
      ],
    );
  }

  // ─── GET_IMAGE trigger UI ───────────────────────────────────────────────
  Widget _buildImageTrigger(_ChatMsg msg) {
    final angles = _allowedAnglesOf(msg);
    if (angles.isEmpty) {
      return _buildLegacyImageTrigger();
    }
    final minCount = _payloadInt(msg, 'min_count') ?? angles.length;
    final maxCount = _payloadInt(msg, 'max_count') ?? angles.length;
    // Count only the angles this trigger owns. The global map can carry stray
    // entries from a different group's still-open failure card.
    final filledCount = angles.where(_angleImages.containsKey).length;
    final canSubmit =
        filledCount >= minCount &&
        !_uploadingFiles &&
        !_botTyping;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload Photos',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _kDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$filledCount of $maxCount uploaded · min $minCount',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < angles.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _buildAngleRow(angles[i], maxCount),
          ],
          const SizedBox(height: 12),
          if (filledCount >= minCount)
            GestureDetector(
              onTap: canSubmit
                  ? () => _onSubmitAngleImages(originatingMsg: msg)
                  : null,
              child: Opacity(
                opacity: canSubmit ? 1.0 : 0.5,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _kBlue,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_uploadingFiles)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      else
                        const Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: Colors.white,
                        ),
                      const SizedBox(width: 8),
                      const Text(
                        'DONE',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// One row in the per-angle uploader: label + thumbnail (when picked) +
  /// upload/replace/remove controls. Single-image picker per row.
  Widget _buildAngleRow(String angle, int maxCount) {
    final picked = _angleImages[angle];
    final atCap = _angleImages.length >= maxCount && picked == null;
    final stillRejected =
        _failedAnglePaths[angle] != null &&
        picked?.path == _failedAnglePaths[angle];
    final String statusText;
    final Color statusColor;
    if (stillRejected) {
      statusText =
          '${_humanizeAngle(angle)} does not match the required view. Please re-upload.';
      statusColor = const Color(0xFFB00020);
    } else if (picked == null) {
      statusText = 'Not uploaded';
      statusColor = Colors.grey.shade600;
    } else {
      statusText = 'Uploaded';
      statusColor = _kBlue;
    }
    return Row(
      children: [
        if (picked != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(picked, width: 48, height: 48, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
        ] else ...[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              stillRejected
                  ? Icons.broken_image_outlined
                  : Icons.image_outlined,
              color: Colors.grey.shade500,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _humanizeAngle(angle),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                statusText,
                style: TextStyle(fontSize: 11, color: statusColor),
              ),
            ],
          ),
        ),
        if (picked != null && !stillRejected)
          IconButton(
            tooltip: 'Remove',
            onPressed: () => _onRemoveAngleImage(angle),
            icon: const Icon(Icons.close, size: 18, color: Colors.red),
            visualDensity: VisualDensity.compact,
          ),
        TextButton.icon(
          onPressed: (atCap || _uploadingFiles)
              ? null
              : () => _onPickAngleImage(angle),
          icon: Icon(
            (picked == null || stillRejected)
                ? Icons.camera_alt_outlined
                : Icons.refresh,
            size: 16,
          ),
          label: Text(
            (picked == null || stillRejected) ? 'Upload' : 'Replace',
            style: const TextStyle(fontSize: 12),
          ),
          style: TextButton.styleFrom(
            foregroundColor: _kBlue,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  /// Legacy single-button image flow used when the bot's GET_IMAGE message
  /// has no `allowed_angles` in its payload.
  Widget _buildLegacyImageTrigger() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload Photos',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _kDark,
            ),
          ),
          if (_pickedImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _pickedImages.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _pickedImages[index],
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: GestureDetector(
                          onTap: () => _onRemoveImage(index),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_pickedImages.length}/$_maxImages UPLOADED',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickedImages.length >= _maxImages
                ? _onSubmitImages
                : _onPickImages,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _pickedImages.length >= _maxImages
                        ? Icons.check_circle_outline
                        : Icons.camera_alt_outlined,
                    size: 18,
                    color: _kDark,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _pickedImages.length >= _maxImages ? 'DONE' : 'UPLOAD',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── GET_DOCUMENT trigger UI ────────────────────────────────────────────
  Widget _buildDocumentTrigger(_ChatMsg msg) {
    final minCount = _payloadInt(msg, 'min_count') ?? 1;
    final maxCount = _payloadInt(msg, 'max_count') ?? _maxDocuments;
    final alreadyUploaded = _docTriggerProgress[msg]?.count ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload Documents',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _kDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                minCount > 1
                    ? '$alreadyUploaded of $maxCount uploaded · min $minCount'
                    : 'You can upload photos or PDF files.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              if (_pickedDocuments.isNotEmpty) ...[
                const SizedBox(height: 12),
                // Document list
                ...List.generate(_pickedDocuments.length, (index) {
                  final doc = _pickedDocuments[index];
                  final sizeKb = doc.size ~/ 1024;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.description_outlined,
                          size: 20,
                          color: _kBlue,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _kDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Document \u2022 $sizeKb KB',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _onRemoveDocument(index),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                Text(
                  '${_pickedDocuments.length}/$_maxDocuments UPLOADED',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Upload / action buttons
              Builder(
                builder: (_) {
                  final pickedCount = _pickedDocuments.length;
                  final totalCount = pickedCount + alreadyUploaded;
                  final canAddMore = pickedCount < _maxDocuments;
                  final minReached = totalCount >= minCount;

                  if (pickedCount == 0) {
                    return _docActionButton(
                      label: 'UPLOAD',
                      icon: Icons.camera_alt_outlined,
                      enabled: !_uploadingFiles,
                      onTap: _onPickDocuments,
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _docActionButton(
                          label: 'ADD',
                          icon: Icons.add,
                          enabled: !_uploadingFiles && canAddMore,
                          onTap: _onPickDocuments,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _docActionButton(
                          label: 'DONE',
                          icon: Icons.check_circle_outline,
                          enabled: !_uploadingFiles && minReached,
                          onTap: () => _onSubmitDocuments(msg),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _docActionButton({
    required String label,
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final color = enabled ? _kDark : Colors.grey.shade400;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: enabled ? Colors.grey.shade300 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SKIP trigger UI ─────────────────────────────────────────────────────
  Widget _buildSkipTrigger() {
    return GestureDetector(
      onTap: () => _onSuggestionTap('Skip'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kBlue),
        ),
        child: const Text(
          'Skip',
          style: TextStyle(
            fontSize: 13,
            color: _kBlue,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ─── Typing Indicator ────────────────────────────────────────────────────
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBotAvatar(),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 600 + (i * 200)),
                  builder: (context, value, _) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade400,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bot Markdown Style ───────────────────────────────────────────────────
final _botMarkdownStyle = MarkdownStyleSheet(
  p: const TextStyle(fontSize: 14, color: _kDark, height: 1.4),
  pPadding: EdgeInsets.zero,
  strong: const TextStyle(
    fontSize: 14,
    color: _kDark,
    fontWeight: FontWeight.bold,
    height: 1.4,
  ),
  tableHead: const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: _kDark,
  ),
  tableBody: const TextStyle(fontSize: 13, color: _kDark),
  tableBorder: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
  tableHeadAlign: TextAlign.left,
  tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
  blockSpacing: 8,
  listBullet: const TextStyle(fontSize: 14, color: _kDark),
  h1: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kDark),
  h1Padding: EdgeInsets.zero,
  h2: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kDark),
  h2Padding: EdgeInsets.zero,
  h3: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _kDark),
  h3Padding: EdgeInsets.zero,
);

// ─── Typewriter Text Widget ───────────────────────────────────────────────
class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final VoidCallback? onComplete;

  const _TypewriterText({
    required this.text,
    required this.style,
    this.onComplete,
  });

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  int _charCount = 0;
  Timer? _timer;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 18), (_) {
      if (_charCount >= widget.text.length) {
        _timer?.cancel();
        if (!_done) {
          _done = true;
          widget.onComplete?.call();
        }
        return;
      }
      setState(() {
        _charCount = (_charCount + 2).clamp(0, widget.text.length);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleText = widget.text.substring(0, _charCount);
    return MarkdownBody(
      data: visibleText,
      selectable: _done,
      fitContent: true,
      shrinkWrap: true,
      styleSheet: _botMarkdownStyle,
    );
  }
}

// ─── Chat Message Model ────────────────────────────────────────────────────
class _ChatMsg {
  final String text;
  final bool isUser;
  final bool animate;
  final String messageType;
  final List<String> suggestions;
  final List<String> triggers;
  final Map<String, dynamic>? claimData;
  final String? payloadType;
  final Map<String, dynamic>? payload;

  final List<String> imagePaths;
  final List<String> documentNames;

  /// Angles flagged as `angle_matches: false` by `/validate-images`. When
  /// non-empty, the bubble renders a per-angle "Upload `<angle>`" button that
  /// re-picks just that slot in `_angleImages`.
  final List<String> validationFailedAngles;
  /// Set when `/validate-images` fails for the legacy free-form flow (no
  /// per-angle breakdown). Drives a single "Re-upload Photos" button.
  final bool validationFailedLegacy;
  /// `group_key` echoed back by `/validate-images`. Scopes the failure card
  /// to a particular upload group (e.g. `vehicle_photos`).
  final String? validationGroupKey;
  /// Full set of allowed angles for this group, carried forward from the
  /// original GET_IMAGE trigger so retry submits can re-validate every angle
  /// (failed + previously valid) — `/validate-images` expects the complete
  /// batch on each call.
  final List<String> validationAllowedAngles;

  const _ChatMsg({
    required this.text,
    required this.isUser,
    this.animate = false,
    this.messageType = '',
    this.suggestions = const [],
    this.triggers = const [],
    this.claimData,
    this.payloadType,
    this.payload,
    this.imagePaths = const [],
    this.documentNames = const [],
    this.validationFailedAngles = const [],
    this.validationFailedLegacy = false,
    this.validationGroupKey,
    this.validationAllowedAngles = const [],
  });
}

/// Running progress for a single GET_DOCUMENT trigger so the user can satisfy
/// `min_count` across multiple separate uploads. Accumulates the count and the
/// names/paths used for the final cumulative user bubble.
class _DocTriggerProgress {
  int count = 0;
  final List<String> imagePaths = [];
  final List<String> docNames = [];
}

/// Snapshot of one upload kept for the final-summary tiles. We hold the local
/// path so we can render a thumbnail even before the network round-trip
/// returns a server-side URL.
class _UploadedAsset {
  final String? id;
  final String? localPath;

  /// 'Image' or 'Document'. Drives the photo-vs-document split in the review
  /// card's upload counts.
  final String kind;
  const _UploadedAsset({this.id, this.localPath, required this.kind});
}

class _ImageViewerPage extends StatefulWidget {
  const _ImageViewerPage({required this.paths, required this.initialIndex});

  final List<String> paths;
  final int initialIndex;

  @override
  State<_ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<_ImageViewerPage> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.paths.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) {
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: Image.file(
                      File(widget.paths[i]),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 64,
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            if (widget.paths.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_index + 1} / ${widget.paths.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
