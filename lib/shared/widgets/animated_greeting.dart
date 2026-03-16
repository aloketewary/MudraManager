import 'package:flutter/material.dart';

class AnimatedGreeting extends StatefulWidget {
  final String greeting;
  final String name;
  final TextStyle? greetingStyle;
  final TextStyle? nameStyle;
  final Duration delay;
  final Duration transitionDuration;

  const AnimatedGreeting({
    super.key,
    required this.greeting,
    required this.name,
    this.greetingStyle,
    this.nameStyle,
    this.delay = const Duration(seconds: 2),
    this.transitionDuration = const Duration(milliseconds: 800),
  });

  @override
  State<AnimatedGreeting> createState() => _AnimatedGreetingState();
}

class _AnimatedGreetingState extends State<AnimatedGreeting>
    with TickerProviderStateMixin {
  static bool _hasPlayedAnimation = false;
  bool _showName = false;
  late AnimationController _controller;
  late Animation<Offset> _greetingSlide;
  late Animation<Offset> _nameSlide;
  late Animation<double> _greetingOpacity;
  late Animation<double> _nameOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.transitionDuration,
      vsync: this,
    );

    _greetingSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _greetingOpacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _nameSlide = Tween<Offset>(
      begin: const Offset(1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _nameOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    // If animation already played, show name immediately
    if (_hasPlayedAnimation) {
      _showName = true;
      _controller.value = 1.0;
    } else {
      // Play animation only once
      Future.delayed(widget.delay, () {
        if (mounted) {
          setState(() => _showName = true);
          _controller.forward();
          _hasPlayedAnimation = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            FadeTransition(
              opacity: _greetingOpacity,
              child: SlideTransition(
                position: _greetingSlide,
                child: Text(
                  widget.greeting,
                  style: widget.greetingStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (_showName)
              FadeTransition(
                opacity: _nameOpacity,
                child: SlideTransition(
                  position: _nameSlide,
                  child: Text(
                    widget.name,
                    style: widget.nameStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
