// lib/widgets/net_image.dart
//
// جایگزین Image.network با:
//  - کش دیسکی و حافظه (CachedNetworkImageProvider): بار دوم بدون دانلود
//  - decode در اندازهٔ نمایش (ResizeImage): حافظه و زمان decode کمتر در لیست‌ها
// امضا مثل Image.network است؛ برای نمایش تمام‌صفحه full: true بدهید تا اندازه کوچک نشود.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

class NetImage extends StatelessWidget {
  final String url;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final ImageErrorWidgetBuilder? errorBuilder;
  final ImageLoadingBuilder? loadingBuilder;

  /// عرض decode به پیکسل؛ اگر ندهید از width (در صورت محدود بودن) یا ۶۰۰ استفاده می‌شود.
  final int? cacheWidth;

  /// تصویر کامل (برای نمایش بزرگ/زوم)
  final bool full;

  const NetImage(
    this.url, {
    super.key,
    this.fit,
    this.width,
    this.height,
    this.errorBuilder,
    this.loadingBuilder,
    this.cacheWidth,
    this.full = false,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider provider = CachedNetworkImageProvider(url);
    if (!full) {
      final w = width;
      final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
      final px = cacheWidth ??
          ((w != null && w.isFinite && w > 0) ? (w * dpr).round() : 600);
      provider = ResizeImage.resizeIfNeeded(px, null, provider);
    }
    return Image(
      image: provider,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: errorBuilder,
      loadingBuilder: loadingBuilder,
    );
  }
}
