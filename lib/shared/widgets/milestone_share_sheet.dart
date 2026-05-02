import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Data class describing a shareable milestone.
class MilestoneData {
  final String emoji;
  final String title;
  final String stat;
  final String description;
  final IconData icon;
  final Color accent;

  const MilestoneData({
    required this.emoji,
    required this.title,
    required this.stat,
    required this.description,
    required this.icon,
    required this.accent,
  });
}

/// Shows a bottom sheet with a branded share card preview + share button.
Future<void> showMilestoneShareSheet(
  BuildContext context,
  MilestoneData data,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MilestoneShareSheet(data: data),
  );
}

class _MilestoneShareSheet extends ConsumerWidget {
  final MilestoneData data;
  final _cardKey = GlobalKey();

  _MilestoneShareSheet({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: color.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(
          spacing.cardHorizontalMax,
          spacing.cardVertical,
          spacing.cardHorizontalMax,
          spacing.cardVerticalMax,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: color.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: spacing.sectionGap),
            ClipRRect(
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              child: RepaintBoundary(
                key: _cardKey,
                child: _MilestoneShareCard(data: data),
              ),
            ),
            SizedBox(height: spacing.sectionGap),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => _captureAndShare(context),
                icon: const Icon(LucideIcons.share2, size: 18),
                label: Text(
                  ctxt.milestone_shareButton,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: data.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  ),
                ),
              ),
            ),
            SizedBox(height: spacing.elementGap),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                ctxt.common_close,
                style: textTheme.labelLarge?.copyWith(
                  color: color.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureAndShare(BuildContext context) async {
    HapticFeedback.mediumImpact();
    try {
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/mudra_milestone_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await SharePlus.instance.share(
        ShareParams(
          text: '${data.emoji} ${data.title} — ${data.stat}\n\n'
              'Tracked with Mudra Manager \u{1F4B0}\n'
              'https://play.google.com/store/apps/details?id=com.mudramanager.app',
          files: [XFile(file.path)],
        ),
      );
    } catch (_) {
      final text = '${data.emoji} ${data.title} — ${data.stat}\n\n'
          'Tracked with Mudra Manager \u{1F4B0}\n'
          'https://play.google.com/store/apps/details?id=com.mudramanager.app';
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copied to clipboard!')),
        );
      }
    }
  }
}

/// Branded 9:16 share card rendered offscreen, captured as image.
class _MilestoneShareCard extends StatelessWidget {
  final MilestoneData data;
  const _MilestoneShareCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      height: 640,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A1A2E),
              Color.lerp(const Color(0xFF1A1A2E), data.accent, 0.15)!,
              const Color(0xFF0F0F1A),
            ],
          ),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter:
                      _DotPatternPainter(data.accent.withValues(alpha: 0.05)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const SizedBox(height: 80),
                    // Header pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: data.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: data.accent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '${data.emoji} MILESTONE',
                        style: TextStyle(
                          color: data.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Icon badge
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: data.accent.withValues(alpha: 0.5),
                                  blurRadius: 40,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                          ),
                          CustomPaint(
                            size: const Size(140, 140),
                            painter: _RingPainter(
                              color: data.accent,
                              strokeWidth: 5,
                            ),
                          ),
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  data.accent.withValues(alpha: 0.2),
                                  data.accent.withValues(alpha: 0.05),
                                ],
                              ),
                            ),
                            child: Icon(
                              data.icon,
                              size: 56,
                              color: data.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Stat
                    Text(
                      data.stat,
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Title
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    // Description
                    Text(
                      data.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                    // Branding
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/logo/logo.png',
                          width: 28,
                          height: 28,
                          errorBuilder: (_, __, ___) => Icon(
                            LucideIcons.indianRupee,
                            size: 28,
                            color: data.accent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Mudra Manager',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your money, your language, your rules.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  final Color color;
  _DotPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 24.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      for (var y = 0.0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPatternPainter old) => old.color != color;
}

class _RingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  _RingPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.color != color;
}
