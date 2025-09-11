import 'package:flutter/material.dart';
import 'package:workshop_assignment/authencation/auth_service.dart';

import '../main.dart'; // <- for navigatorKey
import '../Models/Notifications.dart';
import '../Repository/notifications_repo.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationRepository _repo = NotificationRepository();
  List<NotificationItem> notifications = [];
  bool _loading = true;
  int limit = 20;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    AuthService authService=AuthService();
    if (authService.currentUserId == null) {
      return;
    }
    final userId = authService.currentUserId!;
    try {
      final list = await _repo.getchUnreadNotifications(userId);
      if (!mounted) return;
      setState(() {
        notifications = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error loading notifications')));
      setState(() => _loading = false);
    }
  }

  Future<void> _onRefresh() => _loadNotifications();

  // Future<void> _onTap(NotificationItem n) async {
  //   // optimistic mark-as-read
  //   if (!n.userHasRead) {
  //     setState(() {
  //       final i = notifications.indexWhere((x) => x.id == n.id);
  //       if (i != -1) notifications[i] = notifications[i].copyWith(userHasRead: true);
  //     });
  //     try { await _repo.markAsRead(n.id); } catch (_) {}
  //   }
  //   // navigate by data.screen
  //   final data = n.data;
  //   final route = (data['screen'] as String?)?.trim();
  //   if (route == null || route.isEmpty) {
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context)
  //         .showSnackBar(const SnackBar(content: Text('No route in notification')));
  //     return;
  //   }
  //   if (!mounted) return;
  //   Navigator.of(context).pushNamed(route, arguments: data);
  // }


  Future<void> _onTap(NotificationItem n) async {
    // optimistic mark-as-read
    if (!n.userHasRead) {
      setState(() {
        final i = notifications.indexWhere((x) => x.id == n.id);
        if (i != -1) notifications[i] = notifications[i].copyWith(userHasRead: true);
      });
      try { await _repo.markAsRead(n.id); } catch (e) { debugPrint('mark err: $e'); }
    }

    // normalize route name
    final raw = (n.data['screen'] as String?) ?? '';
    var route = raw.trim();
    if (route.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No route in notification')));
      return;
    }
    if (!route.startsWith('/')) route = '/$route';

    // alias common variations to your registered keys
    final aliases = <String, String>{
      '/appointmentdetails': '/AppointmentDetails',
      '/servicereminder': '/ServiceReminder',
    };
    route = aliases[route.toLowerCase()] ?? route;

    debugPrint('➡️ navigating to "$route" with args: ${n.data}');
    // use global navigatorKey to avoid nested Navigator issues
    navigatorKey.currentState?.pushNamed(route, arguments: n.data);
  }

  Widget _tile(NotificationItem n) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListTile(
        onTap: () => _onTap(n),
        title: Text(
          n.title,
          style: TextStyle(
            fontWeight: n.userHasRead ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(n.body),
            const SizedBox(height: 4),
            Text('Sent: ${n.sentAt.toLocal()}',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        trailing: n.userHasRead
            ? null
            : const CircleAvatar(radius: 5, backgroundColor: Colors.red),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : notifications.isEmpty
        ? const Center(child: Text('No notifications yet'))
        : ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: notifications.length,
      itemBuilder: (_, i) => _tile(notifications[i]),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadNotifications),
        ],
      ),
      body: RefreshIndicator(onRefresh: _onRefresh, child: body),
    );
  }
}
