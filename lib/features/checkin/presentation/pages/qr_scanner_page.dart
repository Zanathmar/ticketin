import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../presentation/bloc/checkin_bloc.dart';
import '../../../../shared/theme/app_theme.dart';

class QrScannerPage extends StatefulWidget {
  final bool isCheckOut;
  const QrScannerPage({super.key, this.isCheckOut = false});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  MobileScannerController? _controller;
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    setState(() => _scanned = true);
    _controller?.stop();

    context.read<CheckInBloc>().add(CheckInQrScanned(
          qrData: raw,
          isCheckOut: widget.isCheckOut,
        ));
  }

  void _reset() {
    setState(() => _scanned = false);
    context.read<CheckInBloc>().add(CheckInReset());
    _controller?.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.isCheckOut ? 'Scan to Check-Out' : 'Scan to Check-In',
          style: AppTextStyles.title.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => _controller?.toggleTorch(),
          ),
        ],
      ),
      body: BlocConsumer<CheckInBloc, CheckInState>(
        listener: (context, state) {
          if (state is CheckInSuccess || state is CheckInError) {
            _showResultSheet(context, state);
          }
        },
        builder: (context, state) {
          return Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: _controller!,
                onDetect: _onDetect,
              ),
              _ScannerOverlay(isCheckOut: widget.isCheckOut),
              if (state is CheckInLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showResultSheet(BuildContext context, CheckInState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isDismissible: false,
      builder: (_) {
        if (state is CheckInSuccess) {
          return _ResultSheet(
            isSuccess: true,
            title: widget.isCheckOut ? 'Checked Out!' : 'Checked In!',
            message: state.message,
            registration: state.registration,
            onDone: () {
              Navigator.pop(context);
              _reset();
            },
          );
        } else if (state is CheckInError) {
          return _ResultSheet(
            isSuccess: false,
            title: 'Error',
            message: (state).message,
            onDone: () {
              Navigator.pop(context);
              _reset();
            },
          );
        }
        return const SizedBox();
      },
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  final bool isCheckOut;
  const _ScannerOverlay({this.isCheckOut = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark overlay around scanner
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.6),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                  decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut)),
              Center(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Corner brackets
        Center(
          child: SizedBox(
            width: 260,
            height: 260,
            child: CustomPaint(
              painter: _CornerPainter(
                  color: isCheckOut ? AppColors.error : AppColors.primary),
            ),
          ),
        ),
        // Bottom label
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                isCheckOut
                    ? 'Point camera at your QR code to check out'
                    : 'Point camera at your QR code to check in',
                style: const TextStyle(color: Colors.white, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 28.0;
    const r = 12.0;

    // Top-left
    canvas.drawLine(Offset(r, 0), Offset(len, 0), paint);
    canvas.drawLine(Offset(0, r), Offset(0, len), paint);
    canvas.drawArc(const Rect.fromLTWH(0, 0, r * 2, r * 2), 3.14, -1.57, false, paint);

    // Top-right
    canvas.drawLine(Offset(size.width - len, 0), Offset(size.width - r, 0), paint);
    canvas.drawLine(Offset(size.width, r), Offset(size.width, len), paint);
    canvas.drawArc(Rect.fromLTWH(size.width - r * 2, 0, r * 2, r * 2), 4.71, -1.57, false, paint);

    // Bottom-left
    canvas.drawLine(Offset(0, size.height - len), Offset(0, size.height - r), paint);
    canvas.drawLine(Offset(r, size.height), Offset(len, size.height), paint);
    canvas.drawArc(Rect.fromLTWH(0, size.height - r * 2, r * 2, r * 2), 1.57, -1.57, false, paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width, size.height - len), Offset(size.width, size.height - r), paint);
    canvas.drawLine(Offset(size.width - len, size.height), Offset(size.width - r, size.height), paint);
    canvas.drawArc(Rect.fromLTWH(size.width - r * 2, size.height - r * 2, r * 2, r * 2), 0, -1.57, false, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ResultSheet extends StatelessWidget {
  final bool isSuccess;
  final String title;
  final String message;
  final Map<String, dynamic>? registration;
  final VoidCallback onDone;

  const _ResultSheet({
    required this.isSuccess,
    required this.title,
    required this.message,
    this.registration,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isSuccess
                  ? AppColors.successLight
                  : AppColors.errorLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check_rounded : Icons.close_rounded,
              color: isSuccess ? AppColors.success : AppColors.error,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.headline3),
          const SizedBox(height: 8),
          Text(message,
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          if (registration != null && isSuccess) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    label: 'Status',
                    value: registration!['is_inside'] == true
                        ? 'Inside'
                        : 'Checked Out',
                  ),
                  if (registration!['last_checkin'] != null)
                    _InfoRow(
                        label: 'Last Check-in',
                        value: registration!['last_checkin'].toString()),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onDone,
            child: const Text('Scan Another'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption),
          Text(value,
              style: AppTextStyles.bodyMedium.copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}
