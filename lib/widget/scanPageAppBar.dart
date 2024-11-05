import 'package:fanishion_project_v1/constant/appColor.dart';
import 'package:fanishion_project_v1/constant/font.dart';
import 'package:fanishion_project_v1/pages/controlPage.dart';
import 'package:fanishion_project_v1/service/ble_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScanPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ScanPageAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Consumer<BleController>(
      builder: (context, controller, child) {
        String title = controller.getStatusString();
        return AppBar(
          shadowColor: AppColor.accent,
          title: Text(title, style: Font.h2),
          actions: [
            if (controller.connectedDevice != null)
              IconButton(
                icon: const Icon(Icons.arrow_right, color: AppColor.accent),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ControlPage()));
                },
              )
          ],
          automaticallyImplyLeading: false,
          centerTitle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
        );
      },
    );
  }
}
