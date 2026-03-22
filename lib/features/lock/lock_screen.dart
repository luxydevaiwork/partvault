import 'package:flutter/material.dart';

import '../../core/services/lock_service.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _authenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    if (_authenticating) return;
    setState(() {
      _authenticating = true;
      _errorMessage = null;
    });

    final success = await LockService.authenticate();

    if (!mounted) return;

    if (success) {
      widget.onUnlocked();
    } else {
      setState(() {
        _authenticating = false;
        _errorMessage = 'Autenticazione fallita. Riprova.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(Icons.lock_outlined,
                      size: 40, color: cs.onPrimaryContainer),
                ),
                const SizedBox(height: 24),
                Text('PartVault',
                    style: tt.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('App bloccata',
                    style: tt.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 32),
                if (_authenticating) ...[
                  CircularProgressIndicator(color: cs.primary),
                  const SizedBox(height: 16),
                  Text('Autenticazione in corso...',
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ] else ...[
                  if (_errorMessage != null) ...[
                    Text(_errorMessage!,
                        style:
                            tt.bodySmall?.copyWith(color: cs.error),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                  ],
                  FilledButton.icon(
                    onPressed: _authenticate,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Sblocca'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
