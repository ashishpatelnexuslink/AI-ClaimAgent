import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:claim_ai/core/constants/app_theme.dart';
import 'package:claim_ai/core/utils/date_utils.dart';
import 'package:claim_ai/core/widgets/loading_widget.dart';
import 'package:claim_ai/core/widgets/error_widget.dart';
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
  final Set<String> _busyCategories = {};
  final Set<String> _deletingIds = {};

  static const _allowedDocExtensions = ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'];

  @override
  void initState() {
    super.initState();
    context.read<ClaimsCubit>().fetchClaimDetail(widget.claimId);
    _loadDocuments();
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

  Future<void> _pickAndUploadPhoto(String category) async {
    if (!_isEditable()) return;
    if (_busyCategories.contains(category)) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
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

    setState(() => _busyCategories.add(category));
    try {
      final ds = di.sl<ClaimsRemoteDataSource>();
      final bytes = await File(picked.path).readAsBytes();
      final name = picked.path.split(RegExp(r'[\\/]')).last;
      final response = await ds.uploadClaimDocument(
        bytes: bytes,
        fileName: name.isEmpty ? 'image.jpg' : name,
        kind: 'Image',
        category: category,
      );
      final id = (response['id'] ?? '').toString();
      if (id.isNotEmpty) {
        await ds.attachClaimDocuments(
          claimId: widget.claimId,
          documentIds: [id],
        );
      }
      await _loadDocuments();
      _snack('Photo uploaded');
    } catch (e) {
      _snack('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _busyCategories.remove(category));
    }
  }

  Future<void> _pickAndUploadDocument(String category) async {
    if (!_isEditable()) return;
    if (_busyCategories.contains(category)) return;

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: _allowedDocExtensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) return;

    setState(() => _busyCategories.add(category));
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
          category: category,
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
      _snack('${uploadedIds.length} file(s) uploaded');
    } catch (e) {
      _snack('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _busyCategories.remove(category));
    }
  }

  Future<void> _deleteDoc(String id) async {
    if (!_isEditable()) return;
    if (id.isEmpty || _deletingIds.contains(id)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove document?'),
        content: const Text('This will permanently delete the file.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
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
      _snack('Delete failed: $e');
    } finally {
      if (mounted) setState(() => _deletingIds.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Claim Summary'),
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
            return const AppErrorWidget(message: 'Claim not found');
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
                _AccidentInfoCard(claim: claim),
                const SizedBox(height: AppSpacing.md),
                _DocumentsCard(
                  claim: claim,
                  documents: _documents,
                  loading: _documentsLoading,
                  busyCategories: _busyCategories,
                  deletingIds: _deletingIds,
                  onUploadPhoto: _pickAndUploadPhoto,
                  onUploadDocument: _pickAndUploadDocument,
                  onDeleteDoc: _deleteDoc,
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
    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Policy Details',
                  style: TextStyle(
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
          _kv('Policy Holder', claim.fullName ?? claim.patientName ?? '—'),
          _kv('Policy Number',
              claim.policyNumber != null ? '#${claim.policyNumber}' : '—'),
          _kv('Vehicle', claim.vehicleModel ?? '—'),
          _kv('Plat Number', claim.vehicleNumber ?? '—'),
          _kv('VIN Number', claim.vinNumber ?? '—'),
          _kv('Coverage', claim.coverageType ?? claim.claimType),
          _kv(
            'Identity Verified',
            claim.identityVerified == null
                ? '—'
                : (claim.identityVerified! ? 'Yes' : 'No'),
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

class _AccidentInfoCard extends StatelessWidget {
  final ClaimEntity claim;
  const _AccidentInfoCard({required this.claim});

  @override
  Widget build(BuildContext context) {
    final date = claim.incidentDate;
    final dateText = date != null
        ? '${AppDateUtils.formatDate(date)}, ${AppDateUtils.formatTime(date)}'
        : '—';

    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Accident Information',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (claim.status == ClaimStatus.pending)
                Icon(Icons.edit_outlined,
                    size: 18, color: Colors.grey.shade600),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _row('Date & Time', dateText),
          _row('Location', claim.incidentLocation ?? '—'),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Description:',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  claim.incidentDescription ?? claim.description ?? '—',
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
      ),
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

// ─── Documents Card ──────────────────────────────────────────────────────

class _DocumentsCard extends StatelessWidget {
  final ClaimEntity claim;
  final List<Map<String, dynamic>> documents;
  final bool loading;
  final Set<String> busyCategories;
  final Set<String> deletingIds;
  final Future<void> Function(String category) onUploadPhoto;
  final Future<void> Function(String category) onUploadDocument;
  final Future<void> Function(String id) onDeleteDoc;

  const _DocumentsCard({
    required this.claim,
    required this.documents,
    required this.loading,
    required this.busyCategories,
    required this.deletingIds,
    required this.onUploadPhoto,
    required this.onUploadDocument,
    required this.onDeleteDoc,
  });

  @override
  Widget build(BuildContext context) {
    final canEdit = claim.status == ClaimStatus.pending;
    final vehiclePhotos = _ofCategory('VehiclePhoto');
    final damagePhotos = _ofCategory('DamagePhoto');
    final licensePhotos = _ofCategory('DriverLicense');
    final billDocs = _ofCategory('BillInvoice');
    final policeDocs = _ofCategory('PoliceReport');
    final supporting = [
      ..._ofCategory('SupportingDocument'),
      ...policeDocs,
    ];

    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Documents (${documents.length})',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _PhotoSection(
              title: 'VEHICLE PHOTOS',
              photos: vehiclePhotos,
              quota: claim.vehiclePhotosCount == 0
                  ? 4
                  : claim.vehiclePhotosCount,
              category: 'VehiclePhoto',
              busy: busyCategories.contains('VehiclePhoto'),
              deletingIds: deletingIds,
              canEdit: canEdit,
              onUpload: onUploadPhoto,
              onDelete: onDeleteDoc,
            ),
            const _SectionDivider(),
            _PhotoSection(
              title: 'DAMAGED VEHICLE PHOTOS',
              photos: damagePhotos,
              quota: claim.damagePhotosCount == 0
                  ? 10
                  : claim.damagePhotosCount,
              category: 'DamagePhoto',
              busy: busyCategories.contains('DamagePhoto'),
              deletingIds: deletingIds,
              canEdit: canEdit,
              onUpload: onUploadPhoto,
              onDelete: onDeleteDoc,
            ),
            const _SectionDivider(),
            _FilesSection(
              title: 'BILL/INVOICE',
              docs: billDocs,
              quota: claim.repairBillCount == 0 ? 2 : claim.repairBillCount,
              category: 'BillInvoice',
              busy: busyCategories.contains('BillInvoice'),
              deletingIds: deletingIds,
              canEdit: canEdit,
              onUpload: onUploadDocument,
              onDelete: onDeleteDoc,
            ),
            const _SectionDivider(),
            _PhotoSection(
              title: "DRIVER'S LICENSE",
              photos: licensePhotos,
              quota: claim.licensePhotosCount == 0
                  ? 2
                  : claim.licensePhotosCount,
              category: 'DriverLicense',
              busy: busyCategories.contains('DriverLicense'),
              deletingIds: deletingIds,
              canEdit: canEdit,
              onUpload: onUploadPhoto,
              onDelete: onDeleteDoc,
            ),
            const _SectionDivider(),
            _FilesSection(
              title: 'SUPPORTING DOCUMENTS',
              docs: supporting,
              quota: 10,
              category: 'SupportingDocument',
              busy: busyCategories.contains('SupportingDocument'),
              deletingIds: deletingIds,
              canEdit: canEdit,
              onUpload: onUploadDocument,
              onDelete: onDeleteDoc,
            ),
          ],
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _ofCategory(String category) {
    return documents
        .where((d) => (d['category'] ?? '').toString() == category)
        .toList();
  }
}

class _PhotoSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> photos;
  final int quota;
  final String category;
  final bool busy;
  final Set<String> deletingIds;
  final bool canEdit;
  final Future<void> Function(String category) onUpload;
  final Future<void> Function(String id) onDelete;

  const _PhotoSection({
    required this.title,
    required this.photos,
    required this.quota,
    required this.category,
    required this.busy,
    required this.deletingIds,
    required this.onUpload,
    required this.onDelete,
    this.canEdit = true,
  });

  @override
  Widget build(BuildContext context) {
    final canUpload = canEdit && photos.length < quota;
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
        if (photos.isEmpty)
          _EmptyRow(label: 'No photos uploaded')
        else
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final p = photos[i];
                final url = (p['url'] ?? '').toString();
                final id = (p['id'] ?? '').toString();
                return _PhotoThumb(
                  url: url,
                  deleting: deletingIds.contains(id),
                  onDelete: (!canEdit || id.isEmpty)
                      ? null
                      : () => onDelete(id),
                );
              },
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${photos.length}/$quota uploaded',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (canEdit) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _TagButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'FRONT',
                  busy: busy,
                  onTap: canUpload && !busy ? () => onUpload(category) : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TagButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'SIDE',
                  busy: busy,
                  onTap: canUpload && !busy ? () => onUpload(category) : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TagButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'CLOSE UP',
                  busy: busy,
                  onTap: canUpload && !busy ? () => onUpload(category) : null,
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
  final List<Map<String, dynamic>> docs;
  final int quota;
  final String category;
  final bool busy;
  final Set<String> deletingIds;
  final bool canEdit;
  final Future<void> Function(String category) onUpload;
  final Future<void> Function(String id) onDelete;

  const _FilesSection({
    required this.title,
    required this.docs,
    required this.quota,
    required this.category,
    required this.busy,
    required this.deletingIds,
    required this.onUpload,
    required this.onDelete,
    this.canEdit = true,
  });

  @override
  Widget build(BuildContext context) {
    final canUpload = canEdit && docs.length < quota;
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
          _EmptyRow(label: 'No documents uploaded')
        else
          ...docs.map((d) {
            final id = (d['id'] ?? '').toString();
            return _FileRow(
              name: (d['fileName'] ?? 'file').toString(),
              sizeBytes: (d['fileSize'] as num?)?.toInt() ?? 0,
              deleting: deletingIds.contains(id),
              onDelete: (!canEdit || id.isEmpty)
                  ? null
                  : () => onDelete(id),
            );
          }),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${docs.length}/$quota uploaded',
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
            onTap: canUpload && !busy ? () => onUpload(category) : null,
          ),
        ],
      ],
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final String url;
  final bool deleting;
  final VoidCallback? onDelete;

  const _PhotoThumb({
    required this.url,
    this.deleting = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
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
        ),
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
  const _FileRow({
    required this.name,
    required this.sizeBytes,
    this.deleting = false,
    this.onDelete,
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
                  sizeKb > 0 ? 'Document • $sizeKb KB' : 'Document',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
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
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.4,
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
              const Text(
                'UPLOAD',
                style: TextStyle(
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
    final (Color bg, Color fg, String label) = switch (status) {
      ClaimStatus.draft => (const Color(0xFFE8EAED), const Color(0xFF5F6368), 'DRAFT'),
      ClaimStatus.pending => (const Color(0xFFFFE7B8), const Color(0xFFB76E00), 'PENDING'),
      ClaimStatus.submitted => (const Color(0xFFD7E7FD), const Color(0xFF1557B0), 'SUBMITTED'),
      ClaimStatus.inReview => (const Color(0xFFEADFFD), const Color(0xFF6A3BD6), 'NEED INFO'),
      ClaimStatus.approved => (const Color(0xFFD5F1DE), const Color(0xFF0E7C3A), 'APPROVED'),
      ClaimStatus.rejected => (const Color(0xFFFBDAD7), const Color(0xFFB3261E), 'REJECTED'),
      ClaimStatus.closed => (const Color(0xFFE8EAED), const Color(0xFF5F6368), 'CLOSED'),
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
