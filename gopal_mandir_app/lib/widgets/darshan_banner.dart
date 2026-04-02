import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/default_images.dart';

class DarshanBanner extends StatelessWidget {
  const DarshanBanner({super.key});

  static const double _bannerRadius = 24;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(_bannerRadius);
    return Container(
      height: 260,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [
          BoxShadow(
            color: AppColors.krishnaBlue.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        // Painted inside the rounded rect by BoxDecoration (reliable on web; Image.asset often ignores clip)
        image: DecorationImage(
          image: AssetImage(DefaultImages.darshan1),
          fit: BoxFit.cover,
        ),
      ),
      child: ClipRRect(
        borderRadius: r,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(10),
                    Colors.black.withAlpha(40),
                    Colors.black.withAlpha(160),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.templeGold.withAlpha(200),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      'Live Darshan',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'जय गोपाल',
                    style: TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 12,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'श्री गोपाल वैष्णव पीठ गोपाल मंदिर — आज का दर्शन',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.white.withAlpha(230),
                      fontWeight: FontWeight.w400,
                      shadows: const [
                        Shadow(
                          blurRadius: 8,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
