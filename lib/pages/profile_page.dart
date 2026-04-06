import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../providers/app_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/avatar_widget.dart';

/// User profile page with account info, edit name, and logout
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditingName = false;
  late TextEditingController _nameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
              child: Text('Profile',
                  style: Theme.of(context).textTheme.displayLarge),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    children: [
                      // ── Avatar & User Info Card ──
                      GlassCard(
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            AvatarWidget(
                              name: provider.currentUser,
                              size: 80,
                            ),
                            const SizedBox(height: 16),
                            if (_isEditingName)
                              _buildNameEditor(provider)
                            else
                              _buildNameDisplay(provider),
                            const SizedBox(height: 6),
                            Text(
                              provider.authService.email,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Settings Card ──
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Settings',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 16),

                            // Theme toggle
                            _SettingsTile(
                              icon: isDark
                                  ? Icons.light_mode_rounded
                                  : Icons.dark_mode_rounded,
                              title: isDark ? 'Light Mode' : 'Dark Mode',
                              subtitle: 'Switch app theme',
                              trailing: Switch.adaptive(
                                value: isDark,
                                onChanged: (_) => provider.toggleTheme(),
                                activeColor: AppTheme.primaryPurple,
                              ),
                            ),
                            const Divider(height: 1),

                            // Edit name
                            _SettingsTile(
                              icon: Icons.edit_rounded,
                              title: 'Edit Display Name',
                              subtitle: provider.currentUser,
                              onTap: () {
                                _nameController.text = provider.currentUser;
                                setState(() => _isEditingName = true);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── About Card ──
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'About',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 16),
                            _SettingsTile(
                              icon: Icons.info_outline_rounded,
                              title: 'ClearLedger',
                              subtitle: 'Version 1.0.0',
                            ),
                            const Divider(height: 1),
                            _SettingsTile(
                              icon: Icons.code_rounded,
                              title: 'Built with Flutter',
                              subtitle: 'Powered by Firebase',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Logout Button ──
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => _confirmLogout(context, provider),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color:
                                      AppTheme.error.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.logout_rounded,
                                        color: AppTheme.error, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Sign Out',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameDisplay(AppProvider provider) {
    return GestureDetector(
      onTap: () {
        _nameController.text = provider.currentUser;
        setState(() => _isEditingName = true);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            provider.currentUser,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.edit_rounded,
            size: 16,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildNameEditor(AppProvider provider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 200,
          child: TextField(
            controller: _nameController,
            autofocus: true,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (_isSaving)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else ...[
          IconButton(
            icon: const Icon(Icons.check_rounded, color: AppTheme.success),
            onPressed: () async {
              final newName = _nameController.text.trim();
              if (newName.isNotEmpty) {
                setState(() => _isSaving = true);
                await provider.updateDisplayName(newName);
                if (mounted) {
                  setState(() {
                    _isSaving = false;
                    _isEditingName = false;
                  });
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppTheme.error),
            onPressed: () => setState(() => _isEditingName = false),
          ),
        ],
      ],
    );
  }

  void _confirmLogout(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.signOut();
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Settings Tile
// ─────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primaryPurple, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
