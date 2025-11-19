import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../models/meeting_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/meeting_service.dart';
import '../../utils/constants.dart';
import '../../widgets/modern_card.dart';

class AdminMeetingsScreen extends StatefulWidget {
  const AdminMeetingsScreen({super.key});

  @override
  State<AdminMeetingsScreen> createState() => _AdminMeetingsScreenState();
}

class _AdminMeetingsScreenState extends State<AdminMeetingsScreen> {
  bool _isLoading = false;
  List<MeetingModel> _meetings = [];

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    try {
      final meetings = await MeetingService.getAllMeetings();
      if (mounted) {
        setState(() => _meetings = meetings);
      }
    } catch (e) {
      print('Error loading meetings: $e');
      if (mounted) {
        setState(() => _meetings = []);
        _showError('Failed to load meetings: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createMeeting() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CreateMeetingDialog(),
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        await MeetingService.createMeeting(
          title: result['title'],
          description: result['description'],
          scheduledDate: result['scheduledDate'],
          organizerId: authProvider.currentUser!.userId,
          organizerName: authProvider.currentUser!.name,
          attendeeIds: result['attendeeIds'] ?? [],
          meetingType: result['meetingType'] ?? 'general',
          googleMeetUrl: result['googleMeetUrl'] ?? '',
        );

        _loadMeetings();
        _showSuccess('Meeting created successfully!');
      } catch (e) {
        _showError('Failed to create meeting: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Meetings'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _createMeeting),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMeetings),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUpcomingMeetings(),
                  const SizedBox(height: 24),
                  _buildAllMeetings(),
                ],
              ),
            ),
    );
  }

  Widget _buildUpcomingMeetings() {
    final upcomingMeetings = _meetings
        .where((meeting) => meeting.isUpcoming)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Meetings',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (upcomingMeetings.isEmpty)
          ModernCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No upcoming meetings scheduled',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ...upcomingMeetings.map((meeting) => _buildMeetingCard(meeting)),
      ],
    );
  }

  Widget _buildAllMeetings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Meetings',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ..._meetings.map((meeting) => _buildMeetingCard(meeting)),
      ],
    );
  }

  Widget _buildMeetingCard(MeetingModel meeting) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
      _showSuccess('Meeting link copied to clipboard!');
    } catch (e) {
      _showError('Failed to copy link: $e');
    }
  }

  void _joinMeeting(String meetingUrl) async {
    try {
      await MeetingService.joinMeeting(meetingUrl);
    } catch (e) {
      _showError('Failed to join meeting: $e');
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
  final List<String> _attendeeIds = [];
  String _meetingType = 'general';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _googleMeetUrlController.dispose();
    super.dispose();
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
                initialValue: _meetingType,
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
        'attendeeIds': _attendeeIds,
        'meetingType': _meetingType,
        'googleMeetUrl': _googleMeetUrlController.text.trim(),
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
