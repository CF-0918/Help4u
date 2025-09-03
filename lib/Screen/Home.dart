import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import 'package:workshop_assignment/authencation/auth_service.dart';
import 'package:workshop_assignment/Repository/user_repo.dart';
import 'package:workshop_assignment/Repository/outlet_repo.dart';

import '../Models/UserProfile.dart';
import '../Models/Outlet.dart';
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

  bool _busy = false;
  int _current = 0;

  /// Outlets pulled from Supabase
  List<Outlet> _workshops = [];

  late final List<Widget> _pages =
  [
    HomeTab(),
    ProgressTab(),
    AppointmentsTab(),
    ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    uid = _authService.currentUser?.id;
    _initData();

    // separate “after first frame” work so it never collides with build/nav
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeSuggestNearest(context);
    });
  }

  @override
  Future<void> _initData() async {
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      if (uid != null) {
        final user = await _userRepo.fetchUserDetails(uid!);
        if (!mounted) return;
        setState(() => userDetails = user);
      }

      // If your DB values might be “Active/ACTIVE”, our repo ilike will match.
      final outlets = await OutletRepo().fetchOutlets(status: 'active');
      if (!mounted) return;

      final provider = context.read<LocationProvider>();
      if (outlets.isNotEmpty &&
          !outlets.any((o) => o.outletID == provider.locationId)) {
        // Correctly initialize with the first outlet's ID if no location is selected
        provider.updateLocation(outlets.first.outletID);
      }

      setState(() => _workshops = outlets);
    } catch (e) {
      if (!mounted) return;
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

      appBar: _current == 0
          ? HomeAppBar(
        userName: userDetails?.name ?? 'User',
        workshops: _workshops,
      )
          : null,

      body: Stack(
        children: [
          IndexedStack(index: _current, children: _pages),
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
      if (_workshops.isEmpty) return;

      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition();

      // Find nearest outlet
      Outlet nearest = _workshops.first;
      double nearestDist = double.infinity;

      for (final w in _workshops) {
        final d = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          w.latitude,
          w.longitude,
        );
        if (d < nearestDist) {
          nearestDist = d;
          nearest = w;
        }
      }

      final provider = context.read<LocationProvider>();
      final currentId = provider.locationId;

      // If already selected, do nothing
      if (currentId == nearest.outletID) return;

      // distance for currently selected (if it exists)
      final current = _workshops.firstWhere(
            (w) => w.outletID == currentId,
        orElse: () => nearest,
      );

      final currentDist = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        current.latitude,
        current.longitude,
      );

      // Suggest if current is >500m farther than the nearest choice
      if (currentDist - nearestDist > 500) {
        if (!mounted) return;
        final km = (nearestDist / 1000).toStringAsFixed(1);

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final switchIt = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Nearby workshop found'),
              content: Text(
                'You are about $km km from "${nearest.outletName}".\nSwitch to this location?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Keep current'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Switch'),
                ),
              ],
            ),
          );

          if (switchIt == true && mounted) {
            // Correctly update with the outlet's ID
            provider.updateLocation(nearest.outletID);
          }
        });
      }
    } catch (_) {
      // swallow location/permission errors quietly
    }
  }
}

class HomeAppBar extends StatefulWidget implements PreferredSizeWidget {
  const HomeAppBar({
    super.key,
    required this.workshops,
    required this.userName,
  });

  final String userName;
  final List<Outlet> workshops;

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
        final items = widget.workshops;
        return SafeArea(
          child: ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text("Choose a workshop",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "No outlets found. Please check your data or network.",
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              else
                ...items.map((w) => RadioListTile<String>(
                  value: w.outletID,
                  groupValue: selected,
                  onChanged: (v) => Navigator.pop(context, v),
                  title: Text(w.outletName, style: const TextStyle(color: Colors.white)),
                  activeColor: Colors.white,
                )),
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
    final selected = context.watch<LocationProvider>().locationId;

    // Find the outlet name for the selected ID
    final selectedOutlet = widget.workshops.firstOrNullWhere((w) => w.outletID == selected);
    final locationDisplayName = selectedOutlet?.outletName ?? "Select location";

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
                  onTap: () => _pickLocation(context, selected!),
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
                            locationDisplayName,
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

// handy Optional-first helper (kept from your original)
extension _FirstOrNull<E> on Iterable<E> {
  E? firstOrNullWhere(bool Function(E element) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
