import 'package:flutter/material.dart';
import 'package:hustle_stay/models/requests/mess/menu_change_request.dart';
import 'package:hustle_stay/models/user/user.dart';
import 'package:hustle_stay/screens/requests/mess/menu_change_screen.dart';
import 'package:hustle_stay/screens/requests/requests_screen.dart';
import 'package:hustle_stay/tools.dart';
import 'package:hustle_stay/widgets/requests/grid_tile_logo.dart';

class MessRequestScreen extends StatelessWidget {
  static const String routeName = 'MessRequestScreen';
  const MessRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: shaderText(
          context,
          title: 'Mess Requests',
          style:
              theme.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            GridTileLogo(
              onTap: () {
                Navigator.of(context).pop();
              },
              title: 'Mess',
              icon: Icon(
                requestMainPageElements['Mess']!['icon'],
                size: 50,
              ),
              color: theme.colorScheme.background,
            ),
            Expanded(
              child: GridView.extent(
                maxCrossAxisExtent: 300,
                childAspectRatio: 3 / 2,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
                children: [
                  GridTileLogo(
                    onTap: () {
                      navigatorPush(context, MenuChangeRequestScreen());
                    },
                    title: 'Menu Change',
                    icon: Icon(
                      MenuChangeRequest(requestingUserEmail: currentUser.email!)
                          .uiElement['icon'],
                      size: 50,
                    ),
                    color: MenuChangeRequest(
                            requestingUserEmail: currentUser.email!)
                        .uiElement['color'],
                  ),
                  // GridTileLogo(
                  //   onTap: () {},
                  //   title: 'Lunch',
                  //   icon: Icon(
                  //     Request.uiElements['Mess']!['Lunch']['icon'],
                  //     size: 50,
                  //   ),
                  //   color: Request.uiElements['Mess']!['Lunch']['color'],
                  // ),
                  // GridTileLogo(
                  //   onTap: () {},
                  //   title: 'Snacks',
                  //   icon: Icon(
                  //     Request.uiElements['Mess']!['Snacks']['icon'],
                  //     size: 50,
                  //   ),
                  //   color: Request.uiElements['Mess']!['Snacks']['color'],
                  // ),
                  // GridTileLogo(
                  //   onTap: () {},
                  //   title: 'Dinner',
                  //   icon: Icon(
                  //     Request.uiElements['Mess']!['Dinner']['icon'],
                  //     size: 50,
                  //   ),
                  //   color: Request.uiElements['Mess']!['Dinner']['color'],
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
