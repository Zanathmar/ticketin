import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'features/auth/data/datasources/auth_datasource.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/checkin/data/datasources/checkin_datasource.dart';
import 'features/checkin/presentation/bloc/checkin_bloc.dart';
import 'features/events/data/datasources/events_datasource.dart';
import 'features/events/presentation/bloc/events_bloc.dart';
import 'shared/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TicketinApp());
}

class TicketinApp extends StatefulWidget {
  const TicketinApp({super.key});

  @override
  State<TicketinApp> createState() => _TicketinAppState();
}

class _TicketinAppState extends State<TicketinApp> {
  // Dependencies — created once, shared across app
  late final ApiClient _apiClient;
  late final AuthDatasource _authDatasource;
  late final EventsDatasource _eventsDatasource;
  late final CheckInDatasource _checkInDatasource;
  late final AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(storage: const FlutterSecureStorage());
    _authDatasource = AuthDatasource(_apiClient);
    _eventsDatasource = EventsDatasource(_apiClient);
    _checkInDatasource = CheckInDatasource(_apiClient);

    _authBloc = AuthBloc(
      datasource: _authDatasource,
      apiClient: _apiClient,
    )..add(AuthCheckRequested());
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider(create: (_) => EventsBloc(_eventsDatasource)),
        BlocProvider(create: (_) => CheckInBloc(_checkInDatasource)),
      ],
      child: Builder(
        builder: (context) {
          final router = createRouter(_authBloc);
          return MaterialApp.router(
            title: 'Ticketin',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
