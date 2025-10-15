import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/providers.dart';

class SettingsScreen extends HookConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.read(storageServiceProvider);
    final baseUrlController = useTextEditingController();
    final isSaving = useState(false);

    // Load saved base URL on mount
    useEffect(() {
      Future<void> loadBaseUrl() async {
        final savedUrl = await storage.getBaseUrl();
        // If it's the default localhost, prefill with example IP for development
        if (savedUrl == 'http://localhost:3001') {
          baseUrlController.text = 'http://172.16.28.187:3001';
        } else {
          baseUrlController.text = savedUrl;
        }
      }
      loadBaseUrl();
      return null;
    }, []);

    Future<void> saveBaseUrl() async {
      final url = baseUrlController.text.trim();
      if (url.isEmpty) return;

      isSaving.value = true;
      try {
        await storage.saveBaseUrl(url);
        ref.read(baseUrlProvider.notifier).state = url;

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Base URL saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        isSaving.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Server Configuration',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(8),
          const Text(
            'Configure the server URL for development',
            style: TextStyle(color: Colors.grey),
          ),
          const Gap(24),
          TextField(
            controller: baseUrlController,
            decoration: InputDecoration(
              labelText: 'Base URL',
              hintText: 'http://172.16.28.187:3001',
              helperText: 'Example: http://192.168.1.100:3001',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.link),
              suffixIcon: baseUrlController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        baseUrlController.clear();
                      },
                    )
                  : null,
            ),
            keyboardType: TextInputType.url,
          ),
          const Gap(24),
          FilledButton.icon(
            onPressed: isSaving.value ? null : saveBaseUrl,
            icon: isSaving.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(isSaving.value ? 'Saving...' : 'Save Configuration'),
          ),
          const Gap(16),
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const Gap(8),
                      Text(
                        'How to find your IP address',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  const Gap(8),
                  Text(
                    '1. On your development machine, run:\n'
                    '   • Mac/Linux: ifconfig | grep "inet "\n'
                    '   • Windows: ipconfig\n\n'
                    '2. Look for your local network IP (usually starts with 192.168 or 172.16)\n\n'
                    '3. Enter the full URL including port:\n'
                    '   http://YOUR_IP:3001',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
