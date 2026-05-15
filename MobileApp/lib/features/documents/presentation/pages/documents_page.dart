import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:claim_ai/core/constants/app_theme.dart';
import 'package:claim_ai/core/l10n/generated/app_localizations.dart';
import 'package:claim_ai/core/utils/date_utils.dart';
import 'package:claim_ai/core/widgets/loading_widget.dart';
import 'package:claim_ai/core/widgets/error_widget.dart';
import 'package:claim_ai/core/widgets/empty_widget.dart';
import 'package:claim_ai/features/documents/domain/entities/document_entity.dart';
import 'package:claim_ai/features/documents/presentation/cubit/documents_cubit.dart';
import 'package:claim_ai/features/documents/presentation/cubit/documents_state.dart';

class DocumentsPage extends StatefulWidget {
  final String claimId;

  const DocumentsPage({super.key, required this.claimId});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  @override
  void initState() {
    super.initState();
    context.read<DocumentsCubit>().fetchDocuments(widget.claimId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DocumentsCubit, DocumentsState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
          context.read<DocumentsCubit>().clearMessages();
        }
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.successMessage!)),
          );
          context.read<DocumentsCubit>().clearMessages();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).documents_appBarTitle),
        ),
        floatingActionButton: BlocBuilder<DocumentsCubit, DocumentsState>(
          buildWhen: (prev, curr) => prev.isUploading != curr.isUploading,
          builder: (context, state) {
            final l = AppLocalizations.of(context);
            return FloatingActionButton.extended(
              onPressed: state.isUploading
                  ? null
                  : () => context
                      .read<DocumentsCubit>()
                      .pickAndUploadDocument(widget.claimId),
              icon: state.isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(
                state.isUploading ? l.documents_uploading : l.documents_uploadButton,
              ),
            );
          },
        ),
        body: BlocBuilder<DocumentsCubit, DocumentsState>(
          builder: (context, state) {
            final l = AppLocalizations.of(context);
            if (state.isLoading) {
              return LoadingWidget(message: l.documents_loading);
            }

            if (state.errorMessage != null && state.documents.isEmpty) {
              return AppErrorWidget(
                message: state.errorMessage!,
                onRetry: () => context
                    .read<DocumentsCubit>()
                    .fetchDocuments(widget.claimId),
              );
            }

            if (state.documents.isEmpty) {
              return EmptyWidget(
                message: l.documents_empty,
                icon: Icons.description_outlined,
              );
            }

            return RefreshIndicator(
              onRefresh: () =>
                  context.read<DocumentsCubit>().fetchDocuments(widget.claimId),
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: state.documents.length,
                itemBuilder: (context, index) {
                  final doc = state.documents[index];
                  return _buildDocumentCard(context, doc);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, DocumentEntity doc) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: _getFileIcon(doc.fileType),
        title: Text(
          doc.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${_formatFileSize(doc.fileSize)} - ${AppDateUtils.formatDate(doc.createdAt, Localizations.localeOf(context).languageCode)}',
          style:
              const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'delete',
              child: Text(AppLocalizations.of(context).common_delete),
            ),
          ],
          onSelected: (value) {
            if (value == 'delete') {
              context
                  .read<DocumentsCubit>()
                  .deleteDocument(doc.id, widget.claimId);
            }
          },
        ),
      ),
    );
  }

  Widget _getFileIcon(String fileType) {
    final (IconData icon, Color color) = switch (fileType.toLowerCase()) {
      'pdf' => (Icons.picture_as_pdf, Colors.red),
      'jpg' || 'jpeg' || 'png' => (Icons.image, Colors.blue),
      'doc' || 'docx' => (Icons.description, Colors.indigo),
      _ => (Icons.insert_drive_file, AppColors.textSecondary),
    };

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.1),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }
}
