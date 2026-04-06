// lib/widgets/cached_network_image_with_auth.dart - CORRIGÉ avec tous les imports
import 'package:flutter/material.dart';
import 'dart:io'; // ✅ Pour File
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart'; // ✅ Pour CachedNetworkImage
import '../services/media_cache_service.dart'; // ✅ Pour MediaCacheService

class CachedNetworkImageWithAuth extends StatefulWidget {
  final String imageUrl;
  final Map<String, String>? headers;
  final int? assetId;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, String)? placeholder;
  final Function(String)? onCacheComplete;

  const CachedNetworkImageWithAuth({
    super.key,
    required this.imageUrl,
    this.headers,
    this.assetId,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.onCacheComplete,
  });

  @override
  State<CachedNetworkImageWithAuth> createState() =>
      _CachedNetworkImageWithAuthState();
}

class _CachedNetworkImageWithAuthState
    extends State<CachedNetworkImageWithAuth> {
  final MediaCacheService _mediaCache = MediaCacheService();
  String? _cachedPath;
  bool _isLoadingCache = true;

  @override
  void initState() {
    super.initState();
    _checkCache();
  }

  @override
  void didUpdateWidget(CachedNetworkImageWithAuth oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetId != widget.assetId ||
        oldWidget.imageUrl != widget.imageUrl) {
      _checkCache();
    }
  }

  Future<void> _checkCache() async {
    if (widget.assetId != null) {
      final cached = await _mediaCache.getCachedMedia(widget.assetId!);
      if (cached != null && mounted) {
        setState(() {
          _cachedPath = cached.filePath;
          _isLoadingCache = false;
        });
        widget.onCacheComplete?.call(_cachedPath!);
        return;
      }
    }
    if (mounted) {
      setState(() => _isLoadingCache = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCache) {
      if (widget.placeholder != null) {
        return widget.placeholder!(context, widget.imageUrl);
      }
      return Container(color: Colors.grey.shade200);
    }

    // Si on a le fichier en cache
    if (_cachedPath != null && File(_cachedPath!).existsSync()) {
      return Image.file(
        File(_cachedPath!),
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: (context, error, stackTrace) {
          return _buildNetworkImage();
        },
      );
    }

    return _buildNetworkImage();
  }

  Widget _buildNetworkImage() {
    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      httpHeaders: widget.headers,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      placeholder: widget.placeholder ?? _defaultPlaceholder,
      errorWidget: (context, url, error) => Container(
        color: Colors.grey.shade300,
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
        ),
      ),
    );
  }

  Widget _defaultPlaceholder(BuildContext context, String url) {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
