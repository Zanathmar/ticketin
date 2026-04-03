import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/events_datasource.dart';
import '../../data/models/event_model.dart';

// Events
abstract class EventsEvent {}

class EventsLoadRequested extends EventsEvent {
  final bool upcoming;
  final String? search;
  EventsLoadRequested({this.upcoming = false, this.search});
}

class EventsSearchChanged extends EventsEvent {
  final String query;
  EventsSearchChanged(this.query);
}

class EventRegisterRequested extends EventsEvent {
  final int eventId;
  EventRegisterRequested(this.eventId);
}

class MyRegistrationsLoadRequested extends EventsEvent {}

// States
abstract class EventsState {}

class EventsInitial extends EventsState {}

class EventsLoading extends EventsState {}

class EventsLoaded extends EventsState {
  final List<EventModel> events;
  final bool isUpcoming;
  EventsLoaded(this.events, {this.isUpcoming = false});
}

class EventsError extends EventsState {
  final String message;
  EventsError(this.message);
}

class EventRegisterLoading extends EventsState {
  final List<EventModel> events;
  EventRegisterLoading(this.events);
}

class EventRegistered extends EventsState {
  final List<EventModel> events;
  final String qrData;
  final String message;
  EventRegistered({required this.events, required this.qrData, required this.message});
}

class EventRegisterError extends EventsState {
  final List<EventModel> events;
  final String message;
  EventRegisterError({required this.events, required this.message});
}

class MyRegistrationsLoading extends EventsState {}

class MyRegistrationsLoaded extends EventsState {
  final List<Map<String, dynamic>> registrations;
  MyRegistrationsLoaded(this.registrations);
}

class MyRegistrationsError extends EventsState {
  final String message;
  MyRegistrationsError(this.message);
}

// BLoC
class EventsBloc extends Bloc<EventsEvent, EventsState> {
  final EventsDatasource _datasource;

  EventsBloc(this._datasource) : super(EventsInitial()) {
    on<EventsLoadRequested>(_onLoad);
    on<EventRegisterRequested>(_onRegister);
    on<MyRegistrationsLoadRequested>(_onMyRegistrations);
  }

  Future<void> _onLoad(
      EventsLoadRequested event, Emitter<EventsState> emit) async {
    emit(EventsLoading());
    final result = await _datasource.getEvents(
      upcoming: event.upcoming,
      search: event.search,
    );
    if (result.isSuccess) {
      emit(EventsLoaded(result.data!, isUpcoming: event.upcoming));
    } else {
      emit(EventsError(result.failure!.message));
    }
  }

  Future<void> _onRegister(
      EventRegisterRequested event, Emitter<EventsState> emit) async {
    final currentEvents =
        state is EventsLoaded ? (state as EventsLoaded).events : <EventModel>[];
    emit(EventRegisterLoading(currentEvents));

    final result = await _datasource.registerForEvent(event.eventId);
    if (result.isSuccess) {
      final data = result.data!;
      emit(EventRegistered(
        events: currentEvents,
        qrData: data['qr_data'],
        message: data['message'] ?? 'Successfully registered!',
      ));
    } else {
      emit(EventRegisterError(
        events: currentEvents,
        message: result.failure!.message,
      ));
    }
  }

  Future<void> _onMyRegistrations(
      MyRegistrationsLoadRequested event, Emitter<EventsState> emit) async {
    emit(MyRegistrationsLoading());
    final result = await _datasource.getMyRegistrations();
    if (result.isSuccess) {
      emit(MyRegistrationsLoaded(result.data!));
    } else {
      emit(MyRegistrationsError(result.failure!.message));
    }
  }
}
