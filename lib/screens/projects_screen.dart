import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/app_enums.dart';
import '../providers/client_provider.dart';
import '../providers/project_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common/ui_kit.dart';
import '../widgets/project/project_dialogs.dart';
import '../widgets/project/project_widgets.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  String _query = '';
  bool _showArchive = false;

  @override
  Widget build(BuildContext context) {
    // ─── 1. CORE ROSTER RESOLUTIONS ───
    final projects = context.watch<ProjectProvider>().projects;
    final clients = context.watch<ClientProvider>().clients;

    // Optimized flat look-up index map skips dirty O(N^2) processing nested inside lists
    final clientMap = {for (var c in clients) c.id: c};

    // ─── 2. SEARCH & ARTIFACT FILTERING ───
    final filtered = projects.where((p) {
      final isArchivedStatus =
          p.status == ProjectStatus.completed ||
          p.status == ProjectStatus.dropped ||
          p.status == ProjectStatus.archived;

      if (_showArchive != isArchivedStatus) return false;

      final clientName =
          clientMap[p.clientId]?.businessName ?? 'Unknown Client';
      final search = _query.toLowerCase().trim();

      if (search.isEmpty) return true;

      return p.projectName.toLowerCase().contains(search) ||
          clientName.toLowerCase().contains(search) ||
          p.dealType.value.toLowerCase().contains(search) ||
          p.status.value.toLowerCase().contains(search);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(filtered.length),
            const SizedBox(height: 20),
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : ProjectTable(projects: filtered, clients: clients),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int count) {
    return DreamPageHeader(
      title: 'Projects Board',
      subtitle: '$count ${_showArchive ? 'archived' : 'active'} projects.',
      searchHint: 'Search projects...',
      actionLabel: '+ Add Project',
      onSearch: (v) => setState(() => _query = v),
      onAction: () => _openAddDialog(context),
      filterWidget: _buildArchiveToggle(),
    );
  }

  Widget _buildArchiveToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleChip(
            label: 'Active',
            selected: !_showArchive,
            onTap: () => setState(() => _showArchive = false),
          ),
          const SizedBox(width: 4),
          _ToggleChip(
            label: 'Archived',
            selected: _showArchive,
            onTap: () => setState(() => _showArchive = true),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _showArchive
                ? Icons.inventory_2_outlined
                : Icons.folder_open_rounded,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            _query.isEmpty
                ? (_showArchive
                      ? 'No archived projects found.'
                      : 'No active projects found.')
                : 'No projects found matching "$_query".',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddDialog(BuildContext ctx) => showDialog(
    context: ctx,
    barrierDismissible: false,
    builder: (_) =>
        const ProjectCreationWizard(sourceLead: null, sourceProposal: null),
  );
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
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
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide.none,
      ),
    );
  }
}
