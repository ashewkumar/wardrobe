import 'package:flutter/material.dart';
import 'app_theme.dart';

class ModernUI {

  // ================= APP BAR =================

  static PreferredSizeWidget appBar({
    required BuildContext context,
    required String title,
    VoidCallback? logout,
    List<Widget>? actions,
  }) {
    final colors = Theme.of(context).colorScheme;

    return AppBar(
      elevation: 0,
      centerTitle: true,

      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),

      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.primary,
              colors.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),


      actions: [
        if (actions != null) ...actions,
        if (logout != null)
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: logout,
          ),
      ],
    );
  }

  // ================= CARD =================

  static Widget dashboardCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,

      borderRadius: BorderRadius.circular(20),

      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.softBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.softBorder),
          boxShadow: AppTheme.softShadows,
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: color),
            ),

            const SizedBox(height: 10),

            Text(
              title,
              style: const TextStyle(
                color: AppTheme.navy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= INPUT FIELD =================

  static Widget inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,

      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }

  // ================= PRIMARY BUTTON =================

  static Widget primaryButton({
    required String text,
    required VoidCallback onTap,
    bool loading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,

      child: ElevatedButton(
        onPressed: loading ? null : onTap,

        child: loading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(text),
      ),
    );
  }

  // ================= PAGE WRAPPER =================

  static Widget pageWrapper({
    required Widget child,
  }) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            AppTheme.softBg,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),

      child: child,
    );
  }
}
