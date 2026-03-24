import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;
  late SharedPreferences _prefs;
  bool _isLoading = true;
  bool _serverHealthy = false;
  bool _checkedHealth = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ApiService.baseURL);
    _initPreferences();
  }

  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    final savedUrl = _prefs.getString('api_base_url');
    if (savedUrl != null) {
      setState(() {
        _urlController.text = savedUrl;
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('URL cannot be empty')));
      return;
    }

    await _prefs.setString('api_base_url', url);
    // Update the ApiService base URL
    ApiService.baseURL = url;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _checkServerHealth() async {
    setState(() => _checkedHealth = false);

    try {
      final apiService = ApiService();
      await apiService.healthCheck();
      setState(() {
        _serverHealthy = true;
        _checkedHealth = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Server is healthy'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _serverHealthy = false;
        _checkedHealth = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✗ Server error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF9859FF),
        elevation: 0,
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Server Configuration Section
                    _buildSectionTitle('Server Configuration'),
                    const SizedBox(height: 16),
                    _buildUrlInput(),
                    const SizedBox(height: 16),
                    _buildServerStatus(),
                    const SizedBox(height: 24),
                    // App Info Section
                    _buildSectionTitle('App Information'),
                    const SizedBox(height: 16),
                    _buildInfoItem('App Name', 'ViseNotes'),
                    _buildInfoItem('Version', '1.0.0'),
                    _buildInfoItem('API Version', 'v1'),
                    const SizedBox(height: 24),
                    // About Section
                    _buildSectionTitle('About'),
                    const SizedBox(height: 16),
                    _buildAboutContent(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF9859FF),
      ),
    );
  }

  Widget _buildUrlInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Backend URL',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _urlController,
          decoration: InputDecoration(
            hintText: 'http://192.168.0.106:8000',
            prefixIcon: const Icon(Icons.language),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF9859FF), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _saveUrl,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9859FF),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Save URL'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _checkServerHealth,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFF9859FF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Test Connection'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServerStatus() {
    if (!_checkedHealth) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Click "Test Connection" to check server status',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _serverHealthy
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _serverHealthy ? Colors.green : Colors.red),
      ),
      child: Row(
        children: [
          Icon(
            _serverHealthy ? Icons.check_circle : Icons.error_outline,
            color: _serverHealthy ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _serverHealthy ? 'Server is online' : 'Server is offline',
              style: TextStyle(
                color: _serverHealthy ? Colors.green[700] : Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutContent() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'ViseNotes is an audio processing and note-taking application that converts your audio recordings into clean transcripts and AI-generated notes. '
        'Powered by Whisper for transcription and Google Gemini for intelligent note generation.',
        style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.6),
      ),
    );
  }
}
