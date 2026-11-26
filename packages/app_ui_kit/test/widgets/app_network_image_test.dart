import "dart:async";
import "dart:convert";

import "package:app_ui_kit/app_ui_kit.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:file/memory.dart";
import "package:flutter/material.dart";
import "package:flutter_cache_manager/flutter_cache_manager.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  tearDown(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  for (final url in <String?>[
    null,
    "",
    "  ",
    "file:///private/photo.png",
    "not an image URL",
    "https://user:password@example.invalid/photo.png",
  ]) {
    testWidgets("unavailable link $url renders fallback without a request", (
      tester,
    ) async {
      final cache = _MemoryCacheManager(const Stream<FileResponse>.empty());

      await _render(
        tester,
        AppNetworkImage(url: url, width: 120, height: 80, cacheManager: cache),
      );

      expect(find.byIcon(AppIcons.gallery), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(cache.requests, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets("pending image keeps bounds and a localized image description", (
    tester,
  ) async {
    final response = StreamController<FileResponse>();
    final cache = _MemoryCacheManager(response.stream);
    final semantics = tester.ensureSemantics();
    try {
      await _render(
        tester,
        AppNetworkImage(
          url: "https://images.example.invalid/loading.png",
          width: 120,
          height: 80,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          semanticLabel: "Vehicle photo",
          cacheManager: cache,
        ),
      );

      expect(find.byType(AppLoadingIndicator), findsOneWidget);
      expect(tester.getSize(find.byType(AppNetworkImage)), const Size(120, 80));
      expect(find.bySemanticsLabel("Vehicle photo"), findsOneWidget);
      expect(
        tester.widget<ClipRRect>(find.byType(ClipRRect)).borderRadius,
        const BorderRadius.all(Radius.circular(8)),
      );

      response.addError(StateError("Offline fixture cleanup"));
      await response.close();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    "decodes a cached image without HTTP and removes the placeholder",
    (tester) async {
      const url = "https://images.example.invalid/cached.gif";
      final file = MemoryFileSystem().file("/cached.gif")
        ..writeAsBytesSync(
          base64Decode(
            "R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7",
          ),
        );
      final cache = _MemoryCacheManager(
        Stream<FileResponse>.value(
          FileInfo(file, FileSource.Cache, DateTime.utc(2030), url),
        ),
      );

      await tester.runAsync(() async {
        await _render(
          tester,
          AppNetworkImage(
            url: url,
            width: 120,
            height: 80,
            cacheManager: cache,
          ),
        );
        await precacheImage(
          CachedNetworkImageProvider(url, cacheManager: cache),
          tester.element(find.byType(AppNetworkImage)),
        );
      });
      await tester.pumpAndSettle();

      final image = tester.widget<RawImage>(find.byType(RawImage)).image;
      expect(image, isNotNull);
      expect(image!.width, 1);
      expect(image.height, 1);
      expect(find.byType(AppLoadingIndicator), findsNothing);
      expect(find.byIcon(AppIcons.gallery), findsNothing);
      expect(cache.requests.single.url, url);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("image errors use the caller's fallback in dark mode", (
    tester,
  ) async {
    final cache = _MemoryCacheManager(
      Stream<FileResponse>.error(StateError("Image unavailable offline")),
    );

    await _render(
      tester,
      AppNetworkImage(
        url: "https://images.example.invalid/failed.png",
        width: 120,
        height: 80,
        cacheManager: cache,
        fallbackBuilder: (_) => const Text("Photo unavailable"),
      ),
      dark: true,
    );
    await tester.pumpAndSettle();

    expect(find.text("Photo unavailable"), findsOneWidget);
    expect(find.byType(AppLoadingIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    "retains query identity and forwards only explicit image headers",
    (tester) async {
      const url =
          "https://images.example.invalid/photo.png?version=2&signature=x";
      final cache = _MemoryCacheManager(
        Stream<FileResponse>.error(StateError("Offline fixture")),
      );

      await _render(
        tester,
        AppNetworkImage(
          url: url,
          width: 120,
          height: 80,
          cacheKey: "tenant-1/vehicle-12/photo-v2",
          cacheManager: cache,
          httpHeaders: const {"X-Image-Token": "image-service-token"},
        ),
      );
      await tester.pumpAndSettle();

      final request = cache.requests.single;
      expect(request.url, url);
      expect(request.key, "tenant-1/vehicle-12/photo-v2");
      expect(request.headers, {"X-Image-Token": "image-service-token"});
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("decorative fallback excludes the image description", (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _render(
        tester,
        const AppNetworkImage(
          url: null,
          width: 120,
          height: 80,
          semanticLabel: "Decorative background",
          excludeFromSemantics: true,
        ),
      );

      expect(find.bySemanticsLabel("Decorative background"), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
}

Future<void> _render(
  WidgetTester tester,
  AppNetworkImage image, {
  bool dark = false,
}) => tester.pumpWidget(
  MaterialApp(
    theme: dark ? DarkTheme.dark() : LightTheme.light(),
    home: AppScaffold(body: Center(child: image)),
  ),
);

typedef _ImageRequest = ({
  String url,
  String? key,
  Map<String, String>? headers,
});

class _MemoryCacheManager extends Fake implements BaseCacheManager {
  _MemoryCacheManager(this.responses);

  final Stream<FileResponse> responses;
  final List<_ImageRequest> requests = [];

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) {
    requests.add((url: url, key: key, headers: headers));
    return responses;
  }
}
