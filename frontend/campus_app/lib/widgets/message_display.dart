import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';

class MessageDisplay extends StatefulWidget {
  final String message;
  final bool isSuccess;
  final int maxCharacters;
  final VoidCallback? onDismiss;
  final Duration displayDuration;

  const MessageDisplay({
    Key? key,
    required this.message,
    required this.isSuccess,
    this.maxCharacters = 150,
    this.onDismiss,
    this.displayDuration = const Duration(seconds: 5),
  }) : super(key: key);

  @override
  State<MessageDisplay> createState() => _MessageDisplayState();
}

class _MessageDisplayState extends State<MessageDisplay> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  bool _showDetails = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _slideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _animationController.forward();
    
    // Auto-dismiss the message after the specified duration if onDismiss is provided
    if (widget.onDismiss != null) {
      Future.delayed(widget.displayDuration, () {
        if (mounted) {
          _animationController.reverse().then((_) {
            widget.onDismiss!();
          });
        }
      });
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Truncate the message if it exceeds the max length and we're not showing details
    String displayMessage = (!_showDetails && widget.message.length > widget.maxCharacters)
        ? '${widget.message.substring(0, widget.maxCharacters)}...'
        : widget.message;
        
    bool isLongMessage = widget.message.length > widget.maxCharacters;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: widget.isSuccess 
                ? Colors.white.withOpacity(0.3) 
                : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isLongMessage ? () {
                    setState(() {
                      _showDetails = !_showDetails;
                    });
                  } : null,
                  splashColor: Colors.white.withOpacity(0.1),
                  highlightColor: Colors.white.withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status icon with gradient background
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: widget.isSuccess
                                ? const LinearGradient(
                                    colors: [Colors.white, Color(0xFFE0E0E0)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : const LinearGradient(
                                    colors: [Colors.white, Color(0xFFBDBDBD)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                          ),
                          child: Center(
                            child: Icon(
                              widget.isSuccess ? LineIcons.checkCircle : LineIcons.exclamationCircle,
                              color: Colors.black,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Message content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.isSuccess ? 'Başarılı' : 'Uyarı',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                displayMessage,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                  letterSpacing: 0.25,
                                ),
                              ),
                              if (isLongMessage && !_showDetails)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LineIcons.angleDown,
                                        size: 14,
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Detayları Göster",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.6),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (isLongMessage && _showDetails)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LineIcons.angleUp,
                                        size: 14,
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Küçült",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.6),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        // Dismiss button
                        if (widget.onDismiss != null)
                          IconButton(
                            onPressed: () {
                              _animationController.reverse().then((_) {
                                widget.onDismiss!();
                              });
                            },
                            icon: Icon(
                              LineIcons.times,
                              color: Colors.white.withOpacity(0.6),
                              size: 18,
                            ),
                            splashRadius: 20,
                            tooltip: 'Kapat',
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Progress bar for auto-dismiss
              if (widget.onDismiss != null)
                SizedBox(
                  height: 2,
                  child: TweenAnimationBuilder<double>(
                    duration: widget.displayDuration,
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return LinearProgressIndicator(
                        value: value,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.isSuccess ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.2),
                        ),
                        minHeight: 2,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}