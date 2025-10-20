import 'package:flutter/foundation.dart';
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

  // Load all groups
  Future<void> loadGroups() async {
    try {
      _setLoading(true);
      _clearError();

      _groups = await FirestoreService.getAllGroups();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load groups: $e');
    } finally {
      _setLoading(false);
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

  // Create a new group
  Future<bool> createGroup({
    required String groupName,
    required String description,
    required String adminId,
    List<String>? initialMembers,
  }) async {
    try {
      _setLoading(true);
      _clearError();

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

  // Add member to group
  Future<bool> addMemberToGroup(String groupId, String userId) async {
    try {
      _setLoading(true);
      _clearError();

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
        final updatedMemberIds = List<String>.from(_groups[groupIndex].memberIds)
          ..remove(userId);
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

  // Delete a group
  Future<bool> deleteGroup(String groupId) async {
    try {
      _setLoading(true);
      _clearError();

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
