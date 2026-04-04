
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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
  final _imageUrlCtrl = TextEditingController();

  final _venueNameCtrl = TextEditingController();
  final _venueAddressCtrl = TextEditingController();
  final _venueCityCtrl = TextEditingController();
  final _venueStateCtrl = TextEditingController();
  final _venueCountryCtrl = TextEditingController();
  final _venuePostalCtrl = TextEditingController();

  DateTime? _startTime;
  DateTime? _endTime;

  // Picked image state
  XFile? _pickedFile;
  Uint8List? _pickedBytes;
  bool _useUrlMode = false; // toggle between file picker and URL

  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _capacityCtrl.dispose();
    _imageUrlCtrl.dispose();
    _venueNameCtrl.dispose();
    _venueAddressCtrl.dispose();
    _venueCityCtrl.dispose();
    _venueStateCtrl.dispose();
    _venueCountryCtrl.dispose();
    _venuePostalCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _pickedFile = file;
        _pickedBytes = bytes;
        _imageUrlCtrl.clear();
      });
    } catch (_) {
      if (mounted) SnackHelper.error(context, 'Could not access image. Check permissions.');
    }
  }

  void _clearImage() {
    setState(() {
      _pickedFile = null;
      _pickedBytes = null;
      _imageUrlCtrl.clear();
    });
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => _datePickerTheme(ctx, child!),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => _datePickerTheme(ctx, child!),
    );
    if (time == null || !mounted) return;
    final picked =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  Widget _datePickerTheme(BuildContext ctx, Widget child) {
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
    final hasFile = _pickedBytes != null && _pickedFile != null;
    final urlValue = _imageUrlCtrl.text.trim();

    context.read<EventsBloc>().add(EventCreateRequested(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          capacity: int.parse(_capacityCtrl.text.trim()),
          startTime: fmt.format(_startTime!),
          endTime: fmt.format(_endTime!),
          imageUrl: (!hasFile && urlValue.isNotEmpty) ? urlValue : null,
          imageBytes: hasFile ? _pickedBytes!.toList() : null,
          imageFileName: hasFile ? _pickedFile!.name : null,
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
                    _SectionLabel(label: 'Event Image'),
                    const SizedBox(height: 12),
                    _ImagePicker(
                      pickedBytes: _pickedBytes,
                      pickedFileName: _pickedFile?.name,
                      urlCtrl: _imageUrlCtrl,
                      useUrlMode: _useUrlMode,
                      enabled: !isLoading,
                      onPickGallery: () => _pickImage(ImageSource.gallery),
                      onPickCamera: () => _pickImage(ImageSource.camera),
                      onClear: _clearImage,
                      onToggleMode: () =>
                          setState(() => _useUrlMode = !_useUrlMode),
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

// ─── Image Picker Widget ──────────────────────────────────────────────────────

class _ImagePicker extends StatelessWidget {
  final Uint8List? pickedBytes;
  final String? pickedFileName;
  final TextEditingController urlCtrl;
  final bool useUrlMode;
  final bool enabled;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final VoidCallback onClear;
  final VoidCallback onToggleMode;

  const _ImagePicker({
    required this.pickedBytes,
    required this.pickedFileName,
    required this.urlCtrl,
    required this.useUrlMode,
    required this.enabled,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onClear,
    required this.onToggleMode,
  });

  bool get _hasFile => pickedBytes != null;
  bool get _hasUrl => urlCtrl.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode toggle
        Row(
          children: [
            _ModeChip(
              label: 'From Device',
              icon: Icons.photo_library_outlined,
              selected: !useUrlMode,
              onTap: enabled ? onToggleMode : null,
            ),
            const SizedBox(width: 10),
            _ModeChip(
              label: 'From URL',
              icon: Icons.link_rounded,
              selected: useUrlMode,
              onTap: enabled ? onToggleMode : null,
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (!useUrlMode) ...[
          // File picker mode
          if (_hasFile) ...[
            _ImagePreviewBox(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(pickedBytes!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover),
              ),
              onClear: onClear,
              label: pickedFileName ?? 'image',
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _PickerButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery',
                    onTap: enabled ? onPickGallery : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerButton(
                    icon: Icons.camera_alt_outlined,
                    label: 'Camera',
                    onTap: (!kIsWeb && enabled) ? onPickCamera : null,
                    disabled: kIsWeb,
                  ),
                ),
              ],
            ),
          ],
        ] else ...[
          // URL mode
          StatefulBuilder(
            builder: (context, setSub) {
              return Column(
                children: [
                  TextFormField(
                    controller: urlCtrl,
                    enabled: enabled,
                    style: AppTextStyles.body,
                    keyboardType: TextInputType.url,
                    onChanged: (_) => setSub(() {}),
                    decoration: InputDecoration(
                      labelText: 'Image URL',
                      hintText: 'https://example.com/image.jpg',
                      prefixIcon: const Icon(Icons.link_rounded),
                      suffixIcon: urlCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: AppColors.textMuted, size: 18),
                              onPressed: () {
                                urlCtrl.clear();
                                setSub(() {});
                              },
                            )
                          : null,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      if (!v.startsWith('http')) return 'Enter a valid URL';
                      return null;
                    },
                  ),
                  if (_hasUrl && urlCtrl.text.startsWith('http')) ...[
                    const SizedBox(height: 10),
                    _ImagePreviewBox(
                      label: 'Preview',
                      onClear: null,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          urlCtrl.text,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Text('Cannot load image',
                                style: TextStyle(color: AppColors.textMuted)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],

        const SizedBox(height: 6),
        Text(
          'Optional — leave empty to skip the cover image.',
          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _ImagePreviewBox extends StatelessWidget {
  final Widget child;
  final VoidCallback? onClear;
  final String label;

  const _ImagePreviewBox({
    required this.child,
    required this.label,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: child,
        ),
        if (onClear != null)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onClear,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontFamily: 'DMSans'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool disabled;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final active = !disabled && onTap != null;
    return GestureDetector(
      onTap: active ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withOpacity(0.08)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? AppColors.primary.withOpacity(0.4) : AppColors.cardBorder,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 28,
                color: active ? AppColors.primary : AppColors.textMuted),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: active ? AppColors.primary : AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (disabled)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('(not on web)',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted, fontSize: 10)),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15,
                color: selected ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: selected ? AppColors.primary : AppColors.textMuted,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

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
                        : AppTextStyles.body
                            .copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}