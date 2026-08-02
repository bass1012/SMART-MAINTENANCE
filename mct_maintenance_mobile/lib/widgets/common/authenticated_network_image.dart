import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthenticatedNetworkImage extends StatefulWidget {
  const AuthenticatedNetworkImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit,
    this.loadingBuilder,
    this.errorBuilder,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final ImageLoadingBuilder? loadingBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  State<AuthenticatedNetworkImage> createState() =>
      _AuthenticatedNetworkImageState();
}

class _AuthenticatedNetworkImageState extends State<AuthenticatedNetworkImage> {
  static const _storage = FlutterSecureStorage();
  late Future<String?> _token;

  @override
  void initState() {
    super.initState();
    _token = _storage.read(key: 'auth_token');
  }

  @override
  void didUpdateWidget(covariant AuthenticatedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _token = _storage.read(key: 'auth_token');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _token,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final token = snapshot.data;
        return Image.network(
          widget.url,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          headers: token == null || token.isEmpty
              ? null
              : <String, String>{'Authorization': 'Bearer $token'},
          loadingBuilder: widget.loadingBuilder,
          errorBuilder: widget.errorBuilder,
        );
      },
    );
  }
}
