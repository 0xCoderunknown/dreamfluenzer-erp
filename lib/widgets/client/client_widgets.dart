import 'package:flutter/material.dart';

import '../../domain/app_enums.dart';
import '../../models/client_model.dart';
import '../../theme/app_theme.dart';
import 'client_dialogs.dart';

// ===========================================================================
// CLIENTS TABLE
// ===========================================================================
class ClientTable extends StatelessWidget {
  final List<Client> clients;

  const ClientTable({super.key, required this.clients});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const ClientTableHeader(),
          Expanded(
            child: ListView.separated(
              itemCount: clients.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (_, i) => ClientRow(client: clients[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class ClientTableHeader extends StatelessWidget {
  const ClientTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    const s = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: Color(0xFF9CA3AF),
      letterSpacing: 0.8,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FF),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: const Row(
        children: [
          SizedBox(width: 44), // Matches the Avatar placement dimension
          SizedBox(width: 12),
          Expanded(flex: 4, child: Text('BUSINESS NAME', style: s)),
          Expanded(flex: 2, child: Text('INDUSTRY', style: s)),
          Expanded(flex: 2, child: Text('TIER', style: s)),
          Expanded(flex: 3, child: Text('LOCATION', style: s)),
          Expanded(flex: 2, child: Text('CONTACT PERSON', style: s)),
          SizedBox(width: 80),
        ],
      ),
    );
  }
}

class ClientRow extends StatelessWidget {
  final Client client;

  const ClientRow({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    final c = client;
    return InkWell(
      onTap: () => _openProfileDialog(context, c),
      hoverColor: AppTheme.primaryPurple.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            ClientAvatar(name: c.businessName, size: 44),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Text(
                c.businessName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.primaryDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                c.industryType.isEmpty ? '—' : c.industryType,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: ClientTierChip(tier: c.tier),
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      c.location.isEmpty ? '—' : c.location,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                c.contactName.isNotEmpty ? c.contactName : '—',
                style: TextStyle(
                  fontSize: 13,
                  color: c.contactName.isNotEmpty
                      ? Colors.grey.shade700
                      : Colors.grey.shade400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit_rounded,
                      color: Colors.grey.shade500,
                      size: 18,
                    ),
                    tooltip: 'Edit Details',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => AddClientDialog(clientToEdit: c),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openProfileDialog(BuildContext context, Client c) {
    showDialog(
      context: context,
      builder: (_) => ClientProfileDialog(
        client: c,
        onEdit: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AddClientDialog(clientToEdit: c),
          );
        },
      ),
    );
  }
}

// ===========================================================================
// CORE UI CHIPS & DECORATIONS
// ===========================================================================
class ClientTierChip extends StatelessWidget {
  final ClientTier tier;

  const ClientTierChip({super.key, required this.tier});

  @override
  Widget build(BuildContext context) {
    Color baseColor;
    switch (tier) {
      case ClientTier.tier1:
        baseColor = const Color(0xFF10B981); // Emerald Green
        break;
      case ClientTier.tier2:
        baseColor = const Color(0xFF3B82F6); // Royal Blue
        break;
      case ClientTier.tier3:
        baseColor = const Color(0xFF6B7280); // Charcoal Grey
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: baseColor.withValues(alpha: 0.25), width: 1),
      ),
      child: Text(
        tier.value.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: baseColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class ClientKpiStat extends StatelessWidget {
  final String label, value;
  final Color? valueColor;

  const ClientKpiStat({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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

class ClientQuickFact extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool isItalic;

  const ClientQuickFact({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.isItalic = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.primaryDark,
                fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ClientAvatar extends StatelessWidget {
  final String name;
  final double size;

  const ClientAvatar({super.key, required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppTheme.primaryPurple,
      AppTheme.success,
      AppTheme.info,
      AppTheme.warning,
    ];
    final color = colors[name.length % colors.length];
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.7), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
