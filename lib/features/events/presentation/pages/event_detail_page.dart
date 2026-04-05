import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../bloc/events_bloc.dart';
import '../../data/models/event_model.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/snack_helper.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class EventDetailPage extends StatelessWidget {
  final EventModel event;
  const EventDetailPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return BlocListener<EventsBloc, EventsState>(
      listener: (context, state) {
        if (state is EventRegistered) {
          SnackHelper.success(context, state.message);
          context.push('/my-ticket', extra: state.qrData);
        } else if (state is EventRegisterError) {
          SnackHelper.error(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                _HeroAppBar(event: event),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StatusRow(event: event),
                        const SizedBox(height: 14),
                        Text(event.title, style: AppTextStyles.headline2),
                        const SizedBox(height: 20),
                        _InfoCard(children: [
                          _InfoRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Start',
                            value: DateFormat('EEE, MMM d, yyyy')
                                .format(event.startTime),
                            sub: DateFormat('h:mm a').format(event.startTime),
                          ),
                          _Divider(),
                          _InfoRow(
                            icon: Icons.event_outlined,
                            label: 'End',
                            value: DateFormat('EEE, MMM d, yyyy')
                                .format(event.endTime),
                            sub: DateFormat('h:mm a').format(event.endTime),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        if (event.venue != null) ...[
                          _InfoCard(children: [
                            _InfoRow(
                              icon: Icons.location_on_outlined,
                              label: event.venue!.name,
                              value: event.venue!.address,
                              sub:
                                  '${event.venue!.city}${event.venue!.state != null ? ", ${event.venue!.state}" : ""}, ${event.venue!.country}',
                            ),
                          ]),
                          const SizedBox(height: 14),
                        ],
                        _CapacityCard(event: event),
                        if (event.organizer != null) ...[
                          const SizedBox(height: 14),
                          _InfoCard(children: [
                            _InfoRow(
                              icon: Icons.person_outline,
                              label: 'Organizer',
                              value: event.organizer!.name,
                              sub: event.organizer!.email,
                            ),
                          ]),
                        ],
                        if (event.description != null &&
                            event.description!.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _AboutCard(description: event.description!),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _BottomBar(event: event),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero AppBar ──────────────────────────────────────────────────────────────

class _HeroAppBar extends StatelessWidget {
  final EventModel event;
  const _HeroAppBar({required this.event});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final canEdit = authState is AuthAuthenticated &&
        (authState.user.isAdmin ||
            (authState.user.isOrganizer &&
                event.organizerId == authState.user.id));

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.bg,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                size: 16, color: Colors.white),
          ),
        ),
      ),
      actions: [
        if (canEdit)
          Padding(
            padding: const EdgeInsets.all(8),
            child: GestureDetector(
              onTap: () => context.push('/edit-event', extra: event),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_outlined,
                    size: 16, color: Colors.white),
              ),
            ),
          ),
      ],
      flexibleSpace: const FlexibleSpaceBar(
        background: _EventPlaceholder(),
      ),
    );
  }
}

class _EventPlaceholder extends StatelessWidget {
  const _EventPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2235), Color(0xFF151827)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.event_rounded, size: 72, color: AppColors.cardBorder),
      ),
    );
  }
}

// ─── Status Row ───────────────────────────────────────────────────────────────

class _StatusRow extends StatelessWidget {
  final EventModel event;
  const _StatusRow({required this.event});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        _StatusBadge(status: event.status),
        if (event.isOngoing)
          _TagBadge(
              label: 'Happening Now',
              color: AppColors.activeGreen,
              bg: AppColors.activeBg),
        if (event.isPast && !event.isCancelled)
          _TagBadge(
              label: 'Event Ended',
              color: AppColors.textMuted,
              bg: AppColors.surfaceLight),
        if (event.isFull)
          _TagBadge(
              label: 'Full',
              color: AppColors.cancelledRed,
              bg: AppColors.cancelledBg),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (status) {
      case 'active':
        bg = AppColors.activeBg;
        fg = AppColors.activeGreen;
        break;
      case 'cancelled':
        bg = AppColors.cancelledBg;
        fg = AppColors.cancelledRed;
        break;
      default:
        bg = AppColors.completedBg;
        fg = AppColors.completedBlue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: AppTextStyles.label.copyWith(color: fg, letterSpacing: 0),
      ),
    );
  }
}

class _TagBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _TagBadge(
      {required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: AppTextStyles.label.copyWith(color: color, letterSpacing: 0)),
    );
  }
}

// ─── Info Card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? sub;
  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.sub});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(value, style: AppTextStyles.bodyMedium),
                if (sub != null && sub!.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(sub!,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 64, color: AppColors.cardBorder);
  }
}

// ─── Capacity Card ────────────────────────────────────────────────────────────

class _CapacityCard extends StatelessWidget {
  final EventModel event;
  const _CapacityCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final pct = event.capacityPercent;
    final color = event.isFull ? AppColors.error : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.people_outline, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Capacity',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 2),
                    Text(
                      '${event.currentAttendees} of ${event.capacity} registered',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: AppTextStyles.bodyMedium.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.surfaceLight,
              color: color,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── About Card ───────────────────────────────────────────────────────────────

class _AboutCard extends StatefulWidget {
  final String description;
  const _AboutCard({required this.description});

  @override
  State<_AboutCard> createState() => _AboutCardState();
}

class _AboutCardState extends State<_AboutCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_outline,
                    size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text('About',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedCrossFade(
            firstChild: Text(
              widget.description,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary, height: 1.6),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            secondChild: Text(
              widget.description,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary, height: 1.6),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
          if (widget.description.length > 180) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Show less' : 'Read more',
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Bottom Bar ───────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final EventModel event;
  const _BottomBar({required this.event});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isOrganizer = authState is AuthAuthenticated &&
        (authState.user.isOrganizer || authState.user.isAdmin);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      child: BlocBuilder<EventsBloc, EventsState>(
        builder: (context, state) {
          final isLoading = state is EventRegisterLoading;

          if (isOrganizer) {
            return _DisabledButton(
              label: 'Organizer View',
              icon: Icons.visibility_outlined,
            );
          }
          if (!event.isActive) {
            return _DisabledButton(
              label:
                  event.isCancelled ? 'Event Cancelled' : 'Event Completed',
            );
          }
          if (event.isPast) {
            return _DisabledButton(label: 'Event Has Ended');
          }
          if (event.isFull) {
            return _DisabledButton(label: 'Event Full');
          }

          return ElevatedButton(
            onPressed: isLoading
                ? null
                : () => context
                    .read<EventsBloc>()
                    .add(EventRegisterRequested(event.id)),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Register for Event'),
          );
        },
      ),
    );
  }
}

class _DisabledButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  const _DisabledButton({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 8),
          ],
          Text(label,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}