import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:gap/gap.dart';
import '../../core/providers/providers.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usernameController = useTextEditingController(text: 'Babababa');
    final passwordController = useTextEditingController(text: 'babababa');
    final baseUrlController = useTextEditingController();
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);
    final showServerSettings = useState(false);
    final isTesting = useState(false);
    final testResult = useState<String?>(null);
    final storage = ref.read(storageServiceProvider);
    final apiService = ref.read(apiServiceProvider);

    // Load saved base URL on mount
    useEffect(() {
      Future<void> loadBaseUrl() async {
        final savedUrl = await storage.getBaseUrl();
        print('🔐 Login Screen: Loaded saved URL: $savedUrl');
        // Already using the correct public IP as default
        baseUrlController.text = savedUrl;
        if (savedUrl == 'http://98.70.88.219:3001') {
          print('🔐 Login Screen: Using public server IP');
        } else {
          baseUrlController.text = savedUrl;
          print('🔐 Login Screen: Using saved URL: $savedUrl');
        }
      }
      loadBaseUrl();
      return null;
    }, []);

    Future<void> testConnection() async {
      final testUrl = baseUrlController.text.trim();
      if (testUrl.isEmpty) {
        testResult.value = '❌ Please enter a server URL';
        return;
      }

      isTesting.value = true;
      testResult.value = null;

      try {
        print('🧪 Testing connection to: $testUrl');

        // Temporarily update the API service base URL for testing
        apiService.updateBaseUrl(testUrl);

        // Try to fetch the config endpoint
        final config = await apiService.getConfig();

        print('✅ Connection test successful: $config');
        testResult.value = '✅ Connection successful!\nServer: ${config['wsUrl'] ?? 'Unknown'}';
      } catch (e) {
        print('❌ Connection test failed: $e');
        testResult.value = '❌ Connection failed\n${e.toString().split('\n').first}';
      } finally {
        isTesting.value = false;
      }
    }

    Future<void> handleLogin() async {
      if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
        errorMessage.value = 'Please enter username and password';
        return;
      }

      isLoading.value = true;
      errorMessage.value = null;

      try {
        // Save base URL if changed
        final newBaseUrl = baseUrlController.text.trim();
        if (newBaseUrl.isNotEmpty) {
          print('💾 Saving new base URL: $newBaseUrl');
          await storage.saveBaseUrl(newBaseUrl);
          ref.read(baseUrlProvider.notifier).state = newBaseUrl;
          print('✅ Base URL saved and provider updated');
        }

        print('🔑 Attempting login with username: ${usernameController.text}');
        await ref
            .read(authStateProvider.notifier)
            .login(usernameController.text, passwordController.text);
        print('✅ Login successful');
        // Successful login - widget will be unmounted by router
      } catch (e) {
        print('❌ Login failed: $e');
        // Only update UI if still mounted (login failed)
        if (context.mounted) {
          errorMessage.value = e.toString();
          isLoading.value = false;
        }
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Title
                  Icon(
                    Icons.code,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const Gap(16),
                  Text(
                    'Claude Coder',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(8),
                  Text(
                    'AI-Powered Code Assistant',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(48),

                  // Username field
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    enabled: !isLoading.value,
                    textInputAction: TextInputAction.next,
                  ),
                  const Gap(16),

                  // Password field
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    enabled: !isLoading.value,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => handleLogin(),
                  ),
                  const Gap(24),

                  // Server Settings (Expandable)
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            showServerSettings.value = !showServerSettings.value;
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.dns,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const Gap(12),
                                Expanded(
                                  child: Text(
                                    'Server Settings',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Icon(
                                  showServerSettings.value
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (showServerSettings.value) ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Development Server URL',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const Gap(8),
                                TextField(
                                  controller: baseUrlController,
                                  decoration: InputDecoration(
                                    hintText: 'http://172.16.28.187:3001',
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.link),
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surface,
                                  ),
                                  keyboardType: TextInputType.url,
                                  enabled: !isLoading.value,
                                ),
                                const Gap(8),
                                Text(
                                  'Enter your development server IP address and port',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                                const Gap(12),
                                // Test Connection Button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: (isTesting.value || isLoading.value) ? null : testConnection,
                                    icon: isTesting.value
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.wifi_find, size: 18),
                                    label: Text(isTesting.value ? 'Testing...' : 'Test Connection'),
                                  ),
                                ),
                                // Test Result
                                if (testResult.value != null) ...[
                                  const Gap(8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: testResult.value!.startsWith('✅')
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      border: Border.all(
                                        color: testResult.value!.startsWith('✅')
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      testResult.value!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: testResult.value!.startsWith('✅')
                                            ? Colors.green.shade900
                                            : Colors.red.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Gap(24),

                  // Error message
                  if (errorMessage.value != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        errorMessage.value!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  if (errorMessage.value != null) const Gap(16),

                  // Login button
                  FilledButton(
                    onPressed: isLoading.value ? null : handleLogin,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: isLoading.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Login'),
                    ),
                  ),

                  const Gap(16),

                  // Help text
                  Text(
                    'Default credentials: admin / admin',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
