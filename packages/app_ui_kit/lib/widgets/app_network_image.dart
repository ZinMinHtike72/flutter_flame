import "package:app_ui_kit/theme/app_spacing.dart";
import "package:app_ui_kit/widgets/app_icons.dart";
import "package:app_ui_kit/widgets/app_loading_indicator.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter_cache_manager/flutter_cache_manager.dart";

/// Cached HTTP(S) image with themed loading and unavailable states.
///
/// Supply constraints through [width], [height], or the parent layout. Labels
/// and custom placeholders belong to the caller so they can be localized.
class AppNetworkImage extends StatelessWidget {
  /// Creates a remote image. Empty or invalid links show the fallback directly.
  const AppNetworkImage({
    required this.url,
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.cacheKey,
    this.cacheManager,
    this.httpHeaders,
    this.placeholderBuilder,
    this.fallbackBuilder,
    this.memCacheWidth,
    this.memCacheHeight,
  }) : assert(width == null || width >= 0),
       assert(height == null || height >= 0),
       assert(memCacheWidth == null || memCacheWidth > 0),
       assert(memCacheHeight == null || memCacheHeight > 0);

  /// HTTP(S) URL, including any query string required by the image service.
  final String? url;

  /// Optional display width; otherwise inherited from the parent.
  final double? width;

  /// Optional display height; otherwise inherited from the parent.
  final double? height;

  /// How the decoded image fills its bounds.
  final BoxFit fit;

  /// Corner clipping shared by the image, placeholder, and fallback.
  final BorderRadius borderRadius;

  /// Caller-localized description for assistive technology.
  final String? semanticLabel;

  /// Whether the image is decorative and should be excluded from semantics.
  final bool excludeFromSemantics;

  /// Explicit cache identity. By default the full URL is retained.
  final String? cacheKey;

  /// Optional shared cache policy; defaults to the package's normal disk cache.
  final BaseCacheManager? cacheManager;

  /// Optional image-service headers. Never pass API credentials to another host.
  final Map<String, String>? httpHeaders;

  /// Optional localized replacement for the default loading indicator.
  final WidgetBuilder? placeholderBuilder;

  /// Optional localized replacement for unavailable or invalid images.
  final WidgetBuilder? fallbackBuilder;

  /// Optional decoded pixel-width limit for Flutter's in-memory image cache.
  final int? memCacheWidth;

  /// Optional decoded pixel-height limit for Flutter's in-memory image cache.
  final int? memCacheHeight;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url?.trim() ?? "";
    final uri = Uri.tryParse(imageUrl);
    final loadable =
        uri != null &&
        (uri.scheme == "https" || uri.scheme == "http") &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty;
    final child = SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: loadable
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                cacheKey: cacheKey,
                cacheManager: cacheManager,
                httpHeaders: httpHeaders,
                width: width,
                height: height,
                fit: fit,
                memCacheWidth: memCacheWidth,
                memCacheHeight: memCacheHeight,
                placeholder: (context, _) => _placeholder(context),
                errorWidget: (context, _, _) => _fallback(context),
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
              )
            : _fallback(context),
      ),
    );
    return excludeFromSemantics
        ? ExcludeSemantics(child: child)
        : Semantics(
            image: true,
            label: semanticLabel,
            excludeSemantics: true,
            child: child,
          );
  }

  Widget _placeholder(BuildContext context) =>
      placeholderBuilder?.call(context) ??
      ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: AppLoadingIndicator()),
      );

  Widget _fallback(BuildContext context) =>
      fallbackBuilder?.call(context) ??
      ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            AppIcons.gallery,
            size: AppSpacing.lg,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
}
