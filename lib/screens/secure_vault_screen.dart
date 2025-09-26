// lib/screens/secure_vault_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureVaultScreen extends StatefulWidget {
  const SecureVaultScreen({super.key});

  @override
  State<SecureVaultScreen> createState() => _SecureVaultScreenState();
}

class _SecureVaultScreenState extends State<SecureVaultScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _passwordController = TextEditingController();
  final _secureStorage = const FlutterSecureStorage();
  late SharedPreferences _prefs;

  String _storedText = "";
  String _storedTitle = "";
  bool _isAddingContent = true; // 🚀 Initially show the add content page
  bool _isContentVisible = false; // Controls visibility of saved content
  String _errorMessage = "";
  bool _hasPassword = false;

  @override
  void initState() {
    super.initState();
    _initVault();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _initVault() async {
    _prefs = await SharedPreferences.getInstance();
    String? storedPassword = await _secureStorage.read(key: 'vault_password');
    if (storedPassword != null) {
      setState(() {
        _hasPassword = true;
      });
    }
  }

  Future<void> _loadStoredContent() async {
    _storedTitle = _prefs.getString('vault_title') ?? "No private notes found.";
    _storedText = _prefs.getString('vault_description') ?? "";
  }

  Future<void> _saveContent() async {
    final title = _titleController.text;
    final description = _descController.text;
    if (title.isNotEmpty) {
      await _prefs.setString('vault_title', title);
      await _prefs.setString('vault_description', description);
      setState(() {
        _storedTitle = title;
        _storedText = description;
        _titleController.clear();
        _descController.clear();
      });
      _showSnackbar("Content saved successfully!");
    }
  }

  Future<void> _savePassword() async {
    if (_passwordController.text.isNotEmpty) {
      await _secureStorage.write(key: 'vault_password', value: _passwordController.text);
      setState(() {
        _hasPassword = true;
        _errorMessage = "";
      });
      _passwordController.clear();
      _showSnackbar("Password set successfully!");
    }
  }

  Future<void> _verifyPassword() async {
    String? storedPassword = await _secureStorage.read(key: 'vault_password');
    if (storedPassword == _passwordController.text) {
      setState(() {
        _isContentVisible = true;
        _errorMessage = "";
      });
      _passwordController.clear();
      _showSnackbar("Password verified!");
      _loadStoredContent(); // Load content after successful verification
    } else {
      setState(() {
        _errorMessage = "Incorrect password. Please try again.";
      });
    }
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildPasswordForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_hasPassword)
          const Text(
            "Enter your password to view content:",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          )
        else
          const Text(
            "Create a password for your vault:",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: "Enter password",
            border: const OutlineInputBorder(),
            errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _hasPassword ? _verifyPassword : _savePassword,
          icon: Icon(_hasPassword ? Icons.lock_open : Icons.lock),
          label: Text(_hasPassword ? "Unlock Vault" : "Set Password"),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Saved Content:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text("Title", style: TextStyle(fontWeight: FontWeight.bold)),
        Text(
          _storedTitle,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        const Text("Description", style: TextStyle(fontWeight: FontWeight.bold)),
        Text(
          _storedText,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildAddContentPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Add Private Content",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _saveContent,
              icon: const Icon(Icons.save),
              label: const Text("Save Content"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Secure Vault"),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isContentVisible
          ? _buildContent()
          : (_isAddingContent ? _buildAddContentPage() : _buildPasswordForm()),

      // 🚀 FloatingActionButton at the bottom right
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isAddingContent = false; // Switch to the password/view mode
            _isContentVisible = false; // Hide content until authenticated
            _passwordController.clear();
            _errorMessage = "";
          });
        },
        tooltip: 'View Saved Content',
        backgroundColor: Colors.blue.shade700,
        child: const Icon(Icons.lock, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}