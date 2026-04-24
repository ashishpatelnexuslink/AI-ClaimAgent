import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:claim_ai/features/documents/domain/usecases/get_documents_usecase.dart';
import 'package:claim_ai/features/documents/domain/usecases/upload_document_usecase.dart';
import 'package:claim_ai/features/documents/domain/usecases/delete_document_usecase.dart';
import 'package:claim_ai/features/documents/presentation/cubit/documents_state.dart';

class DocumentsCubit extends Cubit<DocumentsState> {
  final GetDocumentsUseCase _getDocumentsUseCase;
  final UploadDocumentUseCase _uploadDocumentUseCase;
  final DeleteDocumentUseCase _deleteDocumentUseCase;

  DocumentsCubit({
    required GetDocumentsUseCase getDocumentsUseCase,
    required UploadDocumentUseCase uploadDocumentUseCase,
    required DeleteDocumentUseCase deleteDocumentUseCase,
  })  : _getDocumentsUseCase = getDocumentsUseCase,
        _uploadDocumentUseCase = uploadDocumentUseCase,
        _deleteDocumentUseCase = deleteDocumentUseCase,
        super(const DocumentsState());

  Future<void> fetchDocuments(String claimId) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _getDocumentsUseCase(claimId);
    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
      (docs) => emit(state.copyWith(
        isLoading: false,
        documents: docs,
      )),
    );
  }

  Future<void> pickAndUploadDocument(String claimId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) return;

    emit(state.copyWith(isUploading: true));

    final uploadResult = await _uploadDocumentUseCase(
      UploadDocumentParams(
        claimId: claimId,
        filePath: file.path!,
        fileName: file.name,
      ),
    );

    uploadResult.fold(
      (failure) => emit(state.copyWith(
        isUploading: false,
        errorMessage: failure.message,
      )),
      (doc) => emit(state.copyWith(
        isUploading: false,
        documents: [...state.documents, doc],
        successMessage: 'Document uploaded successfully',
      )),
    );
  }

  Future<void> deleteDocument(String documentId, String claimId) async {
    final result = await _deleteDocumentUseCase(documentId);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => emit(state.copyWith(
        documents: state.documents.where((d) => d.id != documentId).toList(),
        successMessage: 'Document deleted',
      )),
    );
  }

  void clearMessages() {
    emit(state.copyWith(clearError: true, clearSuccess: true));
  }
}
