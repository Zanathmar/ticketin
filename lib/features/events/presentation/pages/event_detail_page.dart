import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../bloc/events_bloc.dart';
import '../../data/models/event_model.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/snack_helper.dart';

class EventDetailPage extends StatelessWidget {
  final EventModel event;
  const EventDetailPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE, MMMM d, yyyy · h:mm a');

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: BlocListener<EventsBloc, EventsState>(
        listener: (context, state) {
          if (state is EventRegistered) {
            SnackHelper.success(context, state.message);
            context.push('/my-ticket', extra: state.qrData);
          } else if (state is EventRegisterError) {
            SnackHelper.error(context, state.message);
          }
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: AppColors.bg,
              flexibleSpace: FlexibleSpaceBar(
                background: event.imageUrl != null
                    ? Image.network(event.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
              leading: IconButton(
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.bg.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      size: 16, color: AppColors.textPrimary),
                ),
                onPressed: () => context.pop(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusBadgeWidget(status: event.status),
                    const SizedBox(height: 12),
                    Text(event.title, style: AppTextStyles.headline2),
                    const SizedBox(height: 20),
                    _InfoSection(
                      icon: Icons.schedule_outlined,
                      title: 'Date & Time',
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Start: ${fmt.format(event.startTime)}',
                              style: AppTextStyles.body),
                          const SizedBox(height: 4),
                          Text('End: ${fmt.format(event.endTime)}',
                              style: AppTextStyles.body.copyWith(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (event.venue != null)
                      _InfoSection(
                        icon: Icons.location_on_outlined,
                        title: 'Venue',
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.venue!.name,
                                style: AppTextStyles.bodyMedium),
                            const SizedBox(height: 4),
                            Text(event.venue!.fullAddress,
                                style: AppTextStyles.body.copyWith(
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    _InfoSection(
                      icon: Icons.people_outline,
                      title: 'Capacity',
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${event.currentAttendees} / ${event.capacity} attendees',
                              style: AppTextStyles.body),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: event.capacityPercent,
                            backgroundColor: AppColors.surfaceLight,
                            color: event.isFull
                                ? AppColors.error
                                : AppColors.primary,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ],
                      ),
                    ),
                    if (event.organizer != null) ...[
                      const SizedBox(height: 16),
                      _InfoSection(
                        icon: Icons.person_outline,
                        title: 'Organizer',
                        content: Text(event.organizer!.name,
                            style: AppTextStyles.body),
                      ),
                    ],
                    if (event.description != null &&
                        event.description!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _InfoSection(
                        icon: Icons.description_outlined,
                        title: 'About',
                        content: Text(event.description!,
                            style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.6)),
                      ),
                    ],
                    const SizedBox(height: 32),
                    BlocBuilder<EventsBloc, EventsState>(
                      builder: (context, state) {
                        final isLoading = state is EventRegisterLoading;
                        if (!event.isActive) {
                          return _DisabledButton(
                              label: event.isCancelled
                                  ? 'Event Cancelled'
                                  : 'Event Completed');
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
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Register for Event'),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: const Center(
        child: Icon(Icons.event, size: 64, color: AppColors.cardBorder),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget content;
  const _InfoSection(
      {required this.icon, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: AppTextStyles.label
                      .copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }
}

class _StatusBadgeWidget extends StatelessWidget {
  final String status;
  const _StatusBadgeWidget({required this.status});

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
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status[0].toUpperCase() + status.substring(1),
          style: AppTextStyles.label.copyWith(color: fg, letterSpacing: 0)),
    );
  }
}

class _DisabledButton extends StatelessWidget {
  final String label;
  const _DisabledButton({required this.label});

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
      child: Center(
        child: Text(label,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textMuted)),
      ),
    );
  }
}
