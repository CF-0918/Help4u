import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import 'package:workshop_assignment/Repository/user_repo.dart';
import 'package:workshop_assignment/authencation/auth_service.dart';

import '../Models/UserProfile.dart';
import '../TabScreen/HomeTab.dart';
import '../TabScreen/ProgressTab.dart';
import '../TabScreen/AppointmentsTab.dart';
import '../TabScreen/ProfileTab.dart';
import 'package:workshop_assignment/Provider/LocationProvider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final UserRepository _userRepo = UserRepository();
  final AuthService _authService = AuthService();

  String? uid;
  UserProfile? userDetails;

  bool _busy = false; // in-tree loading instead of Navigator-based overlay
  int _current = 0;

  // Define your workshops with coordinates
  static const List<_WorkshopLocation> workshops = [
    _WorkshopLocation("Bukit Jalil Workshop", 3.0580, 101.6896),
    _WorkshopLocation("Air Asia Workshop", 2.7456, 101.7090),
  ];

  // Keep pages simple; use const where possible.
  late final List<Widget> _pages = [
    HomeTab(),
    const ProgressTab(),
    const AppointmentsTab(),
    const ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    uid = _authService.currentUser?.id;
    _initData();

    // After first frame, we can safely do permission & dialog flow.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeSuggestNearest(context);
    });
  }

  Future<void> _initData() async {
    if (!mounted) return;

    setState(() => _busy = true);
    try {
      if (uid == null) {
        // No authenticated user; just stop the spinner gracefully.
        return;
      }

      final user = await _userRepo.fetchUserDetails(uid!); // returns UserProfile?
      if (!mounted) return;
      setState(() => userDetails = user);
    } catch (e) {
      if (!mounted) return;
      // Schedule SnackBar after frame to avoid build-time side effects
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch data: $e")),
        );
      });
    } finally {
      if (!mounted) return;
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      // Show AppBar only on index 0
      appBar: _current == 0
          ? HomeAppBar(
        userName: userDetails?.name ?? 'User',
        workshops: workshops,
      )
          : null,

      body: Stack(
        children: [
          // Keep state of tabs with IndexedStack
          IndexedStack(index: _current, children: _pages),

          // Simple, safe loading overlay (no Navigator involved)
          if (_busy) const ModalBarrier(dismissible: false, color: Color(0x88000000)),
          if (_busy) const Center(child: CircularProgressIndicator()),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        selectedIconTheme: const IconThemeData(color: Colors.white),
        unselectedIconTheme: const IconThemeData(color: Colors.grey),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: false,
        currentIndex: _current,
        onTap: (index) => setState(() => _current = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.car_rental), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Appointments'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // ===== Nearest-location logic =====
  Future<void> _maybeSuggestNearest(BuildContext context) async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        return; // user didn’t grant permission; do nothing
      }

      final pos = await Geolocator.getCurrentPosition();

      // Find nearest workshop
      _WorkshopLocation nearest = workshops.first;
      double nearestDist = double.infinity;

      for (final w in workshops) {
        final d = Geolocator.distanceBetween(pos.latitude, pos.longitude, w.lat, w.lng);
        if (d < nearestDist) {
          nearestDist = d;
          nearest = w;
        }
      }

      final provider = context.read<LocationProvider>();
      final currentName = provider.locationName;

      // If already the same, no prompt
      if (currentName == nearest.name) return;

      // Compute current-selected distance (if it exists in list)
      final current = workshops.where((w) => w.name == currentName).cast<_WorkshopLocation?>().firstOrNull;
      double currentDist = double.infinity;
      if (current != null) {
        currentDist = Geolocator.distanceBetween(pos.latitude, pos.longitude, current.lat, current.lng);
      }

      // Suggest if current distance is > nearest distance by 500m
      if (currentDist - nearestDist > 500) {
        if (!mounted) return;
        final km = (nearestDist / 1000).toStringAsFixed(1);

        // Schedule dialog after frame to avoid Navigator lock edge cases
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final switchIt = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Nearby workshop found'),
              content: Text('You are about $km km from "${nearest.name}".\nSwitch to this location?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Keep current')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Switch')),
              ],
            ),
          );

          if (switchIt == true && mounted) {
            provider.updateLocation(nearest.name);
          }
        });
      }
    } catch (_) {
      // Silently ignore errors (e.g., simulator without location, permission flow interrupted)
    }
  }
}

class HomeAppBar extends StatefulWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key, required this.workshops, required this.userName});
  final String userName; // already non-null
  final List<_WorkshopLocation> workshops;

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _HomeAppBarState extends State<HomeAppBar> {
  Future<void> _pickLocation(BuildContext context, String selected) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFF1C1C1E),
      builder: (_) {
        return SafeArea(
          child: ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  "Choose a workshop",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
              ...widget.workshops.map(
                    (w) => RadioListTile<String>(
                  value: w.name,
                  groupValue: selected,
                  onChanged: (v) => Navigator.pop(context, v),
                  title: Text(w.name, style: const TextStyle(color: Colors.white)),
                  activeColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (chosen != null && mounted) {
      context.read<LocationProvider>().updateLocation(chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<LocationProvider>().locationName;

    final hour = DateTime.now().hour;
    final greet = hour < 12
        ? 'Morning'
        : (hour < 18 ? 'Afternoon' : 'Evening');

    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      scrolledUnderElevation: 3,
      shadowColor: Colors.white70,
      titleSpacing: 8,

      title: Row(
        children: [
          // Logo
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage("assets/images/logo.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Titles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Help4U",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "$greet, ${widget.userName}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),

      actions: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: SizedBox(
                width: 170,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _pickLocation(context, selected),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2D),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.place, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            selected,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.white70),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const _BellWithDot(),
      ],
    );
  }
}

class _BellWithDot extends StatelessWidget {
  const _BellWithDot();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.white),
          onPressed: () {},
        ),
        Positioned(
          right: 10,
          top: 10,
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
          ),
        ),
      ],
    );
  }
}

// Small helper model
class _WorkshopLocation {
  final String name;
  final double lat;
  final double lng;
  const _WorkshopLocation(this.name, this.lat, this.lng);
}

// Nice helper for Optional first element
extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
