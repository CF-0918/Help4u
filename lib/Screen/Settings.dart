import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workshop_assignment/Repository/settings_repo.dart';
import 'package:workshop_assignment/Repository/user_repo.dart';
import 'package:workshop_assignment/authencation/auth_service.dart';

// Avoid name clash with the widget by using an alias for the model.
import '../Models/Settings.dart' as m;
import 'Login.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final Color surface = const Color(0xFF1F2937);

  /// UI State
  bool serviceReminder = true;
  String? selectedValue = '14'; // default when user just registered

  /// Data
  final _auth = AuthService();
  final _repo = SettingsRepository();
  m.Settings? _settings; // nullable until loaded
  bool _loading = true;
  bool _saving = false;

  /// Load settings for the logged in user
  Future<void> _loadSettings() async {
    final userId = _auth.currentUserId;
    if (userId == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      final s = await _repo.getByUserId(userId);
      // If no row yet, we keep defaults (14 days, enabled)
      setState(() {
        _settings = s;
        selectedValue = (s?.serviceReminderDays ?? 14).toString();
        serviceReminder = true; // if you support disabling, bind it to a column
        _loading = false;
      });
    } catch (e) {
      // Fail gracefully but let user still interact
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load settings: $e')),
      );
    }
  }

  /// Save to repository (upsert)
  Future<void> _save() async {
    final userId = _auth.currentUserId;
    if (userId == null || selectedValue == null) return;

    setState(() => _saving = true);
    try {
      // SAVE: adapt if your repo uses a different method signature.
      await _repo.update(
        userId: userId,
        serviceReminderDays: int.parse(selectedValue!),
      );
      // Keep local cache in sync
      _settings = m.Settings(
        id: _settings!.id,
        userId: userId,
        serviceReminderDays: int.parse(selectedValue!),
        createdAt: _settings!.createdAt,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
      padding: const EdgeInsets.all(15),
      children: [
        // Preferences section
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _sectionHeader(icon: Icons.tune, label: "Preferences"),
              const Divider(height: 1, color: Colors.white12),
              _settingTile(
                icon: Icons.lightbulb,
                title: "Service Reminder",
                value: serviceReminder,
                onChanged: (v) async {
                  setState(() => serviceReminder = v);
                  // If you actually store enable/disable in DB, save here.
                  // For now, we only store days; the switch just hides radios.
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Radio group section (only when enabled)
        if (serviceReminder) ...[
          Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _sectionHeader(
                  icon: Icons.schedule,
                  label: "Reminder Period",
                ),
                const Divider(height: 1, color: Colors.white12),

                // 7 days
                _radioTile(
                  value: "7",
                  title: "7 Days Before",
                  subtitle:
                  "You will receive a reminder 7 days before your service is due.",
                  onChanged: (val) async {
                    setState(() => selectedValue = val);
                    await _save(); // SAVE on change
                  },
                ),
                const Divider(height: 1, color: Colors.white12),

                // 14 days
                _radioTile(
                  value: "14",
                  title: "14 Days Before",
                  subtitle:
                  "You will receive a reminder 14 days before your service is due.",
                  onChanged: (val) async {
                    setState(() => selectedValue = val);
                    await _save(); // SAVE on change
                  },
                ),
                const Divider(height: 1, color: Colors.white12),

                // 30 days
                _radioTile(
                  value: "30",
                  title: "30 Days Before",
                  subtitle:
                  "You will receive a reminder 30 days before your service is due.",
                  onChanged: (val) async {
                    setState(() => selectedValue = val);
                    await _save(); // SAVE on change
                  },
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              "Enable Service Reminder to choose your reminder period.",
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Delete Account box (unchanged, just slightly tidied)
        _deleteAccountCard(),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF111827),
        foregroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Settings",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            if (_saving) ...[
              const SizedBox(width: 10),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ),
      backgroundColor: const Color(0xFF0B1220),
      body: body,
    );
  }

  // ----- UI helpers -----

  Widget _sectionHeader({required IconData icon, required String label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      dense: true,
      secondary: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      inactiveThumbColor: Colors.white70,
      inactiveTrackColor: Colors.white12,
    );
  }

  Widget _radioTile({
    required String value,
    required String title,
    String? subtitle,
    required ValueChanged<String> onChanged,
  }) {
    return RadioListTile<String>(
      value: value,
      groupValue: selectedValue,
      onChanged: (val) {
        if (val != null) onChanged(val);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, style: const TextStyle(color: Colors.white70)),
      activeColor: Colors.blueAccent,
    );
  }

  Widget _deleteAccountCard() {
    final controller = TextEditingController();

    void _showDeleteAccDialog() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Delete Account"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Please confirm you really want to delete this account"),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  label: const Text("Enter Password"),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  suffixIcon: const Icon(Icons.remove_red_eye),
                ),
                obscureText: true,
              ),
            ],
          ),
          backgroundColor: surface,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final pwd = controller.text.trim();

                if (pwd.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.red,
                      content: Text(
                        'Please enter your password',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      duration: Duration(seconds: 3),
                    ),
                  );
                  return;
                }

                try {
                  // Re-authenticate (verifies password)
                  final email = _auth.currentUserEmail;
                  if (email == null) {
                    throw Exception('No email on the current session.');
                  }

                  // Supabase v2
                  await Supabase.instance.client.auth.signInWithPassword(
                    email: email,
                    password: pwd,
                  );

                  // If we get here, password is correct → disable the account
                  final userId = _auth.currentUserId;
                  if (userId == null) {
                    throw Exception('No user id on the current session.');
                  }

                  await UserRepository().disabledUserAcc(userId);

                  if (!context.mounted) return;
                  Navigator.of(context).pop(); // close the dialog

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.red,
                      content: Text(
                        'Account Deleted',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      duration: Duration(seconds: 4),
                    ),
                  );

                  // Sign out and go to Login
                  await _auth.signOut();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const Login()),
                        (_) => false,
                  );
                } on AuthException catch (_) {
                  // Wrong password
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.red,
                      content: Text(
                        'Wrong password. Please try again.',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      duration: Duration(seconds: 3),
                    ),
                  );
                } catch (e) {
                  // Anything else
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.red,
                      content: Text(
                        'Failed to delete account: $e',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
              ,
              child: const Text("Delete"),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Delete Account?",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _showDeleteAccDialog,
                child: const Text("Delete"),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Please confirm you really want to delete this account",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
