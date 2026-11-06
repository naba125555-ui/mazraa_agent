import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models.dart';
import '../domain/ports.dart';

const baseUrl=String.fromEnvironment('API_BASE_URL',defaultValue:'https://mzraa.runasp.net');
class RemoteRepository implements AgentRepository {
  RemoteRepository({Dio? client,Dio? refreshClient,FlutterSecureStorage? secure})
      : client=client??Dio(BaseOptions(baseUrl:baseUrl,connectTimeout:const Duration(seconds:15),
          receiveTimeout:const Duration(seconds:25),sendTimeout:const Duration(seconds:25),headers:{'Accept':'application/json'})),
        refreshClient=refreshClient??Dio(BaseOptions(baseUrl:baseUrl,connectTimeout:const Duration(seconds:15),receiveTimeout:const Duration(seconds:20))),
        secure=secure??const FlutterSecureStorage(aOptions:AndroidOptions(encryptedSharedPreferences:true)) {
    this.client.interceptors.add(InterceptorsWrapper(onRequest:(o,h){
      if(!_sameOrigin(o.path)||o.extra['epoch']!=epoch) {
        return h.reject(DioException(requestOptions:o,type:DioExceptionType.cancel));
      }
      if(!_auth(o.path)&&session!=null) o.headers['Authorization']='Bearer ${session!.token}';
      h.next(o);
    },onError:(e,h)async{
      final o=e.requestOptions,old=session,oldEpoch=epoch;
      if(e.response?.statusCode!=401||_auth(o.path)||old==null||o.extra['epoch']!=epoch)return h.next(e);
      if(o.extra['retried']==true){await _expire(oldEpoch);return h.next(e);}
      try {
        final next=o.headers['Authorization']!='Bearer ${old.token}'?old:await _rotate(old,oldEpoch);
        if(next==null||epoch!=oldEpoch)return h.next(e);
        o.extra['retried']=true;o.headers['Authorization']='Bearer ${next.token}';
        if(o.data is FormData)o.data=(o.data as FormData).clone();
        h.resolve(await this.client.fetch<dynamic>(o));
      }on DioException catch(refreshError){
        if(refreshError.response?.statusCode==401)await _expire(oldEpoch);
        h.next(e);
      }catch(_){h.next(e);}
    }));
  }
  final Dio client,refreshClient;
  final FlutterSecureStorage secure;
  @override Session? session;
  @override int epoch=0;
  @override void Function()? onExpired;
  Future<Session?>? _rotating;int? _rotatingEpoch;
  bool _auth(String p)=>p.toLowerCase().startsWith('/api/auth/');
  bool _sameOrigin(String p){final uri=Uri.tryParse(p);return uri!=null&&(!uri.hasAuthority||uri.origin==Uri.parse(baseUrl).origin);}
  @override Future<void> restore()async{
    final text=await secure.read(key:'session');if(text==null)return;
    try{final value=Session(obj(jsonDecode(text)));if(value.usable)session=value;}on FormatException{await secure.delete(key:'session');}
  }
  Future<void> _expire(int expected)async{
    if(epoch!=expected)return;
    epoch++;session=null;await secure.delete(key:'session');onExpired?.call();
  }
  Future<Session?> _rotate(Session old,int expected){
    if(_rotating!=null&&_rotatingEpoch==expected)return _rotating!;
    _rotatingEpoch=expected;
    final future=()async{
      final r=await refreshClient.post<dynamic>('/api/auth/refresh',data:{'refreshToken':old.refresh,'deviceName':'mazraa-agent'});
      final next=Session(obj(r.data));
      if(epoch!=expected||session?.refresh!=old.refresh||!next.usable||old.userId!=next.userId)return null;
      session=next;await secure.write(key:'session',value:jsonEncode(next.json));return next;
    }();
    _rotating=future;return future.whenComplete((){if(identical(_rotating,future))_rotating=null;});
  }
  @override Future<void> login(String email,String password)async{
    final value=Session(obj(await write('POST','/api/auth/login',{'email':email.trim(),'password':password,'deviceName':'mazraa-agent'})));
    if(!value.usable)throw const Failure(401,'');
    epoch++;session=value;await secure.write(key:'session',value:jsonEncode(value.json));
  }
  @override Future<void> logout()async{
    final old=session;
    // The local session ends even if the remote logout is unavailable.
    if(old!=null){try{await write('POST','/api/auth/logout',{'refreshToken':old.refresh});}catch(_){}}
    await _expire(epoch);
  }
  Failure _failure(DioException e){
    final raw=e.response?.data,map=obj(raw);
    var message=str(map['message']??map['detail']??map['title']);
    if(map['errors'] is Map)message=obj(map['errors']).values.expand((v)=>v is List?v:[v]).join('\n');
    if(raw is String&&raw.length<1000&&!raw.contains('<'))message=raw;
    return Failure(e.response?.statusCode??0,message,uncertain:e.response==null&&e.type!=DioExceptionType.cancel);
  }
  Future<dynamic> _request(String method,String path,{Object? body,Json? query})async{
    if(!_sameOrigin(path))throw const Failure(403,'');
    final expected=epoch;
    try{
      final r=await client.request<dynamic>(path,data:body,queryParameters:query,options:Options(method:method,extra:{'epoch':expected}));
      if(epoch!=expected)throw const Failure(401,'');
      return r.data;
    }on DioException catch(e){throw _failure(e);}
  }
  @override Future<dynamic> read(String path,{Json? query})=>_request('GET',path,query:query);
  @override Future<dynamic> write(String method,String path,Object? body)=>_request(method,path,body:body);
  @override Future<Uint8List> download(String path)async{
    if(!_sameOrigin(path))throw const Failure(403,'');
    final expected=epoch;
    try{final r=await client.get<List<int>>(path,options:Options(responseType:ResponseType.bytes,extra:{'epoch':expected}));
      if(expected!=epoch)throw const Failure(401,'');return Uint8List.fromList(r.data??[]);
    }on DioException catch(e){throw _failure(e);}
  }
  @override Future<dynamic> upload(String path,String name,Uint8List bytes,Json fields)=>write('POST',path,
    FormData.fromMap({...fields,'file':MultipartFile.fromBytes(bytes,filename:name)}));
  @override Future<String?> local(String key,{bool secure=false})async=>secure?this.secure.read(key:key):(await SharedPreferences.getInstance()).getString(key);
  @override Future<void> save(String key,String? value,{bool secure=false})async{
    if(secure){if(value==null){await this.secure.delete(key:key);}else{await this.secure.write(key:key,value:value);}return;}
    final prefs=await SharedPreferences.getInstance();if(value==null){await prefs.remove(key);}else{await prefs.setString(key,value);}
  }
}
