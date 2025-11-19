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
            if (title.isNotEmpty)
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            if (title.isNotEmpty) const SizedBox(height: 16),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'No data available',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final max =
        maxValue ?? data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final min = data.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    // Ensure minimum range for better visualization
    final adjustedMax = (max == min ? max + 1000 : max).toDouble();
    final adjustedMin = (max == min ? (min > 0 ? min - 1000 : 0) : min).toDouble();
    final adjustedRange = adjustedMax - adjustedMin;

    final primaryColor = lineColor ?? Theme.of(context).colorScheme.primary;
    final fillGradientColor = fillColor ?? primaryColor.withOpacity(0.15);

    return Container(
      padding: ResponsiveHelper.getPadding(context),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final chartHeight = ResponsiveHelper.getChartHeight(
                context,
                baseHeight: ResponsiveHelper.isMobile(context) ? 220 : 280,
              );
              final isSmallScreen = ResponsiveHelper.isMobile(context);
              final chartWidth = isSmallScreen && data.length > 6
                  ? (data.length * 70).toDouble().clamp(
                      constraints.maxWidth,
                      double.infinity,
                    )
                  : constraints.maxWidth;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Y-axis labels
                  SizedBox(
                    height: chartHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Y-axis labels
                        SizedBox(
                          width: isSmallScreen ? 45 : 60,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(5, (index) {
                              final value = adjustedMax -
                                  (adjustedRange / 4) * index;
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: isSmallScreen ? 4 : 8,
                                ),
                                child: Text(
                                  _formatChartValue(value),
                                  style: Theme.of(context)
                                      .textTheme.bodySmall
                                      ?.copyWith(
                                        fontSize: isSmallScreen ? 9 : 10,
                                        color: Theme.of(context)
                                            .colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                  textAlign: TextAlign.right,
                                ),
                              );
                            }),
                          ),
                        ),
                        // Chart area
                        Expanded(
                          child: isSmallScreen && data.length > 6
                              ? SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    width: chartWidth,
                                    height: chartHeight,
                                    child: CustomPaint(
                                      painter: LineChartPainter(
                                        data: data,
                                        max: adjustedMax,
                                        min: adjustedMin,
                                        range: adjustedRange,
                                        lineColor: primaryColor,
                                        fillColor: fillGradientColor,
                                        showGrid: true,
                                      ),
                                      child: Container(),
                                    ),
                                  ),
                                )
                              : CustomPaint(
                                  painter: LineChartPainter(
                                    data: data,
                                    max: adjustedMax,
                                    min: adjustedMin,
                                    range: adjustedRange,
                                    lineColor: primaryColor,
                                    fillColor: fillGradientColor,
                                    showGrid: true,
                                  ),
                                  child: Container(),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // X-axis labels (month names)
                  isSmallScreen && data.length > 6
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: chartWidth,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: data.map((item) {
                                return SizedBox(
                                  width: 60,
                                  child: Column(
                                    children: [
                                      Text(
                                        _formatChartValue(item.value),
                                        style: Theme.of(context)
                                            .textTheme.bodySmall
                                            ?.copyWith(
                                              fontSize: isSmallScreen ? 9 : 10,
                                              fontWeight: FontWeight.w600,
                                              color: primaryColor,
                                            ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.label,
                                        style: Theme.of(context)
                                            .textTheme.bodySmall
                                            ?.copyWith(
                                              fontSize: isSmallScreen ? 9 : 10,
                                              color: Theme.of(context)
                                                  .colorScheme.onSurfaceVariant,
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: data.map((item) {
                            return Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    _formatChartValue(item.value),
                                    style: Theme.of(context)
                                        .textTheme.bodySmall
                                        ?.copyWith(
                                          fontSize: isSmallScreen ? 9 : 10,
                                          fontWeight: FontWeight.w600,
                                          color: primaryColor,
                                        ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.label,
                                    style: Theme.of(context)
                                        .textTheme.bodySmall
                                        ?.copyWith(
                                          fontSize: isSmallScreen ? 9 : 10,
                                          color: Theme.of(context)
                                              .colorScheme.onSurfaceVariant,
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
  final bool showGrid;

  LineChartPainter({
    required this.data,
    required this.max,
    required this.min,
    required this.range,
    required this.lineColor,
    required this.fillColor,
    this.showGrid = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final width = size.width;
    final height = size.height;
    final stepX = data.length > 1 ? width / (data.length - 1) : width;

    // Draw grid lines if enabled
    if (showGrid) {
      final gridPaint = Paint()
        ..color = Colors.grey.withOpacity(0.15)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      // Horizontal grid lines (5 lines)
      for (int i = 0; i <= 4; i++) {
        final y = (height / 4) * i;
        canvas.drawLine(
          Offset(0, y),
          Offset(width, y),
          gridPaint,
        );
      }

      // Vertical grid lines (for each data point)
      for (int i = 0; i < data.length; i++) {
        final x = i * stepX;
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, height),
          gridPaint,
        );
      }
    }

    // Create gradient for fill
    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        fillColor,
        fillColor.withOpacity(0.0),
      ],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(
        Rect.fromLTWH(0, 0, width, height),
      )
      ..style = PaintingStyle.fill;

    // Line paint with better styling
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final fillPath = Path();

    // Start the fill path from the bottom-left
    fillPath.moveTo(0, height);

    // Calculate points with smooth curves
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedValue =
          range > 0 ? (data[i].value - min) / range : 0.5;
      final y = height - (normalizedValue * height);
      points.add(Offset(x, y));
    }

    // Create smooth curve using cubic bezier
    if (points.length > 1) {
      path.moveTo(points[0].dx, points[0].dy);
      fillPath.lineTo(points[0].dx, points[0].dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final controlPoint1 = Offset(
          p0.dx + (p1.dx - p0.dx) / 2,
          p0.dy,
        );
        final controlPoint2 = Offset(
          p0.dx + (p1.dx - p0.dx) / 2,
          p1.dy,
        );

        path.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          p1.dx,
          p1.dy,
        );
        fillPath.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          p1.dx,
          p1.dy,
        );
      }
    }

    // Complete the fill path
    fillPath.lineTo(width, height);
    fillPath.close();

    // Draw fill area (gradient)
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    canvas.drawPath(path, linePaint);

    // Draw data points with better styling
    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final pointBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final point in points) {
      // Draw white circle background
      canvas.drawCircle(point, 5, pointBorderPaint);
      // Draw colored circle
      canvas.drawCircle(point, 3.5, pointPaint);
    }
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
