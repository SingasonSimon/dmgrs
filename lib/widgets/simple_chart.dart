import 'package:flutter/material.dart';
import '../utils/responsive.dart';

// Color palette for charts
class ChartColors {
  static const List<Color> primaryPalette = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFFEF4444), // Red
    Color(0xFFF59E0B), // Amber
    Color(0xFF10B981), // Emerald
    Color(0xFF06B6D4), // Cyan
    Color(0xFF3B82F6), // Blue
    Color(0xFF84CC16), // Lime
    Color(0xFFF97316), // Orange
  ];

  static const List<Color> secondaryPalette = [
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFFEF4444), // Red
    Color(0xFFF59E0B), // Amber
    Color(0xFF10B981), // Emerald
    Color(0xFF06B6D4), // Cyan
    Color(0xFF3B82F6), // Blue
    Color(0xFF84CC16), // Lime
    Color(0xFFF97316), // Orange
    Color(0xFF6366F1), // Indigo
  ];

  static const List<Color> successPalette = [
    Color(0xFF10B981), // Emerald
    Color(0xFF059669), // Emerald 600
    Color(0xFF047857), // Emerald 700
    Color(0xFF065F46), // Emerald 800
    Color(0xFF064E3B), // Emerald 900
  ];

  static const List<Color> warningPalette = [
    Color(0xFFF59E0B), // Amber
    Color(0xFFD97706), // Amber 600
    Color(0xFFB45309), // Amber 700
    Color(0xFF92400E), // Amber 800
    Color(0xFF78350F), // Amber 900
  ];

  static const List<Color> errorPalette = [
    Color(0xFFEF4444), // Red
    Color(0xFFDC2626), // Red 600
    Color(0xFFB91C1C), // Red 700
    Color(0xFF991B1B), // Red 800
    Color(0xFF7F1D1D), // Red 900
  ];

  static Color getColorAtIndex(int index, {List<Color>? palette}) {
    final colors = palette ?? primaryPalette;
    return colors[index % colors.length];
  }

  static List<Color> getGradientColors(Color baseColor) {
    return [
      baseColor.withOpacity(0.8),
      baseColor.withOpacity(0.6),
      baseColor.withOpacity(0.4),
      baseColor.withOpacity(0.2),
    ];
  }
}

class SimpleBarChart extends StatelessWidget {
  final List<ChartData> data;
  final String title;
  final double? maxValue;
  final Color? barColor;

  const SimpleBarChart({
    super.key,
    required this.data,
    required this.title,
    this.maxValue,
    this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final max =
        maxValue ?? data.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final chartHeight = ResponsiveHelper.getChartHeight(
                context,
                baseHeight: 280,
              );
              final barMaxHeight = chartHeight - 60; // Space for labels
              final isSmallScreen = ResponsiveHelper.isMobile(context);
              
              return SizedBox(
                height: chartHeight,
                child: isSmallScreen && data.length > 6
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: (data.length * 60).toDouble().clamp(
                            constraints.maxWidth,
                            double.infinity,
                          ),
                          height: chartHeight,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: data.map((item) {
                              final height = (item.value / max) * barMaxHeight;
                              return SizedBox(
                                width: 50,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _formatNumber(item.value),
                                        style: Theme.of(context)
                                            .textTheme.bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 8,
                                              color: Theme.of(context)
                                                  .colorScheme.onSurface,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 800),
                                      width: 16,
                                      height: height,
                                      decoration: BoxDecoration(
                                        color: barColor ??
                                            Theme.of(context).colorScheme.primary,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.label,
                                      style: Theme.of(context)
                                          .textTheme.bodySmall
                                          ?.copyWith(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(context)
                                                .colorScheme.onSurface,
                                          ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: data.map((item) {
                          final height = (item.value / max) * barMaxHeight;
                          return Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _formatNumber(item.value),
                                    style: Theme.of(context)
                                        .textTheme.bodySmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 8,
                                          color: Theme.of(context)
                                              .colorScheme.onSurface,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 800),
                                  width: 16,
                                  height: height,
                                  decoration: BoxDecoration(
                                    color: barColor ??
                                        Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.label,
                                  style: Theme.of(context)
                                      .textTheme.bodySmall
                                      ?.copyWith(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context)
                                            .colorScheme.onSurface,
                                      ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }
}

class SimpleLineChart extends StatelessWidget {
  final List<ChartData> data;
  final String title;
  final double? maxValue;
  final Color? lineColor;
  final Color? fillColor;

  const SimpleLineChart({
    super.key,
    required this.data,
    required this.title,
    this.maxValue,
    this.lineColor,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            const Center(child: Text('No data available')),
          ],
        ),
      );
    }

    final max =
        maxValue ?? data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final min = data.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final range = max - min;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final chartHeight = ResponsiveHelper.getChartHeight(
                context,
                baseHeight: 200,
              );
              final isSmallScreen = ResponsiveHelper.isMobile(context);
              
              return Column(
                children: [
                  SizedBox(
                    height: chartHeight,
                    child: isSmallScreen && data.length > 6
                        ? SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: (data.length * 60).toDouble().clamp(
                                constraints.maxWidth,
                                double.infinity,
                              ),
                              height: chartHeight,
                              child: CustomPaint(
                                painter: LineChartPainter(
                                  data: data,
                                  max: max,
                                  min: min,
                                  range: range,
                                  lineColor: lineColor ??
                                      Theme.of(context).colorScheme.primary,
                                  fillColor: fillColor ??
                                      (lineColor ??
                                              Theme.of(context)
                                                  .colorScheme.primary)
                                          .withOpacity(0.1),
                                ),
                                child: Container(),
                              ),
                            ),
                          )
                        : CustomPaint(
                            painter: LineChartPainter(
                              data: data,
                              max: max,
                              min: min,
                              range: range,
                              lineColor: lineColor ??
                                  Theme.of(context).colorScheme.primary,
                              fillColor: fillColor ??
                                  (lineColor ??
                                          Theme.of(context).colorScheme.primary)
                                      .withOpacity(0.1),
                            ),
                            child: Container(),
                          ),
                  ),
                  const SizedBox(height: 8),
                  // Month labels and values
                  isSmallScreen && data.length > 6
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: (data.length * 60).toDouble().clamp(
                              constraints.maxWidth,
                              double.infinity,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: data.map((item) {
                                    final formattedValue =
                                        _formatChartValue(item.value);
                                    return SizedBox(
                                      width: 50,
                                      child: Text(
                                        formattedValue,
                                        style: Theme.of(context)
                                            .textTheme.bodySmall
                                            ?.copyWith(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme.primary,
                                            ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: data.map((item) {
                                    return SizedBox(
                                      width: 50,
                                      child: Text(
                                        item.label,
                                        style: Theme.of(context)
                                            .textTheme.bodySmall
                                            ?.copyWith(
                                              fontSize: 10,
                                              color: Theme.of(context)
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: data.map((item) {
                                final formattedValue =
                                    _formatChartValue(item.value);
                                return Expanded(
                                  child: Text(
                                    formattedValue,
                                    style: Theme.of(context)
                                        .textTheme.bodySmall
                                        ?.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme.primary,
                                        ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: data.map((item) {
                                return Expanded(
                                  child: Text(
                                    item.label,
                                    style: Theme.of(context)
                                        .textTheme.bodySmall
                                        ?.copyWith(
                                          fontSize: 10,
                                          color: Theme.of(context)
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatChartValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else if (value == 0) {
      return '0';
    } else {
      return value.toStringAsFixed(0);
    }
  }
}

class LineChartPainter extends CustomPainter {
  final List<ChartData> data;
  final double max;
  final double min;
  final double range;
  final Color lineColor;
  final Color fillColor;

  LineChartPainter({
    required this.data,
    required this.max,
    required this.min,
    required this.range,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final width = size.width;
    final height = size.height;
    final stepX = width / (data.length - 1);

    // Start the fill path from the bottom
    fillPath.moveTo(0, height);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedValue = range > 0 ? (data[i].value - min) / range : 0.5;
      final y = height - (normalizedValue * height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      // Draw data points
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = lineColor);
    }

    // Complete the fill path
    fillPath.lineTo(width, height);
    fillPath.close();

    // Draw fill area
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SimplePieChart extends StatelessWidget {
  final List<ChartData> data;
  final String title;
  final double size;

  const SimplePieChart({
    super.key,
    required this.data,
    required this.title,
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) {
    final total = data.fold(0.0, (sum, item) => sum + item.value);
    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      Colors.orange,
      Colors.green,
      Colors.purple,
    ];
    final responsiveSize = ResponsiveHelper.getPieChartSize(
      context,
      baseSize: size,
    );
    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      padding: ResponsiveHelper.getPadding(context),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          isMobile
              ? Column(
                  children: [
                    SizedBox(
                      width: responsiveSize,
                      height: responsiveSize,
                      child: CustomPaint(
                        painter: PieChartPainter(data, colors),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: data.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final percentage = (item.value / total) * 100;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: colors[index % colors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: Theme.of(context)
                                      .textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${percentage.toStringAsFixed(0)}%',
                                style: Theme.of(context)
                                    .textTheme.bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                )
              : Row(
                  children: [
                    SizedBox(
                      width: responsiveSize,
                      height: responsiveSize,
                      child: CustomPaint(
                        painter: PieChartPainter(data, colors),
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getSpacing(context)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: data.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final percentage = (item.value / total) * 100;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: colors[index % colors.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: Theme.of(context)
                                        .textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${percentage.toStringAsFixed(0)}%',
                                  style: Theme.of(context)
                                      .textTheme.bodySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

class ChartData {
  final String label;
  final double value;
  final Color? color;

  ChartData({required this.label, required this.value, this.color});
}

class PieChartPainter extends CustomPainter {
  final List<ChartData> data;
  final List<Color> colors;

  PieChartPainter(this.data, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final total = data.fold(0.0, (sum, item) => sum + item.value);
    double startAngle = -90 * (3.14159 / 180); // Start from top

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final sweepAngle = (item.value / total) * 2 * 3.14159;

      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AnimatedCounter extends StatefulWidget {
  final double value;
  final Duration duration;
  final TextStyle? style;
  final String? prefix;
  final String? suffix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 1000),
    this.style,
    this.prefix,
    this.suffix,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: 0,
      end: widget.value,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _animation.addListener(() {
      setState(() {
        _currentValue = _animation.value;
      });
    });

    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: _currentValue,
        end: widget.value,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '${widget.prefix ?? ''}${_currentValue.toStringAsFixed(0)}${widget.suffix ?? ''}',
      style: widget.style,
    );
  }
}
