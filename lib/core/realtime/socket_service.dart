import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:thot/core/realtime/event_bus.dart';
import 'package:thot/core/network/api_config.dart';
import 'package:thot/core/monitoring/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();
  io.Socket? _socket;
  final EventBus _eventBus = EventBus();
  final _logger = LoggerService.instance;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  bool get isConnected => _isConnected;
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        _logger
            .warning('No auth token available, skipping socket initialization');
        return;
      }
      final apiBaseUrl = await ApiConfigService.getApiBaseUrl();
      final baseUrl = apiBaseUrl.replaceAll('/api', '').replaceAll(RegExp(r'/$'), '');
      _logger.info('Initializing socket connection to: $baseUrl');
      _socket = io.io(
        baseUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .setAuth({'token': 'Bearer $token'})
            .setTimeout(20000)
            .enableReconnection()
            .setReconnectionDelay(2000)
            .setReconnectionDelayMax(10000)
            .setReconnectionAttempts(5)
            .build(),
      );
      _setupEventHandlers();
      _socket!.connect();
    } catch (e) {
      _logger.error('Failed to initialize socket', e);
    }
  }
  void disconnect() {
    _cancelReconnectTimer();
    _isConnected = false;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _logger.info('Socket disconnected and disposed');
  }
  void reconnect() {
    disconnect();
    initialize();
  }
  void _setupEventHandlers() {
    if (_socket == null) return;
    _socket!.on('connect', (_) {
      _logger.info('Socket connected successfully');
      _isConnected = true;
      _reconnectAttempts = 0;
      _cancelReconnectTimer();
    });
    _socket!.on('connected', (data) {
      _logger.info('Server confirmed connection: $data');
    });
    _socket!.on('disconnect', (_) {
      _logger.warning('Socket disconnected');
      _isConnected = false;
      _scheduleReconnect();
    });
    _socket!.on('connect_error', (error) {
      _logger.error('Socket connection error', error);
      _isConnected = false;
      _scheduleReconnect();
    });
    _socket!.on('notification:new', _handleNewNotification);
    _socket!.on('post:updated', _handlePostUpdated);
    _socket!.on('post:liked', _handlePostLiked);
  }
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _logger.error('Max reconnection attempts reached');
      return;
    }
    _cancelReconnectTimer();
    final delay = Duration(seconds: 2 * (_reconnectAttempts + 1));
    _logger.info(
        'Scheduling reconnect attempt ${_reconnectAttempts + 1} in ${delay.inSeconds} seconds');
    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      if (_socket != null) {
        _socket!.connect();
      }
    });
  }
  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }
  void subscribeToPost(String postId) {
    if (_socket == null || !_isConnected) return;
    _socket!.emit('subscribe:post', postId);
    _logger.info('Subscribed to post: $postId');
  }
  void unsubscribeFromPost(String postId) {
    if (_socket == null || !_isConnected) return;
    _socket!.emit('unsubscribe:post', postId);
    _logger.info('Unsubscribed from post: $postId');
  }
  void subscribeToNotifications() {
    if (_socket == null || !_isConnected) return;
    _socket!.emit('subscribe:notifications');
    _logger.info('Subscribed to notifications');
  }
  void subscribeToUser(String userId) {
    if (_socket == null || !_isConnected) return;
    _socket!.emit('subscribe:user', userId);
    _logger.info('Subscribed to user: $userId');
  }
  void startTyping(String postId) {
    if (_socket == null || !_isConnected) return;
    _socket!.emit('typing:start', {'postId': postId});
  }
  void stopTyping(String postId) {
    if (_socket == null || !_isConnected) return;
    _socket!.emit('typing:stop', {'postId': postId});
  }
  void emit(String event, dynamic data) {
    if (_socket == null || !_isConnected) {
      _logger.warning('Cannot emit $event: socket not connected');
      return;
    }
    _socket!.emit(event, data);
    _logger.debug('Emitted event: $event');
  }
  void _handleNewNotification(dynamic data) {
    _logger.info('New notification: $data');
    _eventBus.fire(SocketNotificationEvent(notification: data));
  }
  void _handlePostUpdated(dynamic data) {
    _logger.info('Post updated: $data');
    _eventBus.fire(SocketPostEvent(
      type: 'updated',
      data: data,
    ));
  }
  void _handlePostLiked(dynamic data) {
    _logger.info('Post liked: $data');
    _eventBus.fire(SocketPostEvent(
      type: 'liked',
      data: data,
    ));
  }
}