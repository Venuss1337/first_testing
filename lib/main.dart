import 'package:first_testing/pages/login.dart';
import 'package:first_testing/repository/chat_cubit.dart';
import 'package:first_testing/repository/chat_repository.dart';
import 'package:first_testing/services/encryption_service.dart';
import 'package:first_testing/services/mqtt_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/adapters.dart';
import './pages/menu.dart';
import 'models/active_chat.dart';
import 'models/chat_message.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  
  Hive.registerAdapter(ChatMessageAdapter());
  Hive.registerAdapter(ActiveChatAdapter());

  await Hive.openBox<ChatMessage>(ChatRepository.MESSAGE_BOX);
  await Hive.openBox<ActiveChat>(ChatRepository.CHAT_BOX);

  final repository = ChatRepository();

  final encryptionService = MessageEncryptionService(encryptionKey: 'encryptionKey');

  final secureStorage = FlutterSecureStorage();

  final mqttService = MqttService(
    server: 'mqtt://localhost',
    clientId: secureStorage.read(key:"userId").toString(),
    encryptionService: encryptionService,
    port: 1883,
  );

  runApp(TestApp(
    repository: repository,
    mqttService: mqttService,
    encryptionService: encryptionService
  ));
}
class TestApp extends StatelessWidget {
  final ChatRepository repository;
  final MqttService mqttService;
  final MessageEncryptionService encryptionService;

  const TestApp({
    super.key,
    required this.repository,
    required this.mqttService,
    required this.encryptionService
  })

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Filagram',
      home: BlocProvider(create: (context) => ChatCubit(
        repository: repository,
        mqttService: mqttService,
        encryptionService: encryptionService,
      ),
      child: LoginPage()
      )
      // TODO: Add app routes here if needed
    );
  }
}