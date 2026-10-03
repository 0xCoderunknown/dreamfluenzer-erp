import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/app_enums.dart';
import '../engines/revenue_engine.dart';
import '../models/campaign_model.dart';
import '../models/client_model.dart';
import '../models/project_model.dart';
import '../providers/campaign_provider.dart';
import '../providers/client_provider.dart';
import '../providers/project_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common/ui_kit.dart';
import '../widgets/finance/invoice_widgets.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  String _query = '';
  bool _showPaid = false;

  @override
  Widget build(BuildContext context) {
    final projectProv = context.watch<ProjectProvider>();
    final campaignProv = context.watch<CampaignProvider>();

    final projects = projectProv.projects;
    final allCampaigns = campaignProv.campaigns;
    final clients = context.watch<ClientProvider>().clients;
    final filtered = _getFilteredProjects(projects, clients);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : _buildGrid(filtered, clients, allCampaigns),
            ),
          ],
        ),
      ),
    );
  }

  List<Project> _getFilteredProjects(
    List<Project> projects,
    List<Client> clients,
  ) {
    return projects
        .where((p) => p.dealType != DealType.prGift) // Only billable
        .where((p) {
          final invoice = RevenueEngine.calculateInvoice(p);
          if (_showPaid != invoice.isPaid) return false;

          final client = clients.where((c) => c.id == p.clientId).firstOrNull;
          final matchesQuery =
              p.projectName.toLowerCase().contains(_query.toLowerCase()) ||
              (client?.businessName.toLowerCase().contains(
                    _query.toLowerCase(),
                  ) ??
                  false);

          return matchesQuery;
        })
        .toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
  }

  Widget _buildHeader() {
    return DreamPageHeader(
      title: 'Invoices & Billing',
      subtitle: '${_showPaid ? 'Paid' : 'Pending'} accounts overview.',
      searchHint: 'Search projects or clients...',
      onSearch: (v) => setState(() => _query = v),
      filterWidget: _ToggleSwitch(
        showPaid: _showPaid,
        onChanged: (val) => setState(() => _showPaid = val),
      ),
    );
  }

  Widget _buildGrid(
    List<Project> filtered,
    List<Client> clients,
    List<Campaign> allCampaigns,
  ) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final p = filtered[index];
        final client = clients.where((c) => c.id == p.clientId).firstOrNull;

        final projectCampaigns = allCampaigns
            .where((c) => c.projectId == p.id)
            .toList();

        return InvoiceCard(
          project: p,
          client: client,
          campaigns:
              projectCampaigns, // ─── Passing it down to the dumb widget ───
          isPaidMode: _showPaid,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        _showPaid
            ? 'No paid invoices found.'
            : 'All caught up! No pending invoices.',
        style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
      ),
    );
  }
}

// --- Internal Helper for the Toggle ---

class _ToggleSwitch extends StatelessWidget {
  final bool showPaid;
  final Function(bool) onChanged;

  const _ToggleSwitch({required this.showPaid, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _Chip(
            label: 'Pending',
            selected: !showPaid,
            onTap: () => onChanged(false),
          ),
          const SizedBox(width: 4),
          _Chip(
            label: 'Fully Paid',
            selected: showPaid,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.transparent,
      selectedColor: Colors.white,
      showCheckmark: false,
      labelStyle: TextStyle(
        color: selected ? AppTheme.primaryDark : Colors.grey.shade600,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide.none,
      ),
    );
  }
}
