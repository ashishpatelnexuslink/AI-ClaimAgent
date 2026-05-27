import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:claim_ai/core/constants/api_constants.dart';
import 'package:claim_ai/core/constants/app_theme.dart';
import 'package:claim_ai/core/l10n/generated/app_localizations.dart';
import 'package:claim_ai/core/network/dio_client.dart';
import 'package:claim_ai/features/assistant/presentation/widgets/voice_mode/triggers/image_trigger.dart' as img_trigger;
import 'package:claim_ai/core/platform/android_downloads.dart';
import 'package:claim_ai/core/utils/date_utils.dart';
import 'package:claim_ai/core/widgets/loading_widget.dart';
import 'package:claim_ai/core/widgets/error_widget.dart';
import 'package:claim_ai/features/assistant/presentation/widgets/sample_images_dialog.dart';
import 'package:claim_ai/features/claims/data/datasources/claims_remote_datasource.dart';
import 'package:claim_ai/features/claims/domain/entities/claim_entity.dart';
import 'package:claim_ai/features/claims/presentation/cubit/claims_cubit.dart';
import 'package:claim_ai/features/claims/presentation/cubit/claims_state.dart';
import 'package:claim_ai/injection_container.dart' as di;

class ClaimDetailPage extends StatefulWidget {
  final String claimId;

  const ClaimDetailPage({super.key, required this.claimId});

  @override
  State<ClaimDetailPage> createState() => _ClaimDetailPageState();
}

class _ClaimDetailPageState extends State<ClaimDetailPage> {
  final _imagePicker = ImagePicker();

  List<Map<String, dynamic>> _documents = const [];
  bool _documentsLoading = false;
  _TemplateSettings? _templateSettings;
  // Tracked per (groupKey, angle) so multiple buttons in the same group
  // (front_left, front_right, …) can show their own busy state.
  final Set<String> _busyKeys = {};
  final Set<String> _deletingIds = {};
  final Set<String> _downloadingDocs = {};

  String _busyKey(String groupKey, String? angle) =>
      '$groupKey::${angle ?? ''}';

  static const _allowedDocExtensions = ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'];

  @override
  void initState() {
    super.initState();
    context.read<ClaimsCubit>().fetchClaimDetail(widget.claimId);
    _loadDocuments();
    _loadActiveTemplate();
  }

  /// Pulls the single Active template from `/mobile/templates/active` so the
  /// documents card can render groups dynamically from `photoSettings` /
  /// `documentSettings`. Failure leaves `_templateSettings` null and the
  /// section renders a "no template configured" empty state.
  ///
  /// `Accept-Language` is attached automatically by [ApiInterceptor] so the
  /// backend substitutes localized Label / Instruction values from the
  /// template translation tables.
  Future<void> _loadActiveTemplate() async {
    try {
      final response =
          await di.sl<DioClient>().get(ApiConstants.activeTemplate);
      final data = response.data;
      final payload = (data is Map && data['data'] is Map)
          ? data['data'] as Map<String, dynamic>
          : (data is Map<String, dynamic> ? data : null);
      if (payload == null || !mounted) return;
      setState(() {
        _templateSettings = _TemplateSettings.fromJson(payload);
      });
    } catch (e) {
      // Non-fatal; the documents card just shows an empty state.
      // ignore: avoid_print
      debugPrint('[ClaimDetail] failed to load active template: $e');
    }
  }

  Future<void> _loadDocuments() async {
    setState(() => _documentsLoading = true);
    try {
      final docs = await di
          .sl<ClaimsRemoteDataSource>()
          .getDocumentsByClaim(widget.claimId);
      if (!mounted) return;
      setState(() {
        _documents = docs;
        _documentsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _documentsLoading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  bool _isEditable() {
    final claim = context.read<ClaimsCubit>().state.selectedClaim;
    return claim?.status == ClaimStatus.pending;
  }

  Future<void> _pickAndUploadPhoto({
    required String groupKey,
    required String label,
    String? angle,
  }) async {
    if (!_isEditable()) return;
    final busyKey = _busyKey(groupKey, angle);
    if (_busyKeys.contains(busyKey)) return;

    final l = AppLocalizations.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l.claimDetail_takePhoto),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l.claimDetail_chooseFromGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;

    setState(() => _busyKeys.add(busyKey));
    try {
      final ds = di.sl<ClaimsRemoteDataSource>();
      final bytes = await File(picked.path).readAsBytes();
      final name = picked.path.split(RegExp(r'[\\/]')).last;
      final response = await ds.uploadClaimDocument(
        bytes: bytes,
        fileName: name.isEmpty ? 'image.jpg' : name,
        kind: 'Image',
        groupKey: groupKey,
        label: label,
        angle: angle,
      );
      final id = (response['id'] ?? '').toString();
      if (id.isNotEmpty) {
        await ds.attachClaimDocuments(
          claimId: widget.claimId,
          documentIds: [id],
        );
      }
      await _loadDocuments();
      if (mounted) _snack(AppLocalizations.of(context).claimDetail_photoUploaded);
    } catch (e) {
      if (mounted) {
        _snack(AppLocalizations.of(context)
            .claimDetail_uploadFailed(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _busyKeys.remove(busyKey));
    }
  }

  Future<void> _pickAndUploadDocument({
    required String groupKey,
    required String label,
  }) async {
    if (!_isEditable()) return;
    final busyKey = _busyKey(groupKey, null);
    if (_busyKeys.contains(busyKey)) return;

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: _allowedDocExtensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) return;

    setState(() => _busyKeys.add(busyKey));
    try {
      final ds = di.sl<ClaimsRemoteDataSource>();
      final uploadedIds = <String>[];
      for (final f in result.files) {
        List<int> bytes;
        if (f.bytes != null) {
          bytes = f.bytes!;
        } else if (f.path != null) {
          bytes = await File(f.path!).readAsBytes();
        } else {
          continue;
        }
        final ext = (f.extension ?? '').toLowerCase();
        final isImage = const {'jpg', 'jpeg', 'png'}.contains(ext);
        final response = await ds.uploadClaimDocument(
          bytes: bytes,
          fileName: f.name,
          kind: isImage ? 'Image' : 'Document',
          groupKey: groupKey,
          label: label,
        );
        final id = (response['id'] ?? '').toString();
        if (id.isNotEmpty) uploadedIds.add(id);
      }
      if (uploadedIds.isNotEmpty) {
        await ds.attachClaimDocuments(
          claimId: widget.claimId,
          documentIds: uploadedIds,
        );
      }
      await _loadDocuments();
      if (mounted) {
        _snack(AppLocalizations.of(context)
            .claimDetail_filesUploaded(uploadedIds.length));
      }
    } catch (e) {
      if (mounted) {
        _snack(AppLocalizations.of(context)
            .claimDetail_uploadFailed(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _busyKeys.remove(busyKey));
    }
  }

  Future<Directory> _resolveDownloadsDir() async {
    if (Platform.isAndroid) {
      final publicDownloads = Directory('/storage/emulated/0/Download');
      if (await publicDownloads.exists()) return publicDownloads;
      try {
        await publicDownloads.create(recursive: true);
        return publicDownloads;
      } catch (_) {
        final ext = await getExternalStorageDirectory();
        if (ext != null) return ext;
      }
    }
    return getApplicationDocumentsDirectory();
  }

  Future<bool> _ensureStoragePermission() async {
    if (!Platform.isAndroid) return true;
    // Only reachable on Android 9 and below (Q+ writes via MediaStore through
    // the platform channel, no permission needed).
    return Permission.storage.request().isGranted;
  }

  String _uniqueFilePath(String dir, String name) {
    final dot = name.lastIndexOf('.');
    final base = dot > 0 ? name.substring(0, dot) : name;
    final ext = dot > 0 ? name.substring(dot) : '';
    var candidate = '$dir/$name';
    var i = 1;
    while (File(candidate).existsSync()) {
      candidate = '$dir/$base ($i)$ext';
      i++;
    }
    return candidate;
  }

  Future<void> _downloadDoc(String url, String name) async {
    if (url.isEmpty) return;
    if (_downloadingDocs.contains(url)) return;
    final l = AppLocalizations.of(context);
    setState(() => _downloadingDocs.add(url));
    try {
      final safeName = name.trim().isEmpty ? 'document.pdf' : name.trim();

      if (Platform.isIOS) {
        // iOS app sandbox isn't user-visible, so download to a temp file and
        // hand it to the system share sheet (Save to Files, AirDrop, …).
        final tempDir = await getTemporaryDirectory();
        final filePath = _uniqueFilePath(tempDir.path, safeName);
        await di.sl<DioClient>().dio.download(url, filePath);
        if (!mounted) return;
        // iPad anchors the popover to this rect; iOS also rejects an empty
        // rect, so derive a real one from the page's render box.
        final box = context.findRenderObject() as RenderBox?;
        final origin = (box != null && box.hasSize)
            ? box.localToGlobal(Offset.zero) & box.size
            : const Rect.fromLTWH(0, 0, 1, 1);
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: safeName,
          sharePositionOrigin: origin,
        );
      } else if (Platform.isAndroid) {
        final tempDir = await getTemporaryDirectory();
        final tempPath = _uniqueFilePath(tempDir.path, safeName);
        await di.sl<DioClient>().dio.download(url, tempPath);
        try {
          await AndroidDownloads.saveToDownloads(
            srcPath: tempPath,
            fileName: safeName,
            mimeType: _mimeForName(safeName),
          );
          _snack(l.claimDetail_savedToDownloads);
        } on PlatformException catch (e) {
          if (e.code == 'UNSUPPORTED') {
            // Android 9 and below — keep the legacy permission flow.
            if (!await _ensureStoragePermission()) {
              _snack(l.claimDetail_storagePermissionDenied);
              return;
            }
            final dir = await _resolveDownloadsDir();
            final dest = _uniqueFilePath(dir.path, safeName);
            await File(tempPath).copy(dest);
            _snack(l.claimDetail_savedTo(dest));
          } else {
            rethrow;
          }
        } finally {
          try {
            await File(tempPath).delete();
          } catch (_) {}
        }
      } else {
        if (!await _ensureStoragePermission()) {
          _snack(l.claimDetail_storagePermissionDenied);
          return;
        }
        final dir = await _resolveDownloadsDir();
        final filePath = _uniqueFilePath(dir.path, safeName);
        await di.sl<DioClient>().dio.download(url, filePath);
        _snack(l.claimDetail_savedTo(filePath));
      }
    } catch (e) {
      _snack(l.claimDetail_downloadFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _downloadingDocs.remove(url));
    }
  }

  String _mimeForName(String name) {
    final i = name.lastIndexOf('.');
    if (i < 0) return 'application/octet-stream';
    switch (name.substring(i + 1).toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _deleteDoc(String id) async {
    if (!_isEditable()) return;
    if (id.isEmpty || _deletingIds.contains(id)) return;
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.claimDetail_removeDocumentTitle),
        content: Text(l.claimDetail_removeDocumentBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.common_delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deletingIds.add(id));
    try {
      await di.sl<ClaimsRemoteDataSource>().deleteClaimDocument(id);
      await _loadDocuments();
    } catch (e) {
      _snack(l.claimDetail_deleteFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _deletingIds.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).claimDetail_appBarTitle),
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 16, color: AppColors.textPrimary),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.account_balance_wallet_outlined,
                  size: 18, color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: BlocBuilder<ClaimsCubit, ClaimsState>(
        builder: (context, state) {
          if (state.isLoading && state.selectedClaim == null) {
            return const LoadingWidget();
          }

          if (state.errorMessage != null && state.selectedClaim == null) {
            return AppErrorWidget(
              message: state.errorMessage!,
              onRetry: () =>
                  context.read<ClaimsCubit>().fetchClaimDetail(widget.claimId),
            );
          }

          final claim = state.selectedClaim;
          if (claim == null) {
            return AppErrorWidget(
                message: AppLocalizations.of(context).claimDetail_notFound);
          }

          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                context.read<ClaimsCubit>().fetchClaimDetail(widget.claimId),
                _loadDocuments(),
              ]);
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _PolicyDetailsCard(claim: claim),
                const SizedBox(height: AppSpacing.md),
                _AccidentInfoCard(
                  claim: claim,
                  onUpdated: () =>
                      context.read<ClaimsCubit>().fetchClaimDetail(widget.claimId),
                ),
                const SizedBox(height: AppSpacing.md),
                _DocumentsCard(
                  claim: claim,
                  documents: _documents,
                  loading: _documentsLoading,
                  templateSettings: _templateSettings,
                  busyKeys: _busyKeys,
                  deletingIds: _deletingIds,
                  onUploadPhoto: _pickAndUploadPhoto,
                  onUploadDocument: _pickAndUploadDocument,
                  onDeleteDoc: _deleteDoc,
                  onDownloadDoc: _downloadDoc,
                  downloadingDocs: _downloadingDocs,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Policy Details Card ─────────────────────────────────────────────────

class _PolicyDetailsCard extends StatelessWidget {
  final ClaimEntity claim;
  const _PolicyDetailsCard({required this.claim});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.claimDetail_policyDetails,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _StatusPill(status: claim.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _kv(l.claimDetail_policyHolder, claim.fullName ?? '—'),
          _kv(l.claimDetail_policyNumber,
              claim.policyNumber != null ? '#${claim.policyNumber}' : '—'),
          _kv(l.claimDetail_vehicle, claim.vehicleModel ?? '—'),
          _kv(l.claimDetail_platNumber,
              claim.vehicleRegistrationNumber ?? '—'),
          _kv(l.claimDetail_vinNumber, claim.vinNumber ?? '—'),
          _kv(l.claimDetail_coverage, claim.claimType),
          _kv(
            l.claimDetail_identityVerified,
            claim.identityVerified == null
                ? '—'
                : (claim.identityVerified! ? l.common_yes : l.common_no),
            highlight: claim.identityVerified == true,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, {bool highlight = false, bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              '$k:',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 7,
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: highlight
                    ? AppColors.success
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Accident Info Card ──────────────────────────────────────────────────

class _AccidentInfoCard extends StatefulWidget {
  final ClaimEntity claim;
  final VoidCallback onUpdated;
  const _AccidentInfoCard({required this.claim, required this.onUpdated});

  @override
  State<_AccidentInfoCard> createState() => _AccidentInfoCardState();
}

class _AccidentInfoCardState extends State<_AccidentInfoCard> {
  bool _editing = false;
  bool _saving = false;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  DateTime? _incidentDate;

  @override
  void initState() {
    super.initState();
    _locationController =
        TextEditingController(text: widget.claim.incidentLocation ?? '');
    _descriptionController = TextEditingController(
      text: widget.claim.incidentDescription ?? '',
    );
    _incidentDate = widget.claim.incidentDate;
  }

  @override
  void didUpdateWidget(covariant _AccidentInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh form values when the parent reloads the claim after a save.
    if (!_editing && widget.claim != oldWidget.claim) {
      _locationController.text = widget.claim.incidentLocation ?? '';
      _descriptionController.text =
          widget.claim.incidentDescription ?? '';
      _incidentDate = widget.claim.incidentDate;
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _enterEditMode() {
    setState(() {
      _locationController.text = widget.claim.incidentLocation ?? '';
      _descriptionController.text =
          widget.claim.incidentDescription ?? '';
      _incidentDate = widget.claim.incidentDate;
      _editing = true;
    });
  }

  void _cancelEdit() {
    setState(() => _editing = false);
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initial = _incidentDate ?? now;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (!mounted) return;
    final time = pickedTime ?? TimeOfDay.fromDateTime(initial);
    setState(() {
      _incidentDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await di.sl<ClaimsRemoteDataSource>().updateAccidentInfo(
            id: widget.claim.id,
            incidentDate: _incidentDate,
            incidentLocation: _locationController.text.trim().isEmpty
                ? null
                : _locationController.text.trim(),
            incidentDescription: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _editing = false;
        _saving = false;
      });
      widget.onUpdated();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context).claimDetail_updatedSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)
              .claimDetail_updateFailed(e.toString())),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = widget.claim.status == ClaimStatus.pending;
    final l = AppLocalizations.of(context);
    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.claimDetail_accidentInformation,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (canEdit && !_editing)
                IconButton(
                  icon: Icon(Icons.edit_outlined,
                      size: 18, color: Colors.grey.shade600),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _enterEditMode,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_editing) _buildEditMode() else _buildViewMode(),
        ],
      ),
    );
  }

  Widget _buildViewMode() {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final date = widget.claim.incidentDate;
    final dateText = date != null
        ? '${AppDateUtils.formatDate(date, locale)}, ${AppDateUtils.formatTime(date, locale)}'
        : '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row(l.claimDetail_dateTime, dateText),
        _row(l.claimDetail_location, widget.claim.incidentLocation ?? '—'),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.claimDetail_descriptionWithColon,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.claim.incidentDescription ?? '—',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditMode() {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final dateLabel = _incidentDate != null
        ? '${AppDateUtils.formatDate(_incidentDate!, locale)}, ${AppDateUtils.formatTime(_incidentDate!, locale)}'
        : l.claimDetail_selectDateTime;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(l.claimDetail_dateTime),
        InkWell(
          onTap: _saving ? null : _pickDateTime,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_outlined,
                    size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dateLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _incidentDate == null
                          ? AppColors.textHint
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down,
                    color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _FieldLabel(l.claimDetail_location),
        TextField(
          controller: _locationController,
          enabled: !_saving,
          decoration: InputDecoration(
            hintText: l.claimDetail_locationHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _FieldLabel(l.claimDetail_descriptionLabel),
        TextField(
          controller: _descriptionController,
          enabled: !_saving,
          minLines: 3,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: l.claimDetail_descriptionHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : _cancelEdit,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(l.common_cancel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(l.common_save),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(String k, String v) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              '$k:',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 8,
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ─── Documents Card ──────────────────────────────────────────────────────

class _DocumentsCard extends StatelessWidget {
  final ClaimEntity claim;
  final List<Map<String, dynamic>> documents;
  final bool loading;
  final _TemplateSettings? templateSettings;
  final Set<String> busyKeys;
  final Set<String> deletingIds;
  final Future<void> Function({
    required String groupKey,
    required String label,
    String? angle,
  }) onUploadPhoto;
  final Future<void> Function({
    required String groupKey,
    required String label,
  }) onUploadDocument;
  final Future<void> Function(String id) onDeleteDoc;
  final Future<void> Function(String url, String name) onDownloadDoc;
  final Set<String> downloadingDocs;

  const _DocumentsCard({
    required this.claim,
    required this.documents,
    required this.loading,
    required this.templateSettings,
    required this.busyKeys,
    required this.deletingIds,
    required this.onUploadPhoto,
    required this.onUploadDocument,
    required this.onDeleteDoc,
    required this.onDownloadDoc,
    required this.downloadingDocs,
  });

  @override
  Widget build(BuildContext context) {
    final canEdit = claim.status == ClaimStatus.pending;
    final settings = templateSettings;

    final sections = <Widget>[];
    if (settings != null) {
      for (final ps in settings.photoSettings) {
        if (sections.isNotEmpty) sections.add(const _SectionDivider());
        final groupDocs = _ofGroup(ps.groupKey);
        sections.add(_PhotoSection(
          title: ps.label.toUpperCase(),
          groupKey: ps.groupKey,
          label: ps.label,
          photos: groupDocs,
          minCount: ps.minCount,
          maxCount: ps.maxCount,
          allowedAngles: ps.allowedAngles,
          showSample: ps.showSample,
          sampleImageUrls: ps.sampleImageUrls,
          busyKeys: busyKeys,
          deletingIds: deletingIds,
          canEdit: canEdit,
          onUpload: onUploadPhoto,
          onDelete: onDeleteDoc,
        ));
      }
      for (final ds in settings.documentSettings) {
        if (sections.isNotEmpty) sections.add(const _SectionDivider());
        final groupDocs = _ofGroup(ds.docKey);
        sections.add(_FilesSection(
          title: ds.label.toUpperCase(),
          groupKey: ds.docKey,
          label: ds.label,
          docs: groupDocs,
          minCount: ds.minCount,
          maxCount: ds.maxCount,
          busyKeys: busyKeys,
          deletingIds: deletingIds,
          canEdit: canEdit,
          onUpload: onUploadDocument,
          onDelete: onDeleteDoc,
          onDownload: onDownloadDoc,
          downloadingDocs: downloadingDocs,
        ));
      }
    }

    final l = AppLocalizations.of(context);
    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.claimDetail_documentsCount(documents.length),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (loading || settings == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (sections.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                l.claimDetail_noTemplate,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            ...sections,
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _ofGroup(String groupKey) {
    return documents
        .where((d) => (d['groupKey'] ?? '').toString() == groupKey)
        .toList();
  }
}

class _PhotoSection extends StatelessWidget {
  final String title;
  final String groupKey;
  final String label;
  final List<Map<String, dynamic>> photos;
  final int minCount;
  final int maxCount;
  final List<String> allowedAngles;
  final bool showSample;
  final List<String> sampleImageUrls;
  final Set<String> busyKeys;
  final Set<String> deletingIds;
  final bool canEdit;
  final Future<void> Function({
    required String groupKey,
    required String label,
    String? angle,
  }) onUpload;
  final Future<void> Function(String id) onDelete;

  const _PhotoSection({
    required this.title,
    required this.groupKey,
    required this.label,
    required this.photos,
    required this.minCount,
    required this.maxCount,
    required this.allowedAngles,
    required this.busyKeys,
    required this.deletingIds,
    required this.onUpload,
    required this.onDelete,
    this.showSample = false,
    this.sampleImageUrls = const [],
    this.canEdit = true,
  });

  /// Quota shown next to the photo count. Falls back to angle count when the
  /// template doesn't specify min/max.
  int get _quota {
    if (maxCount > 0) return maxCount;
    if (minCount > 0) return minCount;
    if (allowedAngles.isNotEmpty) return allowedAngles.length;
    return 1;
  }

  String _humanizeAngle(BuildContext context, String angle) {
    if (angle.isEmpty) return angle;
    // Reuse the shared localized humanizer so "front_left" becomes
    // "Vorne links" in German, "Front Left" in English, etc. The claim
    // summary page renders angles in all-caps to match the section header
    // style, so uppercase the localized result.
    return img_trigger
        .humanizeAngle(angle, AppLocalizations.of(context))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final uploadedAngles = <String>{
      for (final p in photos) (p['angle'] ?? '').toString(),
    };

    // For an allowed-angles group, "pending" angles are those without a doc.
    final pendingAngles = allowedAngles
        .where((a) => !uploadedAngles.contains(a))
        .toList(growable: false);

    final canStillAdd = canEdit && photos.length < _quota;
    final canShowSample = showSample;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            if (canShowSample)
              GestureDetector(
                onTap: () {
                  showSampleImagesDialog(
                    context: context,
                    assetPaths: const [
                      'assets/images/damage_photos_sample.png',
                    ],
                    labels: const [],
                  );
                },
                child: Text(
                  AppLocalizations.of(context).claimDetail_seeSample,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (photos.isEmpty)
          _EmptyRow(label: AppLocalizations.of(context).claimDetail_noPhotos)
        else
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final p = photos[i];
                final url = (p['url'] ?? '').toString();
                final id = (p['id'] ?? '').toString();
                final angle = (p['angle'] ?? '').toString();
                return SizedBox(
                  width: 76,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _PhotoThumb(
                        url: url,
                        deleting: deletingIds.contains(id),
                        onDelete: (!canEdit || id.isEmpty)
                            ? null
                            : () => onDelete(id),
                        onTap: url.isEmpty
                            ? null
                            : () {
                                final urls = photos
                                    .map((e) => (e['url'] ?? '').toString())
                                    .where((u) => u.isNotEmpty)
                                    .toList();
                                final initial = urls.indexOf(url);
                                _showImageViewer(
                                  ctx,
                                  urls,
                                  initial < 0 ? 0 : initial,
                                );
                              },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        angle.isEmpty ? '—' : _humanizeAngle(context, angle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppLocalizations.of(context)
              .claimDetail_quotaUploaded(photos.length, _quota),
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (canEdit) ...[
          const SizedBox(height: AppSpacing.sm),
          if (allowedAngles.isEmpty) ...[
            // Free-form group — single generic button gated by quota.
            if (canStillAdd)
              _UploadButton(
                busy: busyKeys.contains('$groupKey::'),
                onTap: () => onUpload(groupKey: groupKey, label: label),
              ),
          ] else if (pendingAngles.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final angle in pendingAngles)
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - 96) / 3,
                    child: _TagButton(
                      icon: Icons.camera_alt_outlined,
                      label: _humanizeAngle(context, angle),
                      busy: busyKeys.contains('$groupKey::$angle'),
                      onTap: canStillAdd
                          ? () => onUpload(
                                groupKey: groupKey,
                                label: label,
                                angle: angle,
                              )
                          : null,
                    ),
                  ),
              ],
            ),
        ],
      ],
    );
  }
}

class _FilesSection extends StatelessWidget {
  final String title;
  final String groupKey;
  final String label;
  final List<Map<String, dynamic>> docs;
  final int minCount;
  final int maxCount;
  final Set<String> busyKeys;
  final Set<String> deletingIds;
  final bool canEdit;
  final Future<void> Function({
    required String groupKey,
    required String label,
  }) onUpload;
  final Future<void> Function(String id) onDelete;
  final Future<void> Function(String url, String name) onDownload;
  final Set<String> downloadingDocs;

  const _FilesSection({
    required this.title,
    required this.groupKey,
    required this.label,
    required this.docs,
    required this.minCount,
    required this.maxCount,
    required this.busyKeys,
    required this.deletingIds,
    required this.onUpload,
    required this.onDelete,
    required this.onDownload,
    required this.downloadingDocs,
    this.canEdit = true,
  });

  int get _quota {
    if (maxCount > 0) return maxCount;
    if (minCount > 0) return minCount;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final quota = _quota;
    final canUpload = canEdit && docs.length < quota;
    final busy = busyKeys.contains('$groupKey::');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (docs.isEmpty)
          _EmptyRow(
              label: AppLocalizations.of(context).claimDetail_noDocuments)
        else
          ...docs.map((d) {
            final id = (d['id'] ?? '').toString();
            final url = (d['url'] ?? '').toString();
            final name = (d['fileName'] ?? 'file').toString();
            return _FileRow(
              name: name,
              sizeBytes: (d['fileSize'] as num?)?.toInt() ?? 0,
              deleting: deletingIds.contains(id),
              onDelete: (!canEdit || id.isEmpty)
                  ? null
                  : () => onDelete(id),
              downloading: downloadingDocs.contains(url),
              onDownload: url.isEmpty ? null : () => onDownload(url, name),
            );
          }),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppLocalizations.of(context)
              .claimDetail_quotaUploaded(docs.length, quota),
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (canEdit) ...[
          const SizedBox(height: AppSpacing.sm),
          _UploadButton(
            busy: busy,
            onTap: canUpload && !busy
                ? () => onUpload(groupKey: groupKey, label: label)
                : null,
          ),
        ],
      ],
    );
  }
}

void _showImageViewer(
  BuildContext context,
  List<String> urls,
  int initialIndex,
) {
  if (urls.isEmpty) return;
  final controller = PageController(initialPage: initialIndex);
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    builder: (ctx) {
      return Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(ctx).pop(),
            behavior: HitTestBehavior.opaque,
            child: PageView.builder(
              controller: controller,
              itemCount: urls.length,
              itemBuilder: (_, i) {
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 5,
                  child: Center(
                    child: Image.network(
                      urls[i],
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 64,
                      ),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: MediaQuery.of(ctx).padding.top + 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ),
        ],
      );
    },
  );
}

class _PhotoThumb extends StatelessWidget {
  final String url;
  final bool deleting;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const _PhotoThumb({
    required this.url,
    this.deleting = false,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final thumb = Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        image: url.isEmpty
            ? null
            : DecorationImage(
                image: NetworkImage(url),
                fit: BoxFit.cover,
              ),
      ),
      child: url.isEmpty
          ? const Icon(Icons.image_not_supported_outlined,
              color: AppColors.textHint)
          : null,
    );
    return Stack(
      children: [
        (onTap != null && url.isNotEmpty)
            ? GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: thumb,
              )
            : thumb,
        if (onDelete != null)
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: deleting ? null : onDelete,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: deleting
                    ? const Padding(
                        padding: EdgeInsets.all(4),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.close,
                        size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

class _FileRow extends StatelessWidget {
  final String name;
  final int sizeBytes;
  final bool deleting;
  final VoidCallback? onDelete;
  final bool downloading;
  final VoidCallback? onDownload;
  const _FileRow({
    required this.name,
    required this.sizeBytes,
    this.deleting = false,
    this.onDelete,
    this.downloading = false,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final sizeKb = sizeBytes > 0 ? sizeBytes ~/ 1024 : 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.picture_as_pdf_outlined,
                size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sizeKb > 0
                      ? AppLocalizations.of(context)
                          .claimDetail_documentWithSize(sizeKb)
                      : AppLocalizations.of(context).claimDetail_document,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (onDownload != null)
            downloading
                ? const Padding(
                    padding: EdgeInsets.all(4),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : GestureDetector(
                    onTap: onDownload,
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.file_download_outlined,
                          size: 20, color: AppColors.primary),
                    ),
                  ),
          if (onDelete != null) ...[
            const SizedBox(width: 4),
            if (deleting)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              GestureDetector(
                onTap: onDelete,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close,
                      size: 18, color: Colors.grey.shade500),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TagButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool busy;
  final VoidCallback? onTap;

  const _TagButton({
    required this.icon,
    required this.label,
    this.busy = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !busy;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF3EEFB),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(icon, size: 14, color: AppColors.textPrimary),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadButton extends StatelessWidget {
  final bool busy;
  final VoidCallback? onTap;

  const _UploadButton({this.busy = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !busy;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3EEFB),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.camera_alt_outlined,
                    size: 16, color: AppColors.textPrimary),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context).claimDetail_uploadButton,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final String label;
  const _EmptyRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textHint,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Divider(height: 1, color: AppColors.divider),
    );
  }
}

// ─── Shared card + status pill ───────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final Widget child;
  const _DetailCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: child,
    );
  }
}

class _StatusPill extends StatelessWidget {
  final ClaimStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (Color bg, Color fg, String label) = switch (status) {
      ClaimStatus.draft => (const Color(0xFFE8EAED), const Color(0xFF5F6368), l.claim_status_draft),
      ClaimStatus.pending => (const Color(0xFFFFE7B8), const Color(0xFFB76E00), l.claim_status_pending),
      ClaimStatus.submitted => (const Color(0xFFD7E7FD), const Color(0xFF1557B0), l.claim_status_submitted),
      ClaimStatus.inReview => (const Color(0xFFEADFFD), const Color(0xFF6A3BD6), l.claim_status_needInfo),
      ClaimStatus.approved => (const Color(0xFFD5F1DE), const Color(0xFF0E7C3A), l.claim_status_approved),
      ClaimStatus.rejected => (const Color(0xFFFBDAD7), const Color(0xFFB3261E), l.claim_status_rejected),
      ClaimStatus.closed => (const Color(0xFFE8EAED), const Color(0xFF5F6368), l.claim_status_closed),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.round),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Template settings DTOs ──────────────────────────────────────────────
//
// Subset of the backend `TemplateDetailDto` that the documents card needs.
// Decoded from `/api/mobile/templates/active`. Mirrors the same shape used
// in `claim_chat_screen.dart` — kept private here to avoid coupling the two
// pages, since the chat flow may evolve independently.

class _TemplateSettings {
  final List<_PhotoSettingDto> photoSettings;
  final List<_DocumentSettingDto> documentSettings;
  const _TemplateSettings({
    required this.photoSettings,
    required this.documentSettings,
  });

  factory _TemplateSettings.fromJson(Map<String, dynamic> json) {
    final photos = (json['photoSettings'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_PhotoSettingDto.fromJson)
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    final docs = (json['documentSettings'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_DocumentSettingDto.fromJson)
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return _TemplateSettings(photoSettings: photos, documentSettings: docs);
  }
}

class _PhotoSettingDto {
  final String groupKey;
  final String label;
  final int minCount;
  final int maxCount;
  final bool isRequired;
  final List<String> allowedAngles;
  final bool showSample;
  final List<String> sampleImageUrls;
  final int displayOrder;

  const _PhotoSettingDto({
    required this.groupKey,
    required this.label,
    required this.minCount,
    required this.maxCount,
    required this.isRequired,
    required this.allowedAngles,
    required this.showSample,
    required this.sampleImageUrls,
    required this.displayOrder,
  });

  factory _PhotoSettingDto.fromJson(Map<String, dynamic> json) {
    return _PhotoSettingDto(
      groupKey: (json['groupKey'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      minCount: (json['minCount'] as num?)?.toInt() ?? 0,
      maxCount: (json['maxCount'] as num?)?.toInt() ?? 0,
      isRequired: json['isRequired'] == true,
      allowedAngles: (json['allowedAngles'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
      showSample: json['showSample'] == true,
      sampleImageUrls: (json['sampleImageUrls'] as List? ?? const [])
          .map((e) => e.toString())
          .where((s) => s.isNotEmpty)
          .toList(),
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

class _DocumentSettingDto {
  final String docKey;
  final String label;
  final int minCount;
  final int maxCount;
  final bool isRequired;
  final int displayOrder;

  const _DocumentSettingDto({
    required this.docKey,
    required this.label,
    required this.minCount,
    required this.maxCount,
    required this.isRequired,
    required this.displayOrder,
  });

  factory _DocumentSettingDto.fromJson(Map<String, dynamic> json) {
    return _DocumentSettingDto(
      docKey: (json['docKey'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      minCount: (json['minCount'] as num?)?.toInt() ?? 0,
      maxCount: (json['maxCount'] as num?)?.toInt() ?? 0,
      isRequired: json['isRequired'] == true,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
    );
  }
}
