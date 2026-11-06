import 'dart:typed_data';
import 'models.dart';

abstract interface class AgentRepository {
  Session? get session;
  int get epoch;
  Future<void> restore();
  Future<void> login(String email,String password);
  Future<void> logout();
  Future<dynamic> read(String path,{Json? query});
  Future<dynamic> write(String method,String path,Object? body);
  Future<Uint8List> download(String path);
  Future<dynamic> upload(String path,String name,Uint8List bytes,Json fields);
  Future<String?> local(String key,{bool secure=false});
  Future<void> save(String key,String? value,{bool secure=false});
  set onExpired(void Function()? callback);
}
