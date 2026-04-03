import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../bloc/events_bloc.dart';
import '../../data/models/event_model.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/shimmer_card.dart';
import '../../../../shared/widgets/snack_helper.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEvents();
  }

  void _loadEvents({bool upcoming = false, String? search}) {
    context
        .read<EventsBloc>()
        .add(EventsLoadRequested(upcoming: upcoming, search: search));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isOrganizer = user != null && (user.isOrganizer || user.isAdmin);

    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: isOrganizer
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/create-event'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('New Event',
                  style: TextStyle(
                      fontFamily: 'Syne',
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(user?.name),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _EventsList(onRegister: _handleRegister),
                  _EventsList(upcoming: true, onRegister: _handleRegister),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String? name) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${name?.split(' ').first ?? 'there'}',
                      style: AppTextStyles.headline2,
                    ),
                    const SizedBox(height: 2),
                    Text('Discover events near you',
                        style: AppTextStyles.caption),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _showSearch ? Icons.close : Icons.search,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  setState(() => _showSearch = !_showSearch);
                  if (!_showSearch) {
                    _searchCtrl.clear();
                    _loadEvents(upcoming: _tabController.index == 1);
                  }
                },
              ),
            ],
          ),
          if (_showSearch) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _searchCtrl,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (val) => _loadEvents(
                  upcoming: _tabController.index == 1, search: val),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (i) => _loadEvents(upcoming: i == 1),
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.bodyMedium,
        tabs: const [
          Tab(text: 'All Events'),
          Tab(text: 'Upcoming'),
        ],
      ),
    );
  }

  void _handleRegister(EventModel event) {
    context.read<EventsBloc>().add(EventRegisterRequested(event.id));
  }
}

class _EventsList extends StatelessWidget {
  final bool upcoming;
  final Function(EventModel) onRegister;

  const _EventsList({this.upcoming = false, required this.onRegister});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EventsBloc, EventsState>(
      listener: (context, state) {
        if (state is EventRegistered) {
          SnackHelper.success(context, state.message);
          context.push('/my-ticket', extra: state.qrData);
        } else if (state is EventRegisterError) {
          SnackHelper.error(context, state.message);
        }
      },
      builder: (context, state) {
        if (state is EventsLoading || state is EventsInitial) {
          return _buildShimmer();
        }

        List<EventModel> events = [];
        bool isRegLoading = false;

        if (state is EventsLoaded) events = state.events;
        if (state is EventRegisterLoading) {
          events = state.events;
          isRegLoading = true;
        }
        if (state is EventRegistered) events = state.events;
        if (state is EventRegisterError) events = state.events;

        if (state is EventsError) {
          return _buildError(context, state.message);
        }

        if (events.isEmpty) {
          return _buildEmpty();
        }

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            context
                .read<EventsBloc>()
                .add(EventsLoadRequested(upcoming: upcoming));
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
            itemCount: events.length,
            itemBuilder: (context, i) => _EventCard(
              event: events[i],
              onRegister: isRegLoading ? null : () => onRegister(events[i]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
      itemCount: 5,
      itemBuilder: (_, __) => const ShimmerCard(),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(message,
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context
                .read<EventsBloc>()
                .add(EventsLoadRequested(upcoming: upcoming)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_busy, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('No events found',
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onRegister;

  const _EventCard({required this.event, this.onRegister});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE, MMM d · h:mm a');

    // Check if current user is organizer/admin to hide register button
    final authState = context.read<AuthBloc>().state;
    final isOrganizer = authState is AuthAuthenticated &&
        (authState.user.isOrganizer || authState.user.isAdmin);

    return GestureDetector(
      onTap: () => context.push('/event/${event.id}', extra: event),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.imageUrl != null)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  event.imageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                ),
              )
            else
              _buildImagePlaceholder(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _StatusBadge(status: event.status),
                      const Spacer(),
                      if (event.isFull)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.errorLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('FULL',
                              style: AppTextStyles.label
                                  .copyWith(color: AppColors.error)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(event.title,
                      style: AppTextStyles.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(fmt.format(event.startTime),
                          style: AppTextStyles.caption),
                    ],
                  ),
                  if (event.venue != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${event.venue!.name}, ${event.venue!.city}',
                            style: AppTextStyles.caption,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${event.currentAttendees}/${event.capacity}',
                              style: AppTextStyles.caption,
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: event.capacityPercent,
                              backgroundColor: AppColors.surfaceLight,
                              color: event.isFull
                                  ? AppColors.error
                                  : AppColors.primary,
                              minHeight: 4,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ],
                        ),
                      ),
                      if (!isOrganizer && event.isActive && !event.isFull) ...[
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: onRegister,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(100, 36),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            textStyle: const TextStyle(
                                fontFamily: 'Syne',
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                          child: onRegister == null
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Register'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 140,
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: const Center(
        child: Icon(Icons.event, size: 48, color: AppColors.cardBorder),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    String label;
    switch (status) {
      case 'active':
        bg = AppColors.activeBg;
        fg = AppColors.activeGreen;
        label = 'Active';
        break;
      case 'cancelled':
        bg = AppColors.cancelledBg;
        fg = AppColors.cancelledRed;
        label = 'Cancelled';
        break;
      case 'completed':
        bg = AppColors.completedBg;
        fg = AppColors.completedBlue;
        label = 'Completed';
        break;
      default:
        bg = AppColors.surfaceLight;
        fg = AppColors.textSecondary;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: AppTextStyles.label.copyWith(color: fg, letterSpacing: 0)),
    );
  }
}