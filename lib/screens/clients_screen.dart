import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/client_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/client/client_dialogs.dart';
import '../widgets/client/client_widgets.dart';
import '../widgets/common/ui_kit.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    // ─── 1. FETCH DATA ───
    final clients = context.watch<ClientProvider>().clients;

    // ─── 2. FILTER DATA ───
    final filtered = clients
        .where(
          (c) =>
              c.businessName.toLowerCase().contains(_query.toLowerCase()) ||
              c.industryType.toLowerCase().contains(_query.toLowerCase()) ||
              c.location.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    // ─── 3. BUILD UI ───
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DreamPageHeader(
              title: 'Clients',
              subtitle: '${clients.length} clients in your roster.',
              searchHint: 'Search by name, industry, or location…',
              actionLabel: '+ Add Client',
              onSearch: (v) => setState(() => _query = v),
              onAction: () => _openAddDialog(context),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: filtered.isEmpty
                  ? _empty(_query)
                  : ClientTable(clients: filtered),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(String q) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.business_outlined, size: 48, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text(
          q.isEmpty
              ? 'No clients yet. Add your first one!'
              : 'No match for "$q".',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
        ),
      ],
    ),
  );

  Future<void> _openAddDialog(BuildContext ctx, [dynamic client]) => showDialog(
    context: ctx,
    barrierDismissible: false,
    builder: (_) => AddClientDialog(clientToEdit: client),
  );
}
