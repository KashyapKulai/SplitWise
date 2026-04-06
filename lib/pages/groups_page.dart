import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../models/group_model.dart';
import '../providers/app_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/empty_state.dart';

/// Groups page — grid of group cards with hover effects and create group dialog
class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<GroupModel>>(
        stream: provider.firestoreService.getGroupsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final groups = snapshot.data ?? [];
          final filtered = provider.searchQuery.isEmpty
              ? groups
              : groups
                  .where((g) => g.name
                      .toLowerCase()
                      .contains(provider.searchQuery.toLowerCase()))
                  .toList();

          return CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Groups',
                                style:
                                    Theme.of(context).textTheme.displayLarge),
                            const SizedBox(height: 4),
                            Text('${groups.length} groups',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      _buildSearchField(context, provider),
                    ],
                  ),
                ),
              ),

              // Groups Grid
              if (filtered.isEmpty)
                SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.group_add_rounded,
                    title: 'No groups yet',
                    subtitle: 'Create a group to get started',
                    action: _CreateGroupButton(provider: provider),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 100),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 380,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.6,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _GroupCard(
                          group: filtered[index],
                          index: index,
                          onTap: () =>
                              provider.setActiveGroupId(filtered[index].id),
                          onDelete: () => _confirmDelete(
                              context, provider, filtered[index]),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: _AnimatedFAB(
        onPressed: () => _showCreateGroupDialog(context, provider),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context, AppProvider provider) {
    return SizedBox(
      width: 220,
      child: TextField(
        onChanged: provider.setSearchQuery,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search groups…',
          prefixIcon: const Icon(Icons.search, size: 18),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, AppProvider provider, GroupModel group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text('Delete "${group.name}" and all its expenses?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              provider.firestoreService.deleteGroup(group.id);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context, AppProvider provider) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Create Group',
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, anim, secondAnim, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (context, anim, secondAnim) {
        return _CreateGroupDialog(provider: provider);
      },
    );
  }
}

// ─────────────────────────────────────────────
// Group Card
// ─────────────────────────────────────────────
class _GroupCard extends StatelessWidget {
  final GroupModel group;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GroupCard({
    required this.group,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = AppConstants.getAvatarGradient(index);

    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    group.icon,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  group.name,
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.3),
                ),
                onPressed: onDelete,
              ),
            ],
          ),
          const Spacer(),
          AvatarStack(names: group.members, size: 30),
          const SizedBox(height: 8),
          Text(
            '${group.members.length} members',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Create Group Dialog
// ─────────────────────────────────────────────
class _CreateGroupDialog extends StatefulWidget {
  final AppProvider provider;
  const _CreateGroupDialog({required this.provider});

  @override
  State<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<_CreateGroupDialog> {
  final _nameController = TextEditingController();
  final _memberNameController = TextEditingController();
  final _memberEmailController = TextEditingController();
  final List<String> _members = [];
  final Map<String, String> _memberEmails = {}; // name -> email
  String _selectedIcon = '👥';
  bool _isCreating = false;

  static const _icons = ['👥', '🏠', '✈️', '🍕', '🎉', '💼', '🎮', '📚'];

  @override
  void initState() {
    super.initState();
    _members.add(widget.provider.currentUser);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _memberNameController.dispose();
    _memberEmailController.dispose();
    super.dispose();
  }

  void _addMember() {
    final name = _memberNameController.text.trim();
    final email = _memberEmailController.text.trim();
    if (name.isNotEmpty && !_members.contains(name)) {
      setState(() {
        _members.add(name);
        if (email.isNotEmpty) {
          _memberEmails[name] = email;
        }
        _memberNameController.clear();
        _memberEmailController.clear();
      });
    }
  }

  Future<void> _createGroup() async {
    if (_nameController.text.trim().isEmpty || _members.length < 2) return;

    setState(() => _isCreating = true);
    final groupId = await widget.provider.firestoreService.createGroup(
      name: _nameController.text.trim(),
      members: _members,
      icon: _selectedIcon,
    );
    // Store member emails if any
    for (final entry in _memberEmails.entries) {
      await widget.provider.firestoreService
          .inviteMemberByEmail(groupId, entry.key, entry.value);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 480,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Theme.of(context).dialogTheme.backgroundColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.glowShadow,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create Group',
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 24),

                // Icon picker
                Wrap(
                  spacing: 8,
                  children: _icons.map((icon) {
                    final selected = _selectedIcon == icon;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = icon),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.primaryPurple.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppTheme.primaryPurple
                                : Colors.transparent,
                          ),
                        ),
                        child: Center(
                          child:
                              Text(icon, style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Group name
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    hintText: 'e.g. Goa Trip',
                    prefixIcon: Icon(Icons.group_rounded),
                  ),
                ),
                const SizedBox(height: 20),

                // Add member section
                Text('Add Members',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                TextField(
                  controller: _memberNameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    hintText: 'e.g. John Doe',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _memberEmailController,
                        keyboardType: TextInputType.emailAddress,
                        onSubmitted: (_) => _addMember(),
                        decoration: const InputDecoration(
                          labelText: 'Email (optional)',
                          hintText: 'john@example.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _addMember,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Members list
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _members.map((name) {
                    final email = _memberEmails[name];
                    return Chip(
                      avatar: AvatarWidget(name: name, size: 24),
                      label: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontSize: 13)),
                          if (email != null)
                            Text(email,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5),
                                )),
                        ],
                      ),
                      deleteIcon: name == widget.provider.currentUser
                          ? null
                          : const Icon(Icons.close, size: 16),
                      onDeleted: name == widget.provider.currentUser
                          ? null
                          : () {
                              setState(() {
                                _members.remove(name);
                                _memberEmails.remove(name);
                              });
                            },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _isCreating ? null : _createGroup,
                      icon: _isCreating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Animated FAB
// ─────────────────────────────────────────────
class _AnimatedFAB extends StatefulWidget {
  final VoidCallback onPressed;
  const _AnimatedFAB({required this.onPressed});

  @override
  State<_AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<_AnimatedFAB>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: _isHovered ? 20 : 16,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(_isHovered ? 20 : 16),
            boxShadow: _isHovered ? AppTheme.glowShadow : AppTheme.softShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 22),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _isHovered
                    ? const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text(
                          'New Group',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateGroupButton extends StatelessWidget {
  final AppProvider provider;
  const _CreateGroupButton({required this.provider});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () {
        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel: 'Create Group',
          transitionDuration: const Duration(milliseconds: 400),
          transitionBuilder: (context, anim, secondAnim, child) {
            return ScaleTransition(
              scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
              child: FadeTransition(opacity: anim, child: child),
            );
          },
          pageBuilder: (context, anim, secondAnim) {
            return _CreateGroupDialog(provider: provider);
          },
        );
      },
      icon: const Icon(Icons.add_rounded),
      label: const Text('Create Group'),
    );
  }
}
