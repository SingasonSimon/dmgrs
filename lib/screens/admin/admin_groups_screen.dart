import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/group_model.dart';
import '../../widgets/modern_card.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';

class AdminGroupsScreen extends StatefulWidget {
  const AdminGroupsScreen({super.key});

  @override
  State<AdminGroupsScreen> createState() => _AdminGroupsScreenState();
}

class _AdminGroupsScreenState extends State<AdminGroupsScreen> {
  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  void _loadGroups() {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    groupProvider.loadGroups();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateGroupDialog(context),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadGroups),
        ],
      ),
      body: Consumer<GroupProvider>(
        builder: (context, groupProvider, child) {
          if (groupProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (groupProvider.groups.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async => _loadGroups(),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              itemCount: groupProvider.groups.length,
              itemBuilder: (context, index) {
                final group = groupProvider.groups[index];
                return _buildGroupCard(context, group);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: ModernCard(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.groups,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No Groups Yet',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Create your first group to start managing members and activities.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showCreateGroupDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Create Group'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, GroupModel group) {
    return ModernCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.1),
                  child: Icon(
                    Icons.groups,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.groupName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${group.memberCount} members',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) =>
                      _handleGroupAction(context, group, value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: ListTile(
                        leading: Icon(Icons.visibility),
                        title: Text('View Details'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit Group'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'members',
                      child: ListTile(
                        leading: Icon(Icons.people),
                        title: Text('Manage Members'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text(
                          'Delete Group',
                          style: TextStyle(color: Colors.red),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (group.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                group.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleGroupAction(context, group, 'view'),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _handleGroupAction(context, group, 'members'),
                    icon: const Icon(Icons.people, size: 18),
                    label: const Text('Members'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleGroupAction(
    BuildContext context,
    GroupModel group,
    String action,
  ) {
    switch (action) {
      case 'view':
        _showGroupDetails(context, group);
        break;
      case 'edit':
        _showEditGroupDialog(context, group);
        break;
      case 'members':
        _showManageMembersDialog(context, group);
        break;
      case 'delete':
        _showDeleteGroupDialog(context, group);
        break;
    }
  }

  void _showCreateGroupDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                AppHelpers.showErrorSnackBar(context, 'Group name is required');
                return;
              }

              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              final groupProvider = Provider.of<GroupProvider>(
                context,
                listen: false,
              );

              final success = await groupProvider.createGroup(
                groupName: nameController.text.trim(),
                description: descriptionController.text.trim(),
                adminId: authProvider.userId,
              );

              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  AppHelpers.showSuccessSnackBar(
                    context,
                    'Group created successfully',
                  );
                } else {
                  AppHelpers.showErrorSnackBar(
                    context,
                    groupProvider.error ?? 'Failed to create group',
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showGroupDetails(BuildContext context, GroupModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(group.groupName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Description', group.description),
            _buildDetailRow('Members', '${group.memberCount}'),
            _buildDetailRow('Created', AppHelpers.formatDate(group.createdAt)),
            if (group.updatedAt != null)
              _buildDetailRow(
                'Updated',
                AppHelpers.formatDate(group.updatedAt!),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditGroupDialog(BuildContext context, GroupModel group) {
    final nameController = TextEditingController(text: group.groupName);
    final descriptionController = TextEditingController(
      text: group.description,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                AppHelpers.showErrorSnackBar(context, 'Group name is required');
                return;
              }

              final groupProvider = Provider.of<GroupProvider>(
                context,
                listen: false,
              );
              final updatedGroup = group.copyWith(
                groupName: nameController.text.trim(),
                description: descriptionController.text.trim(),
              );

              final success = await groupProvider.updateGroup(updatedGroup);

              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  AppHelpers.showSuccessSnackBar(
                    context,
                    'Group updated successfully',
                  );
                } else {
                  AppHelpers.showErrorSnackBar(
                    context,
                    groupProvider.error ?? 'Failed to update group',
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showManageMembersDialog(BuildContext context, GroupModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${group.groupName} - Members'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              Text('${group.memberCount} members'),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: group.memberIds.length,
                  itemBuilder: (context, index) {
                    final memberId = group.memberIds[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text('Member $memberId'),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                        ),
                        onPressed: () =>
                            _removeMember(context, group, memberId),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteGroupDialog(BuildContext context, GroupModel group) {
    AppHelpers.showConfirmationDialog(
      context,
      title: 'Delete Group',
      message:
          'Are you sure you want to delete "${group.groupName}"? This action cannot be undone.',
    ).then((confirmed) async {
      if (confirmed == true) {
        final groupProvider = Provider.of<GroupProvider>(
          context,
          listen: false,
        );
        final success = await groupProvider.deleteGroup(group.groupId);

        if (mounted) {
          if (success) {
            AppHelpers.showSuccessSnackBar(
              context,
              'Group deleted successfully',
            );
          } else {
            AppHelpers.showErrorSnackBar(
              context,
              groupProvider.error ?? 'Failed to delete group',
            );
          }
        }
      }
    });
  }

  void _removeMember(BuildContext context, GroupModel group, String memberId) {
    AppHelpers.showConfirmationDialog(
      context,
      title: 'Remove Member',
      message: 'Are you sure you want to remove this member from the group?',
    ).then((confirmed) async {
      if (confirmed == true) {
        final groupProvider = Provider.of<GroupProvider>(
          context,
          listen: false,
        );
        final success = await groupProvider.removeMemberFromGroup(
          group.groupId,
          memberId,
        );

        if (mounted) {
          if (success) {
            AppHelpers.showSuccessSnackBar(
              context,
              'Member removed successfully',
            );
          } else {
            AppHelpers.showErrorSnackBar(
              context,
              groupProvider.error ?? 'Failed to remove member',
            );
          }
        }
      }
    });
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
