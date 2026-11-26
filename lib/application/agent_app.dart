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
  Access access=const Access();int? grantId;int revision=0,refreshTick=0,scopeRevision=0;
  final List<Json> basket=[];Json sale={},auctionDraft={},prescriptionDraft={};
  final Map<String,Json> _records={};
  final Map<int, Future<Json>> _variants = {};
  bool get signedIn=>repo.session!=null;
  bool get ar=>language=='ar';
  String tr(String arabic,String english)=>ar?arabic:english;
  String get currency=>str(bootstrap['currency']??summary['catalogCurrency']);
  Grant? get grant=>access.grants.where((g)=>g.id==grantId&&g.active).firstOrNull;
  bool allows(int mask)=>grant?.allows(mask)??false;
  bool canOpen(ScreenSpec spec) =>
      signedIn &&
      (!spec.doctor || access.doctor) &&
      (spec.cap == 0 || allows(spec.cap)) &&
      (spec.id != 'T04' || allows(Cap.sell) || allows(Cap.inventory)) &&
      (spec.id != 'C13' || access.dispenser);
  Future<void> initialize()async{
    try{
      language=await repo.local('language')??'ar';theme=await repo.local('theme')??'system';
      await repo.restore().timeout(const Duration(seconds:6));
      if(signedIn)await refreshAccess();
    }catch(e){accessError=e;}
    starting=false;notifyListeners();
  }
  Future<void> login(String email,String password,{bool remember=true})async{
    await repo.login(email,password,remember:remember);_reset();notifyListeners();await refreshAccess();
  }
  void _reset(){bootstrap={};profile={};summary={};user={};access=const Access();grantId=null;
    _records.clear();_variants.clear();basket.clear();sale={};auctionDraft={};prescriptionDraft={};revision++;scopeRevision++;}
  Future<void> refreshAccess()async{
    if(!signedIn)return;final epoch=repo.epoch;loading=true;accessError=null;notifyListeners();
    try{
      final result=await Future.wait([repo.read('/api/agent/mobile/bootstrap'),repo.read('/api/agent/me'),
        repo.read('/api/agent/operations/home'),repo.read('/api/users/me')]);
      if(repo.epoch!=epoch)return;
      final previousAuthority = _authority(bootstrap, profile);
      final previousGrant = grantId;
      bootstrap=obj(result[0]);profile=obj(result[1]);summary=obj(result[2]);user=obj(result[3]);
      access=Access.from({...bootstrap, 'doctorApproved': bootstrap['doctorApproved'] == true && profile['canPractice'] != false}, summary);
      if(!access.grants.any((g)=>g.id==grantId&&g.active))grantId=access.grants.where((g)=>g.active).firstOrNull?.id;
      if (previousGrant != grantId || previousAuthority != _authority(bootstrap, profile)) {
        _workContextChanged();
        if (!access.doctor) prescriptionDraft = {};
      }
      refreshTick++;
    }catch(e){if(repo.epoch==epoch)accessError=e;rethrow;}
    finally{if(repo.epoch==epoch){loading=false;notifyListeners();}}
  }
  Future<void> logout()async{await repo.save(_key('notes'),null,secure:true);await repo.logout();_reset();notifyListeners();}
  Future<void> preferences({String? language,String? theme})async{
    if(language!=null){this.language=language;await repo.save('language',language);}
    if(theme!=null){this.theme=theme;await repo.save('theme',theme);}notifyListeners();
  }
  String _authority(Json snapshot, Json profile) => jsonEncode({
    'doctor': snapshot['doctorApproved'] == true && profile['canPractice'] != false,
    'dispenser': snapshot['dispensingApproved'],
    'delegations': maps(snapshot['delegations'])..sort((a, b) => numId(a['id']).compareTo(numId(b['id']))),
  });
  void _workContextChanged() {
    _records.clear();
    _variants.clear();
    basket.clear();
    sale = {};
    auctionDraft = {};
    revision++;
    scopeRevision++;
  }
  void selectGrant(int id) {
    if (id == grantId || !access.grants.any((g) => g.id == id && g.active)) return;
    grantId = id;
    _workContextChanged();
    notifyListeners();
  }
  void changed(){revision++;_records.clear();_variants.clear();notifyListeners();}
  Future<Json> variant(int id) => _variants.putIfAbsent(id, () async {
    final variant = obj(await read('/api/product-variants/$id'));
    final productId = numId(variant['productId']);
    if(productId==0) return variant;
    try {
      final images = rows(await read('/api/Images/by-entity',query:{'type':'Product','entityId':productId}));
      return {...variant,'images':images};
    } on Failure {
      return variant;
    }
  });
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
  Future<List<Json>> page(String path, {int afterId = 0, Json? query}) async =>
      rows(await read(path, query: {...?query, 'afterId': afterId}));

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
  Future<RecordPage> cursorPage(String path, {int afterId = 0, Json? query}) async =>
      RecordPage.from(await read(path, query: {...?query, 'afterId': afterId}));

  Future<Json> record(String kind, int id, {bool fresh = false}) async {
    final scope = scopeRevision;
    final epoch = repo.epoch;
    final key = '$grantId:$kind:$id';
    if (!fresh && _records.containsKey(key)) return _records[key]!;
    final route = switch (kind) {
      'case' => '/api/vet/cases/$id',
      'prescription' => '/api/vet/prescriptions/$id',
      'document' => '/api/agent/commercial/documents/$id/receipt',
      'settlement' => '/api/agent/finance/settlements/$id',
      'pickup' => '/api/agent/pickup/requests/$id',
      'campaign' => '/api/agent/field/campaigns/$id/report',
      'task' => '/api/agent/field/tasks/$id',
      'visit' => '/api/agent/field/visits/$id',
      'stock' => '/api/agent/commerce/inventory/$id',
      'proposal' => '/api/agent/marketplace/proposals/$id',
      'transfer' => '/api/agent/commerce/transfers/$id',
      'procurement' => '/api/agent/procurement/$id',
      'auction' => '/api/agent/marketplace/auctions/$id',
      _ => throw const Failure(404, ''),
    };
    final scopedRecord = !const {'case', 'campaign', 'task', 'visit'}.contains(kind);
    final raw = obj(await read(route, query: scopedRecord ? scoped() : null));
    if (scopeRevision != scope || repo.epoch != epoch) throw const Failure(403, '');
    final result = kind == 'auction'
        ? {...obj(raw['auction']), 'version': raw['version'], 'review': obj(raw['review'])}
        : raw;
    if (result.isEmpty) throw const Failure(404, '');
    _records[key] = result;
    return result;
  }
}
