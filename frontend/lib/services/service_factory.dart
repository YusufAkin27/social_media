import 'package:dio/dio.dart';
import 'package:social_media/services/authService.dart';
import 'package:social_media/services/friendRequestService.dart';
import 'package:social_media/services/studentService.dart';
import 'package:social_media/services/logService.dart';
import 'package:social_media/services/followRelationService.dart';
import 'package:social_media/services/storyService.dart';
import 'package:social_media/services/chat_service.dart';

/// ServiceFactory sınıfı, uygulama içindeki tüm servisleri merkezi olarak yönetir.
/// Her servis, token yenileme mekanizması içeren aynı Dio örneğini kullanır.
class ServiceFactory {
  static final ServiceFactory _instance = ServiceFactory._internal();
  Dio? _sharedDio;
  bool _isInitialized = false;

  // Lazy-loaded services
  AuthService? _authService;
  FriendRequestService? _friendRequestService;
  LogService? _logService;
  FollowRelationService? _followRelationService;
  StoryService? _storyService;
  ChatService? _chatService;
  StudentService? _studentService;

  // Factory constructor
  factory ServiceFactory() {
    return _instance;
  }

  // Private constructor
  ServiceFactory._internal();

  // Initialization
  Future<void> initialize() async {
    if (!_isInitialized) {
      _sharedDio = await AuthService.getDio();
      _isInitialized = true;
    }
  }

  // Auth Service
  Future<AuthService> get authService async {
    await initialize();
    return _authService ??= AuthService();
  }

  // Friend Request Service
  Future<FriendRequestService> get friendRequestService async {
    await initialize();
    return _friendRequestService ??= FriendRequestService();
  }

  // Log Service
  Future<LogService> get logService async {
    await initialize();
    _logService ??= LogService(_sharedDio!);
    return _logService!;
  }

  // Follow Relation Service
  Future<FollowRelationService> get followRelationService async {
    await initialize();
    _followRelationService ??= FollowRelationService(_sharedDio!);
    return _followRelationService!;
  }

  // Story Service
  Future<StoryService> get storyService async {
    await initialize();
    _storyService ??= StoryService(_sharedDio!);
    return _storyService!;
  }

  // Chat Service
  Future<ChatService> get chatService async {
    await initialize();
    _chatService ??= ChatService(_sharedDio!);
    return _chatService!;
  }

  // Student Service
  Future<StudentService> get studentService async {
    await initialize();
    _studentService ??= StudentService();
    return _studentService!;
  }

  // Token yenileme işlemini manuel olarak tetikleme metodu
  Future<bool> refreshTokenManually() async {
    final auth = await authService;
    return await auth.refreshToken();
  }
} 