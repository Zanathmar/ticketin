import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/checkin_datasource.dart';

abstract class CheckInEvent {}

class CheckInQrScanned extends CheckInEvent {
  final String qrData;
  final bool isCheckOut;
  CheckInQrScanned({required this.qrData, this.isCheckOut = false});
}

class CheckInReset extends CheckInEvent {}

abstract class CheckInState {}

class CheckInInitial extends CheckInState {}
class CheckInLoading extends CheckInState {}

class CheckInSuccess extends CheckInState {
  final String message;
  final Map<String, dynamic> registration;
  final bool isCheckOut;
  CheckInSuccess({
    required this.message,
    required this.registration,
    this.isCheckOut = false,
  });
}

class CheckInError extends CheckInState {
  final String message;
  CheckInError(this.message);
}

class CheckInBloc extends Bloc<CheckInEvent, CheckInState> {
  final CheckInDatasource _datasource;

  CheckInBloc(this._datasource) : super(CheckInInitial()) {
    on<CheckInQrScanned>(_onQrScanned);
    on<CheckInReset>((_, emit) => emit(CheckInInitial()));
  }

  Future<void> _onQrScanned(
      CheckInQrScanned event, Emitter<CheckInState> emit) async {
    emit(CheckInLoading());

    final result = event.isCheckOut
        ? await _datasource.checkOut(event.qrData)
        : await _datasource.checkIn(event.qrData);

    if (result.isSuccess) {
      final data = result.data!;
      emit(CheckInSuccess(
        message: data['message'],
        registration: data['registration'] as Map<String, dynamic>,
        isCheckOut: event.isCheckOut,
      ));
    } else {
      emit(CheckInError(result.failure!.message));
    }
  }
}
