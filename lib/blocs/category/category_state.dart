import 'package:alnisa_store/models/category/category_model.dart';
import 'package:equatable/equatable.dart';

enum CategoryStatus { initial, loading, success, failure }

class CategoryState extends Equatable {
  const CategoryState({
    this.status = CategoryStatus.initial,
    this.categories = const [],
    this.error,
  });

  final CategoryStatus status;
  final List<CategoryModel> categories;
  final String? error;

  CategoryState copyWith({
    CategoryStatus? status,
    List<CategoryModel>? categories,
    String? error,
  }) {
    return CategoryState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, categories, error];
}
