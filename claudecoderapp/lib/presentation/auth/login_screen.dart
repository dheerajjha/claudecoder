import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:gap/gap.dart';
import '../../core/providers/providers.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usernameController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);

    Future<void> handleLogin() async {
      if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
        errorMessage.value = 'Please enter username and password';
        return;
      }

      isLoading.value = true;
      errorMessage.value = null;

      try {
        await ref
            .read(authStateProvider.notifier)
            .login(usernameController.text, passwordController.text);
        // Successful login - widget will be unmounted by router
      } catch (e) {
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
