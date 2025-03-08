import 'package:flutter/material.dart';

// Ekranlar
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/home_screen.dart';
import '../screens/user_profile_screen.dart';
import '../screens/profile_edit_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/change_password_screen.dart';
import '../screens/two_factor_auth_screen.dart';
import '../screens/saved_posts_screen.dart';
import '../screens/liked_posts_screen.dart';
import '../screens/liked_stories_screen.dart';
import '../screens/my_comments_screen.dart';
import '../screens/create_post_screen.dart';
import '../screens/add_story_screen.dart';
import '../screens/archived_posts_screen.dart';
import '../screens/archived_stories_screen.dart';
import '../screens/followers_screen.dart';
import '../screens/following_screen.dart';
import '../screens/profile_menu_screen.dart';
// Yeni eklenen sayfalar
import '../screens/notifications_screen.dart';
import '../screens/messages_screen.dart';
import '../screens/blocked_users_screen.dart';
import '../screens/explore_screen.dart';
import '../screens/activity_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String userProfile = '/user-profile';
  static const String profileEdit = '/edit-profile';
  static const String settings = '/settings';
  static const String changePassword = '/change-password';
  static const String twoFactorAuth = '/two-factor-auth';
  static const String savedPosts = '/saved-posts';
  static const String likedPosts = '/liked-posts';
  static const String likedStories = '/liked-stories';
  static const String myComments = '/my-comments';
  static const String createPost = '/create-post';
  static const String createStory = '/create-story';
  static const String archivedPosts = '/archived-posts';
  static const String archivedStories = '/archived-stories';
  static const String followers = '/followers';
  static const String following = '/following';
  static const String profileMenu = '/profile-menu';
  static const String connectedDevices = '/connected-devices';
  static const String privacySecurity = '/privacy-security';
  static const String helpSupport = '/help-support';
  static const String recoveryCode = '/recovery-codes';
  // Yeni route'lar
  static const String notifications = '/notifications';
  static const String messages = '/messages';
  static const String blockedUsers = '/blocked-users';
  static const String explore = '/explore';
  static const String activity = '/activity';

  // Uygulama route'larını ayarla
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      forgotPassword: (context) => const ForgotPasswordScreen(),
      home: (context) => const HomeScreen(),
      userProfile: (context) => const UserProfileScreen(),
      profileEdit: (context) => const ProfileEditScreen(),
      settings: (context) => const SettingsScreen(),
      changePassword: (context) => const ChangePasswordScreen(),
      twoFactorAuth: (context) => const TwoFactorAuthScreen(),
      savedPosts: (context) => const SavedPostsScreen(),
      likedPosts: (context) => const LikedPostsScreen(),
      likedStories: (context) => const LikedStoriesScreen(),
      myComments: (context) => const MyCommentsScreen(),
      createPost: (context) => const CreatePostScreen(),
      createStory: (context) => const AddStoryScreen(),
      archivedPosts: (context) => const ArchivedPostsScreen(),
      archivedStories: (context) => const ArchivedStoriesScreen(),
      followers: (context) => const FollowersScreen(),
      following: (context) => const FollowingScreen(),
      profileMenu: (context) => const ProfileMenuScreen(),
      // Yeni eklenen sayfalar
      notifications: (context) => const NotificationsScreen(),
      messages: (context) => const MessagesScreen(),
      blockedUsers: (context) => const BlockedUsersScreen(),
      explore: (context) => const ExploreScreen(),
      activity: (context) => const ActivityScreen(),
      // Diğer sayfalar eklendiğinde bu listeye eklenecek
    };
  }

  // Ana route'ları ayarla
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Route adını settings.name'den al
    final routeName = settings.name;
    
    // Switch case ile doğru route'u belirle
    if (routeName == login) {
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    } else if (routeName == register) {
      return MaterialPageRoute(builder: (_) => const RegisterScreen());
    } else if (routeName == forgotPassword) {
      return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
    } else if (routeName == home) {
      return MaterialPageRoute(builder: (_) => const HomeScreen());
    } else if (routeName == userProfile) {
      return MaterialPageRoute(builder: (_) => const UserProfileScreen());
    } else if (routeName == profileEdit) {
      return MaterialPageRoute(builder: (_) => const ProfileEditScreen());
    } else if (routeName == settings) {
      return MaterialPageRoute(builder: (_) => const SettingsScreen());
    } else if (routeName == changePassword) {
      return MaterialPageRoute(builder: (_) => const ChangePasswordScreen());
    } else if (routeName == twoFactorAuth) {
      return MaterialPageRoute(builder: (_) => const TwoFactorAuthScreen());
    } else if (routeName == savedPosts) {
      return MaterialPageRoute(builder: (_) => const SavedPostsScreen());
    } else if (routeName == likedPosts) {
      return MaterialPageRoute(builder: (_) => const LikedPostsScreen());
    } else if (routeName == likedStories) {
      return MaterialPageRoute(builder: (_) => const LikedStoriesScreen());
    } else if (routeName == myComments) {
      return MaterialPageRoute(builder: (_) => const MyCommentsScreen());
    } else if (routeName == createPost) {
      return MaterialPageRoute(builder: (_) => const CreatePostScreen());
    } else if (routeName == createStory) {
      return MaterialPageRoute(builder: (_) => const AddStoryScreen());
    } else if (routeName == archivedPosts) {
      return MaterialPageRoute(builder: (_) => const ArchivedPostsScreen());
    } else if (routeName == archivedStories) {
      return MaterialPageRoute(builder: (_) => const ArchivedStoriesScreen());
    } else if (routeName == followers) {
      return MaterialPageRoute(builder: (_) => const FollowersScreen());
    } else if (routeName == following) {
      return MaterialPageRoute(builder: (_) => const FollowingScreen());
    } else if (routeName == profileMenu) {
      return MaterialPageRoute(builder: (_) => const ProfileMenuScreen());
    } 
    // Yeni route'lar
    else if (routeName == notifications) {
      return MaterialPageRoute(builder: (_) => const NotificationsScreen());
    } else if (routeName == messages) {
      return MaterialPageRoute(builder: (_) => const MessagesScreen());
    } else if (routeName == blockedUsers) {
      return MaterialPageRoute(builder: (_) => const BlockedUsersScreen());
    } else if (routeName == explore) {
      return MaterialPageRoute(builder: (_) => const ExploreScreen());
    } else if (routeName == activity) {
      return MaterialPageRoute(builder: (_) => const ActivityScreen());
    }
        
    // Route bulunamazsa veya ek parametreler gerekiyorsa
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(
          child: Text('Sayfa bulunamadı: ${settings.name}'),
        ),
      ),
    );
  }
} 