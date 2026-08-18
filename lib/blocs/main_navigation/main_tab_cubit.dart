import 'package:alnisa_store/blocs/main_navigation/main_tab_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MainTabCubit extends Cubit<MainTabState> {
  MainTabCubit() : super(const MainTabState(index: 0));

  void changeTab(int index) => emit(MainTabState(index: index));
}
