import 'dart:typed_data' as t;

import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:workshop_assignment/Screen/ChangePassword.dart';
import 'package:workshop_assignment/Screen/EditProfile.dart';
import 'package:workshop_assignment/Screen/MyFeedback.dart';
import 'package:workshop_assignment/Screen/Settings.dart';

import '../Screen/LogOut.dart';
import '../Screen/ServiceReminder.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

// ---------- Model ----------
class ProfileTabItem {
  final IconData icon;
  final String label;
  final WidgetBuilder? builder; // screen page as a builder
  final VoidCallback? onTap;

  const ProfileTabItem({
    required this.icon,
    required this.label,
    this.builder,
    this.onTap,
  });
}

final List<ProfileTabItem> profileTabsList = [
  ProfileTabItem(icon: Icons.person,        label: 'Edit Profile',        builder: (_) => const EditProfile()),
  ProfileTabItem(icon: Icons.lock,          label: 'Change Password',     builder: (_) => const ChangePassword()),
  ProfileTabItem(icon: Icons.history,       label: 'Appointment History', builder: (_) => const Servicereminder()),
  ProfileTabItem(icon: Icons.note_alt, label: 'My Feedback',  builder: (_) => const MyFeedback()),
  ProfileTabItem(icon: Icons.notifications, label: 'Service Reminder',    builder: (_) => const Servicereminder()),
  ProfileTabItem(icon: Icons.card_giftcard, label: 'Vouchers & Rewards',  builder: (_) => const Servicereminder()),
  ProfileTabItem(icon: Icons.settings,      label: 'Settings',            builder: (_) => const Settings()),
  ProfileTabItem(icon: Icons.logout,        label: 'Log out',builder: (_) => const LogOut()),
];

// ---------- Member barcode overlay ----------
void showMemberBarcodeOverlay(BuildContext context, {required String data}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'barcode',
    barrierColor: Colors.black54,
    pageBuilder: (_, __, ___) => _BarcodeOverlay(data: data),
    transitionBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim, child: child),
  );
}

class _BarcodeOverlay extends StatefulWidget {
  final String data;
  const _BarcodeOverlay({required this.data});

  @override
  State<_BarcodeOverlay> createState() => _BarcodeOverlayState();
}

class _BarcodeOverlayState extends State<_BarcodeOverlay> {
  double? _oldBrightness;

  @override
  void initState() {
    super.initState();
    _boostBrightness();
  }

  Future<void> _boostBrightness() async {
    try {
      _oldBrightness = await ScreenBrightness().current;
      await ScreenBrightness().setScreenBrightness(1.0);
    } catch (_) {/* ignore on web/unsupported platforms */}
  }

  Future<void> _restoreBrightness() async {
    try {
      if (_oldBrightness != null) {
        await ScreenBrightness().setScreenBrightness(_oldBrightness!);
      }
    } catch (_) {/* ignore */}
  }

  @override
  void dispose() {
    _restoreBrightness();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Spacer(),
                const Text(
                  'Member Barcode',
                  style: TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BarcodeWidget(
                      barcode: Barcode.code128(),
                      data: widget.data,
                      drawText: true,
                      width: double.infinity,
                      height: 160,
                      color: Colors.black,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.data,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Show this at the counter for scanning.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ---------- Main Profile Tab ----------
enum PhotoAction { camera, gallery, remove }

class _ProfileTabState extends State<ProfileTab> {
  final ImagePicker _picker = ImagePicker();
  t.Uint8List? _avatarBytes; // works on web & mobile

  Future<void> _chooseCameraOrLibrary() async {
    final action = await showModalBottomSheet<PhotoAction>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding:EdgeInsets.symmetric(vertical: 10,horizontal: 15),
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(ctx, PhotoAction.camera),
            ),
            Divider(height: 3,thickness: 2,color: Colors.grey,),
            ListTile(
              contentPadding:EdgeInsets.symmetric(vertical: 10,horizontal: 15),
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, PhotoAction.gallery),
            ),
            if (_avatarBytes != null) const Divider(height: 0),
            if (_avatarBytes != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remove photo'),
                onTap: () => Navigator.pop(ctx, PhotoAction.remove),
              ),
          ],
        ),
      ),
    );

    if (action == null) return;

    if (action == PhotoAction.remove) {
      setState(() => _avatarBytes = null);
      return;
    }

    final source =
    (action == PhotoAction.camera) ? ImageSource.camera : ImageSource.gallery;

    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() => _avatarBytes = t.Uint8List.fromList(bytes)); // web-safe
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF9333EA);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            // ===== Header (gradient + avatar + name + points) =====
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                ),
                borderRadius: BorderRadius.all(Radius.circular(25)),
              ),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: GestureDetector(
                          onTap: _chooseCameraOrLibrary,
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor: Colors.white,
                            backgroundImage: _avatarBytes != null
                                ? MemoryImage(_avatarBytes!)
                                : const AssetImage('assets/images/profile.jpg')
                            as ImageProvider,
                          ),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(3),
                          child: const CircleAvatar(
                            radius: 14,
                            backgroundColor: purple,
                            child: Icon(Icons.camera_alt,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "John Mechanic",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Customer - Brownse Member",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.money, size: 20, color: Colors.amber),
                      SizedBox(width: 6),
                      Text(
                        "Member Points (198 pts)",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // View barcode button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton.icon(
                      onPressed: () {
                        showMemberBarcodeOverlay(context, data: 'SM-000198');
                      },
                      icon: const Icon(Icons.qr_code,
                          size: 20, color: Colors.white),
                      label: const Text(
                        "View Member Barcode",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== Menu list =====
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: profileTabsList.length,
              itemBuilder: (context, i) {
                final tab = profileTabsList[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ProfileTile(
                    icon: tab.icon,
                    label: tab.label,
                    onTap: tab.onTap ??
                            () {
                          if (tab.builder != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: tab.builder!),
                            );
                          }
                        },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Tile widget ----------
class ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const ProfileTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1F2937),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(Icons.chevron_right,
                    color: Colors.transparent), // spacer
                Icon(icon, size: 24, color: const Color(0xFF9333EA)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF9333EA)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
