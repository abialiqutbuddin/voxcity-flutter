import 'package:flutter/material.dart';

class TopBar extends StatefulWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onExit;
  final bool hoverable;

  const TopBar({
    super.key,
    required this.title,
    this.actions,
    this.onExit,
    this.hoverable = true,
  });

  @override
  TopBarState createState() => TopBarState();
}

class TopBarState extends State<TopBar> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _positionAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _positionAnimation = Tween<double>(begin: -60, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    if (!widget.hoverable) {
      _animationController.value = 1.0;
    }
  }

  void _toggleVisibility(bool show) {
    if (show) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Hover detection area
        if (widget.hoverable)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 20,
            child: MouseRegion(
              onEnter: (_) => _toggleVisibility(true),
            ),
          ),
        // Animated top bar with blur and translucency
        AnimatedBuilder(
          animation: _positionAnimation,
          builder: (context, child) {
            return Positioned(
              top: _positionAnimation.value,
              left: 0,
              right: 0,
              child: MouseRegion(
                onExit: (_) {
                  if (widget.hoverable) {
                    widget.onExit?.call();
                    _toggleVisibility(false);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal:20.0,vertical: 5),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.9),
                      borderRadius: const BorderRadius.all(Radius.circular(20))
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Title
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (widget.actions != null) ...widget.actions!,
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}