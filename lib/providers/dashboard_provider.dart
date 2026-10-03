import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../engines/dashboard_auditor.dart';
import '../models/campaign_model.dart';
import '../models/creator_model.dart';
import '../models/project_model.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardAuditor? _currentAuditor;
  bool _isLoading = true;

  List<Project>? _lastProjects;
  List<Campaign>? _lastCampaigns;
  List<Creator>? _lastCreators;

  DashboardAuditor? get auditor => _currentAuditor;

  bool get isLoading => _isLoading;

  /// Natively evaluates the state arrays of core dependencies
  void updateData({
    required List<Project> projects,
    required List<Campaign> campaigns,
    required List<Creator> creators,
  }) {
    if (_currentAuditor != null &&
        listEquals(_lastProjects, projects) &&
        listEquals(_lastCampaigns, campaigns) &&
        listEquals(_lastCreators, creators)) {
      return;
    }

    _lastProjects = projects;
    _lastCampaigns = campaigns;
    _lastCreators = creators;

    _currentAuditor = DashboardAuditor.process(projects, campaigns, creators);
    _isLoading = false;

    notifyListeners();
  }
}
