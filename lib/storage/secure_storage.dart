import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();

Future<void> saveYMLoginInfo(String username, String password) async {
  await storage.write(key: 'ym_zendesk_username', value: username);
  await storage.write(key: 'ym_zendesk_password', value: password);
}

Future<Map<String, String?>> getYMLoginInfo() async {
  final username = await storage.read(key: 'ym_zendesk_username');
  final password = await storage.read(key: 'ym_zendesk_password');
  return {'username': username, 'password': password};
}

Future<void> saveVoxLoginInfo(String username, String password) async {
  await storage.write(key: 'vox_zendesk_username', value: username);
  await storage.write(key: 'vox_zendesk_password', value: password);
}

Future<Map<String, String?>> getVoxLoginInfo() async {
  final username = await storage.read(key: 'vox_zendesk_username');
  final password = await storage.read(key: 'vox_zendesk_password');
  return {'username': username, 'password': password};
}

Future<void> saveVoxWaveLoginInfo(String username, String password) async {
  await storage.write(key: 'vox_wave_zendesk_username', value: username);
  await storage.write(key: 'vox_wave_zendesk_password', value: password);
}

Future<Map<String, String?>> getVoxWaveLoginInfo() async {
  final username = await storage.read(key: 'vox_wave_zendesk_username');
  final password = await storage.read(key: 'vox_wave_zendesk_password');
  return {'username': username, 'password': password};
}

Future<void> saveYMWaveLoginInfo(String username, String password) async {
  await storage.write(key: 'ym_wave_zendesk_username', value: username);
  await storage.write(key: 'ym_wave_zendesk_password', value: password);
}

Future<Map<String, String?>> getYMWaveLoginInfo() async {
  final username = await storage.read(key: 'ym_wave_zendesk_username');
  final password = await storage.read(key: 'ym_wave_zendesk_password');
  return {'username': username, 'password': password};
}