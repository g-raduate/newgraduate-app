import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:newgraduate/widgets/smart_youtube_player_manager.dart';

/// Responsive video banner. Prevents overflow and optionally shows a carousel
/// when multiple videos are provided. Auto-advances every 7 seconds.
class VideoBanner extends StatefulWidget {
  /// Backward-compatible single video id.
  final String videoId;

  /// Optional additional video ids to make a carousel (first entry is [videoId]).
  final List<String>? videoIds;

  /// Optional overlay text shown on the card; rendered in smaller font and
  /// constrained to avoid overflow.
  final String? overlayText;

  const VideoBanner({
    super.key,
    required this.videoId,
    this.videoIds,
    this.overlayText,
  });

  @override
  State<VideoBanner> createState() => _VideoBannerState();
}

class _VideoBannerState extends State<VideoBanner> {
  late final List<String> _ids;
  final PageController _pageController = PageController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ids = [widget.videoId, ...?widget.videoIds];

    if (_ids.length > 1) {
      // Auto-advance carousel every 10 seconds
      _timer = Timer.periodic(const Duration(seconds: 10), (_) => _advance());
    }
  }

  void _advance() {
    if (!mounted) return;
    final current = (_pageController.hasClients
            ? (_pageController.page ?? _pageController.initialPage)
            : _pageController.initialPage)
        .toInt();
    final next = (current + 1) % _ids.length;
    // smoother, slightly longer animation
    _pageController.animateToPage(next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ids.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(builder: (context, constraints) {
      final maxWidth = constraints.maxWidth;
      final screenHeight = MediaQuery.of(context).size.height;
      // compute 16:9 height
      double heightByWidth = maxWidth * 9 / 16;
      // also compute a height fraction of screen (32%) to avoid overflow on short screens
      double heightByScreen = screenHeight * 0.32;
      // pick the smaller (but not less than a sensible min)
      double targetHeight = max(100.0, min(heightByWidth, heightByScreen));
      // Respect parent's maxHeight when available to avoid overflow in unbounded layouts
      final double finalHeight = constraints.maxHeight.isFinite
          ? min(targetHeight, constraints.maxHeight)
          : targetHeight;

      return Container(
        // reduced horizontal margin to give more space to content
        // lower vertical margin to help small screens
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        width: double.infinity,
        height: finalHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).cardColor,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_ids.length == 1)
                SmartYouTubePlayerManager(
                  videoUrl: 'https://www.youtube.com/watch?v=${_ids.first}',
                  videoTitle: 'مشاريع التخرج',
                  autoPlay: true,
                  enableProtection: false,
                )
              else
                PageView.builder(
                  controller: _pageController,
                  itemCount: _ids.length,
                  itemBuilder: (context, index) => SmartYouTubePlayerManager(
                    videoUrl: 'https://www.youtube.com/watch?v=${_ids[index]}',
                    videoTitle: 'مشروع ${index + 1}',
                    autoPlay: true,
                    enableProtection: false,
                  ),
                ),

              if (_ids.length > 1)
                // place dots in SafeArea so they don't push content on small screens
                Positioned(
                  left: 6,
                  right: 6,
                  bottom: 4,
                  child: SafeArea(
                    top: false,
                    bottom: true,
                    minimum: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_ids.length, (i) {
                        return AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            final page = _pageController.hasClients
                                ? (_pageController.page ??
                                    _pageController.initialPage.toDouble())
                                : _pageController.initialPage.toDouble();
                            final selected = page.round() == i;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: selected ? 14 : 7,
                              height: 5,
                              decoration: BoxDecoration(
                                  color:
                                      selected ? Colors.white : Colors.white54,
                                  borderRadius: BorderRadius.circular(3)),
                            );
                          },
                        );
                      }),
                    ),
                  ),
                ),
              // optional overlay text in the center of the card
              if (widget.overlayText != null && widget.overlayText!.isNotEmpty)
                Positioned(
                  left: 12,
                  right: 12,
                  // slightly higher so dots don't collide with text space
                  top: finalHeight * 0.22,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: finalHeight * 0.5),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Text(
                          widget.overlayText!,
                          textAlign: TextAlign.center,
                          softWrap: true,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontSize: 13,
                                    height: 1.05,
                                    letterSpacing: 0.0,
                                  ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}
