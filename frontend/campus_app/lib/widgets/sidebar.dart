import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:social_media/screens/user_profile_screen.dart';
import 'package:flutter/services.dart';

class Sidebar extends StatefulWidget {
  final String profilePhotoUrl;
  final int initialIndex;

  const Sidebar({
    Key? key, 
    required this.profilePhotoUrl, 
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _animationController;
  final List<String> _tooltips = [
    'Ana Sayfa', 
    'Keşfet', 
    'Paylaş', 
    'Aktivite', 
    'Profil'
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(
            color: Colors.white12,
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Active indicator - animating pill
          if (_currentIndex != 2) // Don't show for the center "add" button
            AnimatedPositioned(
              duration: Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              top: 0,
              left: MediaQuery.of(context).size.width / 5 * _currentIndex + 
                  (MediaQuery.of(context).size.width / 5 - 40) / 2,
              child: Container(
                width: 40,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(5)),
                ),
              ),
            ),
          
          // Navigation items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, LineIcons.home, 28),
              _buildNavItem(1, LineIcons.search, 28),
              _buildCreateButton(),
              _buildNavItem(3, LineIcons.bell, 26),
              _buildProfileItem(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, double size) {
    final bool isSelected = _currentIndex == index;
    
    return Expanded(
      child: Tooltip(
        message: _tooltips[index],
        child: InkWell(
          onTap: () => _onNavigationTap(index),
          highlightColor: Colors.transparent,
          splashColor: Colors.white10,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with animation
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.all(isSelected ? 10 : 6),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : Colors.white60,
                    size: size,
                  ),
                ),
                
                // Label with animation
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  height: isSelected ? 16 : 0,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: isSelected ? 1.0 : 0.0,
                      duration: Duration(milliseconds: 200),
                      child: Text(
                        _tooltips[index],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return Expanded(
      child: Tooltip(
        message: _tooltips[2],
        child: InkWell(
          onTap: () => _onNavigationTap(2),
          highlightColor: Colors.transparent,
          splashColor: Colors.white10,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple, Colors.blue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: _currentIndex == 2 ? 8 : 0,
                        spreadRadius: _currentIndex == 2 ? 2 : 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    LineIcons.plus,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                
                // Label
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  height: _currentIndex == 2 ? 16 : 0,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _currentIndex == 2 ? 1.0 : 0.0,
                      duration: Duration(milliseconds: 200),
                      child: Text(
                        _tooltips[2],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem() {
    final bool isSelected = _currentIndex == 4;
    
    return Expanded(
      child: Tooltip(
        message: _tooltips[4],
        child: InkWell(
          onTap: () => _onNavigationTap(4),
          highlightColor: Colors.transparent,
          splashColor: Colors.white10,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: Colors.white.withOpacity(0.2),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundImage: NetworkImage(widget.profilePhotoUrl),
                    backgroundColor: Colors.grey[900],
                  ),
                ),
                
                // Label
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  height: isSelected ? 16 : 0,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: isSelected ? 1.0 : 0.0,
                      duration: Duration(milliseconds: 200),
                      child: Text(
                        _tooltips[4],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onNavigationTap(int index) {
    // Only perform haptic feedback and animation if the index is changing
    if (_currentIndex != index) {
      HapticFeedback.lightImpact();
      
      setState(() {
        _currentIndex = index;
      });

      _animationController.reset();
      _animationController.forward();
    }
    
    switch (index) {
      case 0:
        if (ModalRoute.of(context)?.settings.name != '/home') {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
        break;
      case 1:
        Navigator.pushNamed(context, '/explore');
        break;
      case 2:
        Navigator.pushNamed(context, '/create-post');
        break;
      case 3:
        Navigator.pushNamed(context, '/activity');
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => UserProfileScreen()),
        );
        break;
    }
  }
}
