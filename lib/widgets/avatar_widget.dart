import 'package:flutter/material.dart';
import '../core/constants.dart';

/// Colored circle avatar generated from user name initials
class AvatarWidget extends StatelessWidget {
  final String name;
  final double size;
  final int? colorIndex;

  const AvatarWidget({
    super.key,
    required this.name,
    this.size = 40,
    this.colorIndex,
  });

  @override
  Widget build(BuildContext context) {
    final idx = colorIndex ?? name.hashCode.abs();
    final gradient = AppConstants.getAvatarGradient(idx);
    final initials = _getInitials(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

/// Overlapping avatar row for groups
class AvatarStack extends StatelessWidget {
  final List<String> names;
  final double size;
  final int maxDisplay;

  const AvatarStack({
    super.key,
    required this.names,
    this.size = 32,
    this.maxDisplay = 4,
  });

  @override
  Widget build(BuildContext context) {
    final displayCount =
        names.length > maxDisplay ? maxDisplay : names.length;
    final overflow = names.length - maxDisplay;

    return SizedBox(
      width: size + (displayCount - 1) * (size * 0.65) + (overflow > 0 ? size * 0.65 : 0),
      height: size,
      child: Stack(
        children: [
          for (int i = 0; i < displayCount; i++)
            Positioned(
              left: i * (size * 0.65),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                child: AvatarWidget(
                  name: names[i],
                  size: size - 4,
                  colorIndex: i,
                ),
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: displayCount * (size * 0.65),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '+$overflow',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: size * 0.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
