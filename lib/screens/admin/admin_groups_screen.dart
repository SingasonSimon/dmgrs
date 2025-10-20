import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/group_model.dart';
import '../../widgets/modern_card.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';
import '../../services/firestore_service.dart';

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
                  ).colorScheme.primary.withValues(alpha: 0.1),
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
              final nameError = GroupModel.validateGroupName(
                nameController.text.trim(),
              );
              if (nameError != null) {
                AppHelpers.showErrorSnackBar(context, nameError);
                return;
              }

              final descError = GroupModel.validateDescription(
                descriptionController.text.trim(),
              );
              if (descError != null) {
                AppHelpers.showErrorSnackBar(context, descError);
                return;
              }

              if (!mounted) return;

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
              final nameError = GroupModel.validateGroupName(
                nameController.text.trim(),
              );
              if (nameError != null) {
                AppHelpers.showErrorSnackBar(context, nameError);
                return;
              }

              final descError = GroupModel.validateDescription(
                descriptionController.text.trim(),
              );
              if (descError != null) {
                AppHelpers.showErrorSnackBar(context, descError);
                return;
              }

              if (!mounted) return;

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
          height: 400,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${group.memberCount} members'),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () =>
                            _showAddExistingMemberDialog(context, group),
                        icon: const Icon(Icons.person_add, size: 18),
                        label: const Text('Add Existing'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _showAddNewMemberDialog(context, group),
                        icon: const Icon(Icons.person_add_alt_1, size: 18),
                        label: const Text('Add New'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: group.memberIds.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 48,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No members yet',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            Text(
                              'Add members using the buttons above',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: group.memberIds.length,
                        itemBuilder: (context, index) {
                          final memberId = group.memberIds[index];
                          return FutureBuilder<String?>(
                            future: _getUserName(memberId),
                            builder: (context, snapshot) {
                              final userName = snapshot.data ?? 'Loading...';
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.1),
                                    child: Text(
                                      userName.isNotEmpty
                                          ? userName[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    userName.isNotEmpty
                                        ? userName
                                        : 'Unknown User',
                                  ),
                                  subtitle: Text(memberId),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _removeMember(context, group, memberId),
                                  ),
                                ),
                              );
                            },
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

  Future<String?> _getUserName(String userId) async {
    try {
      return await FirestoreService.getUserName(userId);
    } catch (e) {
      return null;
    }
  }

  void _showAddExistingMemberDialog(BuildContext context, GroupModel group) {
    final TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Existing Member'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search by name or phone',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) async {
                    if (value.length >= 2) {
                      setState(() => isSearching = true);
                      try {
                        searchResults = await FirestoreService.searchUsers(
                          value,
                        );
                      } catch (e) {
                        searchResults = [];
                      }
                      setState(() => isSearching = false);
                    } else {
                      setState(() => searchResults = []);
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (isSearching)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (searchResults.isEmpty &&
                    searchController.text.length >= 2)
                  const Expanded(child: Center(child: Text('No users found')))
                else if (searchController.text.length < 2)
                  const Expanded(
                    child: Center(
                      child: Text('Type at least 2 characters to search'),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final user = searchResults[index];
                        final isAlreadyMember = group.memberIds.contains(
                          user['userId'],
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.1),
                              child: Text(
                                (user['name'] ?? '?')[0].toUpperCase(),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(user['name'] ?? 'Unknown'),
                            subtitle: Text(user['phone'] ?? ''),
                            trailing: isAlreadyMember
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Already Member',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(
                                      Icons.add_circle,
                                      color: Colors.green,
                                    ),
                                    onPressed: () => _addMember(
                                      context,
                                      group,
                                      user['userId'],
                                    ),
                                  ),
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
      ),
    );
  }

  void _showAddNewMemberDialog(BuildContext context, GroupModel group) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Member'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  if (value.trim().length > 50) {
                    return 'Name must be less than 50 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  if (value.trim().length < 10) {
                    return 'Phone number must be at least 10 digits';
                  }
                  if (value.trim().length > 15) {
                    return 'Phone number must be less than 15 digits';
                  }
                  // Basic phone number validation (digits, spaces, hyphens, parentheses)
                  final phoneRegex = RegExp(r'^[\d\s\-\(\)\+]+$');
                  if (!phoneRegex.hasMatch(value.trim())) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await _createAndAddMember(
                  context,
                  group,
                  nameController.text.trim(),
                  phoneController.text.trim(),
                  emailController.text.trim().isEmpty
                      ? null
                      : emailController.text.trim(),
                );
              }
            },
            child: const Text('Create & Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _createAndAddMember(
    BuildContext context,
    GroupModel group,
    String name,
    String phone,
    String? email,
  ) async {
    if (!mounted) return;

    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);

      // Create new user
      final userId = AppHelpers.generateRandomId();
      final newUser = {
        'userId': userId,
        'name': name,
        'phone': phone,
        'email': email,
        'role': 'member',
        'createdAt': DateTime.now(),
        'groupIds': [group.groupId],
      };

      await FirestoreService.createUserFromData(newUser);

      // Add to group
      final success = await groupProvider.addMemberToGroup(
        group.groupId,
        userId,
      );

      if (mounted) {
        Navigator.pop(context); // Close add member dialog
        Navigator.pop(context); // Close manage members dialog

        if (success) {
          AppHelpers.showSuccessSnackBar(
            context,
            'New member created and added successfully',
          );
        } else {
          AppHelpers.showErrorSnackBar(
            context,
            groupProvider.error ?? 'Failed to add member to group',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showErrorSnackBar(context, 'Failed to create member: $e');
      }
    }
  }

  void _showDeleteGroupDialog(BuildContext context, GroupModel group) {
    AppHelpers.showConfirmationDialog(
      context,
      title: 'Delete Group',
      message:
          'Are you sure you want to delete "${group.groupName}"? This action cannot be undone.',
    ).then((confirmed) async {
      if (confirmed == true && mounted) {
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

  void _addMember(
    BuildContext context,
    GroupModel group,
    String memberId,
  ) async {
    if (!mounted) return;

    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    // Close the search dialog first
    Navigator.pop(context);

    final success = await groupProvider.addMemberToGroup(
      group.groupId,
      memberId,
    );

    if (mounted) {
      if (success) {
        AppHelpers.showSuccessSnackBar(context, 'Member added successfully');
      } else {
        AppHelpers.showErrorSnackBar(
          context,
          groupProvider.error ?? 'Failed to add member',
        );
      }
    }
  }

  void _removeMember(BuildContext context, GroupModel group, String memberId) {
    AppHelpers.showConfirmationDialog(
      context,
      title: 'Remove Member',
      message: 'Are you sure you want to remove this member from the group?',
    ).then((confirmed) async {
      if (confirmed == true && mounted) {
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
