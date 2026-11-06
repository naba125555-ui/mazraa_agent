import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../domain/models.dart';
import '../domain/ports.dart';
import '../domain/screens.dart';

String uuid(){
  final r=Random.secure(),b=List<int>.generate(16,(_)=>0);
  for(var i=0;i<16;i++){b[i]=r.nextInt(256);}b[6]=(b[6]&15)|64;b[8]=(b[8]&63)|128;
  final s=b.map((v)=>v.toRadixString(16).padLeft(2,'0')).join();
  return '${s.substring(0,8)}-${s.substring(8,12)}-${s.substring(12,16)}-${s.substring(16,20)}-${s.substring(20)}';
}
class AgentApp extends ChangeNotifier {
  AgentApp(this.repo){repo.onExpired=(){_reset();notifyListeners();};}
  final AgentRepository repo;
  String language='ar',theme='system';bool starting=true,loading=false;
  Object? accessError;
  Json bootstrap={},profile={},summary={},user={};
  Access access=const Access();int? grantId;int revision=0;
  final List<Json> basket=[];Json sale={},auctionDraft={},prescriptionDraft={};
  final Map<String,Json> _records={};
  bool get signedIn=>repo.session!=null;
  bool get ar=>language=='ar';
  String tr(String arabic,String english)=>ar?arabic:english;
  String get currency=>str(bootstrap['currency']??summary['catalogCurrency']);
  Grant? get grant=>access.grants.where((g)=>g.id==grantId&&g.active).firstOrNull;
  bool allows(int mask)=>grant?.allows(mask)??false;
  bool canOpen(ScreenSpec s)=>(!s.doctor||access.doctor)&&(s.cap==0||allows(s.cap))&&
      (s.id!='C13'||access.dispenser);
  Future<void> initialize()async{
    try{
      language=await repo.local('language')??'ar';theme=await repo.local('theme')??'system';
      await repo.restore().timeout(const Duration(seconds:6));
      if(signedIn)await refreshAccess();
    }catch(e){accessError=e;}
    starting=false;notifyListeners();
  }
  Future<void> login(String email,String password)async{
    await repo.login(email,password);_reset();notifyListeners();await refreshAccess();
  }
  void _reset(){bootstrap={};profile={};summary={};user={};access=const Access();grantId=null;
    _records.clear();basket.clear();sale={};auctionDraft={};prescriptionDraft={};revision++;}
  Future<void> refreshAccess()async{
    if(!signedIn)return;final epoch=repo.epoch;loading=true;accessError=null;notifyListeners();
    try{
      final result=await Future.wait([repo.read('/api/agent/mobile/bootstrap'),repo.read('/api/agent/me'),
        repo.read('/api/agent/operations/home'),repo.read('/api/users/me')]);
      if(repo.epoch!=epoch)return;
      bootstrap=obj(result[0]);profile=obj(result[1]);summary=obj(result[2]);user=obj(result[3]);access=Access.from(bootstrap,summary);
      if(!access.grants.any((g)=>g.id==grantId&&g.active))grantId=access.grants.where((g)=>g.active).firstOrNull?.id;
      _records.clear();revision++;
    }catch(e){if(repo.epoch==epoch)accessError=e;rethrow;}
    finally{if(repo.epoch==epoch){loading=false;notifyListeners();}}
  }
  Future<void> logout()async{await repo.save(_key('notes'),null,secure:true);await repo.logout();_reset();notifyListeners();}
  Future<void> preferences({String? language,String? theme})async{
    if(language!=null){this.language=language;await repo.save('language',language);}
    if(theme!=null){this.theme=theme;await repo.save('theme',theme);}notifyListeners();
  }
  void selectGrant(int id){if(!access.grants.any((g)=>g.id==id&&g.active))return;
    grantId=id;_records.clear();basket.clear();sale={};revision++;notifyListeners();}
  void changed(){revision++;_records.clear();notifyListeners();}
  Future<dynamic> read(String path,{Json? query})=>repo.read(path,query:query);
  Future<List<Json>> changes()async{
    final byId=<int,Json>{};Json cursor={};
    for(var page=0;page<200;page++){
      final response=obj(await read('/api/agent/mobile/changes',query:cursor));
      for(final row in maps(response['changes'])){final id=numId(row['id']);if(row['revoked']==true){byId.remove(id);}else{byId[id]=row;}}
      if(response['hasMore']!=true||response['next']==null)break;
      final next=obj(response['next']);if(jsonEncode(next)==jsonEncode(cursor))break;cursor=next;
    }
    return byId.values.toList();
  }
  Future<List<Json>> all(String path,{Json? query,int pageSize=50})async{
    final result=<Json>[];var after=0;
    for(var page=0;page<200;page++){
      final current=rows(await read(path,query:{...?query,'afterId':after}));
      if(current.isEmpty)break;
      result.addAll(current);
      final next=current.map((r)=>numId(r['id']??r['productVariantId'])).reduce(max);
      if(current.length<pageSize||next<=after)break;after=next;
    }return result;
  }
  Json scoped([Json? fields])=>{'delegationId':grantId,...?fields};
  String _key(String name)=>'agent.$name.${repo.session?.userId??0}';
  Future<List<Json>> pending()async{
    final raw=await repo.local(_key('pending'),secure:true);return raw==null?[]:maps(jsonDecode(raw));
  }
  Future<void> _savePending(List<Json> commands)=>repo.save(_key('pending'),jsonEncode(commands),secure:true);
  Future<dynamic> execute(String path,Json body,{String method='POST',String? title})async{
    final command=<String,dynamic>{'id':uuid(),'method':method,'path':path,'title':title,
      'body':body,'createdAt':DateTime.now().toUtc().toIso8601String()};
    command['body']={...body,'requestId':command['id']};
    final commands=await pending();commands.add(command);await _savePending(commands);
    return retry(command);
  }
  Future<dynamic> retry(Json command)async{
    final epoch=repo.epoch;
    try{
      final r=await repo.write(str(command['method']),str(command['path']),command['body']);
      if(repo.epoch==epoch){await _removeCommand(str(command['id']));changed();}return r;
    }on Failure catch(e){if(!e.uncertain&&epoch==repo.epoch)await _removeCommand(str(command['id']));rethrow;}
  }
  Future<void> _removeCommand(String id)async{final all=await pending();all.removeWhere((r)=>r['id']==id);await _savePending(all);}
  Future<dynamic> commandStatus(String id)=>read('/api/agent/mobile/requests/$id');
  Future<List<Json>> notes()async{
    final text=await repo.local(_key('notes'),secure:true);final all=text==null?<Json>[]:maps(jsonDecode(text));
    final cutoff=DateTime.now().toUtc().subtract(const Duration(hours:24));
    all.removeWhere((n)=>(DateTime.tryParse(str(n['savedAt']))??DateTime(1970)).isBefore(cutoff));
    await repo.save(_key('notes'),jsonEncode(all),secure:true);return all;
  }
  Future<void> saveNote(Json note)async{
    final all=await notes();all.add({...note,'requestId':uuid(),'savedAt':DateTime.now().toUtc().toIso8601String(),'state':'local'});
    await repo.save(_key('notes'),jsonEncode(all),secure:true);notifyListeners();
  }
  Future<void> deleteNote(String id)async{final all=await notes();all.removeWhere((n)=>n['requestId']==id);await repo.save(_key('notes'),jsonEncode(all),secure:true);notifyListeners();}
  Future<void> syncNotes()async{
    final all=await notes();if(all.isEmpty)return;final epoch=repo.epoch;
    final r=obj(await repo.write('POST','/api/agent/mobile/sync/clinical-notes',all.take(25).map((n)=>{
      for(final k in ['requestId','caseId','body','sharedWithCustomer','amendsId'])k:n[k]}).toList()));
    if(epoch!=repo.epoch)return;
    for(final response in maps(r['results'])){
      final n=all.where((v)=>v['requestId']==response['requestId']).firstOrNull;if(n==null)continue;
      if(numId(response['status'])==200){all.remove(n);}else{n['state']=numId(response['status'])==403?'revoked':'conflict';n['message']=response['message'];}
    }await repo.save(_key('notes'),jsonEncode(all),secure:true);changed();
  }
  Future<Json> record(String kind,int id,{bool fresh=false})async{
    final key='$grantId:$kind:$id';if(!fresh&&_records.containsKey(key))return _records[key]!;
    Json result;
    switch(kind){
      case 'case':result=obj(await read('/api/vet/cases/$id'));break;
      case 'prescription':result=obj(await read('/api/vet/prescriptions/$id',query:scoped()));break;
      case 'document':result=obj(await read('/api/agent/commercial/documents/$id/receipt',query:scoped()));break;
      case 'pickup':
        final request=(await all('/api/agent/pickup/requests',query:scoped())).firstWhere((r)=>numId(r['id'])==id,orElse:()=>throw const Failure(404,''));
        Json movement={};
        try{movement=obj(await read('/api/agent/pickup/requests/$id/custody-details',query:scoped()));}
        on Failure catch(e){if(e.status!=404)rethrow;}
        result={...movement,...request,'movement':movement};break;
      case 'campaign':result=obj(await read('/api/agent/field/campaigns/$id/report'));break;
      case 'task':result=(await all('/api/agent/field/tasks')).firstWhere((r)=>numId(r['id'])==id,orElse:()=>throw const Failure(404,''));break;
      case 'visit':
        final tasks=await all('/api/agent/field/tasks');
        final visits=[for(final task in tasks)for(final visit in maps(task['visits'])){...visit,'taskId':task['id'],'taskStatus':task['status']}];
        result=visits.firstWhere((v)=>numId(v['id'])==id,orElse:()=>throw const Failure(404,''));break;
      case 'stock':result=(await all('/api/agent/commerce/inventory',query:scoped(),pageSize:100)).firstWhere((r)=>numId(r['id'])==id,orElse:()=>throw const Failure(404,''));break;
      case 'proposal':result=(await all('/api/agent/marketplace/proposals')).firstWhere((r)=>numId(r['id'])==id,orElse:()=>throw const Failure(404,''));break;
      case 'transfer':result=(await all('/api/agent/commerce/transfers',query:scoped())).firstWhere((r)=>numId(r['id'])==id,orElse:()=>throw const Failure(404,''));break;
      case 'procurement':result=(await all('/api/agent/procurement',query:scoped())).firstWhere((r)=>numId(r['id'])==id,orElse:()=>throw const Failure(404,''));break;
      case 'auction':
        final data=obj(await read('/api/agent/marketplace/auctions',query:scoped()));
        final auction=maps(data['auctions']).firstWhere((a)=>numId(a['id'])==id,orElse:()=>throw const Failure(404,''));
        final review=maps(data['reviews']).firstWhere((r)=>numId(r['relatedId'])==id,orElse:()=>{});
        result={...auction,'version':review['version'],'review':review};break;
      default:throw const Failure(404,'');
    }
    _records[key]=result;return result;
  }
}
