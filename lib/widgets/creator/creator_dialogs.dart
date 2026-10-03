import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/app_enums.dart';
import '../../engines/crm_analytics_engine.dart';
import '../../models/campaign_model.dart';
import '../../models/creator_model.dart';
import '../../providers/campaign_provider.dart';
import '../../providers/creator_provider.dart';
import '../../providers/project_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../common/ui_kit.dart';

// CREATOR PROFILE DIALOG
class CreatorProfileDialog extends StatelessWidget {
  final Creator creator;
  final ProjectProvider projectProv;
  final VoidCallback onEdit;

  const CreatorProfileDialog({
    super.key,
    required this.creator,
    required this.projectProv,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final campaignProv = context.read<CampaignProvider>();
    final allCampaigns = campaignProv.campaigns;
    final fmt = NumberFormat('#,##0', 'en_IN');
    final history = CrmAnalyticsEngine.getCampaignHistoryForCreator(
      creator.id,
      allCampaigns,
    );
    final ltv = CrmAnalyticsEngine.getLifetimeValueForCreator(
      creator.id,
      allCampaigns,
    );

    final activeTasks = <Campaign>{};
    final pastTasks = <Campaign>{};

    for (var camp in history) {
      final ac = camp.assignedCreators.firstWhere(
        (a) => a.creatorId == creator.id,
      );
      if ([
        PipelineStatus.draftRequested,
        PipelineStatus.reviewing,
        PipelineStatus.changesRequested,
      ].contains(ac.pipelineStatus)) {
        activeTasks.add(camp);
      } else {
        pastTasks.add(camp);
      }
    }

    final pastList = pastTasks.toList()
      ..sort((a, b) => b.cycleEndDate.compareTo(a.cycleEndDate));
    final recentPast = pastList.take(5).toList();
    final completedCount = history.length - activeTasks.length;
    final double displayRating = (5.0 - (creator.strikeLevel * 0.5)).clamp(
      1.0,
      5.0,
    );
    final bool isBusy =
        creator.busyFrom != null &&
        creator.busyTo != null &&
        creator.busyTo!.isAfter(DateTime.now());

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 950, maxHeight: 850),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopIdentity(context, displayRating, isBusy),
              const SizedBox(height: 24),
              _buildKpiBar(
                creator,
                activeTasks.length,
                completedCount,
                ltv,
                fmt,
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _buildGridMetaTile(
                        Icons.phone_android_rounded,
                        'Phone Number',
                        creator.phoneNumber,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: _buildGridMetaTile(
                        Icons.location_city_rounded,
                        'City',
                        creator.location.isEmpty ? 'N/A' : creator.location,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: _buildGridMetaTile(
                        Icons.account_balance_wallet_rounded,
                        'UPI ID',
                        creator.upiId.isEmpty ? 'N/A' : creator.upiId,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: _buildGridMetaTile(
                        Icons.local_offer_rounded,
                        'Primary Niche',
                        creator.type == CreatorType.influencer
                            ? '${creator.primaryCategory.value}${creator.secondaryNiche.isEmpty ? "" : " ➔ ${creator.secondaryNiche}"}'
                            : creator.primaryCategory.value,
                      ),
                    ),
                  ],
                ),
              ),
              if (creator.notes.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildNotesSection(),
              ],
              const SizedBox(height: 32),
              Expanded(
                child: _buildSplitCrmView(
                  context,
                  activeTasks.toList(),
                  recentPast,
                  fmt,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridMetaTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primaryPurple),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9CA3AF),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopIdentity(
    BuildContext context,
    double displayRating,
    bool isBusy,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppTheme.primaryPurple.withValues(alpha: 0.1),
          child: Text(
            creator.fullName[0].toUpperCase(),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryPurple,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    creator.fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: List.generate(
                      5,
                      (index) => Icon(
                        index < displayRating.floor()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: Colors.amber.shade600,
                        size: 20,
                      ),
                    ),
                  ),
                  if (creator.strikeLevel > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        '(${creator.strikeLevel} Strikes)',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final url = Uri.parse(
                    'https://instagram.com/${creator.handle}',
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '@${creator.handle}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.primaryPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.open_in_new_rounded,
                      size: 12,
                      color: AppTheme.primaryPurple,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DreamStatusChip(label: creator.type.value),
                  DreamStatusChip(
                    label: creator.status.value,
                    customColor: creator.status == CreatorStatus.active
                        ? Colors.green
                        : (creator.status == CreatorStatus.inactive
                              ? Colors.red
                              : Colors.orange),
                  ),
                  if (isBusy)
                    DreamStatusChip(
                      label:
                          'Away: ${DateFormat('dd MMM').format(creator.busyFrom!)} - ${DateFormat('dd MMM').format(creator.busyTo!)}',
                      customColor: Colors.red,
                    ),
                ],
              ),
            ],
          ),
        ),
        _buildActionMenuRow(context),
      ],
    );
  }

  Widget _buildActionMenuRow(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.history_rounded, color: Colors.blueGrey),
          tooltip: 'View History',
          onPressed: () {
            final logsFuture = context.read<CreatorProvider>().getCreatorLogs(
              creator.id,
            );
            showDialog(
              context: context,
              builder: (ctx) => DreamAuditLogDialog(
                title: creator.fullName,
                fetchLogs: logsFuture,
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.grey),
          tooltip: 'Edit Creator Profile',
          onPressed: () {
            Navigator.pop(context);
            onEdit();
          },
        ),
      ],
    );
  }

  Widget _buildKpiBar(
    Creator c,
    int activeCount,
    int completedCount,
    double ltv,
    NumberFormat fmt,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ProfileStatKpi(
            label: 'Base Rate',
            value: '₹${fmt.format(c.baseRate)}',
          ),
          _ProfileStatKpi(
            label: 'Followers',
            value: fmt.format(c.followerCount),
          ),
          _ProfileStatKpi(
            label: 'Active Campaigns',
            value: activeCount.toString(),
            valueColor: activeCount > 0 ? Colors.orange.shade700 : null,
          ),
          _ProfileStatKpi(
            label: 'Completed Campaigns',
            value: completedCount.toString(),
          ),
          _ProfileStatKpi(
            label: 'Lifetime Value (LTV)',
            value: '₹${fmt.format(ltv)}',
            valueColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notes_rounded, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Internal Notes',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  creator.notes,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.primaryDark,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitCrmView(
    BuildContext context,
    List<Campaign> active,
    List<Campaign> past,
    NumberFormat fmt,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: _CampaignTrackingColumn(
            title: 'Active Campaigns',
            campaigns: active,
            creatorId: creator.id,
            fmt: fmt,
            projectProv: projectProv,
          ),
        ),
        const VerticalDivider(width: 48),
        Expanded(
          flex: 4,
          child: _CampaignTrackingColumn(
            title: 'Completed Campaigns',
            campaigns: past,
            creatorId: creator.id,
            fmt: fmt,
            projectProv: projectProv,
          ),
        ),
      ],
    );
  }
}

class _CampaignTrackingColumn extends StatelessWidget {
  final String title;
  final List<Campaign> campaigns;
  final String creatorId;
  final NumberFormat fmt;
  final ProjectProvider projectProv;

  const _CampaignTrackingColumn({
    required this.title,
    required this.campaigns,
    required this.creatorId,
    required this.fmt,
    required this.projectProv,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: campaigns.isEmpty
              ? Center(
                  child: Text(
                    'No completed campaigns found.',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: campaigns.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final camp = campaigns[index];
                    final ac = camp.assignedCreators.firstWhere(
                      (a) => a.creatorId == creatorId,
                    );
                    final project = projectProv.projectById(camp.projectId);

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        title: Text(
                          '${project?.projectName ?? 'Unknown Brand'} - ${camp.title}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ac.deliverables.isEmpty
                                    ? 'No deliverables specified'
                                    : ac.deliverables
                                          .map(
                                            (d) =>
                                                '${d.quantity}x ${d.type.value}',
                                          )
                                          .join(', '),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Target: ${DateFormat('dd MMM yyyy').format(ac.individualDeadline)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      DateTime.now().isAfter(
                                        ac.individualDeadline,
                                      )
                                      ? Colors.red
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              project?.dealType == DealType.prGift
                                  ? 'Barter'
                                  : '₹${fmt.format(ac.agreedPayout)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            DreamStatusChip(label: ac.pipelineStatus.value),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          context.go('/projects/${camp.projectId}');
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class AddEditCreatorDialog extends StatefulWidget {
  final Creator? creator;

  const AddEditCreatorDialog({super.key, this.creator});

  @override
  State<AddEditCreatorDialog> createState() => AddEditCreatorDialogState();
}

class AddEditCreatorDialogState extends State<AddEditCreatorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl,
      _handleCtrl,
      _phoneCtrl,
      _rateCtrl,
      _followerCtrl,
      _upiCtrl,
      _locCtrl,
      _notesCtrl,
      _secondaryNicheCtrl;

  late CreatorType _selectedType;
  late PrimaryCategory _selectedCategory;
  late CreatorStatus _selectedStatus;
  DateTimeRange? _busyRange;

  @override
  void initState() {
    super.initState();
    final c = widget.creator;
    _nameCtrl = TextEditingController(text: c?.fullName);
    _handleCtrl = TextEditingController(text: c?.handle);
    _phoneCtrl = TextEditingController(text: c?.phoneNumber);
    _rateCtrl = TextEditingController(text: c?.baseRate.toStringAsFixed(0));
    _followerCtrl = TextEditingController(text: c?.followerCount.toString());
    _upiCtrl = TextEditingController(text: c?.upiId);
    _locCtrl = TextEditingController(text: c?.location);
    _notesCtrl = TextEditingController(text: c?.notes);
    _secondaryNicheCtrl = TextEditingController(text: c?.secondaryNiche ?? '');
    _selectedType = c?.type ?? CreatorType.influencer;
    _selectedCategory = c?.primaryCategory ?? PrimaryCategory.generalUgc;
    _selectedStatus = c?.status ?? CreatorStatus.trial;
  }

  @override
  void dispose() {
    for (var ctrl in [
      _nameCtrl,
      _handleCtrl,
      _phoneCtrl,
      _rateCtrl,
      _followerCtrl,
      _upiCtrl,
      _locCtrl,
      _notesCtrl,
      _secondaryNicheCtrl,
    ]) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.creator == null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 850),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          key: const ValueKey('AddEditCreatorFormWrapper'),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // ─── STAGE 1: WINDOW HEADER ───
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isNew ? 'Add Creator Profile' : 'Edit Creator Details',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),

                // ─── STAGE 2: FORM INPUT SHEET CONTROLS ───
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Personal Information'),
                        Row(
                          children: [
                            Expanded(
                              child: _formField(
                                'Full Name *',
                                _nameCtrl,
                                val: (v) =>
                                    Validators.validateRequired(v, 'Name'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _formField(
                                'Instagram Handle *',
                                _handleCtrl,
                                prefix: '@',
                                val: Validators.validateInstagramHandle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _sectionLabel('Role & Classification'),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Role',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryDark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<CreatorType>(
                                    initialValue: _selectedType,
                                    items: CreatorType.values
                                        .map(
                                          (t) => DropdownMenuItem(
                                            value: t,
                                            child: Text(t.value),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() {
                                          _selectedType = v;
                                          if (_selectedType !=
                                              CreatorType.influencer) {
                                            _selectedCategory =
                                                PrimaryCategory.generalUgc;
                                            _followerCtrl.text = '0';
                                          } else {
                                            _selectedCategory =
                                                PrimaryCategory.clothing;
                                          }
                                        });
                                      }
                                    },
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Status',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryDark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<CreatorStatus>(
                                    initialValue: _selectedStatus,
                                    items: CreatorStatus.values
                                        .map(
                                          (s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(s.value),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _selectedStatus = v!),
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (_selectedType == CreatorType.influencer) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Primary Category *',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryDark,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<PrimaryCategory>(
                                      initialValue:
                                          _selectedCategory ==
                                              PrimaryCategory.generalUgc
                                          ? PrimaryCategory.clothing
                                          : _selectedCategory,
                                      items: PrimaryCategory.values
                                          .where(
                                            (cat) =>
                                                cat !=
                                                PrimaryCategory.generalUgc,
                                          )
                                          .map(
                                            (cat) => DropdownMenuItem(
                                              value: cat,
                                              child: Text(cat.value),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) => setState(
                                        () => _selectedCategory = v!,
                                      ),
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _formField(
                                  'Secondary Niche',
                                  _secondaryNicheCtrl,
                                  hint: 'e.g. Skincare, Bridal, Cosmetics',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        _buildVacationToggleSwitch(),
                        const SizedBox(height: 16),

                        _sectionLabel('Financial Details'),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _formField(
                                _selectedType == CreatorType.sandboxTrainee
                                    ? 'Stipend (₹) *'
                                    : 'Base Rate (₹) *',
                                _rateCtrl,
                                digitsOnly: true,
                                val: (v) =>
                                    Validators.validateRequired(v, 'Rate'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _formField(
                                    'Follower Count',
                                    _followerCtrl,
                                    digitsOnly: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: _formField(
                                'Contact Number *',
                                _phoneCtrl,
                                val: Validators.validatePhone,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: _formField('City', _locCtrl)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _formField(
                          'UPI ID',
                          _upiCtrl,
                          val: Validators.optional(Validators.validateUpi),
                        ),
                        const SizedBox(height: 16),

                        _formField('Internal Notes', _notesCtrl, maxLines: 3),
                      ],
                    ),
                  ),
                ),

                // ─── STAGE 3: FOOTER ROW ACTIONS ───
                const Divider(),
                _buildFooterRow(isNew),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVacationToggleSwitch() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SwitchListTile(
        title: const Text(
          'Mark as Away / Unavailable',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          _busyRange != null
              ? 'Away: ${DateFormat('dd MMM').format(_busyRange!.start)} to ${DateFormat('dd MMM').format(_busyRange!.end)}'
              : 'Currently active and available for campaigns.',
          style: TextStyle(
            fontSize: 12,
            color: _busyRange != null
                ? Colors.red.shade600
                : Colors.grey.shade600,
          ),
        ),
        value: _busyRange != null,
        activeThumbColor: Colors.red,
        onChanged: (isTurnedOn) async {
          if (isTurnedOn) {
            final minDate = DateTime.now().add(const Duration(days: 30));
            final picked = await showDateRangePicker(
              context: context,
              firstDate: minDate,
              lastDate: DateTime.now().add(const Duration(days: 365)),
              helpText: 'Select Away Dates',
            );
            if (picked != null) setState(() => _busyRange = picked);
          } else {
            setState(() => _busyRange = null);
          }
        },
      ),
    );
  }

  Widget _buildFooterRow(bool isNew) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (!isNew)
          TextButton.icon(
            onPressed: () => _handleDeleteRequest(context, widget.creator!),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Delete Creator'),
          ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 16),
        Navigator(
          onGenerateRoute: (_) => MaterialPageRoute(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;

                final newCreator = Creator(
                  id: isNew ? '' : widget.creator!.id,
                  fullName: _nameCtrl.text.trim(),
                  handle: _handleCtrl.text.trim().replaceAll('@', ''),
                  phoneNumber: _phoneCtrl.text.replaceAll(RegExp(r'\s+'), ''),
                  status: _selectedStatus,
                  type: _selectedType,

                  primaryCategory: _selectedType == CreatorType.influencer
                      ? (_selectedCategory == PrimaryCategory.generalUgc
                            ? PrimaryCategory.clothing
                            : _selectedCategory)
                      : PrimaryCategory.generalUgc,

                  secondaryNiche: _selectedType == CreatorType.influencer
                      ? _secondaryNicheCtrl.text.trim()
                      : '',
                  baseRate: (double.tryParse(_rateCtrl.text) ?? 0.0).abs(),
                  followerCount: _selectedType == CreatorType.influencer
                      ? (int.tryParse(_followerCtrl.text) ?? 0).abs()
                      : 0,
                  upiId: _upiCtrl.text.trim(),
                  location: _locCtrl.text.trim(),
                  notes: _notesCtrl.text.trim(),
                  rating: widget.creator?.rating ?? 5.0,
                  strikeLevel: widget.creator?.strikeLevel ?? 0,
                  busyFrom: _busyRange?.start,
                  busyTo: _busyRange?.end,
                );

                final provider = context.read<CreatorProvider>();
                if (isNew) {
                  provider.addCreator(newCreator);
                } else {
                  provider.updateCreator(newCreator);
                }
                Navigator.pop(context);
              },
              child: Text(isNew ? 'Create Profile' : 'Save Changes'),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleDeleteRequest(
    BuildContext context,
    Creator creator,
  ) async {
    final creatorProv = context.read<CreatorProvider>();
    final campaignProv = context.read<CampaignProvider>();
    final hasHistory = CrmAnalyticsEngine.getCampaignHistoryForCreator(
      creator.id,
      campaignProv.campaigns,
    ).isNotEmpty;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: hasHistory ? Colors.orange : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              hasHistory
                  ? 'Deactivate Creator Profile?'
                  : 'Permanently Delete Creator?',
            ),
          ],
        ),
        content: Text(
          hasHistory
              ? 'This creator has campaign history. They will be marked as Inactive instead of being deleted.'
              : 'Are you sure? This will permanently delete this creator.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: hasHistory ? Colors.orange : Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(hasHistory ? 'Mark Inactive' : 'Delete Forever'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      if (hasHistory) {
        await creatorProv.deactivateCreator(creator.id, actor: 'Admin');
      } else {
        await creatorProv.deleteCreator(creator.id);
      }
      if (context.mounted) Navigator.pop(context);
    }
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade400,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _formField(
    String label,
    TextEditingController ctrl, {
    bool digitsOnly = false,
    int maxLines = 1,
    String? prefix,
    String? hint,
    String? Function(String?)? val,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryDark,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          validator: val,
          maxLines: maxLines,
          textInputAction: TextInputAction.next,
          inputFormatters: digitsOnly
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          decoration: InputDecoration(
            prefixText: prefix,
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 13,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileStatKpi extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ProfileStatKpi({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppTheme.primaryDark,
          ),
        ),
      ],
    );
  }
}
