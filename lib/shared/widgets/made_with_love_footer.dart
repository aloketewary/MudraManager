import 'package:flutter/material.dart';

class MadeWithLoveFooter extends StatefulWidget {
  final String? appName;
  final bool showCopyright;

  const MadeWithLoveFooter({
    super.key,
    this.appName,
    this.showCopyright = true,
  });

  @override
  State<MadeWithLoveFooter> createState() => _MadeWithLoveFooterState();
}

class _MadeWithLoveFooterState extends State<MadeWithLoveFooter>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _heartController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _heartAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _heartController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    
    _heartAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _heartController,
      curve: Curves.elasticOut,
    ));

    // Start animations
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        _controller.forward();
        _startHeartAnimation();
      }
    });
  }
  
  void _startHeartAnimation() {
    _heartController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _heartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            // Subtle divider
            Container(
              width: screenWidth * 0.3,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    color.outline.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Heart icon
            AnimatedBuilder(
              animation: _heartAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _heartAnimation.value,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text('❤️', style: TextStyle(fontSize: 24)),
                  ),
                );
              },
            ),

            SizedBox(height: 16),

            // In India text
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Made with love text
                Text(
                  'Made with ❤️ ',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color.onSurface,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'in India ',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color.onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
                Text('🇮🇳', style: TextStyle(fontSize: 16)),
              ],
            ),

            SizedBox(height: 12),

            // Crafted with Love
            Text(
              'Crafted with Love',
              style: textTheme.bodyMedium?.copyWith(
                color: color.onSurfaceVariant,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 4),

            // Built for You
            Text(
              'Built for You',
              style: textTheme.bodyMedium?.copyWith(
                color: color.onSurfaceVariant,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),

            if (widget.showCopyright) ...[
              SizedBox(height: 20),

              // Bottom divider
              Container(
                width: screenWidth * 0.2,
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      color.outline.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Copyright
              Text(
                '© ${DateTime.now().year} ${widget.appName ?? "Mudra Manager"}',
                style: textTheme.labelMedium?.copyWith(
                  color: color.onSurfaceVariant.withValues(alpha: 0.7),
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 4),

              Text(
                'All rights reserved',
                style: textTheme.labelSmall?.copyWith(
                  color: color.onSurfaceVariant.withValues(alpha: 0.6),
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
