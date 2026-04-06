import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../providers/app_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/empty_state.dart';

/// Groups page — grid of group cards with create group dialog using email search
class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<GroupModel>>(
        stream: provider.firestoreService.getMyGroupsStream(provider.currentUid),
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

          // Cache member UIDs for display
          for (final group in groups) {
            provider.cacheUsers(group.members);
          }

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
                          provider: provider,
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
  final AppProvider provider;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GroupCard({
    required this.group,
    required this.index,
    required this.provider,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = AppConstants.getAvatarGradient(index);
    // Resolve member UIDs to display names
    final memberNames = group.members
        .map((uid) => provider.resolveUserName(uid))
        .toList();

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
          AvatarStack(names: memberNames, size: 30),
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
// Create Group Dialog — with email search
// ─────────────────────────────────────────────
class _CreateGroupDialog extends StatefulWidget {
  final AppProvider provider;
  const _CreateGroupDialog({required this.provider});

  @override
  State<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<_CreateGroupDialog> {
  final _nameController = TextEditingController();
  final _emailSearchController = TextEditingController();
  final List<UserModel> _addedMembers = [];
  String _selectedIcon = '👥';
  bool _isCreating = false;
  bool _isSearching = false;
  String? _searchError;
  UserModel? _searchResult;

  static const _icons = ['👥', '🏠', '✈️', '🍕', '🎉', '💼', '🎮', '📚'];

  @override
  void initState() {
    super.initState();
    // Auto-add the current user
    _addedMembers.add(UserModel(
      uid: widget.provider.currentUid,
      displayName: widget.provider.currentUser,
      email: widget.provider.authService.email,
    ));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailSearchController.dispose();
    super.dispose();
  }

  Future<void> _searchUser() async {
    final email = _emailSearchController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchError = null;
      _searchResult = null;
    });

    final user =
        await widget.provider.firestoreService.searchUserByEmail(email);

    if (user == null) {
      setState(() {
        _isSearching = false;
        _searchError = 'No account found with this email';
      });
    } else if (_addedMembers.any((m) => m.uid == user.uid)) {
      setState(() {
        _isSearching = false;
        _searchError = '${user.displayName} is already added';
      });
    } else {
      setState(() {
        _isSearching = false;
        _searchResult = user;
      });
    }
  }

  void _addSearchedUser() {
    if (_searchResult != null) {
      setState(() {
        _addedMembers.add(_searchResult!);
        _searchResult = null;
        _emailSearchController.clear();
      });
    }
  }

  Future<void> _createGroup() async {
    if (_nameController.text.trim().isEmpty || _addedMembers.length < 2) return;

    setState(() => _isCreating = true);
    await widget.provider.firestoreService.createGroup(
      name: _nameController.text.trim(),
      memberUids: _addedMembers.map((m) => m.uid).toList(),
      icon: _selectedIcon,
    );
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

                // ── Add member by email ──
                Text('Add Members by Email',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _emailSearchController,
                        keyboardType: TextInputType.emailAddress,
                        onSubmitted: (_) => _searchUser(),
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          hintText: 'friend@example.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _isSearching ? null : _searchUser,
                      icon: _isSearching
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search_rounded, size: 18),
                      label: const Text('Search'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Search error
                if (_searchError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            color: AppTheme.error, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _searchError!,
                          style: TextStyle(
                            color: AppTheme.error,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Search result
                if (_searchResult != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        AvatarWidget(
                            name: _searchResult!.displayName, size: 32),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_searchResult!.displayName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              Text(_searchResult!.email,
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _addSearchedUser,
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Add'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // Members list
                Text('Members (${_addedMembers.length})',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _addedMembers.map((user) {
                    final isCurrentUser =
                        user.uid == widget.provider.currentUid;
                    return Chip(
                      avatar: AvatarWidget(name: user.displayName, size: 24),
                      label: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCurrentUser
                                ? '${user.displayName} (You)'
                                : user.displayName,
                            style: const TextStyle(fontSize: 13),
                          ),
                          Text(user.email,
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.5),
                              )),
                        ],
                      ),
                      deleteIcon: isCurrentUser
                          ? null
                          : const Icon(Icons.close, size: 16),
                      onDeleted: isCurrentUser
                          ? null
                          : () {
                              setState(() {
                                _addedMembers
                                    .removeWhere((m) => m.uid == user.uid);
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
