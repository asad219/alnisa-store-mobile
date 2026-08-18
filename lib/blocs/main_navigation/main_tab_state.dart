import 'package:equatable/equatable.dart';

class MainTabState extends Equatable {
  const MainTabState({required this.index});

  final int index;

  @override
  List<Object?> get props => [index];
}
