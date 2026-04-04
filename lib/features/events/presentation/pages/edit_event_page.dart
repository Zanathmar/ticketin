import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../bloc/events_bloc.dart';
import '../../data/models/event_model.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/snack_helper.dart';

class EditEventPage extends StatefulWidget {
  final EventModel event;
  const EditEventPage({super.key, required this.event});

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _capacityCtrl;
  late final TextEditingController _imageUrlCtrl;

  late DateTime? _startTime;
  late DateTime? _endTime;
  late String _status;

  XFile? _pickedFile;
  Uint8List? _pickedBytes;
  bool _useUrlMode = false;

  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleCtrl    = TextEditingController(text: widget.event.title);
    _descCtrl     = TextEditingController(text: widget.event.description ?? '');
    _capacityCtrl = TextEditingController(text: widget.event.capacity.toString());
    // Use resolvedImageUrl so the preview works correctly
    _imageUrlCtrl = TextEditingController(text: widget.event.resolvedImageUrl ?? '');
    _startTime    = widget.event.startTime;
    _endTime      = widget.event.endTime;
    _status       = widget.event.status;
    _useUrlMode   = (widget.event.resolvedImageUrl ?? '').isNotEmpty;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _capacityCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _pickedFile   = file;
        _pickedBytes  = bytes;
        _imageUrlCtrl.clear();
        _useUrlMode   = false;
      });
    } catch (_) {
      if (mounted) SnackHelper.error(context, 'Could not access image. Check permissions.');
    }
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final now  = DateTime.now();
    final init = isStart ? (_startTime ?? now) : (_endTime ?? now);

    final date = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate:  now.add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => _pickerTheme(ctx, child!),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(init),
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
    if (_startTime == null || _endTime == null) {
      SnackHelper.error(context, 'Please select start and end times');
      return;
    }
    if (!_endTime!.isAfter(_startTime!)) {
      SnackHelper.error(context, 'End time must be after start time');
      return;
    }

    final fmt     = DateFormat('yyyy-MM-dd HH:mm:ss');
    final hasFile = _pickedBytes != null && _pickedFile != null;
    final urlVal  = _imageUrlCtrl.text.trim();

    context.read<EventsBloc>().add(EventUpdateRequested(
      id:            widget.event.id,
      title:         _titleCtrl.text.trim(),
      description:   _descCtrl.text.trim(),
      capacity:      int.parse(_capacityCtrl.text.trim()),
      startTime:     fmt.format(_startTime!),
      endTime:       fmt.format(_endTime!),
      imageUrl:      (!hasFile && urlVal.isNotEmpty) ? urlVal : null,
      imageBytes:    hasFile ? _pickedBytes!.toList() : null,
      imageFileName: hasFile ? _pickedFile!.name : null,
      status:        _status,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EventsBloc, EventsState>(
      listener: (context, state) {
        if (state is EventUpdateSuccess) {
          SnackHelper.success(context, 'Event updated successfully!');
          context.pop();
        } else if (state is EventUpdateError) {
          SnackHelper.error(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: const Text('Edit Event'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => context.pop(),
          ),
        ),
        body: BlocBuilder<EventsBloc, EventsState>(
          builder: (context, state) {
            final isLoading = state is EventUpdateLoading;
            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Event Details'),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _titleCtrl,
                      label: 'Title',
                      hint: 'Event title',
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
                    _sectionLabel('Status'),
                    const SizedBox(height: 12),
                    _StatusSelector(
                      value: _status,
                      enabled: !isLoading,
                      onChanged: (v) => setState(() => _status = v),
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel('Event Image'),
                    const SizedBox(height: 12),
                    _ImageSection(
                      pickedBytes:    _pickedBytes,
                      pickedFileName: _pickedFile?.name,
                      urlCtrl:        _imageUrlCtrl,
                      useUrlMode:     _useUrlMode,
                      enabled:        !isLoading,
                      onPickGallery:  _pickImage,
                      onClear: () => setState(() {
                        _pickedFile  = null;
                        _pickedBytes = null;
                        _imageUrlCtrl.clear();
                      }),
                      onToggleMode: () =>
                          setState(() => _useUrlMode = !_useUrlMode),
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel('Date & Time'),
                    const SizedBox(height: 12),
                    _DateTimeTile(
                      label: 'Start Time',
                      value: _startTime,
                      onTap: isLoading
                          ? null
                          : () => _pickDateTime(isStart: true),
                    ),
                    const SizedBox(height: 12),
                    _DateTimeTile(
                      label: 'End Time',
                      value: _endTime,
                      onTap: isLoading
                          ? null
                          : () => _pickDateTime(isStart: false),
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      label: 'Save Changes',
                      onPressed: _submit,
                      isLoading: isLoading,
                      icon: Icons.save_outlined,
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

  Widget _sectionLabel(String label) {
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

// ── Status Selector ───────────────────────────────────────────────────────────

class _StatusSelector extends StatelessWidget {
  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _StatusSelector({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const options = [
      (
        'active',
        'Active',
        Icons.check_circle_outline,
        AppColors.activeGreen,
        AppColors.activeBg,
      ),
      (
        'cancelled',
        'Cancelled',
        Icons.cancel_outlined,
        AppColors.cancelledRed,
        AppColors.cancelledBg,
      ),
      (
        'completed',
        'Completed',
        Icons.flag_outlined,
        AppColors.completedBlue,
        AppColors.completedBg,
      ),
    ];

    return Row(
      children: options.map((o) {
        final selected = value == o.$1;
        return Expanded(
          child: GestureDetector(
            onTap: enabled ? () => onChanged(o.$1) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? o.$5 : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? o.$4 : AppColors.cardBorder,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(o.$3,
                      size: 18,
                      color: selected ? o.$4 : AppColors.textMuted),
                  const SizedBox(height: 4),
                  Text(o.$2,
                      style: AppTextStyles.caption.copyWith(
                        color: selected ? o.$4 : AppColors.textMuted,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      )),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Image Section ─────────────────────────────────────────────────────────────

class _ImageSection extends StatelessWidget {
  final Uint8List? pickedBytes;
  final String? pickedFileName;
  final TextEditingController urlCtrl;
  final bool useUrlMode;
  final bool enabled;
  final VoidCallback onPickGallery;
  final VoidCallback onClear;
  final VoidCallback onToggleMode;

  const _ImageSection({
    required this.pickedBytes,
    required this.pickedFileName,
    required this.urlCtrl,
    required this.useUrlMode,
    required this.enabled,
    required this.onPickGallery,
    required this.onClear,
    required this.onToggleMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode toggle
        Row(
          children: [
            _chip('From Device', Icons.photo_library_outlined, !useUrlMode,
                enabled ? onToggleMode : null),
            const SizedBox(width: 10),
            _chip('From URL', Icons.link_rounded, useUrlMode,
                enabled ? onToggleMode : null),
          ],
        ),
        const SizedBox(height: 12),

        if (!useUrlMode) ...[
          if (pickedBytes != null)
            _previewBox(
              label: pickedFileName ?? 'image',
              onClear: onClear,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(pickedBytes!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover),
              ),
            )
          else
            GestureDetector(
              onTap: enabled ? onPickGallery : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.primary.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.photo_library_outlined,
                        size: 28, color: AppColors.primary),
                    const SizedBox(height: 6),
                    Text('Choose from Gallery',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
        ] else ...[
          StatefulBuilder(builder: (context, setSub) {
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
                if (urlCtrl.text.startsWith('http')) ...[
                  const SizedBox(height: 10),
                  _previewBox(
                    label: 'Current image',
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
          }),
        ],

        const SizedBox(height: 6),
        Text(
          'Leave unchanged to keep the current image.',
          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _chip(
      String label, IconData icon, bool selected, VoidCallback? onTap) {
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
            Text(label,
                style: AppTextStyles.caption.copyWith(
                  color: selected ? AppColors.primary : AppColors.textMuted,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                )),
          ],
        ),
      ),
    );
  }

  Widget _previewBox({
    required Widget child,
    required VoidCallback? onClear,
    required String label,
  }) {
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
                child:
                    const Icon(Icons.close, color: Colors.white, size: 16),
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
                  color: Colors.white, fontSize: 11, fontFamily: 'DMSans'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Date Time Tile ────────────────────────────────────────────────────────────

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