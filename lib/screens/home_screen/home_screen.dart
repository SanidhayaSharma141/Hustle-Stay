import 'package:flutter/material.dart';
import 'package:hustle_stay/models/user/user.dart';
import 'package:hustle_stay/screens/admin_panel/admin_panel_screen.dart';
import 'package:hustle_stay/screens/chat/private_chats.dart';
import 'package:hustle_stay/screens/drawers/main_drawer.dart';
import 'package:hustle_stay/screens/filter_screen/stats_screen.dart';
import 'package:hustle_stay/screens/profile/profile_preview.dart';
import 'package:hustle_stay/screens/requests/stats/requests_stats_screen.dart';
import 'package:hustle_stay/tools.dart';
import 'package:hustle_stay/widgets/other/dark_light_mode_icon_button.dart';
import 'package:hustle_stay/widgets/requests/grid_tile_logo.dart';

class HomeScreen extends StatelessWidget {
  final void Function(int value) pageChanger;
  const HomeScreen({required this.pageChanger, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.blue,
      appBar: AppBar(
        actions: const [DarkLightModeIconButton()],
        // backgroundColor: Colors.transparent,
      ),
      drawer: const MainDrawer(),
      extendBody: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 20, left: 8, right: 8),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: [
              ProfilePreview(
                user: currentUser,
                showCallButton: false,
                showChatButton: false,
                showMailButton: false,
              ),
              const SizedBox(height: 20),
              GridView.extent(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                maxCrossAxisExtent: 320,
                childAspectRatio: 3 / 2,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
                children: [
                  GridTileLogo(
                    title: 'Attendance',
                    icon: const Icon(
                      Icons.calendar_month_rounded,
                      size: 50,
                    ),
                    color: Colors.amberAccent,
                    onTap: () => pageChanger(0),
                  ),
                  GridTileLogo(
                    title: 'Complaints',
                    icon: const Icon(
                      Icons.info_rounded,
                      size: 50,
                    ),
                    color: Colors.redAccent,
                    onTap: () => pageChanger(1),
                  ),
                  GridTileLogo(
                    title: 'Requests',
                    icon: const Icon(
                      Icons.airport_shuttle_rounded,
                      size: 50,
                    ),
                    color: Colors.blueAccent,
                    onTap: () => pageChanger(3),
                  ),
                  if (currentUser.isAdmin)
                    GridTileLogo(
                      title: 'Admin Panel',
                      icon: const Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 50,
                      ),
                      color: Colors.greenAccent,
                      onTap: () {
                        navigatorPush(context, const AdminPanel());
                      },
                    ),
                  GridTileLogo(
                    title: 'Settings',
                    icon: const Icon(
                      Icons.settings_rounded,
                      size: 50,
                    ),
                    color: Colors.deepPurpleAccent,
                    onTap: () => pageChanger(4),
                  ),
                  if (currentUser.permissions.complaints.read == true)
                    GridTileLogo(
                      title: 'Complaint Stats',
                      icon: const Icon(
                        Icons.stacked_bar_chart_rounded,
                        size: 50,
                      ),
                      color: Colors.indigoAccent,
                      onTap: () {
                        navigatorPush(context, const StatisticsPage());
                      },
                    ),
                  if (currentUser.permissions.requests.read == true)
                    GridTileLogo(
                      title: 'Requests Stats',
                      icon: const Icon(
                        Icons.stacked_bar_chart_rounded,
                        size: 50,
                      ),
                      color: Colors.brown,
                      onTap: () {
                        navigatorPush(context, const RequestsStatisticsPage());
                      },
                    ),
                  GridTileLogo(
                    title: 'Chats',
                    icon: const Icon(
                      Icons.chat_rounded,
                      size: 50,
                    ),
                    color: Colors.cyanAccent,
                    onTap: () {
                      navigatorPush(context, const ChatsScreen());
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
