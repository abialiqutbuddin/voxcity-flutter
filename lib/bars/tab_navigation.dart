import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:voxcity/screens/browser.dart';
import 'package:voxcity/screens/slack_screen.dart';
import 'package:voxcity/screens/vox/big_bus_screen.dart';
import 'package:voxcity/screens/vox/forecast_screen.dart';
import 'package:voxcity/screens/vox/product_bookings_screen.dart';
import 'package:voxcity/screens/vox/vox_wave.dart';
import 'package:voxcity/screens/vox/vox_zendesk_screen.dart';
import 'package:voxcity/screens/vox/walker_screen.dart';
import 'package:voxcity/screens/vox/whatsapp_web_screen.dart';
import 'package:voxcity/screens/ym/ym_wave.dart';
import 'package:voxcity/screens/ym/ym_zendesk_screen.dart';

import '../controller/screen_index.dart';
import '../screens/vox/zendesk.dart';

class TabNavigationScreen extends StatelessWidget {
  final GlobalController pageController = Get.put(GlobalController());

  TabNavigationScreen({super.key});

  final List<Map<String, dynamic>> _mainIcons = [
    {
      "icon": FontAwesomeIcons.v,
      "subpages": [
        // {
        //   "icon": FontAwesomeIcons.whatsapp,
        //   "page": const WebWhatsAppScreen(),
        // },
        // {
        //   "icon": FontAwesomeIcons.z,
        //   "page": const ZendeskScreen(),
        // },
        // {
        //   "icon": FontAwesomeIcons.w,
        //   "page": const VoxWave(),
        // },
        {
          "icon": FontAwesomeIcons.ticket,
          "page": const BookingForecastScreen(),
        },
        // Hidden pages
        {
          "icon": FontAwesomeIcons.personWalking,
          "page": const BookingPage(),
        },
        {
          "icon": FontAwesomeIcons.bus,
          "page": const BigBusBookingPage(),
        },
        {
          "icon": Icons.book,
          "page": Obx(() {
            final productPageDate = Get.find<GlobalController>().productPageDate.value;
            final productPageId = Get.find<GlobalController>().productPageId.value;
            return CustomerDetailsScreen(
              date: productPageDate,
              optionId: productPageId,
            );
          }),
        },
        {
          "icon": FontAwesomeIcons.z,
          "page": TicketsScreen(),
        },
      ],
    },
    // {
    //   "icon": FontAwesomeIcons.y,
    //   "subpages": [
    //     {
    //       "icon": FontAwesomeIcons.z,
    //       "page": const YMZendeskScreen(),
    //     },
    //     {
    //       "icon": FontAwesomeIcons.w,
    //       "page": const YMWave(),
    //     },
    //   ],
    // },
    // {
    //   "icon": FontAwesomeIcons.chrome,
    //   "subpages": [
    //     {
    //       "icon": FontAwesomeIcons.slack,
    //       "page": const SlackScreen(),
    //     },
    //     {
    //       "icon": FontAwesomeIcons.searchengin,
    //       "page": const ModernBrowser(),
    //     },
    //   ],
    // },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Main content area
          Expanded(
            child: Obx(() {
              final currentIndex = pageController.currentPageIndex.value;
              return IndexedStack(
                index: currentIndex,
                children: _mainIcons
                    .expand((mainIcon) => mainIcon["subpages"])
                    .map((subPage) {
                  return subPage["page"] as Widget;
                }).toList(),
              );
            }),
          ),
          // Right-side navigation bar
          Container(
            width: 80,
            color: Colors.grey[900],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Obx(() {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: _mainIcons
                          .asMap()
                          .entries
                          .map((mainEntry) {
                        final mainIndex = mainEntry.key;
                        final mainIcon = mainEntry.value;
                        final subPages = mainIcon["subpages"] as List<
                            Map<String, dynamic>>;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Main icon (non-clickable)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: FaIcon(
                                mainIcon["icon"],
                                color: Colors.grey[400],
                                size: 24,
                              ),
                            ),
                            ...subPages
                                .asMap()
                                .entries
                                .where((entry) {
                              final subPage = entry.value;
                              if (subPage["icon"] == Icons.book) {
                                return Get.find<GlobalController>().isProductPageOpen.value;
                              }
                              if (subPage["hidden"] == true) {
                                return false;
                              }
                              return true;
                            }).map((subEntry) {
                              final subIndex = subEntry.key;
                              final subPageIndex =
                                  _mainIcons.take(mainIndex).fold(
                                      0, (sum, icon) => sum +
                                      (icon["subpages"] as List).length) +
                                      subIndex;

                              return Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    pageController.updatePageIndex(
                                        subPageIndex);
                                  },
                                  child: Obx(() {
                                    final isSubSelected = pageController
                                        .currentPageIndex.value == subPageIndex;

                                    return AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 200),
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isSubSelected
                                            ? Colors.blueAccent
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                        boxShadow: isSubSelected
                                            ? [
                                          BoxShadow(
                                            color: Colors.blue.withOpacity(0.5),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          )
                                        ]
                                            : null,
                                      ),
                                      child: subEntry.value["icon"] != null
                                          ? FaIcon(
                                        subEntry.value["icon"],
                                        color: isSubSelected
                                            ? Colors.white
                                            : Colors.grey[400],
                                        size: 16,
                                      )
                                          : const SizedBox.shrink(),
                                    );
                                  }),
                                ),
                              );
                            }),
                            const Divider(thickness: 0.5,)
                          ],
                        );
                      }).toList(),
                    ),
                  );
                }
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}