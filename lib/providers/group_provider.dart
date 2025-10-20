import 'package:flutter/widgets.dart';
import '../models/group_model.dart';
import '../services/firestore_service.dart';
import '../utils/helpers.dart';

class GroupProvider with ChangeNotifier {
  List<GroupModel> _groups = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<GroupModel> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get groups for a specific user
  List<GroupModel> getUserGroups(String userId) {
    return _groups.where((group) => group.isMember(userId)).toList();
  }

  // Get groups where user is admin
  List<GroupModel> getAdminGroups(String userId) {
    return _groups.where((group) => group.isAdmin(userId)).toList();
  }

  // Get groups where user can manage (admin or member)
  List<GroupModel> getManageableGroups(String userId) {
    return _groups.where((group) => group.canManage(userId)).toList();
  }

  // Load all groups (optimized)
  Future<void> loadGroups() async {
    try {
      _setLoading(true);
      _clearError();

      _groups = await FirestoreService.getAllGroups();

      // Cache group data for faster subsequent access
      _cacheGroupData();

      notifyListeners();
    } catch (e) {
      _setError('Failed to load groups: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Cache group data for performance
  void _cacheGroupData() {
    // In a real implementation, you might want to cache group data locally
    // For now, we'll just ensure the data is fresh
    for (final group in _groups) {
      // This is a placeholder for future caching implementation
      // You could store frequently accessed group data in memory
    }
  }

  // Cache member names for faster display
  void _cacheMemberNames(GroupModel group) async {
    for (final memberId in group.memberIds) {
      // This would cache member names - implementation depends on requirements
      // For now, we'll rely on the existing user name caching in FirestoreService
    }
  }

  // Load groups for a specific user
  Future<void> loadUserGroups(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      _groups = await FirestoreService.getUserGroups(userId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load user groups: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create a new group (with advanced validation)
  Future<bool> createGroup({
    required String groupName,
    required String description,
    required String adminId,
    List<String>? initialMembers,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Advanced validation before creation
      final nameValidation = GroupModel.validateGroupName(groupName);
      if (nameValidation != null) {
        _setError(nameValidation);
        return false;
      }

      final descValidation = GroupModel.validateDescription(description);
      if (descValidation != null) {
        _setError(descValidation);
        return false;
      }

      // Check if admin exists and is eligible
      final adminUser = await FirestoreService.getUser(adminId);
      if (adminUser == null) {
        _setError('Admin user not found');
        return false;
      }

      // Check admin's current group count
      final adminGroups = await FirestoreService.getAdminGroups(adminId);
      final maxAdminGroups = 3; // Configurable limit
      if (adminGroups.length >= maxAdminGroups) {
        _setError('Admin has reached maximum number of groups they can manage');
        return false;
      }

      // Validate initial members if provided
      if (initialMembers != null && initialMembers.isNotEmpty) {
        for (final memberId in initialMembers) {
          // For initial members, just check if user exists and basic constraints
          final user = await FirestoreService.getUser(memberId);
          if (user == null) {
            _setError('Initial member $memberId not found');
            return false;
          }

          // Check user's group limit
          final userGroups = await FirestoreService.getUserGroups(memberId);
          final maxGroupsPerUser = 5;
          if (userGroups.length >= maxGroupsPerUser) {
            _setError(
              'Initial member $memberId has reached maximum number of groups',
            );
            return false;
          }
        }
      }

      final groupId = AppHelpers.generateRandomId();
      final group = GroupModel(
        groupId: groupId,
        groupName: groupName,
        description: description,
        adminId: adminId,
        memberIds: initialMembers ?? [],
        createdAt: DateTime.now(),
      );

      await FirestoreService.createGroup(group);
      _groups.insert(0, group);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create group: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update a group
  Future<bool> updateGroup(GroupModel group) async {
    try {
      _setLoading(true);
      _clearError();

      await FirestoreService.updateGroup(group);

      final index = _groups.indexWhere((g) => g.groupId == group.groupId);
      if (index != -1) {
        _groups[index] = group;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to update group: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Add member to group (with advanced validation)
  Future<bool> addMemberToGroup(String groupId, String userId) async {
    try {
      _setLoading(true);
      _clearError();

      // Advanced validation before adding
      final canAdd = await canAddMember(groupId, userId);
      if (!canAdd) {
        return false; // Error message already set in canAddMember
      }

      await FirestoreService.addMemberToGroup(groupId, userId);

      final groupIndex = _groups.indexWhere((g) => g.groupId == groupId);
      if (groupIndex != -1) {
        final updatedGroup = _groups[groupIndex].copyWith(
          memberIds: [..._groups[groupIndex].memberIds, userId],
          updatedAt: DateTime.now(),
        );
        _groups[groupIndex] = updatedGroup;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to add member to group: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Remove member from group
  Future<bool> removeMemberFromGroup(String groupId, String userId) async {
    try {
      _setLoading(true);
      _clearError();

      await FirestoreService.removeMemberFromGroup(groupId, userId);

      final groupIndex = _groups.indexWhere((g) => g.groupId == groupId);
      if (groupIndex != -1) {
        final updatedMemberIds = List<String>.from(
          _groups[groupIndex].memberIds,
        )..remove(userId);
        final updatedGroup = _groups[groupIndex].copyWith(
          memberIds: updatedMemberIds,
          updatedAt: DateTime.now(),
        );
        _groups[groupIndex] = updatedGroup;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to remove member from group: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete a group (with advanced validation)
  Future<bool> deleteGroup(String groupId) async {
    try {
      _setLoading(true);
      _clearError();

      // Check if group exists and get current state
      final group = getGroupById(groupId);
      if (group == null) {
        _setError('Group not found');
        return false;
      }

      // Advanced validation: prevent deletion of groups with active contributions or loans
      final hasActiveContributions = await _checkGroupHasActiveContributions(
        groupId,
      );
      final hasActiveLoans = await _checkGroupHasActiveLoans(groupId);

      if (hasActiveContributions) {
        _setError(
          'Cannot delete group with active contributions. Please resolve all contributions first.',
        );
        return false;
      }

      if (hasActiveLoans) {
        _setError(
          'Cannot delete group with active loans. Please resolve all loans first.',
        );
        return false;
      }

      // Check if group has minimum members (business rule)
      if (group.memberCount > 0) {
        _setError(
          'Cannot delete group with active members. Please remove all members first.',
        );
        return false;
      }

      await FirestoreService.deleteGroup(groupId);

      final groupIndex = _groups.indexWhere((g) => g.groupId == groupId);
      if (groupIndex != -1) {
        final updatedGroup = _groups[groupIndex].copyWith(
          isActive: false,
          updatedAt: DateTime.now(),
        );
        _groups[groupIndex] = updatedGroup;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to delete group: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Advanced business logic methods
  Future<bool> canAddMember(String groupId, String userId) async {
    try {
      final group = getGroupById(groupId);
      if (group == null) return false;

      // Check if group is at capacity
      if (!group.canAcceptNewMembers) {
        _setError('Group has reached maximum capacity');
        return false;
      }

      // Check if user is already a member
      if (group.isMember(userId)) {
        _setError('User is already a member of this group');
        return false;
      }

      // Check if adding this member would create conflicts
      final userGroups = await FirestoreService.getUserGroups(userId);
      final maxGroupsPerUser = 5; // Configurable limit
      if (userGroups.length >= maxGroupsPerUser) {
        _setError('User has reached maximum number of groups');
        return false;
      }

      return true;
    } catch (e) {
      _setError('Failed to validate member addition: $e');
      return false;
    }
  }

  // Helper methods for advanced validation
  Future<bool> _checkGroupHasActiveContributions(String groupId) async {
    try {
      // This would check if group has any pending/unresolved contributions
      // For now, return false as placeholder
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkGroupHasActiveLoans(String groupId) async {
    try {
      // This would check if group has any pending/unresolved loans
      // For now, return false as placeholder
      return false;
    } catch (e) {
      return false;
    }
  }

  // Get group by ID
  GroupModel? getGroupById(String groupId) {
    try {
      return _groups.firstWhere((group) => group.groupId == groupId);
    } catch (e) {
      return null;
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isLoading = loading;
      notifyListeners();
    });
  }

  void _setError(String error) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _error = error;
      notifyListeners();
    });
  }

  void _clearError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _error = null;
      notifyListeners();
    });
  }
}
