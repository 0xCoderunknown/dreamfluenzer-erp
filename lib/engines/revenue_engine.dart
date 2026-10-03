import '../domain/app_enums.dart';
import '../models/campaign_model.dart';
import '../models/creator_model.dart';
import '../models/project_model.dart';

/// DTO for a single project's invoice breakdown
class InvoiceMath {
  final double subtotal;
  final double gstAmount;
  final double grandTotal;
  final double advanceReceived;
  final double balanceDue;
  final bool isPaid;
  final bool isGstApplied;

  InvoiceMath({
    required this.subtotal,
    required this.gstAmount,
    required this.grandTotal,
    required this.advanceReceived,
    required this.balanceDue,
    required this.isPaid,
    required this.isGstApplied,
  });
}

/// DTO for the Barter/Product GMV distribution
class LogisticsMath {
  final double totalGmvBudget;
  final double totalDistributedGmv;
  final double retainedGmv;

  LogisticsMath({
    required this.totalGmvBudget,
    required this.totalDistributedGmv,
    required this.retainedGmv,
  });
}

/// DTO for the Master Ledger view
class LedgerMath {
  final double totalReceivables;
  final double totalPayables;
  final double projectedMargin;
  final List<Map<String, dynamic>> pendingInvoices;
  final List<Map<String, dynamic>> pendingPayouts;

  LedgerMath({
    required this.totalReceivables,
    required this.totalPayables,
    required this.projectedMargin,
    required this.pendingInvoices,
    required this.pendingPayouts,
  });
}

class ProjectProgressStats {
  final double totalPayouts;
  final double totalAdvances;
  final int completedCampaigns;
  final int totalCampaigns;

  ProjectProgressStats({
    required this.totalPayouts,
    required this.totalAdvances,
    required this.completedCampaigns,
    required this.totalCampaigns,
  });

  double get pendingPayouts => totalPayouts - totalAdvances;
}

class RevenueEngine {
  static const double currentGstRate = 0.18;

  // ─── 1. CORE INVOICE LOGIC ───
  static InvoiceMath calculateInvoice(Project project) {
    final subtotal = project.totalContractValue;
    final isGstApplied = project.isGstExclusive;

    final gstAmount = isGstApplied ? (subtotal * currentGstRate) : 0.0;
    final grandTotal = subtotal + gstAmount;
    final balanceDue = grandTotal - project.advanceReceived;

    return InvoiceMath(
      subtotal: subtotal,
      gstAmount: gstAmount,
      grandTotal: grandTotal,
      advanceReceived: project.advanceReceived,
      balanceDue: balanceDue,
      isPaid: balanceDue <= 0,
      isGstApplied: isGstApplied,
    );
  }

  // ─── 2. CASHFLOW GUARD ───
  static double calculateAvailableAdvancePool(
    Project project,
    List<Campaign> projectCampaigns,
    String excludeCreatorId,
    String excludeCampaignId,
  ) {
    double otherAdvances = 0.0;

    for (final camp in projectCampaigns) {
      for (final creator in camp.assignedCreators) {
        if (creator.creatorId != excludeCreatorId ||
            camp.id != excludeCampaignId) {
          otherAdvances += creator.advancePaid;
        }
      }
    }

    final pool = project.advanceReceived - otherAdvances;
    return pool > 0 ? pool : 0.0;
  }

  // ─── 3. LOGISTICS LOGIC ───
  static LogisticsMath calculateProjectLogistics(
    Project project,
    List<Campaign> campaigns,
  ) {
    double distributedGmv = 0.0;

    for (var camp in campaigns) {
      final gmvMap = {
        for (var item in camp.inventoryPool) item.id: item.gmvPerUnit,
      };

      for (var creator in camp.assignedCreators) {
        for (var allocatedItem in creator.allocatedItems) {
          final unitValue = gmvMap[allocatedItem.inventoryId] ?? 0.0;
          distributedGmv += (unitValue * allocatedItem.quantity);
        }
      }
    }

    return LogisticsMath(
      totalGmvBudget: project.gmvBudget,
      totalDistributedGmv: distributedGmv,
      retainedGmv: project.gmvBudget - distributedGmv,
    );
  }

  // ─── 4. MASTER LEDGER LOGIC (Linear Time Optimized O(N)) ───
  static LedgerMath calculateLedger({
    required List<Project> projects,
    required List<Campaign> campaigns,
    required List<Creator> creators,
  }) {
    double receivables = 0.0;
    double payables = 0.0;
    double margin = 0.0;

    final List<Map<String, dynamic>> pendingClientInvoices = [];
    final List<Map<String, dynamic>> pendingCreatorPayouts = [];

    final projectMap = {for (var p in projects) p.id: p};
    final creatorMap = {for (var c in creators) c.id: c};

    // 1. Calculate Receivables
    for (var p in projects) {
      if (p.status == ProjectStatus.dropped ||
          p.status == ProjectStatus.archived ||
          p.dealType == DealType.prGift) {
        continue;
      }

      final invoice = calculateInvoice(p);
      // Net revenue excludes GST (tax liability must not be commingled into margin)
      margin += p.totalContractValue;

      if (!invoice.isPaid) {
        receivables += invoice.balanceDue;
        pendingClientInvoices.add({
          'projectId': p.id,
          'projectName': p.projectName,
          'total': invoice.grandTotal,
          'received': invoice.advanceReceived,
          'due': invoice.balanceDue,
        });
      }
    }

    // 2. Calculate Payables
    for (var camp in campaigns) {
      final parentProject = projectMap[camp.projectId];

      if (parentProject == null ||
          parentProject.status == ProjectStatus.dropped ||
          parentProject.status == ProjectStatus.archived) {
        continue;
      }

      margin -= camp.expenses;

      for (var ac in camp.assignedCreators) {
        if (ac.pipelineStatus == PipelineStatus.dropped) {
          continue;
        }

        margin -= ac.agreedPayout;

        if (!ac.isPaid) {
          payables += ac.agreedPayout;
          final creator = creatorMap[ac.creatorId];

          pendingCreatorPayouts.add({
            'projectId': parentProject.id,
            'campaignTitle': camp.title,
            'creatorName': creator?.fullName ?? 'Deleted Creator',
            'amount': ac.agreedPayout - ac.advancePaid,
            'isUrgent':
                ac.pipelineStatus == PipelineStatus.postedLive ||
                parentProject.status == ProjectStatus.completed,
          });
        }
      }
    }

    pendingClientInvoices.sort((a, b) => b['due'].compareTo(a['due']));

    pendingCreatorPayouts.sort((a, b) {
      if (a['isUrgent'] && !b['isUrgent']) return -1;
      if (!a['isUrgent'] && b['isUrgent']) return 1;
      return b['amount'].compareTo(a['amount']);
    });

    return LedgerMath(
      totalReceivables: receivables,
      totalPayables: payables,
      projectedMargin: margin,
      pendingInvoices: pendingClientInvoices,
      pendingPayouts: pendingCreatorPayouts,
    );
  }

  // ─── 5. PROJECT PROGRESS LOGIC ───
  static ProjectProgressStats calculateProgress(List<Campaign> campaigns) {
    double totalPayouts = 0;
    double totalAdvances = 0;
    int completedCount = 0;

    for (var camp in campaigns) {
      bool allDone = camp.assignedCreators.isNotEmpty;
      for (var creator in camp.assignedCreators) {
        final status = creator.pipelineStatus;

        if (status != PipelineStatus.dropped) {
          totalPayouts += creator.agreedPayout;
          totalAdvances += creator.advancePaid;
        }

        final isTerminal =
            status == PipelineStatus.postedLive ||
            status == PipelineStatus.dropped;

        if (!isTerminal ||
            (status == PipelineStatus.postedLive && !creator.isPaid)) {
          allDone = false;
        }
      }
      if (allDone && camp.assignedCreators.isNotEmpty) completedCount++;
    }

    return ProjectProgressStats(
      totalPayouts: totalPayouts,
      totalAdvances: totalAdvances,
      completedCampaigns: completedCount,
      totalCampaigns: campaigns.length,
    );
  }

  // ─── 6. MARGIN & COST HELPERS ───
  static double totalCampaignCosts(List<Campaign> campaigns) {
    return campaigns.fold(0.0, (double sum, c) {
      final creatorCost = c.assignedCreators.fold(
        0.0,
        (s, ac) => s + ac.agreedPayout,
      );
      return sum + c.expenses + creatorCost;
    });
  }

  static double operatingMargin(Project project, List<Campaign> campaigns) {
    // Agency margin is computed on Liquid Cash net revenue, excluding GST tax liability
    return project.totalContractValue - totalCampaignCosts(campaigns);
  }

  static double operatingMarginPct(Project project, List<Campaign> campaigns) {
    if (project.totalContractValue == 0) return 0.0;
    return (operatingMargin(project, campaigns) / project.totalContractValue) *
        100;
  }
}
