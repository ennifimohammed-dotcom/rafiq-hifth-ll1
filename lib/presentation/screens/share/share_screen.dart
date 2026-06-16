import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';

class ShareScreen extends ConsumerStatefulWidget {
  const ShareScreen({super.key, required this.studentId});
  final String studentId;
  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  String? _token;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() => _loading = true);
    final t = await ref
        .read(firestoreRepositoryProvider)
        .createShareToken(widget.studentId);
    if (mounted) setState(() {
      _token = t;
      _loading = false;
    });
  }

  String get _url => '${AppConstants.reportBaseUrl}/$_token';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مشاركة التقرير')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: QrImageView(data: _url, size: 220),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SelectableText(_url,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => Share.share('تقرير الطالب: $_url'),
                    icon: const Icon(Icons.share),
                    label: const Text('مشاركة الرابط'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _generate,
                    icon: const Icon(Icons.refresh),
                    label: const Text('إنشاء رابط جديد'),
                  ),
                ],
              ),
            ),
    );
  }
}
