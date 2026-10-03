import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/lead_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/lead/lead_dialogs.dart';
import '../widgets/lead/lead_kanban_board.dart'; // Import our new widget

class LeadsScreen extends StatelessWidget {
  const LeadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final leads = context.watch<LeadProvider>().leads;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Leads Dashboard',
          style: TextStyle(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: LeadKanbanBoard(leads: leads),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const AddEditLeadFormWindow(),
        ),
        icon: const Icon(Icons.add_chart_rounded),
        label: const Text('New Lead'),
        backgroundColor: AppTheme.primaryPurple,
      ),
    );
  }
}
