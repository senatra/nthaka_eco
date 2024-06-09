import 'package:nthaka_eco/components/colors.dart';
import 'package:nthaka_eco/global/widgets/app_styles.dart';
import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:flutter/material.dart';
import 'package:nthaka_eco/screens/home/home_screen.dart';
import 'package:nthaka_eco/screens/items/item_screen.dart';
class BottomBar extends StatefulWidget {
  const BottomBar({Key? key}) : super(key: key);

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  int _selectIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    ItemsScreen(),
    // const ProfilePage()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: _widgetOptions[_selectIndex],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectIndex,
          onTap: _onItemTapped,
          elevation: 10,
          showSelectedLabels: false,
          showUnselectedLabels: true,
          selectedItemColor: kPrimaryColor,
          unselectedItemColor: kOtherColor,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Styles.bgcolor,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(FluentSystemIcons.ic_fluent_home_regular),
              activeIcon: Icon(FluentSystemIcons.ic_fluent_home_filled),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(FluentSystemIcons.ic_fluent_history_regular),
              activeIcon: Icon(FluentSystemIcons.ic_fluent_history_filled),
              label: "Items",
            ),
             BottomNavigationBarItem(
              icon: Icon(FluentSystemIcons.ic_fluent_history_regular),
              activeIcon: Icon(FluentSystemIcons.ic_fluent_book_formula_compatibility_filled),
              label: "Inventory",
            ),
       
          ],
        ),
      ),
    );
  }
}
