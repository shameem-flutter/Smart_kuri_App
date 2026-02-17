import 'package:flutter/material.dart';

import '../utilities/api_config.dart';

/// IP Configuration Dialog
///
/// Allows users to change the API base URL dynamically.
class IpConfigDialog extends StatefulWidget {
  const IpConfigDialog({super.key});

  @override
  State<IpConfigDialog> createState() => _IpConfigDialogState();
}

class _IpConfigDialogState extends State<IpConfigDialog> {
  final _hostController = TextEditingController();

  String _selectedProtocol = 'http://';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  void _loadCurrentConfig() {
    final currentUrl = ApiConfig.baseUrl;
    if (currentUrl.startsWith('https://')) {
      _selectedProtocol = 'https://';
      _hostController.text = currentUrl
          .replaceFirst('https://', '')
          .replaceAll(RegExp(r'/$'), '');
    } else if (currentUrl.startsWith('http://')) {
      _selectedProtocol = 'http://';
      _hostController.text = currentUrl
          .replaceFirst('http://', '')
          .replaceAll(RegExp(r'/$'), '');
    } else {
      // Default fallback
      _selectedProtocol = 'http://';
      _hostController.text = currentUrl;
    }
  }

  @override
  void dispose() {
    _hostController.dispose();

    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_hostController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter a host address');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final host = _hostController.text.trim();
      final fullUrl = '$_selectedProtocol$host';

      // Optional: Test connection before saving
      // final isConnected = await _testConnection(fullUrl);
      // if (!isConnected) {
      //   throw Exception('Could not connect to server');
      // }

      await ApiConfig.updateBaseUrl(_selectedProtocol, host);

      if (!mounted) return;

      Navigator.of(context).pop();

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API URL updated to $fullUrl'),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Force app reload or just let the interceptor handle next requests?
      // Since ApiConfig is updated, next requests will use new URL.
      // But we might want to refresh current screen if it failed previously.
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'IP Address',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // Protocol Selector
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildProtocolButton('http://'),
                    _buildProtocolButton('https://'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Host Input
            TextField(
              controller: _hostController,
              decoration: InputDecoration(
                hintText: '127.0.0.1:8000',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                errorText: _errorMessage,
              ),
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 32),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _isLoading ? null : _handleSave,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.teal,
                            ),
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocolButton(String protocol) {
    bool isSelected = _selectedProtocol == protocol;
    return GestureDetector(
      onTap: _isLoading
          ? null
          : () => setState(() => _selectedProtocol = protocol),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          protocol,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.black87 : Colors.grey,
          ),
        ),
      ),
    );
  }
}
