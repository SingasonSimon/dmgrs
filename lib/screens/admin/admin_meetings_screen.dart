import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../models/meeting_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meeting_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/meeting_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/modern_card.dart';

class AdminMeetingsScreen extends StatefulWidget {
  const AdminMeetingsScreen({super.key});

  @override
  State<AdminMeetingsScreen> createState() => _AdminMeetingsScreenState();
}

class _AdminMeetingsScreenState extends State<AdminMeetingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMeetings();
    });
  }

  Future<void> _loadMeetings() async {
    final meetingProvider = Provider.of<MeetingProvider>(context, listen: false);
    await meetingProvider.loadMeetings();
  }

  Future<void> _createMeeting() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CreateMeetingDialog(),
    );

    if (result != null && mounted) {
      final meetingProvider = Provider.of<MeetingProvider>(context, listen: false);
      final meetingId = await meetingProvider.createMeeting(
        title: result['title'],
        description: result['description'],
        scheduledDate: result['scheduledDate'],
        organizerId: authProvider.currentUser!.userId,
        organizerName: authProvider.currentUser!.name,
        attendeeIds: result['attendeeIds'] ?? [],
        meetingType: result['meetingType'] ?? 'general',
        googleMeetUrl: result['googleMeetUrl'] ?? '',
      );

      if (mounted) {
        if (meetingId != null) {
          AppHelpers.showSuccessSnackBar(context, 'Meeting created successfully!');
        } else {
          AppHelpers.showErrorSnackBar(
            context,
            meetingProvider.error ?? 'Failed to create meeting',
          );
        }
      }
    }
  }

  Future<void> _deleteMeeting(MeetingModel meeting) async {
    final isCompleted = meeting.status == AppConstants.meetingCompleted;
    final isPast = meeting.scheduledDate.isBefore(DateTime.now());
    final willArchive = isCompleted || (isPast && meeting.status == AppConstants.meetingScheduled);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(willArchive ? 'Archive Meeting' : 'Delete Meeting'),
        content: Text(
          willArchive
              ? 'This meeting will be archived and moved to history. It will no longer appear in active meetings but will remain in meeting history. Continue?'
              : 'Are you sure you want to permanently delete "${meeting.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: willArchive ? Colors.orange : Colors.red,
            ),
            child: Text(willArchive ? 'Archive' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final meetingProvider = Provider.of<MeetingProvider>(context, listen: false);
      final success = await meetingProvider.deleteMeeting(meeting.meetingId);
      if (mounted) {
        if (success) {
          AppHelpers.showSuccessSnackBar(
            context,
            willArchive
                ? 'Meeting archived successfully! It will appear in meeting history.'
                : 'Meeting deleted successfully!',
          );
        } else {
          AppHelpers.showErrorSnackBar(
            context,
            meetingProvider.error ?? 'Failed to ${willArchive ? 'archive' : 'delete'} meeting',
          );
        }
      }
    }
  }

  Future<void> _updateMeetingStatus(MeetingModel meeting, String status) async {
    final meetingProvider = Provider.of<MeetingProvider>(context, listen: false);
    final success = await meetingProvider.updateMeetingStatus(meeting.meetingId, status);
    if (mounted) {
      if (success) {
        AppHelpers.showSuccessSnackBar(context, 'Meeting status updated!');
      } else {
        AppHelpers.showErrorSnackBar(
          context,
          meetingProvider.error ?? 'Failed to update meeting status',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Meetings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createMeeting,
            tooltip: 'Create Meeting',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMeetings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<MeetingProvider>(
        builder: (context, meetingProvider, child) {
          if (meetingProvider.isLoading && meetingProvider.meetings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (meetingProvider.error != null && meetingProvider.meetings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    meetingProvider.error!,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadMeetings,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final upcomingMeetings = meetingProvider.upcomingMeetings;

          return RefreshIndicator(
            onRefresh: _loadMeetings,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (upcomingMeetings.isNotEmpty) ...[
                    _buildSectionHeader('Upcoming Meetings', upcomingMeetings.length),
                    const SizedBox(height: 16),
                    ...upcomingMeetings.map((meeting) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildMeetingCard(meeting),
                        )),
                    const SizedBox(height: 24),
                  ],
                  _buildSectionHeader('All Active Meetings', meetingProvider.activeMeetings.length),
                  const SizedBox(height: 16),
                  if (meetingProvider.meetings.isEmpty)
                    ModernCard(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 64,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No meetings scheduled',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ...meetingProvider.activeMeetings.map((meeting) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildMeetingCard(meeting),
                        )),
                  if (meetingProvider.archivedMeetings.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionHeader('Archived Meetings (History)', meetingProvider.archivedMeetings.length),
                    const SizedBox(height: 16),
                    ...meetingProvider.archivedMeetings.map((meeting) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildMeetingCard(meeting, isArchived: true),
                        )),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeetingCard(MeetingModel meeting, {bool isArchived = false}) {
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    meeting.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(meeting.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    meeting.statusDisplayText,
                    style: TextStyle(
                      color: _getStatusColor(meeting.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              meeting.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(meeting.scheduledDate),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${meeting.attendeeCount} attendees',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (meeting.googleMeetUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        meeting.googleMeetUrl,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _copyMeetingLink(meeting.googleMeetUrl),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy Link'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _joinMeeting(meeting.googleMeetUrl),
                    icon: const Icon(Icons.video_call, size: 16),
                    label: const Text('Join'),
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
            const SizedBox(height: 12),
            if (isArchived)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.archive, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Archived - This meeting is in history',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (meeting.organizerId ==
                      Provider.of<AuthProvider>(context, listen: false).currentUser?.userId)
                    Row(
                      children: [
                        if (meeting.status == AppConstants.meetingScheduled)
                          TextButton.icon(
                            onPressed: () => _updateMeetingStatus(
                              meeting,
                              AppConstants.meetingInProgress,
                            ),
                            icon: const Icon(Icons.play_arrow, size: 16),
                            label: const Text('Start'),
                          ),
                        if (meeting.status == AppConstants.meetingInProgress)
                          TextButton.icon(
                            onPressed: () => _updateMeetingStatus(
                              meeting,
                              AppConstants.meetingCompleted,
                            ),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Complete'),
                          ),
                        TextButton.icon(
                          onPressed: () => _deleteMeeting(meeting),
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('Delete'),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                        ),
                      ],
                    )
                  else
                    const SizedBox.shrink(),
                  TextButton.icon(
                    onPressed: () => _showMeetingDetails(meeting),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Details'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.meetingScheduled:
        return Colors.blue;
      case AppConstants.meetingInProgress:
        return Colors.green;
      case AppConstants.meetingCompleted:
        return Colors.grey;
      case AppConstants.meetingCancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _copyMeetingLink(String url) async {
    try {
      await Clipboard.setData(ClipboardData(text: url));
      AppHelpers.showSuccessSnackBar(context, 'Meeting link copied to clipboard!');
    } catch (e) {
      AppHelpers.showErrorSnackBar(context, 'Failed to copy link: $e');
    }
  }

  void _joinMeeting(String meetingUrl) async {
    try {
      await MeetingService.joinMeeting(meetingUrl);
    } catch (e) {
      AppHelpers.showErrorSnackBar(context, 'Failed to join meeting: $e');
    }
  }

  void _showMeetingDetails(MeetingModel meeting) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(meeting.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${meeting.description}'),
            const SizedBox(height: 8),
            Text('Scheduled: ${_formatDateTime(meeting.scheduledDate)}'),
            const SizedBox(height: 8),
            Text('Attendees: ${meeting.attendeeCount}'),
            const SizedBox(height: 8),
            Text('Status: ${meeting.statusDisplayText}'),
            if (meeting.googleMeetUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Meeting Link: ${meeting.googleMeetUrl}'),
            ],
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

}

class _CreateMeetingDialog extends StatefulWidget {
  @override
  State<_CreateMeetingDialog> createState() => _CreateMeetingDialogState();
}

class _CreateMeetingDialogState extends State<_CreateMeetingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _googleMeetUrlController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 0);
  final Set<String> _selectedAttendeeIds = {};
  String _meetingType = 'general';
  bool _isLoadingMembers = false;
  List<UserModel> _members = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _googleMeetUrlController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoadingMembers = true);
    try {
      _members = await FirestoreService.getActiveMembers();
    } catch (e) {
      print('Error loading members: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingMembers = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Meeting'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Meeting Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty == true ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) =>
                    value?.isEmpty == true ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_formatDate(_selectedDate)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _selectTime(context),
                      icon: const Icon(Icons.access_time),
                      label: Text(_selectedTime.format(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _googleMeetUrlController,
                decoration: const InputDecoration(
                  labelText: 'Google Meet Link (Optional)',
                  hintText: 'https://meet.google.com/xxx-yyyy-zzz',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final urlPattern = RegExp(
                      r'^https://meet\.google\.com/[a-z-]+$',
                      caseSensitive: false,
                    );
                    if (!urlPattern.hasMatch(value)) {
                      return 'Please enter a valid Google Meet URL';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _meetingType,
                decoration: const InputDecoration(
                  labelText: 'Meeting Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'general', child: Text('General')),
                  DropdownMenuItem(
                    value: 'board',
                    child: Text('Board Meeting'),
                  ),
                  DropdownMenuItem(
                    value: 'emergency',
                    child: Text('Emergency'),
                  ),
                  DropdownMenuItem(value: 'training', child: Text('Training')),
                ],
                onChanged: (value) => setState(() => _meetingType = value!),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Attendees (${_selectedAttendeeIds.length} selected)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search members...',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isLoadingMembers
                    ? const Center(child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ))
                    : _members.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No members available'),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _members.length,
                            itemBuilder: (context, index) {
                              final member = _members[index];
                              final memberId = member.userId;
                              final memberName = member.name;
                              final isSelected = _selectedAttendeeIds.contains(memberId);
                              final searchQuery = _searchController.text.toLowerCase();
                              final matchesSearch = searchQuery.isEmpty ||
                                  memberName.toLowerCase().contains(searchQuery) ||
                                  member.phone.toLowerCase().contains(searchQuery);

                              if (!matchesSearch) return const SizedBox.shrink();

                              return CheckboxListTile(
                                title: Text(memberName),
                                subtitle: Text(member.phone),
                                value: isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedAttendeeIds.add(memberId);
                                    } else {
                                      _selectedAttendeeIds.remove(memberId);
                                    }
                                  });
                                },
                                dense: true,
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _submitForm(),
          child: const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() == true) {
      final scheduledDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      Navigator.pop(context, {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'scheduledDate': scheduledDate,
        'attendeeIds': _selectedAttendeeIds.toList(),
        'meetingType': _meetingType,
        'googleMeetUrl': _googleMeetUrlController.text.trim(),
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
