import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/auth_datasource.dart';
import '../../data/models/user_model.dart';
import '../../../../core/network/api_client.dart';

// Events
abstract class AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  AuthLoginRequested({required this.email, required this.password});
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String passwordConfirmation;
  final String role;
  AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    this.role = 'attendee',
  });
}

class AuthLogoutRequested extends AuthEvent {}

class AuthUserRefreshRequested extends AuthEvent {}

// States
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthDatasource _datasource;
  final ApiClient _apiClient;

  AuthBloc({
    required AuthDatasource datasource,
    required ApiClient apiClient,
  })  : _datasource = datasource,
        _apiClient = apiClient,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthUserRefreshRequested>(_onUserRefresh);
  }

  Future<void> _onCheckRequested(
      AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final hasToken = await _apiClient.hasToken;
    if (!hasToken) {
      emit(AuthUnauthenticated());
      return;
    }
    final result = await _datasource.getMe();
    if (result.isSuccess) {
      emit(AuthAuthenticated(result.data!));
    } else {
      await _apiClient.clearToken();
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
      AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _datasource.login(
      email: event.email,
      password: event.password,
    );
    if (result.isSuccess) {
      final data = result.data!;
      await _apiClient.saveToken(data['token']);
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthError(result.failure!.message));
    }
  }

  Future<void> _onRegisterRequested(
      AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _datasource.register(
      name: event.name,
      email: event.email,
      password: event.password,
      passwordConfirmation: event.passwordConfirmation,
      role: event.role,
    );
    if (result.isSuccess) {
      final data = result.data!;
      await _apiClient.saveToken(data['token']);
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthError(result.failure!.message));
    }
  }

  Future<void> _onLogoutRequested(
      AuthLogoutRequested event, Emitter<AuthState> emit) async {
    // Clear token FIRST before emitting any state
    // This prevents the router from seeing AuthLoading with a valid token
    await _apiClient.clearToken();
    await _datasource.logout(); // best-effort API call, already cleared locally
    emit(AuthUnauthenticated());
  }

  Future<void> _onUserRefresh(
      AuthUserRefreshRequested event, Emitter<AuthState> emit) async {
    final result = await _datasource.getMe();
    if (result.isSuccess) {
      emit(AuthAuthenticated(result.data!));
    }
  }
}
