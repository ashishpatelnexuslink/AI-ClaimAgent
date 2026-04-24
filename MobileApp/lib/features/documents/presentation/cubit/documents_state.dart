import 'package:equatable/equatable.dart';
import 'package:claim_ai/features/documents/domain/entities/document_entity.dart';

class DocumentsState extends Equatable {
  final List<DocumentEntity> documents;
  final bool isLoading;
  final bool isUploading;
  final String? errorMessage;
  final String? successMessage;

  const DocumentsState({
    this.documents = const [],
    this.isLoading = false,
    this.isUploading = false,
    this.errorMessage,
    this.successMessage,
  });

  DocumentsState copyWith({
    List<DocumentEntity>? documents,
    bool? isLoading,
    bool? isUploading,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return DocumentsState(
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [documents, isLoading, isUploading, errorMessage, successMessage];
}
