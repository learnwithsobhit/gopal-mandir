import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/default_images.dart';
import '../models/models.dart';

class LiveDarshanScreen extends StatefulWidget {
  const LiveDarshanScreen({super.key});

  @override
  State<LiveDarshanScreen> createState() => _LiveDarshanScreenState();
}

class _LiveDarshanScreenState extends State<LiveDarshanScreen> {
  final ApiService _api = ApiService();
  LiveDarshanConfig? _cfg;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await _api.getLiveDarshanConfig();
    if (!mounted) return;
    setState(() {
      _cfg = c;
      _loading = false;
    });
  }

  Future<void> _openStream() async {
    final u = _cfg?.streamUrl.trim() ?? '';
    if (u.isEmpty) return;
    final uri = Uri.tryParse(u);
    if (uri == null || !await canLaunchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open stream')),
      );
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg;
    final live = cfg != null && cfg.isLive && cfg.streamUrl.trim().isNotEmpty;
    final String headline = !live
        ? 'लाइव दर्शन शीघ्र उपलब्ध'
        : (cfg.title.trim().isNotEmpty ? cfg.title : 'Live Darshan');
    final bodyText = cfg != null && cfg.description.trim().isNotEmpty
        ? cfg.description
        : 'Live darshan streaming will be available soon. You will be able to watch Shri Gopal Ji\'s darshan from anywhere.';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(cfg != null && cfg.title.trim().isNotEmpty ? cfg.title : 'लाइव दर्शन'),
        backgroundColor: AppColors.krishnaBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.krishnaBlue))
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 320,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.krishnaBlue.withAlpha(30),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      image: DecorationImage(
                        image: AssetImage(DefaultImages.darshan2),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Center(
                            child: GestureDetector(
                              onTap: live ? _openStream : null,
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withAlpha(100),
                                  border: Border.all(color: Colors.white, width: 3),
                                ),
                                child: Icon(
                                  Icons.play_arrow,
                                  size: 40,
                                  color: live ? Colors.white : Colors.white54,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: live ? AppColors.peacockGreen : AppColors.templeGold,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                live ? 'LIVE' : 'शीघ्र उपलब्ध',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.softWhite,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.krishnaBlue.withAlpha(10),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.temple_hindu, size: 40, color: AppColors.templeGold),
                        const SizedBox(height: 12),
                        Text(
                          headline,
                          style: const TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBrown,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bodyText,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: AppColors.warmGrey,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (live) ...[
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _openStream,
                            icon: const Icon(Icons.live_tv),
                            label: const Text('Watch live'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.peacockGreen,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.templeGold.withAlpha(20),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '🕉 जय गोपाल',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: AppColors.templeGoldDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              DefaultImages.darshan3,
                              height: 140,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              DefaultImages.darshan4,
                              height: 140,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
