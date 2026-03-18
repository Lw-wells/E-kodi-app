import 'package:flutter_dotenv/flutter_dotenv.dart';

void testEnv() {
  print('🔍 Testing .env loading...');
  print('FIREBASE_WEB_API_KEY: ${dotenv.env['FIREBASE_WEB_API_KEY']}');
  print('FIREBASE_PROJECT_ID: ${dotenv.env['FIREBASE_PROJECT_ID']}');
  print('FIREBASE_MESSAGING_SENDER_ID: ${dotenv.env['FIREBASE_MESSAGING_SENDER_ID']}');
}