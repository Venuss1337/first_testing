import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'encryption_service.dart';

/// Service to handle MQTT communication
class MqttService {
  late MqttServerClient client;
  final String server;
  final String clientId;
  final int port;
  final MessageEncryptionService encryptionService;

  /// Callback for new messages
  /// Parameters: (topic, decryptedMessage)
  Function(String, String)? onMessageReceived;

  MqttService({
    required this.server,
    required this.clientId,
    required this.encryptionService,
    this.port = 1883,
  });

  /// Connect to the MQTT broker
  Future<MqttServerClient> connect() async {
    client = MqttServerClient.withPort(server, clientId, port);
    client.logging(on: false);
    client.keepAlivePeriod = 60;
    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;

    // Optional: Add authentication if your broker requires it
    // client.authenticateAs('username', 'password');

    try {
      await client.connect();
    } catch (e) {
      print('MQTT Exception: $e');
      client.disconnect();
    }

    // Set up message handler
    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (var msg in messages) {
        final recMess = msg.payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

        try {
          final decryptedMessage = encryptionService.decryptMessage(payload);
          if (onMessageReceived != null) {
            onMessageReceived!(msg.topic, decryptedMessage);
          }
        } catch (e) {
          print('Decryption error: $e');
          // TODO: Implement error handling for failed decryption
        }
      }
    });

    return client;
  }

  /// Subscribe to a topic
  void subscribe(String topic) {
    client.subscribe(topic, MqttQos.atLeastOnce);
  }

  /// Handle successful connection
  void _onConnected() {
    print('Connected to MQTT broker');
    // TODO: Implement reconnection of all active subscriptions if needed
  }

  /// Handle disconnection
  void _onDisconnected() {
    print('Disconnected from MQTT broker');
    // TODO: Implement reconnection logic if needed
  }

  /// Publish a message to a topic
  void publishMessage(String topic, String message) {
    final encryptedMessage = encryptionService.encryptMessage(message);
    final builder = MqttClientPayloadBuilder();
    builder.addString(encryptedMessage);
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  /// Extract the chat ID from a topic
  /// Expected format: chat/{id}/inbox or chat/{id}/outbox
  String extractChatIdFromTopic(String topic) {
    final parts = topic.split('/');
    if (parts.length >= 2) {
      return parts[1];
    }
    return '';
  }
}