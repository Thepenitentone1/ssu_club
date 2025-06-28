import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';

class NotificationBadge extends StatelessWidget {
  final Widget child;
  final double? size;
  final Color? badgeColor;
  final Color? textColor;
  final VoidCallback? onTap;

  const NotificationBadge({
    super.key,
    required this.child,
    this.size,
    this.badgeColor,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return child;

    return StreamBuilder<int>(
      stream: NotificationService().getUnreadNotificationsCount(currentUser.uid),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        
        return GestureDetector(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              child,
              if (unreadCount > 0)
                Positioned(
                  right: -8,
                  top: -8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: badgeColor ?? Colors.red,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                    constraints: BoxConstraints(
                      minWidth: size ?? 20,
                      minHeight: size ?? 20,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: TextStyle(
                        color: textColor ?? Colors.white,
                        fontSize: (size ?? 20) * 0.6,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class NotificationIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final VoidCallback? onTap;

  const NotificationIcon({
    super.key,
    this.size = 24,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationBadge(
      onTap: onTap,
      child: Icon(
        Icons.notifications,
        size: size,
        color: color ?? Theme.of(context).iconTheme.color,
      ),
    );
  }
}

class NotificationButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String? label;
  final IconData? icon;
  final double? size;

  const NotificationButton({
    super.key,
    this.onTap,
    this.label,
    this.icon,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationBadge(
      onTap: onTap,
      child: icon != null
          ? Icon(
              icon,
              size: size ?? 24,
              color: Theme.of(context).iconTheme.color,
            )
          : Text(
              label ?? 'Notifications',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
    );
  }
} 