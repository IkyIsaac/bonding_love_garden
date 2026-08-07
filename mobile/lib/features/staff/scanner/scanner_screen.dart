import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/branded_app_bar.dart';
import 'scanner_providers.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final TextEditingController _manualCodeController = TextEditingController();

  ScannableGame? _selectedGame;
  ScanOutcome? _result;
  String? _error;
  bool _scanning = false;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleCode(String qrCodeValue) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final outcome = await ref
          .read(scannerRepositoryProvider)
          .scan(qrCodeValue: qrCodeValue, catalogItemId: _selectedGame?.id);
      setState(() {
        _result = outcome;
        _scanning = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _scanning = false;
      });
    } finally {
      setState(() => _busy = false);
    }
  }

  void _reset() {
    setState(() {
      _result = null;
      _error = null;
      _manualCodeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final games = ref.watch(staffGamesProvider);

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Scan Wristband',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Admit a guest by scanning their wristband QR code.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            games.when(
              data: (list) => DropdownButtonFormField<ScannableGame?>(
                initialValue: _selectedGame,
                decoration: const InputDecoration(
                  labelText: 'Admitting into (optional)',
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('No specific game'),
                  ),
                  ...list.map(
                    (g) => DropdownMenuItem(value: g, child: Text(g.name)),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedGame = v),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: _result != null
                  ? _ResultCard(result: _result!, onScanNext: _reset)
                  : _scanning
                  ? _CameraView(controller: _controller, onDetect: _handleCode)
                  : _IdlePanel(
                      busy: _busy,
                      error: _error,
                      manualCodeController: _manualCodeController,
                      onStartScan: () => setState(() {
                        _scanning = true;
                        _error = null;
                      }),
                      onManualSubmit: () {
                        final code = _manualCodeController.text.trim();
                        if (code.isNotEmpty) _handleCode(code);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraView extends StatelessWidget {
  const _CameraView({required this.controller, required this.onDetect});

  final MobileScannerController controller;
  final ValueChanged<String> onDetect;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.large),
      child: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          if (capture.barcodes.isEmpty) return;
          final value = capture.barcodes.first.rawValue;
          if (value != null) onDetect(value);
        },
      ),
    );
  }
}

class _IdlePanel extends StatelessWidget {
  const _IdlePanel({
    required this.busy,
    required this.error,
    required this.manualCodeController,
    required this.onStartScan,
    required this.onManualSubmit,
  });

  final bool busy;
  final String? error;
  final TextEditingController manualCodeController;
  final VoidCallback onStartScan;
  final VoidCallback onManualSubmit;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadii.large),
            ),
            child: const Icon(
              Icons.qr_code_scanner,
              size: 72,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (busy) const CircularProgressIndicator(),
          if (!busy)
            ElevatedButton.icon(
              onPressed: onStartScan,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Open Camera'),
            ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Or enter the wristband code manually',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.base),
          SizedBox(
            width: 280,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: manualCodeController,
                    decoration: const InputDecoration(hintText: 'WB-...'),
                    onSubmitted: (_) => onManualSubmit(),
                  ),
                ),
                const SizedBox(width: AppSpacing.base),
                IconButton.filled(
                  onPressed: busy ? null : onManualSubmit,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.onScanNext});

  final ScanOutcome result;
  final VoidCallback onScanNext;

  @override
  Widget build(BuildContext context) {
    final admitted = result.admitted;
    final color = admitted ? AppColors.primary : AppColors.error;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(
                admitted ? Icons.check : Icons.close,
                color: Colors.white,
                size: 52,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              admitted ? 'Admitted' : 'Denied',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            Text(
              result.beneficiary.name ?? 'Guest',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Wristband ${result.wristbandNumber} · ${result.wristbandStatus}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            if (result.plan != null) ...[
              const SizedBox(height: 4),
              Text(
                result.plan!.name,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: onScanNext,
              icon: const Icon(Icons.qr_code_scanner_outlined),
              label: const Text('Scan Next'),
            ),
          ],
        ),
      ),
    );
  }
}
