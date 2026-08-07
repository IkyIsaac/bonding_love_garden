import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_providers.dart';

class ScannableGame {
  const ScannableGame({required this.id, required this.name});

  final String id;
  final String name;
}

/// Active games (not services) a staff member can pick before scanning, to
/// admit into a specific session — matches session-scan-admit's optional
/// catalogItemId, which drives its entitlement check.
final staffGamesProvider = FutureProvider<List<ScannableGame>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final rows = await client
      .from('catalog_items')
      .select('id, name')
      .eq('type', 'game')
      .eq('is_active', true)
      .order('name');
  return rows
      .map(
        (r) => ScannableGame(id: r['id'] as String, name: r['name'] as String),
      )
      .toList();
});

class ScanBeneficiary {
  const ScanBeneficiary({this.name, this.photoUrl});

  final String? name;
  final String? photoUrl;
}

class ScanPlan {
  const ScanPlan({required this.name, this.dailyTimeLimitMinutes});

  final String name;
  final int? dailyTimeLimitMinutes;
}

class ScanSession {
  const ScanSession({
    required this.id,
    required this.startedAt,
    required this.plannedEndAt,
  });

  final String id;
  final DateTime startedAt;
  final DateTime plannedEndAt;
}

/// Mirrors session-scan-admit's response shape exactly — a scan is always a
/// 200 with admitted true/false (invalid/expired wristband is a normal scan
/// outcome the UI renders, not a thrown error); only a genuinely
/// unrecoverable request (network, 403, 404 unknown code) throws.
class ScanOutcome {
  const ScanOutcome({
    required this.admitted,
    required this.wristbandNumber,
    required this.wristbandStatus,
    required this.beneficiary,
    this.plan,
    this.session,
  });

  final bool admitted;
  final String wristbandNumber;
  final String wristbandStatus;
  final ScanBeneficiary beneficiary;
  final ScanPlan? plan;
  final ScanSession? session;
}

class ScannerRepository {
  ScannerRepository(this._client);

  final SupabaseClient _client;

  Future<ScanOutcome> scan({
    required String qrCodeValue,
    String? catalogItemId,
  }) async {
    final response = await _client.functions.invoke(
      'session-scan-admit',
      body: {
        'qrCodeValue': qrCodeValue,
        if (catalogItemId != null) 'catalogItemId': catalogItemId,
        'location': 'Front Gate',
      },
    );
    final data = response.data as Map<String, dynamic>;
    final wristband = data['wristband'] as Map<String, dynamic>;
    final beneficiary = data['beneficiary'] as Map<String, dynamic>;
    final plan = data['plan'] as Map<String, dynamic>?;
    final session = data['session'] as Map<String, dynamic>?;

    return ScanOutcome(
      admitted: data['admitted'] as bool,
      wristbandNumber: wristband['wristbandNumber'] as String,
      wristbandStatus: wristband['status'] as String,
      beneficiary: ScanBeneficiary(
        name: beneficiary['name'] as String?,
        photoUrl: beneficiary['photoUrl'] as String?,
      ),
      plan: plan == null
          ? null
          : ScanPlan(
              name: plan['name'] as String,
              dailyTimeLimitMinutes: plan['dailyTimeLimitMinutes'] as int?,
            ),
      session: session == null
          ? null
          : ScanSession(
              id: session['id'] as String,
              startedAt: DateTime.parse(session['startedAt'] as String),
              plannedEndAt: DateTime.parse(session['plannedEndAt'] as String),
            ),
    );
  }
}

final scannerRepositoryProvider = Provider<ScannerRepository>((ref) {
  return ScannerRepository(ref.watch(supabaseClientProvider));
});
