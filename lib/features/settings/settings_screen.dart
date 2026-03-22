import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/export_service.dart';
import '../../core/services/lock_service.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _lockEnabled = false;
  bool _lockAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadLockState();
  }

  Future<void> _loadLockState() async {
    final enabled = await LockService.isEnabled();
    final available = await LockService.isAvailable();
    if (mounted) {
      setState(() {
        _lockEnabled = enabled;
        _lockAvailable = available;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Theme section
          Text('Aspetto', style: tt.labelLarge?.copyWith(color: cs.primary)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tema', style: tt.titleSmall),
                const SizedBox(height: 12),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('Auto'),
                      icon: Icon(Icons.brightness_auto_outlined),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Chiaro'),
                      icon: Icon(Icons.light_mode_outlined),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Scuro'),
                      icon: Icon(Icons.dark_mode_outlined),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (modes) =>
                      ref.read(themeModeProvider.notifier).setTheme(modes.first),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Security section
          Text('Sicurezza',
              style: tt.labelLarge?.copyWith(color: cs.primary)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SwitchListTile(
              secondary: const Icon(Icons.lock_outlined),
              title: const Text('Blocco biometrico'),
              subtitle: Text(
                _lockAvailable
                    ? 'Richiede impronta o PIN all\'avvio'
                    : 'Non disponibile su questo dispositivo',
                style:
                    tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              value: _lockEnabled && _lockAvailable,
              onChanged: _lockAvailable
                  ? (val) async {
                      if (val) {
                        final ok = await LockService.authenticate();
                        if (!ok) return;
                      }
                      await LockService.setEnabled(val);
                      if (mounted) setState(() => _lockEnabled = val);
                    }
                  : null,
            ),
          ),

          const SizedBox(height: 24),

          // Data section
          Text('Dati', style: tt.labelLarge?.copyWith(color: cs.primary)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_outlined),
                  title: const Text('Esporta backup JSON'),
                  subtitle: const Text('Tutti i dati in formato JSON'),
                  onTap: () => ExportService.exportJson(context, ref),
                ),
                Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: cs.outlineVariant.withAlpha(60)),
                ListTile(
                  leading: const Icon(Icons.table_chart_outlined),
                  title: const Text('Esporta CSV'),
                  subtitle: const Text('Compatibile con Excel e Google Sheets'),
                  onTap: () => ExportService.exportCsv(context, ref),
                ),
                Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: cs.outlineVariant.withAlpha(60)),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Importa backup JSON'),
                  subtitle: const Text('Ripristina da un file di backup'),
                  onTap: () => ExportService.importJson(context, ref),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // About section
          Text('Info', style: tt.labelLarge?.copyWith(color: cs.primary)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.inventory_2_outlined,
                          color: cs.onPrimaryContainer, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PartVault', style: tt.titleMedium),
                        Text('v1.0.0 — Offline & Premium',
                            style: tt.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Nessuna pubblicità. Nessun server. Tutti i dati restano sul tuo dispositivo.',
                  style:
                      tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Legal section
          Text('Legale', style: tt.labelLarge?.copyWith(color: cs.primary)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy e Note Legali'),
              subtitle: const Text('Informativa sul trattamento dei dati'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showDialog(
                context: context,
                builder: (ctx) => const _PrivacyDialog(),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PrivacyDialog extends StatelessWidget {
  const _PrivacyDialog();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AlertDialog(
      title: const Text('Privacy e Note Legali'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section(tt, '1. Titolare del Trattamento',
                  'PartVault è un\'applicazione sviluppata da un singolo sviluppatore indipendente. Per informazioni: [la tua email].'),
              _section(tt, '2. Dati Raccolti',
                  'L\'app non raccoglie, trasmette né condivide alcun dato personale. Tutti i dati inseriti (oggetti, categorie, immagini) vengono salvati esclusivamente sul dispositivo dell\'utente.'),
              _section(tt, '3. Archiviazione Locale',
                  'I dati sono memorizzati in un database SQLite locale e in file immagine nella directory privata dell\'app. Nessun dato viene inviato a server esterni.'),
              _section(tt, '4. Permessi Richiesti',
                  '• Fotocamera / Galleria: per aggiungere immagini agli oggetti.\n'
                  '• NFC: per leggere/scrivere tag NFC associati agli oggetti.\n'
                  '• Notifiche: per avvisi di scadenza e manutenzione.\n'
                  '• Biometria / PIN: per il blocco dell\'app (opzionale).\n'
                  'Nessuno di questi permessi viene usato per raccogliere dati.'),
              _section(tt, '5. Backup ed Esportazione',
                  'La funzione di esportazione (JSON/CSV) crea file sul dispositivo dell\'utente. La gestione e condivisione di tali file è sotto la piena responsabilità dell\'utente.'),
              _section(tt, '6. Servizi di Terze Parti',
                  'L\'app non integra analytics, pubblicità, tracciamento o SDK di terze parti.'),
              _section(tt, '7. Minori',
                  'L\'app non raccoglie dati e non è rivolta specificamente ai minori. Non vi sono rischi particolari per questa categoria di utenti.'),
              _section(tt, '8. Modifiche',
                  'Eventuali aggiornamenti a questa informativa saranno notificati tramite aggiornamento dell\'app sul Play Store.'),
              _section(tt, '9. Contatti',
                  'Per qualsiasi domanda relativa alla privacy: [la tua email].'),
              const SizedBox(height: 8),
              Text(
                'Ultimo aggiornamento: marzo 2025',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Ho capito'),
        ),
      ],
    );
  }

  Widget _section(TextTheme tt, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(body, style: tt.bodySmall),
        ],
      ),
    );
  }
}
