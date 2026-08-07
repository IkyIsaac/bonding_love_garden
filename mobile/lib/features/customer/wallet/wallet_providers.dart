import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/family/current_family_provider.dart';
import '../../../core/models/credit_ledger_entry.dart';

final familyCreditBalanceProvider = FutureProvider<int>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final familyId = await ref.watch(currentFamilyIdProvider.future);
  final row = await client
      .from('family_credit_balance')
      .select('balance')
      .eq('family_id', familyId)
      .maybeSingle();
  return (row?['balance'] as num?)?.toInt() ?? 0;
});

final creditLedgerProvider = FutureProvider<List<CreditLedgerEntry>>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);
  final familyId = await ref.watch(currentFamilyIdProvider.future);
  final rows = await client
      .from('game_credit_ledger')
      .select('id, direction, amount, reason, created_at')
      .eq('family_id', familyId)
      .order('created_at', ascending: false)
      .limit(50);
  return rows.map(CreditLedgerEntry.fromJson).toList();
});
