import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/app_enums.dart';
import '../models/creator_model.dart';
import '../providers/creator_provider.dart';
import '../providers/project_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common/ui_kit.dart';
import '../widgets/creator/creator_card.dart';
import '../widgets/creator/creator_dialogs.dart';

class CreatorRosterScreen extends StatefulWidget {
  const CreatorRosterScreen({super.key});

  @override
  State<CreatorRosterScreen> createState() => _CreatorRosterScreenState();
}

class _CreatorRosterScreenState extends State<CreatorRosterScreen> {
  String _searchQuery = '';
  String _selectedTag = 'All';

  @override
  Widget build(BuildContext context) {
    final creatorProv = context.watch<CreatorProvider>();
    final allCreators = creatorProv.creators;

    final filteredCreators = allCreators.where((c) {
      final search = _searchQuery.toLowerCase().trim();

      final matchesSearch =
          search.isEmpty ||
          c.fullName.toLowerCase().contains(search) ||
          c.handle.toLowerCase().contains(search) ||
          c.primaryCategory.value.toLowerCase().contains(search) ||
          c.secondaryNiche.toLowerCase().contains(search);

      bool matchesType = _selectedTag == 'All';
      if (!matchesType) {
        if (_selectedTag == 'Influencer' && c.type == CreatorType.influencer) {
          matchesType = true;
        }
        if (_selectedTag == 'UGC' && c.type == CreatorType.ugcCreator) {
          matchesType = true;
        }
        if (_selectedTag == 'Trainee' && c.type == CreatorType.sandboxTrainee) {
          matchesType = true;
        }
      }

      return matchesSearch && matchesType;
    }).toList();

    final activeCreators = filteredCreators
        .where((c) => c.status != CreatorStatus.inactive)
        .toList();
    final inactiveCreators = filteredCreators
        .where((c) => c.status == CreatorStatus.inactive)
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DreamPageHeader(
              title: 'Creator Roster',
              subtitle:
                  '${activeCreators.length} active creators in the directory.',
              searchHint: 'Search by handle, category, or niche...',
              actionLabel: '+ Add Creator',
              onSearch: (val) => setState(() => _searchQuery = val),
              onAction: () => _showCreatorDialog(context, null),
              filterWidget: _buildClassificationFilterChips(),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: activeCreators.isEmpty
                  ? Center(
                      child: Text(
                        'No active creators found matching criteria.',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 350,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.1,
                          ),
                      itemCount: activeCreators.length,
                      itemBuilder: (context, index) {
                        return CreatorCard(
                          creator: activeCreators[index],
                          onTap: () => _showCreatorProfile(
                            context,
                            activeCreators[index],
                          ),
                        );
                      },
                    ),
            ),
            if (inactiveCreators.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: Colors.grey.shade200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(
                      'Inactive Creators (${inactiveCreators.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    iconColor: Colors.grey.shade700,
                    collapsedIconColor: Colors.grey.shade700,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 350,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.1,
                              ),
                          itemCount: inactiveCreators.length,
                          itemBuilder: (context, index) {
                            return CreatorCard(
                              creator: inactiveCreators[index],
                              onTap: () => _showCreatorProfile(
                                context,
                                inactiveCreators[index],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClassificationFilterChips() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFilterChip(
            'All',
            _selectedTag == 'All',
            () => setState(() => _selectedTag = 'All'),
          ),
          const SizedBox(width: 4),
          _buildFilterChip(
            'Influencer',
            _selectedTag == 'Influencer',
            () => setState(() => _selectedTag = 'Influencer'),
          ),
          const SizedBox(width: 4),
          _buildFilterChip(
            'UGC',
            _selectedTag == 'UGC',
            () => setState(() => _selectedTag = 'UGC'),
          ),
          const SizedBox(width: 4),
          _buildFilterChip(
            'Trainee',
            _selectedTag == 'Trainee',
            () => setState(() => _selectedTag = 'Trainee'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.transparent,
      selectedColor: Colors.white,
      showCheckmark: false,
      labelStyle: TextStyle(
        color: selected ? AppTheme.primaryPurple : Colors.grey.shade600,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide.none,
      ),
    );
  }

  void _showCreatorProfile(BuildContext context, Creator creator) {
    showDialog(
      context: context,
      builder: (_) => CreatorProfileDialog(
        creator: creator,
        projectProv: context.read<ProjectProvider>(),
        onEdit: () => _showCreatorDialog(context, creator),
      ),
    );
  }

  void _showCreatorDialog(BuildContext context, Creator? creator) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddEditCreatorDialog(creator: creator),
    );
  }
}
