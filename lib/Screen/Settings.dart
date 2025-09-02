import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final Color surface = const Color(0xFF1F2937);
  bool emailNotification = true;
  bool pushNotification = true;
  bool serviceReminder = true;
  String? selectedValue="7"; // current selected radio value

  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    void _showDeleteAccDialog(){
      showDialog(context: context, builder: (context)=> AlertDialog(
        title: Text("Delete Account"),
        content: Column(
          mainAxisSize: MainAxisSize.min,              // 👈 key line
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Please confirm you really want to delete this account"),
            SizedBox(height: 20,),
            Form(
              child:
            TextFormField(
              controller: passwordController,
              decoration: InputDecoration(
                label: Text("Enter Password"),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.red),
                ),
                suffixIcon: Icon(Icons.remove_red_eye),
              ),
              obscureText: true,
            ),
            ),
          ],
        ),
        backgroundColor: surface,
        actions: [
          TextButton(onPressed: (){
            Navigator.pop(context);
          }, child: Text("Cancel")),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.red,
                  content: const Text("Account Deleted",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
                  action: SnackBarAction(
                    label: "Undo",
                    textColor: Colors.white,
                    onPressed: () {
                      // 👇 put your undo logic here
                      print("Undo tapped!");
                    },
                  ),
                  duration: const Duration(seconds: 5), // optional
                ),
              );

              Navigator.pop(context); // close dialog
            },
            child: const Text("Delete"),
          )

        ],
      ));
    }
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF111827),
        foregroundColor: Colors.white,
        title: const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      backgroundColor: const Color(0xFF0B1220),

      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          // Preferences section
          Container(
            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _sectionHeader(icon: Icons.tune, label: "Preferences"),
                const Divider(height: 1, color: Colors.white12),

                _settingTile(
                  icon: Icons.email,
                  title: "Email Notification",
                  value: emailNotification,
                  onChanged: (v) => setState(() => emailNotification = v),
                ),
                const Divider(height: 1, color: Colors.white12),

                _settingTile(
                  icon: Icons.notifications,
                  title: "Push Notification",
                  value: pushNotification,
                  onChanged: (v) => setState(() => pushNotification = v),
                ),
                const Divider(height: 1, color: Colors.white12),

                _settingTile(
                  icon: Icons.lightbulb,
                  title: "Service Reminder",
                  value: serviceReminder,
                  onChanged: (v) => setState(() => serviceReminder = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Radio group section
          serviceReminder!=true?Container(
            child: Text("You can set the reminder period when Service Reminder is enabled."),
          ): Container(
            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _sectionHeader(icon: Icons.schedule, label: "Reminder Period"),
                const Divider(height: 1, color: Colors.white12),

                _radioTile(
                  value: "7",
                  title: "7 Days Onwards",
                  subtitle: "You will receive a reminder 7 days before your service is due.",
                ),
                const Divider(height: 1, color: Colors.white12),

                _radioTile(
                  value: "3",
                  title: "3 Days Onwards",
                  subtitle: "You will receive a reminder 3 days before your service is due.",
                ),
                const Divider(height: 1, color: Colors.white12),

                _radioTile(
                  value: "1",
                  title: "1 Day Onwards",
                  subtitle: "You will receive a reminder 1 day before your service is due.",
                ),

              ],
            ),
          ),

          const SizedBox(height: 16),

          Container(
            margin: EdgeInsets.symmetric(vertical: 16),
            padding: EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color:surface ,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Delete Account?",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8), // spacing
                    Text(
                      "Please confirm you really want to delete this account",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      softWrap: true,                // wraps automatically if needed
                      overflow: TextOverflow.visible, // ensures no clipping
                    ),
                  ],
                ),

                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: (){
                      _showDeleteAccDialog();
                    },
                    child: Text("Delete")
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // ----- helpers -----

  Widget _sectionHeader({required IconData icon, required String label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
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
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      inactiveThumbColor: Colors.white70,
      inactiveTrackColor: Colors.white12,
    );
  }

  Widget _radioTile({
    required String value,
    required String title,
    String? subtitle,
  }) {
    return RadioListTile<String>(
      value: value,
      groupValue: selectedValue,
      onChanged: (val) => setState(() => selectedValue = val),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      subtitle: subtitle == null ? null : Text(subtitle, style: const TextStyle(color: Colors.white70)),
      activeColor: Colors.blueAccent,
    );
  }
}
