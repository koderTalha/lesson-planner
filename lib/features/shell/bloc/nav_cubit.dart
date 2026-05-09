import 'package:flutter_bloc/flutter_bloc.dart';

class NavCubit extends Cubit<int> {
  NavCubit() : super(0);

  void select(int index) {
    if (index == state) return;
    emit(index);
  }
}
