import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_agent/application/agent_app.dart';
import 'package:mazraa_agent/application/workflows.dart';
import 'package:mazraa_agent/domain/models.dart';
import 'package:mazraa_agent/domain/screens.dart';
import 'package:mazraa_agent/presentation/features/general.dart';
import 'package:mazraa_agent/presentation/shell.dart';
import 'fake_repository.dart';

void main(){
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
  test('local clinical sync removes only server-confirmed notes',()async{
    final model=AgentApp(FakeRepository());await model.saveNote({'caseId':1,'body':'A note','sharedWithCustomer':false});
    expect(await model.notes(),hasLength(1));await model.syncNotes();expect(await model.notes(),isEmpty);model.dispose();
  });
  test('commercial prices and scope are derived by the application and server',(){
    final body=prepareBody(operations['sale']!,{'lines':[{'productVariantId':1,'batchId':2,'quantity':3,'unitCost':999}]},{},7,10);
    expect(body['delegationId'],7);expect(body['purchase'],false);expect(maps(body['lines']).single['unitCost'],0);
  });
}
