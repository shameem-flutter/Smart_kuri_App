import 'package:flutter/material.dart';

class CustomErrorWidget extends StatefulWidget {
  final String error;
  final Future<void> Function()? onRetryFuture;
  final VoidCallback? onRetry;

  const CustomErrorWidget({
    super.key,
    required this.error,
    this.onRetryFuture,
    this.onRetry,
  });

  @override
  State<CustomErrorWidget> createState() => _CustomErrorWidgetState();
}

class _CustomErrorWidgetState extends State<CustomErrorWidget> {
  bool _isLoading = false;

  void _handleRetry() async {
    if (_isLoading) return;

    if (widget.onRetryFuture != null) {
      setState(() {
        _isLoading = true;
      });
      try {
        await widget.onRetryFuture!();
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else if (widget.onRetry != null) {
      // For synchronous callbacks (like ref.invalidate), we still show a brief loading state
      // to give the user visual feedback that the button was clicked.
      setState(() {
        _isLoading = true;
      });
      widget.onRetry!();

      // We don't necessarily reset _isLoading here because typically the
      // parent widget (like a FutureProvider watch) will rebuild the entire UI
      // into a loading state anyway. But add a small delay fallback just in case.
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: 48.0,
            ),
            const SizedBox(height: 16.0),
            Text(
              widget.error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16.0, color: Colors.black87),
            ),
            const SizedBox(height: 24.0),
            ElevatedButton.icon(
              onPressed:
                  (widget.onRetry != null || widget.onRetryFuture != null) &&
                      !_isLoading
                  ? _handleRetry
                  : null,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(_isLoading ? 'Retrying...' : 'Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 12.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
