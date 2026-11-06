typedef Json = Map<String, dynamic>;
Json obj(Object? v) => v is Map ? v.map((k, v) => MapEntry('$k', v)) : {};
List<Json> maps(Object? v) => v is List ? v.whereType<Map>().map(obj).toList() : [];
List<Json> rows(Object? v) {
  if(v is List) return maps(v);
  final o=obj(v);
  for(final k in ['items','data','results','records','transactions']) {
    if(o[k] is List) return maps(o[k]);
  }
  return [];
}
int numId(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
double decimal(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
String str(Object? v) => v==null ? '' : '$v';
Json payload(Json v) => obj(v['details'] ?? v['consultation'] ?? v);
String titleOf(Json v) {
  final d=payload(v);
  for(final k in ['title','name','productName','documentNumber','batchNumber','subject','sku']) {
    final s=str(v[k]??d[k]); if(s.isNotEmpty) return s;
  }
  return '#${v['id']??v['productVariantId']??'—'}';
}
abstract final class Cap {
  static const inventory=1,sell=2,purchase=4,transfer=8,count=16,cash=32,
      pickup=64,auction=128,dispense=256,credit=512,discount=1024;
  static const values={'Inventory':1,'Sell':2,'Purchase':4,'Transfer':8,'StockCount':16,
    'Cash':32,'Pickup':64,'Auction':128,'Dispense':256,'Credit':512,'Discount':1024};
  static int parse(Object? v) => v is num?v.toInt():int.tryParse(str(v))??
    str(v).split(',').fold(0,(m,k)=>m|(values[k.trim()]??0));
}
class Grant {
  Grant(this.json);
  final Json json;
  int get id=>numId(json['id']);
  int get warehouse=>numId(json['warehouseId']);
  int get store=>numId(json['storeId']);
  int? get cashbox=>json['cashBoxId']==null?null:numId(json['cashBoxId']);
  bool get active {final end=DateTime.tryParse(str(json['endsAt']));return json['isActive']!=false&&(end==null||end.isAfter(DateTime.now().toUtc()));}
  bool allows(int bits)=>active&&(Cap.parse(json['capabilities'])&bits)==bits;
}
class Access {
  const Access({this.doctor=false,this.dispenser=false,this.grants=const [],this.permissions=const {}});
  final bool doctor,dispenser;
  final List<Grant> grants;
  final Set<String> permissions;
  factory Access.from(Json bootstrap,Json home)=>Access(
    doctor:bootstrap['doctorApproved']==true,dispenser:bootstrap['dispensingApproved']==true,
    grants:maps(bootstrap['delegations']).map(Grant.new).toList(),
    permissions:(home['permissions'] is List?home['permissions'] as List:[]).map((v)=>'$v').toSet());
}
class Failure implements Exception {
  const Failure(this.status,this.message,{this.uncertain=false});
  final int status;final String message;final bool uncertain;
  @override String toString()=>message;
}
class Session {
  Session(this.json);
  final Json json;
  int get userId=>numId(json['userId']);
  String get token=>str(json['token']??json['accessToken']);
  String get refresh=>str(json['refreshToken']);
  bool get usable=>userId>0&&token.isNotEmpty&&refresh.isNotEmpty;
}
