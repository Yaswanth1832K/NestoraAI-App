import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:house_rental/core/theme/app_colors.dart';
import 'dart:math' as math;

class ArMeasurementPage extends StatefulWidget {
  const ArMeasurementPage({super.key});

  @override
  State<ArMeasurementPage> createState() => _ArMeasurementPageState();
}

class _ArMeasurementPageState extends State<ArMeasurementPage> with TickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isReady = false;
  String? _errorMessage;
  
  Offset? _pointA;
  Offset? _pointB;
  double _pixelsToMeter = 200.0; // Initial calibration: 200 pixels = 1 meter

  late AnimationController _scanController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  
  @override
  void initState() {
    super.initState();
    _initCamera();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  Future<void> _initCamera() async {
    setState(() {
      _isReady = false;
      _errorMessage = null;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        throw 'No cameras found on this device.';
      }
      
      _controller = CameraController(
        _cameras![0], 
        ResolutionPreset.high,
        enableAudio: false,
      );
      
      await _controller!.initialize();
      
      if (!mounted) return;
      setState(() => _isReady = true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isReady = false;
        _errorMessage = e.toString().contains('Permission') 
            ? 'Camera permission denied. Please enable it in settings.' 
            : 'Failed to initialize camera: $e';
      });
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _onTap(TapUpDetails details) {
    setState(() {
      if (_pointA == null || (_pointA != null && _pointB != null)) {
        _pointA = details.localPosition;
        _pointB = null;
      } else {
        _pointB = details.localPosition;
      }
    });
  }

  double _calculateDistance() {
    if (_pointA == null || _pointB == null) return 0;
    final dx = _pointA!.dx - _pointB!.dx;
    final dy = _pointA!.dy - _pointB!.dy;
    final pixels = math.sqrt(dx * dx + dy * dy);
    return pixels / _pixelsToMeter;
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _ErrorBuffer(onRetry: _initCamera, message: _errorMessage!);
    }

    if (!_isReady) {
      return const _LoadingBuffer();
    }

    final distance = _calculateDistance();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Preview
          Positioned.fill(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            ),
          ),

          // 2. High-Tech Scanner Grid
          Positioned.fill(
            child: CustomPaint(painter: _ScannerPainter()),
          ),

          // 3. Sci-Fi Scanning HUD
          _ScanningLaser(controller: _scanController),

          // 4. Data Streams (Left Side)
          _MatrixStream(alignLeft: true),
          _MatrixStream(alignLeft: false),

          // 5. Triple-Nested Radar Widget
          Positioned(
            top: 60,
            left: 20,
            child: _UltimateRadar(animation: _rotationController),
          ),

          // Diagnostic Overlays
          Positioned(
            top: 160, left: 20,
            child: _HighTechStats(
              labels: const ['LIDAR_SENS', 'CORE_TEMP', 'SYNC_LAG'],
              values: const ['OPTIMAL', '38.2°C', '4ms'],
            ),
          ),

          // 6. Telemetry Glass Box
          Positioned(
            top: 50,
            right: 20,
            child: _TelemetryPanel(pixelsToMeter: _pixelsToMeter),
          ),

          // 7. Graphics Overlay
          IgnorePointer(
            child: CustomPaint(
              painter: _UltimateMeasurementPainter(
                pointA: _pointA,
                pointB: _pointB,
                pulse: _pulseController.value,
                rotation: _rotationController.value,
              ),
              child: Container(),
            ),
          ),

          // 8. Transparent Interaction Layer
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: _onTap,
            ),
          ),

          // 9. Futuristic Control Hub
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: _ControlHub(
              pointA: _pointA,
              pointB: _pointB,
              distance: distance,
              pixelsToMeter: _pixelsToMeter,
              onCalibrate: (v) => setState(() => _pixelsToMeter = v),
              onReset: () => setState(() { _pointA = null; _pointB = null; }),
            ),
          ),

          // 10. Floating HUD Elements (Corners)
          _CornerHUD(Alignment.topLeft, 'AZ_TRUE_N'),
          _CornerHUD(Alignment.topRight, 'HD_LOCK_ON'),

          // Close Button
          Positioned(
            top: 40,
            left: 20,
            child: _IconButton(icon: Icons.close_rounded, onTap: () => Navigator.pop(context)),
          ),
          
          if (_pointA != null && _pointB == null)
            Center(
              child: _TargetReticle(animation: _rotationController),
            ),
        ],
      ),
    );
  }
}

// --- HUD SUB-COMPONENTS ---

class _ScanningLaser extends StatelessWidget {
  final AnimationController controller;
  const _ScanningLaser({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Positioned(
          top: MediaQuery.of(context).size.height * controller.value,
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(color: AppColors.primary.withOpacity(0.8), blurRadius: 20, spreadRadius: 2),
                BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 40, spreadRadius: 10),
              ],
              gradient: LinearGradient(
                colors: [Colors.transparent, AppColors.primary.withOpacity(0.2), AppColors.primary, AppColors.primary.withOpacity(0.2), Colors.transparent],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UltimateRadar extends StatelessWidget {
  final AnimationController animation;
  const _UltimateRadar({required this.animation});

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: animation,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 1)),
          ),
          RotationTransition(
            turns: ReverseAnimation(animation),
            child: Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 4, strokeAlign: BorderSide.strokeAlignOutside),
              ),
              child: CustomPaint(painter: _RadarLinesPainter()),
            ),
          ),
          const Icon(Icons.navigation_rounded, color: AppColors.primary, size: 10),
        ],
      ),
    );
  }
}

class _MatrixStream extends StatefulWidget {
  final bool alignLeft;
  const _MatrixStream({required this.alignLeft});

  @override
  State<_MatrixStream> createState() => _MatrixStreamState();
}

class _MatrixStreamState extends State<_MatrixStream> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final List<String> _data = List.generate(50, (_) => '');

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _fillData();
  }

  void _fillData() {
    final chars = '0123456789ABCDEF';
    final rand = math.Random();
    for (var i = 0; i < _data.length; i++) {
      _data[i] = List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.alignLeft ? 10 : null,
      right: widget.alignLeft ? null : 10,
      top: 100,
      bottom: 200,
      child: FadeTransition(
        opacity: _ctrl.drive(CurveTween(curve: Curves.easeInOut)),
        child: Column(
          children: _data.take(20).map((d) => Text(d, style: TextStyle(color: AppColors.primary.withOpacity(0.15), fontSize: 6, fontWeight: FontWeight.bold, letterSpacing: 2))).toList(),
        ),
      ),
    );
  }
}

class _TelemetryPanel extends StatelessWidget {
  final double pixelsToMeter;
  const _TelemetryPanel({required this.pixelsToMeter});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _TeleItem('NODE_ID', 'NSTR-08', Colors.cyanAccent),
              _TeleItem('LINK_STAT', 'STABLE', Colors.greenAccent),
              _TeleItem('CAL_RATIO', '${pixelsToMeter.toInt()} PX/M', Colors.white70),
              _TeleItem('GYRO_FIX', 'ACTIVE', Colors.blueAccent),
              const SizedBox(height: 6),
              Container(width: 80, height: 1, color: Colors.white10),
              const SizedBox(height: 4),
              const Text('ENV_RECOGNITION: 94%', style: TextStyle(color: Colors.white24, fontSize: 6, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _TeleItem(String k, String v, Color c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$k:', style: const TextStyle(color: Colors.white24, fontSize: 7, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Text(v, style: TextStyle(color: c, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }
}

class _ControlHub extends StatelessWidget {
  final Offset? pointA, pointB;
  final double distance, pixelsToMeter;
  final Function(double) onCalibrate;
  final VoidCallback onReset;

  const _ControlHub({required this.pointA, required this.pointB, required this.distance, required this.pixelsToMeter, required this.onCalibrate, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withOpacity(0.6), width: 1.5),
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 40, spreadRadius: -10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pointA == null)
                _StatusBadge('INITIALIZING_ENV_MAPPING', Icons.waves_rounded)
              else if (pointB == null)
                _StatusBadge('LOCKING_TARGET_NODES', Icons.center_focus_strong_rounded)
              else
                Column(
                  children: [
                    Text('CALCULATED_SPATIAL_DISTANCE', style: TextStyle(color: AppColors.primary.withOpacity(0.4), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 3)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Icon(Icons.architecture_rounded, color: AppColors.primaryLight, size: 32),
                        const SizedBox(width: 15),
                        Text(distance.toStringAsFixed(3), style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: -3)),
                        const Padding(padding: EdgeInsets.only(bottom: 8, left: 5), child: Text('METERS', style: TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1))),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 25),
              _CalibrationArea(value: pixelsToMeter, onChanged: onCalibrate),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('AI_CORRECTION: V2.5.0', style: TextStyle(color: Colors.white24, fontSize: 7, fontWeight: FontWeight.bold)),
                  _ResetBtn(onReset: onReset),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _StatusBadge(String t, IconData i) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withOpacity(0.3))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(i, color: AppColors.primaryLight, size: 16),
          const SizedBox(width: 12),
          Text(t, style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2)),
        ],
      ),
    );
  }
}

class _CalibrationArea extends StatelessWidget {
  final double value;
  final Function(double) onChanged;
  const _CalibrationArea({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.tune_rounded, color: Colors.white54, size: 14),
            const SizedBox(width: 8),
            const Text('MANUAL_CALIBRATION_CORRECTION', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const Spacer(),
            Text('${value.toInt()} PX', style: const TextStyle(color: AppColors.primaryLight, fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: Colors.white.withOpacity(0.05),
            thumbColor: Colors.white,
            trackHeight: 1,
            overlayColor: AppColors.primary.withOpacity(0.1),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
          ),
          child: Slider(value: value, min: 50, max: 1000, onChanged: onChanged),
        ),
      ],
    );
  }
}

class _ResetBtn extends StatelessWidget {
  final VoidCallback onReset;
  const _ResetBtn({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onReset,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.redAccent.withOpacity(0.2))),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cleaning_services_rounded, size: 12, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('PURGE_BUFFER', style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _CornerHUD extends StatelessWidget {
  final Alignment align;
  final String text;
  const _CornerHUD(this.align, this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: align,
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Text(text, style: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 7, fontWeight: FontWeight.bold, letterSpacing: 3)),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle, border: Border.all(color: Colors.white10)),
        child: Icon(icon, color: Colors.white70, size: 18),
      ),
    );
  }
}

class _TargetReticle extends StatelessWidget {
  final AnimationController animation;
  const _TargetReticle({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _UltimateReticlePainter(rotation: animation.value),
          child: const SizedBox(width: 120, height: 120),
        );
      },
    );
  }
}

// --- PAINTERS ---

class _HighTechStats extends StatelessWidget {
  final List<String> labels;
  final List<String> values;
  final bool alignRight;

  const _HighTechStats({required this.labels, required this.values, this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: List.generate(labels.length, (idx) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!alignRight) ...[
                Text('${labels[idx]}:', style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(width: 8),
                Text(values[idx], style: const TextStyle(color: AppColors.primary, fontSize: 8, fontWeight: FontWeight.bold)),
              ] else ...[
                Text(values[idx], style: const TextStyle(color: AppColors.primary, fontSize: 8, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text('${labels[idx]}:', style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _ScannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const spacing = 100.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
    
    // Corners
    final cornerPaint = Paint()..color = AppColors.primary.withOpacity(0.2)..strokeWidth = 2;
    const l = 40.0;
    canvas.drawLine(const Offset(40, 100), const Offset(40+l, 100), cornerPaint);
    canvas.drawLine(const Offset(40, 100), const Offset(40, 100+l), cornerPaint);
    
    canvas.drawLine(Offset(size.width - 40, 100), Offset(size.width - 40 - l, 100), cornerPaint);
    canvas.drawLine(Offset(size.width - 40, 100), Offset(size.width - 40, 100 + l), cornerPaint);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _RadarLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.primary.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 1;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), paint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), paint);
    canvas.drawCircle(center, 5, Paint()..color = AppColors.primary);
  }
  @override bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _UltimateReticlePainter extends CustomPainter {
  final double rotation;
  _UltimateReticlePainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.primary..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation * 2 * math.pi);
    
    // Brackets
    for (var i = 0; i < 4; i++) {
      canvas.save();
      canvas.rotate(i * math.pi / 2);
      canvas.drawLine(Offset(-radius, -radius), Offset(-radius + 20, -radius), paint);
      canvas.drawLine(Offset(-radius, -radius), Offset(-radius, -radius + 20), paint);
      canvas.restore();
    }
    canvas.restore();
    
    // Dot pulse
    canvas.drawCircle(center, 2, Paint()..color = AppColors.primary);
  }
  @override bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class _UltimateMeasurementPainter extends CustomPainter {
  final Offset? pointA, pointB;
  final double pulse, rotation;

  _UltimateMeasurementPainter({this.pointA, this.pointB, required this.pulse, required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()..color = AppColors.primary.withOpacity(0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final line = Paint()..color = AppColors.primary..strokeWidth = 4..strokeCap = StrokeCap.round;

    if (pointA != null) _drawAnchor(canvas, pointA!, true);
    if (pointB != null) {
      _drawAnchor(canvas, pointB!, false);
      canvas.drawLine(pointA!, pointB!, glow);
      canvas.drawLine(pointA!, pointB!, line);
      _drawMarkers(canvas, pointA!, pointB!);
    }
  }

  void _drawAnchor(Canvas canvas, Offset p, bool primary) {
    canvas.drawCircle(p, 25 * (1 + pulse * 0.2), Paint()..color = AppColors.primary.withOpacity((0.1 * (1 - pulse)).clamp(0.0, 1.0))..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawCircle(p, 6, Paint()..color = Colors.white);
    canvas.drawCircle(p, 12, Paint()..color = AppColors.primary.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 3);
    
    final text = TextPainter(
      text: TextSpan(text: primary ? 'ANCHOR_A' : 'ANCHOR_B', style: TextStyle(color: AppColors.primaryLight, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, Offset(p.dx - 25, p.dy + 25));
  }

  void _drawMarkers(Canvas canvas, Offset p1, Offset p2) {
    final dx = p1.dx - p2.dx;
    final dy = p1.dy - p2.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len == 0) return;
    final nx = -dy / len, ny = dx / len;
    final paint = Paint()..color = Colors.white70..strokeWidth = 1.5;
    canvas.drawLine(Offset(p1.dx + nx * 15, p1.dy + ny * 15), Offset(p1.dx - nx * 15, p1.dy - ny * 15), paint);
    canvas.drawLine(Offset(p2.dx + nx * 15, p2.dy + ny * 15), Offset(p2.dx - nx * 15, p2.dy - ny * 15), paint);
  }

  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- UTILITY WIDGETS ---

class _LoadingBuffer extends StatelessWidget {
  const _LoadingBuffer();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
  }
}

class _ErrorBuffer extends StatelessWidget {
  final VoidCallback onRetry;
  final String message;
  const _ErrorBuffer({required this.onRetry, required this.message});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 64),
        const SizedBox(height: 20),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 40),
        ElevatedButton(onPressed: onRetry, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), child: const Text('RELOAD_SYSTEM')),
      ]))),
    );
  }
}
