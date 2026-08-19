import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  const BottomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    double barWidth = MediaQuery.of(context).size.width - 64; 
    if (barWidth > 360) barWidth = 360; // Max width for large phones
    
    double horizontalPadding = 24.0;
    double availableWidth = barWidth - (horizontalPadding * 2);
    double tabWidth = availableWidth / 4;
    double targetX = horizontalPadding + (currentIndex + 0.5) * tabWidth;

    double sideMargin = (MediaQuery.of(context).size.width - barWidth) / 2;

    return Container(
      margin: EdgeInsets.only(left: sideMargin, right: sideMargin, bottom: 24 + MediaQuery.of(context).padding.bottom),
      height: 76,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Animated Curved Background
          TweenAnimationBuilder<double>(
            tween: Tween(end: targetX),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            builder: (context, x, child) {
              return CustomPaint(
                painter: _BumpPainter(x),
                size: Size(barWidth, 76),
              );
            },
          ),
          // Icons and Labels
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: SizedBox(
              height: 76,
              child: Row(
                children: [
                  Expanded(child: _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home')),
                  Expanded(child: _buildNavItem(1, Icons.shopping_cart_outlined, Icons.shopping_cart_rounded, 'Cart')),
                  Expanded(child: _buildNavItem(2, Icons.shopping_bag_outlined, Icons.shopping_bag_rounded, 'Orders')),
                  Expanded(child: _buildNavItem(3, Icons.person_outline, Icons.person_rounded, 'Profile')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData solidIcon, String label) {
    final isSelected = currentIndex == index;
    final primaryColor = Colors.white;
    final secondaryColor = Colors.white;
    final inactiveColor = Colors.white.withValues(alpha: 0.8);
    final iconColor = const Color(0xFFF15A24); // Original Orange

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact(); // Premium haptic touch
        onTap(index);
      },
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Active Bubble (Gradient)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            top: isSelected ? 4 : 40,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: isSelected ? 1.0 : 0.0,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 400),
                scale: isSelected ? 1.0 : 0.5,
                curve: Curves.easeOutBack,
                child: Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      solidIcon,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Inactive Icon
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            top: isSelected ? 44 : 36,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 0.0 : 1.0,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 400),
                scale: isSelected ? 0.8 : 1.0,
                child: Icon(
                  outlineIcon,
                  color: inactiveColor,
                  size: 26,
                ),
              ),
            ),
          ),
          // Label
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            bottom: isSelected ? 8 : -20,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: isSelected ? 1.0 : 0.0,
              child: Text(
                label,
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BumpPainter extends CustomPainter {
  final double x;

  _BumpPainter(this.x);

  @override
  void paint(Canvas canvas, Size size) {
    final bgColor = const Color(0xFFF15A24); // Original Orange
    Paint paint = Paint()..color = bgColor..style = PaintingStyle.fill;
    Path path = Path();

    double top = 22.0; // Slightly lower flat top for more pronounced bump
    double cornerRadius = (size.height - top) / 2; // Perfectly rounded pill ends

    path.moveTo(cornerRadius, top);

    // Premium wide, fluid water-drop curve
    double leftStart = x - 36;
    if (leftStart < cornerRadius) leftStart = cornerRadius;
    path.lineTo(leftStart, top);

    path.cubicTo(
      x - 18, top, 
      x - 22, 0, 
      x, 0, 
    );

    path.cubicTo(
      x + 20, 0, 
      x + 16, top, 
      x + 32, top, 
    );

    double rightEnd = x + 32;
    if (rightEnd > size.width - cornerRadius) rightEnd = size.width - cornerRadius;
    path.lineTo(rightEnd, top);
    
    // Move to the start of the top-right corner to prevent giant arc distortion
    path.lineTo(size.width - cornerRadius, top);
    
    path.arcToPoint(Offset(size.width, top + cornerRadius), radius: Radius.circular(cornerRadius), clockwise: true);
    path.lineTo(size.width, size.height - cornerRadius);
    path.arcToPoint(Offset(size.width - cornerRadius, size.height), radius: Radius.circular(cornerRadius), clockwise: true);
    path.lineTo(cornerRadius, size.height);
    path.arcToPoint(Offset(0, size.height - cornerRadius), radius: Radius.circular(cornerRadius), clockwise: true);
    path.lineTo(0, top + cornerRadius);
    path.arcToPoint(Offset(cornerRadius, top), radius: Radius.circular(cornerRadius), clockwise: true);
    path.close();

    // Soft, luxurious shadow
    canvas.drawShadow(path, const Color(0xFF000000).withValues(alpha: 0.06), 24, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BumpPainter oldDelegate) => oldDelegate.x != x;
}
