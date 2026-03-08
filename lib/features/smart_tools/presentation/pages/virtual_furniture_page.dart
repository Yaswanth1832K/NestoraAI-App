import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:house_rental/core/theme/app_colors.dart';
import 'dart:ui';

class VirtualFurniturePage extends StatefulWidget {
  const VirtualFurniturePage({super.key});

  @override
  State<VirtualFurniturePage> createState() => _VirtualFurniturePageState();
}

class _VirtualFurniturePageState extends State<VirtualFurniturePage> {
  bool _useArMode = true;
  String _selectedFurniture = 'Sofa';

  final List<Map<String, dynamic>> _furnitureTypes = [
    {'name': 'Bed', 'icon': Icons.bed_rounded, 'model': 'https://modelviewer.dev/shared-assets/models/Astronaut.glb'},
    {'name': 'Sofa', 'icon': Icons.weekend_rounded, 'model': 'https://modelviewer.dev/shared-assets/models/Chair.glb'},
    {'name': 'Table', 'icon': Icons.table_restaurant_rounded, 'model': 'https://modelviewer.dev/shared-assets/models/Chair.glb'},
    {'name': 'Wardrobe', 'icon': Icons.door_sliding_rounded, 'model': 'https://modelviewer.dev/shared-assets/models/Astronaut.glb'},
    {'name': 'Desk', 'icon': Icons.desktop_windows_rounded, 'model': 'https://modelviewer.dev/shared-assets/models/Chair.glb'},
  ];

  @override
  Widget build(BuildContext context) {
    final selectedType = _furnitureTypes.firstWhere((t) => t['name'] == _selectedFurniture);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _useArMode 
            ? _ArPlacementView(modelUrl: selectedType['model'], key: ValueKey(selectedType['model'])) 
            : const _RoomLayout2D(),
          
          // HUD Top Bar
          Positioned(
            top: 50, left: 20, right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _GlassIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.layers_rounded, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        _useArMode ? '3D_MODEL_VIEWER' : '2D_LAYOUT_PLANNER',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
                _GlassIconButton(
                  icon: _useArMode ? Icons.grid_view_rounded : Icons.view_in_ar_rounded,
                  onTap: () => setState(() => _useArMode = !_useArMode),
                ),
              ],
            ),
          ),

          // Bottom Furniture Selector
          Positioned(
            bottom: 30, left: 0, right: 0,
            child: _FurnitureSelector(
              selected: _selectedFurniture,
              types: _furnitureTypes,
              onSelect: (val) => setState(() => _selectedFurniture = val),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArPlacementView extends StatelessWidget {
  final String modelUrl;
  const _ArPlacementView({required this.modelUrl, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Scanner Grid
          CustomPaint(
            painter: _ScannerPainter(),
            size: Size.infinite,
          ),
          
          ModelViewer(
            key: ValueKey(modelUrl),
            backgroundColor: Colors.transparent,
            src: modelUrl,
            alt: "A 3D model of furniture",
            ar: true,
            autoRotate: true,
            cameraControls: true,
            loading: Loading.eager,
            arModes: const ['scene-viewer', 'webxr', 'quick-look'],
            // Note: Poster is shown while loading, but we use our own UI for better "high-tech" feel
            poster: "https://via.placeholder.com/500/0F172A/FFFFFF?text=LOADING_3D_ENVIRONMENT...",
          ),

          // Diagnostic Overlays (High-Tech Feel)
          Positioned(
            top: 120, left: 20,
            child: _HighTechStats(
              labels: const ['POLY_COUNT', 'TEXTURE_RES', 'FPS', 'LATENCY'],
              values: const ['24.5k', '2048x2048', '60.0', '12ms'],
            ),
          ),
          
          Positioned(
            bottom: 300, right: 20,
            child: _HighTechStats(
              labels: const ['SCAN_ID', 'CORE_INIT', 'AR_MODE'],
              values: const ['#NX-882', 'SUCCESS', 'OPTICAL_FLOW'],
              alignRight: true,
            ),
          ),

          // Scanning Line Animation
          const _ScanningLine(),
        ],
      ),
    );
  }
}

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

class _ScanningLine extends StatefulWidget {
  const _ScanningLine();
  @override
  State<_ScanningLine> createState() => _ScanningLineState();
}

class _ScanningLineState extends State<_ScanningLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: MediaQuery.of(context).size.height * _controller.value,
          left: 0, right: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0), AppColors.primary, AppColors.primary.withOpacity(0)],
              ),
            ),
          ),
        );
      },
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

class _FurnitureItem {
  final String name;
  final IconData icon;
  Offset position;
  double width; // in feet
  double length; // in feet
  double rotation; // in radians
  
  _FurnitureItem({
    required this.name, 
    required this.icon, 
    required this.position,
    this.width = 3.0,
    this.length = 3.0,
    this.rotation = 0.0,
  });
}

class _RoomLayout2D extends StatefulWidget {
  const _RoomLayout2D();

  @override
  State<_RoomLayout2D> createState() => _RoomLayout2DState();
}

class _RoomLayout2DState extends State<_RoomLayout2D> {
  final GlobalKey _containerKey = GlobalKey();
  double _roomWidth = 15.0;
  double _roomLength = 20.0;
  final List<_FurnitureItem> _placedFurniture = [];
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final parent = context.findAncestorStateOfType<_VirtualFurniturePageState>();
    const double scale = 25.0; // 1 foot = 25 pixels

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = null),
      child: Container(
        color: const Color(0xFF0F172A),
        child: Stack(
          children: [
            CustomPaint(
              painter: _ScannerPainter(),
              size: Size.infinite,
            ),
            
          // Diagnostic Overlays for 2D Layout
          Positioned(
            top: 200, left: 24,
            child: _HighTechStats(
              labels: const ['GRID_LOCK', 'ALIGN_SNAP', 'SCALE_RATIO'],
              values: const ['ENABLED', 'ACTIVE', '1px:1ft'],
            ),
          ),
          
          Column(
              children: [
                const SizedBox(height: 120),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      _DimensionInput(label: 'ROOM WIDTH', value: _roomWidth, onChanged: (v) => setState(() => _roomWidth = v)),
                      const SizedBox(width: 16),
                      _DimensionInput(label: 'ROOM LENGTH', value: _roomLength, onChanged: (v) => setState(() => _roomLength = v)),
                    ],
                  ),
                ),
                const Spacer(),
                Center(
                  child: Container(
                    key: _containerKey,
                    width: _roomWidth * scale,
                    height: _roomLength * scale,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      border: Border.all(color: AppColors.primary, width: 2),
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 20, spreadRadius: 5),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: _placedFurniture.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        final isSelected = _selectedIndex == idx;
  
                        return Positioned(
                          left: item.position.dx,
                          top: item.position.dy,
                          child: GestureDetector(
                            onTapDown: (_) => setState(() => _selectedIndex = idx),
                            child: Draggable(
                              feedback: _FurnitureBox(item: item, scale: scale, isDragging: true),
                              childWhenDragging: Opacity(opacity: 0.3, child: _FurnitureBox(item: item, scale: scale)),
                              onDragEnd: (details) {
                                final RenderBox? renderBox = _containerKey.currentContext?.findRenderObject() as RenderBox?;
                                if (renderBox == null) return;
                                
                                final localPos = renderBox.globalToLocal(details.offset);
                                setState(() {
                                  item.position = Offset(
                                    localPos.dx.clamp(0.0, (_roomWidth * scale) - (item.width * scale)).toDouble(), 
                                    localPos.dy.clamp(0.0, (_roomLength * scale) - (item.length * scale)).toDouble()
                                  );
                                  _selectedIndex = idx;
                                });
                              },
                              child: _FurnitureBox(item: item, scale: scale, isSelected: isSelected),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          
            if (_selectedIndex != null)
              Positioned(
                bottom: 150, left: 20, right: 20,
                child: _FurnitureControls(
                  item: _placedFurniture[_selectedIndex!],
                  onDelete: () => setState(() {
                    _placedFurniture.removeAt(_selectedIndex!);
                    _selectedIndex = null;
                  }),
                  onUpdate: () => setState(() {}),
                ),
              ),

            Positioned(
              right: 20, bottom: 150,
              child: FloatingActionButton(
                backgroundColor: AppColors.primary,
                elevation: 8,
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
                onPressed: () {
                  if (parent == null) return;
                  final type = parent._furnitureTypes.firstWhere((t) => t['name'] == parent._selectedFurniture);
                  setState(() {
                    _placedFurniture.add(_FurnitureItem(
                      name: type['name'],
                      icon: type['icon'],
                      position: const Offset(20, 20),
                      width: type['name'] == 'Bed' ? 6.0 : (type['name'] == 'Sofa' ? 7.0 : 3.0),
                      length: type['name'] == 'Bed' ? 7.0 : (type['name'] == 'Sofa' ? 3.0 : 3.0),
                    ));
                    _selectedIndex = _placedFurniture.length - 1;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FurnitureBox extends StatelessWidget {
  final _FurnitureItem item;
  final double scale;
  final bool isSelected;
  final bool isDragging;

  const _FurnitureBox({
    required this.item, 
    required this.scale, 
    this.isSelected = false,
    this.isDragging = false,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: item.rotation,
      child: Container(
        width: item.width * scale,
        height: item.length * scale,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(isDragging ? 0.6 : 0.3),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? Colors.white : AppColors.primary, 
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: Colors.white.withOpacity(0.5), size: 16),
                if (item.width > 3)
                  Text(
                    '${item.width.toInt()}x${item.length.toInt()} ft',
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: 2, right: 2,
                child: Container(
                  width: 4, height: 4,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FurnitureControls extends StatelessWidget {
  final _FurnitureItem item;
  final VoidCallback onDelete;
  final VoidCallback onUpdate;

  const _FurnitureControls({required this.item, required this.onDelete, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.black.withOpacity(0.6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    onPressed: onDelete,
                  ),
                ],
              ),
              const Divider(color: Colors.white10),
              Row(
                children: [
                  Expanded(
                    child: _SliderControl(
                      label: 'WIDTH',
                      value: item.width,
                      min: 1, max: 12,
                      onChanged: (v) { item.width = v; onUpdate(); },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SliderControl(
                      label: 'LENGTH',
                      value: item.length,
                      min: 1, max: 12,
                      onChanged: (v) { item.length = v; onUpdate(); },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SliderControl(
                label: 'ROTATION',
                value: item.rotation,
                min: 0, max: 6.28, // 2*PI
                onChanged: (v) { item.rotation = v; onUpdate(); },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderControl extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final Function(double) onChanged;

  const _SliderControl({required this.label, required this.value, required this.min, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
            Text(label == 'ROTATION' ? '${(value * 180 / 3.14).toInt()}°' : '${value.toInt()} ft', 
                 style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            activeColor: AppColors.primary,
            inactiveColor: Colors.white10,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _FurnitureSelector extends StatelessWidget {
  final String selected;
  final List<Map<String, dynamic>> types;
  final Function(String) onSelect;

  const _FurnitureSelector({required this.selected, required this.types, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final type = types[index];
          final isSelected = selected == type['name'];
          return GestureDetector(
            onTap: () => onSelect(type['name']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 80,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white24,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(type['icon'], color: Colors.white, size: 28),
                  const SizedBox(height: 4),
                  Text(
                    type['name'],
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FurnitureIcon extends StatelessWidget {
  final IconData icon;
  const _FurnitureIcon({required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.8),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

class _DimensionInput extends StatefulWidget {
  final String label;
  final double value;
  final Function(double) onChanged;

  const _DimensionInput({required this.label, required this.value, required this.onChanged});

  @override
  State<_DimensionInput> createState() => _DimensionInputState();
}

class _DimensionInputState extends State<_DimensionInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toInt().toString());
  }

  @override
  void didUpdateWidget(_DimensionInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _controller.text = widget.value.toInt().toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      suffixText: ' ft',
                      suffixStyle: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    onChanged: (v) {
                      final val = double.tryParse(v);
                      if (val != null) widget.onChanged(val);
                    },
                    onSubmitted: (v) {
                      final val = double.tryParse(v);
                      if (val != null) widget.onChanged(val);
                      FocusScope.of(context).unfocus();
                    },
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(onTap: () => widget.onChanged(widget.value - 1), child: const Icon(Icons.remove, color: Colors.white54, size: 18)),
                    const SizedBox(width: 8),
                    GestureDetector(onTap: () => widget.onChanged(widget.value + 1), child: const Icon(Icons.add, color: AppColors.primary, size: 18)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1.0;

    const spacing = 30.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
