import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_agent/application/agent_app.dart';
import 'package:mazraa_agent/domain/models.dart';
import 'package:mazraa_agent/presentation/navigation_registry.dart';
import 'fake_repository.dart';

AgentApp agentWith({bool doctor=false,int bits=0}) {
  final app=AgentApp(FakeRepository());
  app.bootstrap=FakeRepository.bootstrap;
  app.grantId=bits==0?null:1;
  app.access=Access(doctor:doctor,
    grants:bits==0?[]:[Grant({'id':1,'warehouseId':1,'storeId':1,'capabilities':bits})]);
  return app;
}
void main() {
  test('every workspace has up to five authorized slots and a center', () {
    final app=agentWith(doctor:true,bits:2047);
    for(final workspace in AgentWorkspace.values){
      final layout=AgentNavigationRegistry.resolve(app,workspace);
      expect(layout.items,isNotEmpty);
      expect(layout.items.first.route,'H05',reason:workspace.name);
      expect(layout.items.where((item)=>item.route=='H05'),hasLength(1));
      expect(layout.items.length,lessThanOrEqualTo(5));
      expect(layout.items[layout.primaryIndex].highlight,isTrue);
      for(final item in layout.items){
        expect(AgentNavigationRegistry.allowed(app,item.route),isTrue,
          reason:'Unauthorized '+item.route+' in '+workspace.name);
      }
    }
    expect(AgentNavigationRegistry.available(app),hasLength(11));
    app.dispose();
  });
  test('the floating root button follows the actual capability',(){
    final cases=<(bool,int,String)>[
      (true,0,'C01'),
      (false,Cap.inventory,'I01'),
      (false,Cap.cash,'N01'),
      (false,Cap.pickup,'P02'),
      (false,Cap.auction,'A01'),
      (false,Cap.sell,'T01'),
      (false,Cap.purchase,'T12'),
      (false,Cap.transfer,'T01'),
      (false,Cap.sell|Cap.cash,'T02'),
    ];
    for(final (doctor,bits,want) in cases){
      final app=agentWith(doctor:doctor,bits:bits);
      if(bits==Cap.sell || bits==Cap.transfer) {
        expect(AgentNavigationRegistry.canEnter(app,AgentWorkspace.branch),isTrue);
      }
      final layout=AgentNavigationRegistry.resolve(app,AgentWorkspace.home);
      expect(layout.items[layout.primaryIndex].route,want);
      expect(layout.items.any((item)=>item.route=='T02'),bits==34);
      app.dispose();
    }
  });
  test('inventory and branch fallback never exposes unauthorized stock counts',(){
    final onlyStock=agentWith(bits:Cap.inventory);
    final branch=AgentNavigationRegistry.resolve(onlyStock,AgentWorkspace.branch);
    final stock=AgentNavigationRegistry.resolve(onlyStock,AgentWorkspace.inventory);
    expect(branch.items[branch.primaryIndex].route,'I01');
    expect(stock.items[stock.primaryIndex].route,'I01');
    expect(stock.items.any((item)=>item.route=='I09'),isFalse);
    onlyStock.dispose();
    final counter=agentWith(bits:Cap.inventory|Cap.count);
    final countLayout=AgentNavigationRegistry.resolve(counter,AgentWorkspace.inventory);
    expect(countLayout.items[countLayout.primaryIndex].route,'I09');
    counter.dispose();
  });
  test('record actions stay on details while ready orders have a dedicated list',(){
    final app=agentWith(doctor:true,bits:Cap.pickup|Cap.cash);
    final clinic=AgentNavigationRegistry.resolve(app,AgentWorkspace.clinic);
    expect(clinic.items.any((item)=>item.route=='C04'||item.route=='C09'),isFalse);
    final pickup=AgentNavigationRegistry.resolve(app,AgentWorkspace.pickup);
    expect(pickup.items[pickup.primaryIndex].route,'P06');
    app.dispose();
  });
  test('detail routes do not silently reset workspace identity',(){
    expect(AgentNavigationRegistry.workspaceForEntry('H05'),AgentWorkspace.home);
    expect(AgentNavigationRegistry.workspaceForEntry('T02'),AgentWorkspace.sales);
    expect(AgentNavigationRegistry.workspaceForEntry('I01'),AgentWorkspace.inventory);
    expect(AgentNavigationRegistry.workspaceForEntry('C04'),AgentWorkspace.clinic);
    expect(AgentNavigationRegistry.workspaceForEntry('P03'),AgentWorkspace.pickup);
  });
}
