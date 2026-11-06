import 'dart:typed_data';
import 'package:mazraa_agent/domain/models.dart';
import 'package:mazraa_agent/domain/ports.dart';

class FakeRepository implements AgentRepository {
  @override Session? session=Session({'userId':10,'token':'test','refreshToken':'test-refresh'});
  @override int epoch=0;
  @override void Function()? onExpired;
  final Map<String,String> storage={};
  final List<Json> writes=[];
  Failure? nextFailure;
  @override Future<void> restore()async{}
  @override Future<void> login(String email,String password)async{}
  @override Future<void> logout()async{session=null;epoch++;}
  @override Future<String?> local(String key,{bool secure=false})async=>storage[key];
  @override Future<void> save(String key,String? value,{bool secure=false})async{if(value==null){storage.remove(key);}else{storage[key]=value;}}
  @override Future<dynamic> write(String method,String path,Object? body)async{
    writes.add({'method':method,'path':path,'body':body});
    if(nextFailure!=null){final failure=nextFailure!;nextFailure=null;throw failure;}
    if(path.endsWith('sync/clinical-notes'))return {'results':[for(final op in maps(body)){'requestId':op['requestId'],'status':200}]};
    return {'id':1,'documentId':1,'status':'Completed'};
  }
  @override Future<Uint8List> download(String path)async=>Uint8List(0);
  @override Future<dynamic> upload(String path,String name,Uint8List bytes,Json fields)async=>{'id':1};
  static Json get bootstrap=>{'doctorApproved':true,'dispensingApproved':true,'currency':'SAR','delegations':[
    {'id':1,'storeId':1,'warehouseId':1,'cashBoxId':1,'capabilities':'Inventory, Sell, Purchase, Transfer, StockCount, Cash, Pickup, Auction, Dispense, Credit, Discount'}]};
  static Json get stock=>{'id':1,'productVariantId':1,'quantityOnHand':20,'availableQuantity':18,'reservedQuantity':2,
    'batches':[{'id':1,'batchNumber':'B-TEST','quantity':20,'expiryDate':'2030-01-01T00:00:00Z','unitCost':8}]};
  static Json get task=>{'id':1,'title':'زيارة متابعة','description':'القرية · العيادة','status':'Accepted','scheduledDate':DateTime.now().toUtc().toIso8601String(),
    'visits':[{'id':1,'status':'Scheduled','latitude':24.7,'longitude':46.7}]};
  static Json get document=>{'id':1,'documentNumber':'TEST-001','type':'SalesInvoice','totalAmount':150.0,'paidAmount':150.0,
    'remainingAmount':0,'currency':'SAR','isPosted':true,'postedAt':DateTime.now().toUtc().toIso8601String(),
    'items':[{'id':1,'productVariantId':1,'quantity':2,'unitPrice':75,'total':150}]};
  @override Future<dynamic> read(String path,{Json? query})async{
    if(numId(query?['afterId'])>0)return [];
    if(path.endsWith('bootstrap'))return bootstrap;
    if(path=='/api/agent/me')return {'user':{'id':10,'name':'د. أحمد'},'profile':{'isAvailable':true}};
    if(path.endsWith('/home'))return {'caseOffers':1,'activeCases':2,'permissions':[]};
    if(path=='/api/users/me')return {'id':10,'name':'د. أحمد','email':'test@example.com'};
    if(path=='/api/vet/cases')return [{'id':1,'status':'Assigned','version':1}];
    if(path.endsWith('/shared-ai'))return [{'id':1,'role':'assistant','content':'سجل اختباري','createdAt':'2026-11-06T12:00:00Z'}];
    if(path.endsWith('/messages'))return [{'id':1,'senderId':20,'body':'رسالة اختبار','createdAt':'2026-11-06T12:00:00Z'}];
    if(path.endsWith('/record'))return {'id':1,'animalId':1,'notes':[],'visits':task['visits'],'inspections':[]};
    if(path=='/api/vet/cases/1')return {'consultation':{'id':1,'status':'Active','version':1,'reason':'متابعة الحالة','animalId':1},'animal':{'id':1,'name':'حيوان اختبار','species':'Sheep'}};
    if(path=='/api/vet/prescriptions')return [{'id':1,'status':'Approved','version':1}];
    if(path=='/api/vet/prescriptions/1')return {'id':1,'ownerId':10,'customerId':20,'status':'Approved','version':1,'details':{'caseId':1,'diagnosis':'متابعة','warnings':'حسب الوصفة','lines':[]}};
    if(path.endsWith('/tasks'))return [task];
    if(path.endsWith('/campaigns'))return [{'id':1,'status':'Active','version':1,'details':{'name':'حملة تلقيح','targetAnimals':12}}];
    if(path.endsWith('/report'))return {'campaign':{'id':1,'version':1,'status':'Active','details':{'name':'حملة تلقيح','targetAnimals':12}},'animals':3};
    if(path.endsWith('/reconciliation'))return {'id':1,'status':'Active','allocations':[],'outcomes':[]};
    if(path.endsWith('/inventory'))return [stock];
    if(path.endsWith('/transfers'))return [{'id':1,'version':1,'status':'Active','details':{'lines':[]}}];
    if(path.endsWith('/documents'))return [document];
    if(path.endsWith('/receipt'))return document;
    if(path.endsWith('/cashbox'))return {'id':1,'name':'الصندوق الرئيسي','currencyCode':'SAR','currentBalance':1200,'openingBalance':1000,'transactions':[],
      'shifts':[{'id':1,'status':'Active','version':1,'details':{'opening':1000}}]};
    if(path.endsWith('/proposals'))return [{'id':1,'version':1,'status':'NeedsChanges','details':{'kind':'product','title':'منتج جديد','description':'منتج زراعي'}}];
    if(path.endsWith('/procurement'))return [{'id':1,'status':'Approved','version':1,'details':{'supplierId':1,'lines':[]}}];
    if(path.endsWith('/auctions'))return {'auctions':[{'id':1,'title':'مزاد المنتجات','status':'Draft','items':[]}],
      'reviews':[{'id':2,'relatedId':1,'version':1,'status':'Draft','details':{}}]};
    if(path.endsWith('/requests'))return [{'id':1,'version':1,'status':'Active','orderId':1}];
    if(path.endsWith('/custody-details'))return {'id':2,'version':5,'shelf':'A-1','status':'Active'};
    if(path.contains('/identifiers/'))return {'qrPayload':'https://mzraa.runasp.net/share/auctions/1','serialNumber':'A-1'};
    if(path=='/api/product-variants')return [{'id':1,'name':'منتج اختبار','sku':'TEST-1','productId':1,'price':75}];
    if(path=='/api/product-variants/1')return {'id':1,'name':'منتج اختبار','price':75};
    if(path.endsWith('/changes'))return {'changes':[]};
    if(path.endsWith('/statements'))return {'balance':0,'currency':'SAR','transactions':[]};
    return [];
  }
}
