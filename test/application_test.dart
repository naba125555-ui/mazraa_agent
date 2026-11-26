import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_agent/application/agent_app.dart';
import 'package:mazraa_agent/application/workflows.dart';
import 'package:mazraa_agent/data/remote_repository.dart';
import 'package:mazraa_agent/domain/api_origin.dart';
import 'package:mazraa_agent/domain/models.dart';
import 'package:mazraa_agent/domain/screens.dart';
import 'package:mazraa_agent/presentation/features/general.dart';
import 'package:mazraa_agent/presentation/shared/product_thumbnail.dart';
import 'package:mazraa_agent/presentation/shell.dart';
import 'fake_repository.dart';

void main(){
  test('auction schedule enforces future start, ordered dates and the thirty-day limit', () {
    final now = DateTime.utc(2026, 11, 26, 21, 42);
    expect(auctionScheduleIssue({'startAt':'2026-11-26T21:39:00Z','endAt':'2027-01-30T21:39:00Z'}, now),
      AuctionScheduleIssue.pastStart);
    final start = now.add(const Duration(days: 1));
    AuctionScheduleIssue? issue(DateTime end) =>
        auctionScheduleIssue({'startAt':start.toIso8601String(),'endAt':end.toIso8601String()}, now);
    expect(issue(start), AuctionScheduleIssue.invalidEnd);
    expect(issue(start.add(const Duration(days: 30, seconds: 1))), AuctionScheduleIssue.duration);
    expect(issue(start.add(const Duration(days: 30))), isNull);
  });

  test('remote repository reads nested validation errors from the API', () async {
    final dio = Dio(BaseOptions(baseUrl: apiBaseUrl));
    final repo = RemoteRepository(client: dio);
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      handler.reject(DioException(
        requestOptions: request, type: DioExceptionType.badResponse,
        response: Response(requestOptions: request, statusCode: 422,
          data: {'error': {'message': 'An auction cannot exceed 30 days.', 'status': 422}}),
      ));
    }));
    await expectLater(repo.write('POST', '/api/agent/marketplace/auctions', {}),
      throwsA(isA<Failure>().having((e) => e.status, 'status', 422)
        .having((e) => e.message, 'message', 'An auction cannot exceed 30 days.')));
  });

  test('variant images are preserved separately from the parent gallery', () async {
    final repo = FakeRepository();
    final app = AgentApp(repo);
    addTearDown(app.dispose);
    repo.responses['/api/product-variants/5'] = {'productId': 3, 'images': [
      {'imageUrl': '/images/productitems/variant.webp'},
    ]};
    repo.responses['/api/Images/by-entity'] = [
      {'imageUrl': '/images/products/parent.webp'},
    ];
    expect(productImages(await app.variant(5)), [
      '$apiBaseUrl/images/productitems/variant.webp',
      '$apiBaseUrl/images/products/parent.webp',
    ]);
    expect(productImages({
      'variantImageUrl': 'https://invalid.example/variant.jpg',
      'thumbnail': '',
      'productImageUrl': '/images/products/parent.webp',
    }), ['$apiBaseUrl/images/products/parent.webp']);
  });

  test('92 unique bilingual screens have a concrete route binding',(){
    expect(screens.length,92);expect(screens.map((s)=>s.id).toSet(),implementedScreens);
    expect(screens.every((s)=>s.ar.isNotEmpty&&s.en.isNotEmpty),isTrue);
  });
  test('a grant must contain the entire capability mask and remain active',(){
    final grant=Grant({'id':1,'capabilities':'Inventory, Sell, Cash'});
    expect(grant.allows(35),isTrue);expect(grant.allows(Cap.dispense),isFalse);
    expect(Grant({'capabilities':2047,'endsAt':'2000-01-01T00:00:00Z'}).allows(1),isFalse);
  });
  test('unknown notifications never become arbitrary navigation',(){
    expect(notificationDestination('vet.case.assigned'),'C02');
    expect(notificationDestination('javascript:alert(1)'),isNull);
  });
  test('uncertain financial retry preserves the exact request id and payload',()async{
    final repo=FakeRepository(),app=AgentApp(FakeRepository());app.dispose();
    final model=AgentApp(repo);repo.nextFailure=const Failure(0,'',uncertain:true);
    await expectLater(model.execute('/api/agent/commerce/documents',{'delegationId':1,'paidAmount':12}),throwsA(isA<Failure>()));
    final pending=await model.pending();expect(pending,hasLength(1));final first=repo.writes.first['body'];
    await model.retry(pending.single);expect(repo.writes.last['body'],first);expect(await model.pending(),isEmpty);model.dispose();
  });
  test('server rejection does not leave a command queued for blind retry',()async{
    final repo=FakeRepository(),app=AgentApp(FakeRepository());app.dispose();final model=AgentApp(repo);
    repo.nextFailure=const Failure(409,'Conflict');
    await expectLater(model.execute('/api/agent/commerce/documents',{}),throwsA(isA<Failure>()));
    expect(await model.pending(),isEmpty);model.dispose();
  });
  test('scope switch clears the sale basket and never combines grants',()async{
    final model=AgentApp(FakeRepository());model.access=Access(grants:[Grant({'id':1,'capabilities':2}),Grant({'id':2,'capabilities':32})]);
    model.grantId=1;model.basket.add({'quantity':1});expect(model.allows(34),isFalse);
    model.selectGrant(2);expect(model.basket,isEmpty);expect(model.allows(34),isFalse);model.dispose();
  });
  test('pickup request version is preserved separately from movement version',()async{
    final model=AgentApp(FakeRepository());model.grantId=1;
    final record=await model.record('pickup',1);expect(record['version'],1);expect(obj(record['movement'])['version'],5);model.dispose();
  });
  test('scoped deep links use a direct read for each record type',()async{
    final repo=FakeRepository();
    final app=AgentApp(repo)..grantId=1;
    const scoped={
      'prescription':'/api/vet/prescriptions/1',
      'document':'/api/agent/commercial/documents/1/receipt',
      'stock':'/api/agent/commerce/inventory/1',
      'transfer':'/api/agent/commerce/transfers/1',
      'procurement':'/api/agent/procurement/1',
      'pickup':'/api/agent/pickup/requests/1',
      'auction':'/api/agent/marketplace/auctions/1',
      'proposal':'/api/agent/marketplace/proposals/1',
      'settlement':'/api/agent/finance/settlements/1',
    };
    const practitioner={
      'case':'/api/vet/cases/1',
      'task':'/api/agent/field/tasks/1',
      'visit':'/api/agent/field/visits/1',
      'campaign':'/api/agent/field/campaigns/1/report',
    };
    for(final entry in {...scoped,...practitioner}.entries){
      final record=await app.record(entry.key,1);
      expect(record,isNotEmpty,reason:entry.key);
      expect(repo.reads.last['path'],entry.value);
      expect(obj(repo.reads.last['query'])['delegationId'],scoped.containsKey(entry.key)?1:null);
    }
    expect(repo.reads.length,scoped.length+practitioner.length);
    app.dispose();
  });

  test('every declared operation reaches the repository with scope, method and request ID',()async{
    final repo=FakeRepository();
    final app=AgentApp(repo);
    expect(operations,hasLength(45));
    for(final operation in operations.values){
      final body=prepareBody(operation,{}, {'id':8,'version':4,'cashToCollect':0}, 2, 10);
      final path=operation.path.replaceAll('{id}','8');
      await app.execute(path,body,method:operation.method);
      final write=repo.writes.last;
      expect(write['path'],path,reason:operation.key);
      expect(write['method'],operation.method);
      expect(obj(write['body'])['requestId'],isNotEmpty);
      if(operation.scope&&operation.key!='receivePurchase') expect(body['delegationId'],2);
      if(operation.version) expect(body['version'],4);
    }
    expect(repo.writes.map((write)=>obj(write['body'])['requestId']).toSet(),hasLength(45));
    expect(await app.pending(),isEmpty);
    app.dispose();
  });
  test('local clinical sync removes only server-confirmed notes',()async{
    final model=AgentApp(FakeRepository());await model.saveNote({'caseId':1,'body':'A note','sharedWithCustomer':false});
    expect(await model.notes(),hasLength(1));await model.syncNotes();expect(await model.notes(),isEmpty);model.dispose();
  });
  test('commercial prices and scope are derived by the application and server',(){
    final body=prepareBody(operations['sale']!,{'lines':[{'productVariantId':1,'batchId':2,'quantity':3,'unitCost':999}]},{},7,10);
    expect(body['delegationId'],7);expect(body['purchase'],false);expect(maps(body['lines']).single['unitCost'],0);
  });
}
