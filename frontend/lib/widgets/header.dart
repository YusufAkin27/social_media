import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class Header extends StatefulWidget {
  final String title;
  final int notificationCount;
  final int messageCount;
  final VoidCallback? onTitleTap;
  final ScrollController? scrollController;

  const Header({
    Key? key,
    required this.title,
    this.notificationCount = 0,
    this.messageCount = 0,
    this.onTitleTap,
    this.scrollController,
  }) : super(key: key);

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _scrollAnimController;
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  
  // Animations
  late Animation<double> _headerSlideAnimation;
  late Animation<double> _headerOpacityAnimation;
  late Animation<double> _blurAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  
  // Scroll state tracking
  bool _isScrollingDown = false;
  double _previousScrollOffset = 0;
  double _scrollOffset = 0;
  double _lastMaxScrollExtent = 0;
  bool _headerVisible = true;

  @override
  void initState() {
    super.initState();
    
    // Initialize scroll animation controller
    _scrollAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0, // Start visible
    );
    
    // Scale animation controller for header elements
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    
    // Pulse animation for badges
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseController.repeat(reverse: true);
    
    // Header slide in/out animation
    _headerSlideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _scrollAnimController,
        curve: Curves.easeOutBack,
      ),
    );
    
    // Header opacity animation
    _headerOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scrollAnimController,
        curve: Curves.easeOut,
      ),
    );
    
    // Blur effect when scrolling
    _blurAnimation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(
        parent: _scrollAnimController,
        curve: Curves.easeOut,
      ),
    );
    
    // Scale animation for header elements
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeOutBack,
      ),
    );
    
    // Pulse animation for badges
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    // ScrollController listener for header show/hide
    if (widget.scrollController != null) {
      widget.scrollController!.addListener(_handleScroll);
    }
  }

  void _handleScroll() {
    if (widget.scrollController == null) return;
    
    // Get current scroll position
    final currentScrollOffset = widget.scrollController!.offset;
    final maxScrollExtent = widget.scrollController!.position.maxScrollExtent;
    
    // Determine scroll direction
    final isScrollingDown = currentScrollOffset > _previousScrollOffset;
    
    // Check if we need to update state
    if (currentScrollOffset != _scrollOffset || 
        maxScrollExtent != _lastMaxScrollExtent || 
        isScrollingDown != _isScrollingDown) {
      
      // Update scroll state
      setState(() {
        _scrollOffset = currentScrollOffset;
        _lastMaxScrollExtent = maxScrollExtent;
        _isScrollingDown = isScrollingDown;
        
        // Show/hide header based on scroll direction and position
        if (_isScrollingDown && currentScrollOffset > 30) {
          // Hide header when scrolling down past 30px
          if (_headerVisible) {
            _headerVisible = false;
            _scrollAnimController.reverse();
            _scaleController.reverse();
          }
        } else if (!_isScrollingDown) {
          // Show header when scrolling up
          if (!_headerVisible) {
            _headerVisible = true;
            _scrollAnimController.forward();
            _scaleController.forward();
          }
        }
      });
    }
    
    // Update previous scroll position
    _previousScrollOffset = currentScrollOffset;
  }

  @override
  void dispose() {
    if (widget.scrollController != null) {
      widget.scrollController!.removeListener(_handleScroll);
    }
    
    // Safely dispose controllers
    _scrollAnimController.dispose();
    _pulseController.dispose();
    _scaleController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;
    
    // Responsive sizing
    final iconSize = math.min(26.0, size.width * 0.065);
    final badgeSize = math.min(14.0, size.width * 0.035);
    final badgeFontSize = math.min(9.0, size.width * 0.022);
    final paddingHorizontal = math.min(16.0, size.width * 0.04);
    final headerHeight = math.min(52.0, size.height * 0.06) + safeArea.top;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_scrollAnimController, _pulseController, _scaleController]),
      builder: (context, child) {
        // Calculate translation for header hiding/showing
        final headerTranslation = headerHeight * _headerSlideAnimation.value;
        
        return Transform.translate(
          offset: Offset(0, headerTranslation),
          child: Transform.scale(
            scale: _headerVisible ? 1.0 : 0.95,
            alignment: Alignment.topCenter,
            child: Opacity(
              opacity: _headerOpacityAnimation.value,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: _blurAnimation.value,
                    sigmaY: _blurAnimation.value,
                  ),
                  child: Container(
                    height: headerHeight,
                    width: size.width,
                    padding: EdgeInsets.only(top: safeArea.top),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Title with subtle shimmer effect
                            GestureDetector(
                              onTap: widget.onTitleTap,
                              child: _buildTitle(),
                            ),
                            
                            // Right side buttons
                            Row(
                              children: [
                                // Notifications button
                                _buildIconButton(
                                  icon: CupertinoIcons.bell,
                                  badgeCount: widget.notificationCount,
                                  iconSize: iconSize,
                                  badgeSize: badgeSize,
                                  badgeFontSize: badgeFontSize,
                                  onTap: () => _navigateToNotificationsScreen(context),
                                ),
                                SizedBox(width: math.min(20, size.width * 0.045)),
                                
                                // Messages button
                                _buildIconButton(
                                  icon: CupertinoIcons.chat_bubble,
                                  badgeCount: widget.messageCount,
                                  iconSize: iconSize,
                                  badgeSize: badgeSize,
                                  badgeFontSize: badgeFontSize,
                                  onTap: () => _navigateToMessagesScreen(context),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  void _navigateToNotificationsScreen(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.pushNamed(context, '/notifications');
  }
  
  void _navigateToMessagesScreen(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.pushNamed(context, '/messages');
  }

  Widget _buildTitle() {
    return Text(
      widget.title,
      style: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.5,
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(reverse: true),
    ).shimmer(
      duration: 3000.ms,
      color: Colors.white30,
      curve: Curves.easeInOutSine,
    ).animate().fadeIn(
      duration: 300.ms,
      curve: Curves.easeOut,
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required int badgeCount,
    required double iconSize,
    required double badgeSize,
    required double badgeFontSize,
    required VoidCallback onTap,
  }) {
    final badgeScale = _pulseAnimation.value;
    final hasItems = badgeCount > 0;
    
    return Container(
      height: iconSize * 1.8,
      width: iconSize * 1.8,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(iconSize),
          splashColor: Colors.white.withOpacity(0.15),
          highlightColor: Colors.white.withOpacity(0.05),
          onTap: onTap,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Icon with subtle animated glow effect when has notifications
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: hasItems ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.15),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ] : null,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
              
              // Badge with custom animation
              if (badgeCount > 0)
                Positioned(
                  top: iconSize * 0.12,
                  right: iconSize * 0.12,
                  child: Transform.scale(
                    scale: badgeScale,
                    child: Container(
                      width: badgeSize,
                      height: badgeSize,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 2,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          badgeCount > 9 ? '9+' : badgeCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: badgeFontSize,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              
              // Ripple effect indicator when has notifications
              if (hasItems)
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(
      duration: 250.ms,
      curve: Curves.easeOut,
    );
  }
} 