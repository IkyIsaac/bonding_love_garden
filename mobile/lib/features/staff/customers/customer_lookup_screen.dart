import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/branded_app_bar.dart';
import 'customer_search_providers.dart';

class CustomerLookupScreen extends ConsumerStatefulWidget {
  const CustomerLookupScreen({super.key});

  @override
  ConsumerState<CustomerLookupScreen> createState() =>
      _CustomerLookupScreenState();
}

class _CustomerLookupScreenState extends ConsumerState<CustomerLookupScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(customerSearchProvider(_query));

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Look Up Customer',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              "Search by the family's phone number.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '255...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(child: _buildResults(context, results)),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(
    BuildContext context,
    AsyncValue<List<CustomerMatch>> results,
  ) {
    if (_query.trim().length < 3) {
      return Center(
        child: Text(
          'Type at least 3 digits to search.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
        ),
      );
    }
    return results.when(
      data: (matches) {
        if (matches.isEmpty) {
          return Center(
            child: Text(
              'No customer found for "$_query".',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          );
        }
        return ListView.builder(
          itemCount: matches.length,
          itemBuilder: (context, i) {
            final m = matches[i];
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.base),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryContainer,
                  child: Icon(
                    Icons.person,
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
                title: Text(m.fullName),
                subtitle: Text(m.phone),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/staff/customers/detail', extra: m),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(
          "Couldn't search customers.",
          style: TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}
