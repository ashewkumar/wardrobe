import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class InnerCircleJoinPage extends StatefulWidget {
  const InnerCircleJoinPage({super.key});

  @override
  State<InnerCircleJoinPage> createState() => _InnerCircleJoinPageState();
}

class _InnerCircleJoinPageState extends State<InnerCircleJoinPage> {
  final TextEditingController _codeController = TextEditingController();
  bool saving = false;
  String? token;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => token = prefs.getString('token'));
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _codeController.text.trim();
    if (value.isEmpty) return;
    if (token == null) return;

    setState(() => saving = true);
    final res = await ApiService.acceptInnerCircleInvite(
      token!,
      code: value,
    );
    setState(() => saving = false);

    if (!mounted) return;

    if (res != null && res['status'] == true) {
      Navigator.pop(context, true);
    } else {
      final msg = res != null && res['message'] != null
          ? res['message'].toString()
          : 'Failed to join';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Inner Circle')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Paste the invite code you received to join.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Invite code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : _submit,
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Join'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
