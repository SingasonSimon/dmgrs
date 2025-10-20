import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/constants.dart';

class MeetingsScreen extends StatelessWidget {
  const MeetingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meetings')),
      body: SingleChildScrollView(
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
                      Text(
                        'Monthly Meeting',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
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
                        'First Saturday of every month at 2:00 PM',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _joinMeeting(context),
                      icon: const Icon(Icons.video_call),
                      label: const Text('Join Meeting'),
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildMeetingItem(
                  context,
                  'Monthly Meeting - December 2024',
                  '2024-12-07',
                  '2:00 PM - 4:00 PM',
                  true,
                ),
                const Divider(),
                _buildMeetingItem(
                  context,
                  'Monthly Meeting - November 2024',
                  '2024-11-02',
                  '2:00 PM - 4:00 PM',
                  true,
                ),
                const Divider(),
                _buildMeetingItem(
                  context,
                  'Monthly Meeting - October 2024',
                  '2024-10-05',
                  '2:00 PM - 4:00 PM',
                  true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeetingItem(
    BuildContext context,
    String title,
    String date,
    String time,
    bool attended,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: attended ? Colors.green : Colors.grey,
        child: Icon(attended ? Icons.check : Icons.close, color: Colors.white),
      ),
      title: Text(title),
      subtitle: Text('$date at $time'),
      trailing: attended
          ? const Chip(
              label: Text('Attended'),
              backgroundColor: Colors.green,
              labelStyle: TextStyle(color: Colors.white),
            )
          : const Chip(
              label: Text('Missed'),
              backgroundColor: Colors.grey,
              labelStyle: TextStyle(color: Colors.white),
            ),
    );
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

  void _joinMeeting(BuildContext context) {
    // Mock Google Meet URL - in a real app, this would come from the database
    const String meetingUrl = 'https://meet.google.com/abc-defg-hij';

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
    }
  }
}
