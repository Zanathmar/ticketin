import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../../events/presentation/bloc/events_bloc.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/shimmer_card.dart';

class MyTicketsPage extends StatefulWidget {
  const MyTicketsPage({super.key});

  @override
  State<MyTicketsPage> createState() => _MyTicketsPageState();
}

class _MyTicketsPageState extends State<MyTicketsPage> {
  @override
  void initState() {
    super.initState();
    context.read<EventsBloc>().add(MyRegistrationsLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('My Tickets'),
        automaticallyImplyLeading: false,
      ),
      body: BlocBuilder<EventsBloc, EventsState>(
        builder: (context, state) {
          if (state is MyRegistrationsLoading) {
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: 4,
              itemBuilder: (_, __) => const ShimmerCard(),
            );
          }
          if (state is MyRegistrationsError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text(state.message,
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context
                        .read<EventsBloc>()
                        .add(MyRegistrationsLoadRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is MyRegistrationsLoaded) {
            if (state.registrations.isEmpty) {
              return _buildEmpty(context);
            }
            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: () async =>
                  context.read<EventsBloc>().add(MyRegistrationsLoadRequested()),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                itemCount: state.registrations.length,
                itemBuilder: (context, i) =>
                    _TicketCard(registration: state.registrations[i]),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.confirmation_number_outlined,
                size: 36, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          Text('No tickets yet', style: AppTextStyles.headline3),
          const SizedBox(height: 8),
          Text('Register for an event to get your ticket',
              style:
                  AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(160, 48),
            ),
            child: const Text('Explore Events'),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Map<String, dynamic> registration;
  const _TicketCard({required this.registration});

  @override
  Widget build(BuildContext context) {
    final event = registration['event'] as Map<String, dynamic>?;
    final venue = event?['venue'] as Map<String, dynamic>?;
    final isInside = registration['is_inside'] == true;
    final lastCheckin = registration['last_checkin'];

    String title = event?['title'] ?? 'Event';
    String city = venue?['city'] ?? '';
    DateTime? startTime;
    if (event?['start_time'] != null) {
      startTime = DateTime.tryParse(event!['start_time']);
    }

    return GestureDetector(
      onTap: () => _showQrSheet(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.confirmation_number,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: AppTextStyles.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (city.isNotEmpty)
                          Text(city, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  _StatusPill(isInside: isInside, lastCheckin: lastCheckin),
                ],
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (startTime != null) ...[
                    const Icon(Icons.schedule,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(DateFormat('MMM d, yyyy').format(startTime),
                        style: AppTextStyles.caption),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.qr_code_2,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('View QR',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500)),
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

  void _showQrSheet(BuildContext context) {
    final event = registration['event'] as Map<String, dynamic>?;
    final eventId = registration['event_id'];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _QrBottomSheet(
        eventId: eventId,
        eventTitle: event?['title'] ?? 'Event',
        registrationId: registration['id'],
        ticketNonce: registration['ticket_nonce'] ?? '',
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isInside;
  final dynamic lastCheckin;
  const _StatusPill({required this.isInside, this.lastCheckin});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    String label;
    if (isInside) {
      bg = AppColors.activeBg;
      fg = AppColors.activeGreen;
      label = 'Inside';
    } else if (lastCheckin != null) {
      bg = AppColors.completedBg;
      fg = AppColors.completedBlue;
      label = 'Was Inside';
    } else {
      bg = AppColors.surfaceLight;
      fg = AppColors.textSecondary;
      label = 'Registered';
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

class _QrBottomSheet extends StatelessWidget {
  final int eventId;
  final String eventTitle;
  final int registrationId;
  final String ticketNonce;

  const _QrBottomSheet({
    required this.eventId,
    required this.eventTitle,
    required this.registrationId,
    required this.ticketNonce,
  });

  @override
  Widget build(BuildContext context) {
    // The QR data is a JSON payload matching the API format
    final qrPayload = '{"registration_id":$registrationId,"event_id":$eventId,"user_id":0,"nonce":"$ticketNonce"}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text('Your Ticket', style: AppTextStyles.headline3),
          const SizedBox(height: 4),
          Text(eventTitle,
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: qrPayload,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Show this QR code at the event entrance for check-in.',
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    side: const BorderSide(color: AppColors.cardBorder),
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/scan');
                  },
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
                  child: const Text('Scan QR'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
