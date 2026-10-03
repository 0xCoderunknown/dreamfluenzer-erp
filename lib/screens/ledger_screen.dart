import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../engines/revenue_engine.dart';
import '../models/campaign_model.dart';
import '../models/creator_model.dart';
import '../models/project_model.dart';
import '../providers/campaign_provider.dart';
import '../providers/creator_provider.dart';
import '../providers/project_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/finance/ledger_widgets.dart';

class FinancialLedgerScreen extends StatelessWidget {
  const FinancialLedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_IN');

    // ─── FIX: Strong Type Selection (No dynamic) ───
    final allProjects = context.select<ProjectProvider, List<Project>>(
      (p) => p.projects,
    );
    final allCampaigns = context.select<CampaignProvider, List<Campaign>>(
      (p) => p.campaigns,
    );
    final allCreators = context.select<CreatorProvider, List<Creator>>(
      (c) => c.creators,
    );

    final ledger = RevenueEngine.calculateLedger(
      projects: allProjects,
      campaigns: allCampaigns,
      creators: allCreators,
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildSummaryGrid(ledger, fmt),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionColumn(
                  title: 'Pending Client Invoices',
                  emptyMsg: 'All clients are fully paid up. Great job!',
                  itemCount: ledger.pendingInvoices.length,
                  itemBuilder: (context, index) => LedgerInvoiceTile(
                    item: ledger.pendingInvoices[index],
                    onTap: () => _navigateToProject(
                      context,
                      ledger.pendingInvoices[index],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                _buildSectionColumn(
                  title: 'Pending Creator Payouts',
                  emptyMsg: 'All creators have been paid.',
                  itemCount: ledger.pendingPayouts.length,
                  itemBuilder: (context, index) => LedgerPayoutTile(
                    item: ledger.pendingPayouts[index],
                    onTap: () => _navigateToProject(
                      context,
                      ledger.pendingPayouts[index],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.account_balance_wallet_rounded,
              size: 32,
              color: AppTheme.primaryDark,
            ),
            SizedBox(width: 16),
            Text(
              'Financial Ledger',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Master overview of agency cash flow and creator payouts.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSummaryGrid(dynamic ledger, NumberFormat fmt) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 900 ? 3 : 1;
        return GridView.count(
          crossAxisCount: cols,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: constraints.maxWidth > 900 ? 2.5 : 3.0,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            LedgerStatCard(
              label: 'Accounts Receivable',
              value: '₹${fmt.format(ledger.totalReceivables)}',
              icon: Icons.arrow_circle_down_rounded,
              color: Colors.orange,
              bgColor: Colors.orange.shade50,
            ),
            LedgerStatCard(
              label: 'Accounts Payable',
              value: '₹${fmt.format(ledger.totalPayables)}',
              icon: Icons.arrow_circle_up_rounded,
              color: AppTheme.primaryPurple,
              bgColor: AppTheme.primaryPurple.withValues(alpha: 0.1),
            ),
            LedgerStatCard(
              label: 'Projected Net Margin',
              value: '₹${fmt.format(ledger.projectedMargin)}',
              icon: Icons.account_balance_rounded,
              color: AppTheme.success,
              bgColor: Colors.green.shade50,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionColumn({
    required String title,
    required String emptyMsg,
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: itemCount == 0
                ? Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      emptyMsg,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: itemCount,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: itemBuilder,
                  ),
          ),
        ],
      ),
    );
  }

  void _navigateToProject(BuildContext context, Map<String, dynamic> item) {
    if (item['projectId'] != 'ORPHANED') {
      context.go('/projects/${item['projectId']}');
    }
  }
}
