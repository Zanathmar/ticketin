import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../bloc/events_bloc.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/snack_helper.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController(text: '100');

  final _venueNameCtrl = TextEditingController();
  final _venueAddressCtrl = TextEditingController();
  final _venueCityCtrl = TextEditingController();
  final _venueStateCtrl = TextEditingController();
  final _venueCountryCtrl = TextEditingController();
  final _venuePostalCtrl = TextEditingController();

  DateTime? _startTime;
  DateTime? _endTime;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _capacityCtrl.dispose();
    _venueNameCtrl.dispose();
    _venueAddressCtrl.dispose();
    _venueCityCtrl.dispose();
    _venueStateCtrl.dispose();
    _venueCountryCtrl.dispose();
    _venuePostalCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => _pickerTheme(ctx, child!),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => _pickerTheme(ctx, child!),
    );
    if (time == null || !mounted) return;
    final picked =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() => isStart ? _startTime = picked : _endTime = picked);
  }

  Widget _pickerTheme(BuildContext ctx, Widget child) {
    return Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
        ),
      ),
      child: child,
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime == null) {
      SnackHelper.error(context, 'Please select a start time');
      return;
    }
    if (_endTime == null) {
      SnackHelper.error(context, 'Please select an end time');
      return;
    }
    if (!_endTime!.isAfter(_startTime!)) {
      SnackHelper.error(context, 'End time must be after start time');
      return;
    }

    final fmt = DateFormat('yyyy-MM-dd HH:mm:ss');

    context.read<EventsBloc>().add(EventCreateRequested(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          capacity: int.parse(_capacityCtrl.text.trim()),
          startTime: fmt.format(_startTime!),
          endTime: fmt.format(_endTime!),
          venue: {
            'name': _venueNameCtrl.text.trim(),
            'address': _venueAddressCtrl.text.trim(),
            'city': _venueCityCtrl.text.trim(),
            'state': _venueStateCtrl.text.trim().isEmpty
                ? null
                : _venueStateCtrl.text.trim(),
            'country': _venueCountryCtrl.text.trim(),
            'postal_code': _venuePostalCtrl.text.trim().isEmpty
                ? null
                : _venuePostalCtrl.text.trim(),
          },
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EventsBloc, EventsState>(
      listener: (context, state) {
        if (state is EventCreateSuccess) {
          SnackHelper.success(context, 'Event "${state.event.title}" created!');
          context.go('/home');
        } else if (state is EventCreateError) {
          SnackHelper.error(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: const Text('Create Event'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => context.pop(),
          ),
        ),
        body: BlocBuilder<EventsBloc, EventsState>(
          builder: (context, state) {
            final isLoading = state is EventCreateLoading;
            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(label: 'Event Details'),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _titleCtrl,
                      label: 'Title',
                      hint: 'Tech Conference 2025',
                      prefixIcon: Icons.event_outlined,
                      enabled: !isLoading,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 3,
                      enabled: !isLoading,
                      style: AppTextStyles.body,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'What is this event about?',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 40),
                          child: Icon(Icons.description_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _capacityCtrl,
                      label: 'Capacity',
                      hint: '100',
                      prefixIcon: Icons.people_outline,
                      keyboardType: TextInputType.number,
                      enabled: !isLoading,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Capacity is required';
                        final n = int.tryParse(v);
                        if (n == null || n < 1) return 'Enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _SectionLabel(label: 'Date & Time'),
                    const SizedBox(height: 12),
                    _DateTimeTile(
                      label: 'Start Time',
                      value: _startTime,
                      onTap: isLoading ? null : () => _pickDateTime(isStart: true),
                    ),
                    const SizedBox(height: 12),
                    _DateTimeTile(
                      label: 'End Time',
                      value: _endTime,
                      onTap: isLoading ? null : () => _pickDateTime(isStart: false),
                    ),
                    const SizedBox(height: 20),
                    _SectionLabel(label: 'Venue'),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _venueNameCtrl,
                      label: 'Venue Name',
                      hint: 'Convention Center',
                      prefixIcon: Icons.location_city_outlined,
                      enabled: !isLoading,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Venue name is required' : null,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _venueAddressCtrl,
                      label: 'Address',
                      hint: '123 Main St',
                      prefixIcon: Icons.location_on_outlined,
                      enabled: !isLoading,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Address is required' : null,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _venueCityCtrl,
                            label: 'City',
                            hint: 'New York',
                            prefixIcon: Icons.apartment_outlined,
                            enabled: !isLoading,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'City is required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: _venueStateCtrl,
                            label: 'State',
                            hint: 'NY',
                            prefixIcon: Icons.map_outlined,
                            enabled: !isLoading,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _venueCountryCtrl,
                            label: 'Country',
                            hint: 'USA',
                            prefixIcon: Icons.flag_outlined,
                            enabled: !isLoading,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Country is required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: _venuePostalCtrl,
                            label: 'Postal Code',
                            hint: '10001',
                            prefixIcon: Icons.markunread_mailbox_outlined,
                            enabled: !isLoading,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      label: 'Create Event',
                      onPressed: _submit,
                      isLoading: isLoading,
                      icon: Icons.add_circle_outline,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback? onTap;

  const _DateTimeTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE, MMM d, yyyy  ·  h:mm a');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule_outlined,
                size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: 2),
                  Text(
                    value != null ? fmt.format(value!) : 'Tap to select',
                    style: value != null
                        ? AppTextStyles.bodyMedium
                        : AppTextStyles.body.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}