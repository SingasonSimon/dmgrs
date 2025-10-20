import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../../models/meeting_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/meeting_service.dart';
import '../../utils/constants.dart';

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  bool _isLoading = false;
  List<MeetingModel> _meetings = [];
  MeetingModel? _nextMeeting;

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        final userMeetings = await MeetingService.getUserMeetings(
          authProvider.currentUser!.userId,
        );
        final upcomingMeetings = await MeetingService.getUpcomingMeetings();

        setState(() {
          _meetings = userMeetings;
          _nextMeeting = upcomingMeetings.isNotEmpty
              ? upcomingMeetings.first
              : null;
        });
      }
    } catch (e) {
      _showError('Failed to load meetings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meetings'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMeetings),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upcoming Meeting
                  _buildUpcomingMeeting(context),

                  const SizedBox(height: 24),

                  // Meeting History
                  _buildMeetingHistory(context),

                  const SizedBox(height: 24),

                  // Meeting Guidelines
                  _buildMeetingGuidelines(context),
                ],
              ),
            ),
    );
  }

  Widget _buildUpcomingMeeting(BuildContext context) {
    if (_nextMeeting == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.video_call,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Next Meeting',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'No upcoming meetings scheduled',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.video_call,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Next Meeting',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _nextMeeting!.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDateTime(_nextMeeting!.scheduledDate),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  if (_nextMeeting!.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _nextMeeting!.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_nextMeeting!.googleMeetUrl.isNotEmpty)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _joinMeeting(context, _nextMeeting!.googleMeetUrl),
                            icon: const Icon(Icons.video_call),
                            label: const Text('Join Meeting'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _copyMeetingLink(_nextMeeting!.googleMeetUrl),
                          icon: const Icon(Icons.copy),
                          tooltip: 'Copy meeting link',
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Meeting link will be available soon',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.orange),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingHistory(BuildContext context) {
    // Filter past meetings (not upcoming and completed)
    final pastMeetings = _meetings
        .where(
          (meeting) =>
              !meeting.isUpcoming &&
              meeting.status == AppConstants.meetingCompleted,
        )
        .toList()
        .reversed
        .take(10)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meeting History',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (pastMeetings.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No meeting history available',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: pastMeetings.map((meeting) {
                  return Column(
                    children: [
                      _buildMeetingItem(context, meeting),
                      if (meeting != pastMeetings.last) const Divider(),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMeetingItem(BuildContext context, MeetingModel meeting) {
    final isAttended = meeting.status == AppConstants.meetingCompleted;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isAttended ? Colors.green : Colors.grey,
        child: Icon(
          isAttended ? Icons.check : Icons.close,
          color: Colors.white,
        ),
      ),
      title: Text(meeting.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_formatDateTime(meeting.scheduledDate)),
          if (meeting.duration != null)
            Text(
              'Duration: ${meeting.formattedDuration}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      trailing: Chip(
        label: Text(
          meeting.statusDisplayText,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        backgroundColor: _getStatusColor(meeting.status),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.meetingCompleted:
        return Colors.green;
      case AppConstants.meetingScheduled:
        return Colors.blue;
      case AppConstants.meetingInProgress:
        return Colors.orange;
      case AppConstants.meetingCancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildMeetingGuidelines(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meeting Guidelines',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGuidelineItem(
                  context,
                  'Attendance',
                  'All members are expected to attend monthly meetings. Absence without prior notice may result in penalties.',
                  Icons.people,
                ),
                const SizedBox(height: 16),
                _buildGuidelineItem(
                  context,
                  'Punctuality',
                  'Please join the meeting on time. Late arrivals disrupt the flow of discussions.',
                  Icons.schedule,
                ),
                const SizedBox(height: 16),
                _buildGuidelineItem(
                  context,
                  'Participation',
                  'Active participation in discussions is encouraged. Share your ideas and concerns constructively.',
                  Icons.chat,
                ),
                const SizedBox(height: 16),
                _buildGuidelineItem(
                  context,
                  'Respect',
                  'Maintain respect for all members. Listen attentively and avoid interrupting others.',
                  Icons.handshake,
                ),
                const SizedBox(height: 16),
                _buildGuidelineItem(
                  context,
                  'Confidentiality',
                  'Keep all group discussions confidential. Do not share sensitive information outside the group.',
                  Icons.security,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuidelineItem(
    BuildContext context,
    String title,
    String description,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _joinMeeting(BuildContext context, String meetingUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Meeting'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Click the button below to join the meeting:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                meetingUrl,
                style: Theme.of(context).textTheme.bodySmall,
              ),
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
              Navigator.pop(context);
              await _launchMeetingUrl(meetingUrl);
            },
            child: const Text('Join Meeting'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchMeetingUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch meeting URL');
      }
    } catch (e) {
      // Handle error - in a real app, you might want to show a snackbar
      print('Error launching meeting URL: $e');
      _showError(
        'Could not open meeting link. Please try again or copy the link manually.',
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _copyMeetingLink(String url) async {
    try {
      await Clipboard.setData(ClipboardData(text: url));
      _showError('Meeting link copied to clipboard!');
    } catch (e) {
      _showError('Failed to copy link: $e');
    }
  }
}
