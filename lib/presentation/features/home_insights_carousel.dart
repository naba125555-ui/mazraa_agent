import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../navigation.dart';
import '../shared/scope.dart';
import '../shared/widgets.dart';
import 'home_insights_data.dart';

/// One responsive glass card, not a vertical list of dashboards. A slide is
/// fetched only after it is selected; PageView may build neighbours but that
/// does not trigger their network calls. No decorative/dummy numbers.
class HomeInsightsCarousel extends StatefulWidget {
  const HomeInsightsCarousel({super.key});
  @override State<HomeInsightsCarousel> createState()=>_HomeInsightsCarouselState();
}

class _HomeInsightsCarouselState extends State<HomeInsightsCarousel> {
  final controller=PageController();
  final futures=<InsightKind,Future<InsightSnapshot>>{};
  int current=0;
  String? sourceSignature;

  @override void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override Widget build(BuildContext context) {
    final app=context.app;
    final kinds=HomeInsightsData.available(app);
    final signature=[
      app.scopeRevision,app.revision,app.refreshTick,app.language,
      app.access.doctor,app.grantId,kinds.join(','),
    ].join(':');
    if(sourceSignature!=signature) {
      sourceSignature=signature;
      futures.clear();
      if(current>=kinds.length) {
        current=0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if(mounted && controller.hasClients) controller.jumpToPage(0);
        });
      }
    }
    if(kinds.isEmpty)return const SizedBox.shrink();
    final dark=Theme.of(context).brightness==Brightness.dark;
    final colors=Theme.of(context).colorScheme;
    final scaler=MediaQuery.textScalerOf(context).scale(16)/16;
    final extra=(scaler-1).clamp(0.0,1.0).toDouble();
    return LayoutBuilder(builder:(context,constraints){
      final narrow=constraints.maxWidth<330;
      final height=(narrow ? 408.0 : 376.0)+extra*93;
      return Semantics(
        label:context.tr('لوحة الإحصائيات القابلة للتمرير',
            'Swipeable insights dashboard'),
        child: SizedBox(
          key:const ValueKey('home-insights-card'),
          height:height,
          child: ClipRRect(
            borderRadius:BorderRadius.circular(27),
            child:BackdropFilter(
              filter:ui.ImageFilter.blur(sigmaX:13,sigmaY:13),
              child:DecoratedBox(
                decoration:BoxDecoration(
                  borderRadius:BorderRadius.circular(27),
                  color:dark
                    ? const Color(0xEE102C24)
                    : const Color(0xF4FAFAF4),
                  border:Border.all(
                    color:dark
                      ? const Color(0x7F7CBEA1)
                      : const Color(0xFFD6E6DB),
                    width:1,
                  ),
                  boxShadow:const [BoxShadow(
                    color:Color(0x16002D20),blurRadius:22,
                    offset:Offset(0,8),
                  )],
                ),
                child:Column(children:[
                  Expanded(
                    child:PageView.builder(
                      key:const ValueKey('home-insights-page-view'),
                      controller:controller,
                      itemCount:kinds.length,
                      onPageChanged:(index)=>setState(()=>current=index),
                      itemBuilder:(context,index) {
                        final kind=kinds[index];
                        if(index!=current) {
                          // A neighbouring offstage slide never starts a fetch.
                          return _WaitingSlide(kind:kind);
                        }
                        final future=futures.putIfAbsent(
                          kind,()=>HomeInsightsData.load(app,kind));
                        return _InsightSlide(
                          key:ValueKey('insight-'+kind.name),
                          kind:kind,future:future,
                          retry:()=>setState(() {
                            futures[kind]=HomeInsightsData.load(app,kind);
                          }),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    height:27,
                    child:Row(
                      mainAxisAlignment:MainAxisAlignment.center,
                      children:[
                        for(var i=0;i<kinds.length;i++)
                          Semantics(
                            button:true,
                            label:context.tr('الشريحة ','Slide ')+
                              (i+1).toString()+' / '+kinds.length.toString(),
                            selected:i==current,
                            child:InkWell(
                              key:ValueKey('insight-dot-'+i.toString()),
                              onTap:()=>controller.animateToPage(
                                i,
                                duration:const Duration(milliseconds:320),
                                curve:Curves.easeOutCubic,
                              ),
                              borderRadius:BorderRadius.circular(10),
                              child:Padding(
                                padding:const EdgeInsets.symmetric(horizontal:3,vertical:6),
                                child:AnimatedContainer(
                                  duration:const Duration(milliseconds:220),
                                  width:i==current?20:6,height:6,
                                  decoration:BoxDecoration(
                                    color:i==current
                                      ? colors.primary
                                      : colors.onSurface.withValues(alpha:.24),
                                    borderRadius:BorderRadius.circular(7),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _WaitingSlide extends StatelessWidget {
  const _WaitingSlide({required this.kind});
  final InsightKind kind;
  @override Widget build(BuildContext context)=>_Frame(
    kind:kind,
    content:const _Skeleton(),
    period:context.tr('تحميل عند العرض','Loads when selected'),
  );
}

class _InsightSlide extends StatelessWidget {
  const _InsightSlide({
    super.key,
    required this.kind,required this.future,required this.retry,
  });
  final InsightKind kind;
  final Future<InsightSnapshot> future;
  final VoidCallback retry;

  @override Widget build(BuildContext context)=>FutureBuilder<InsightSnapshot>(
    future:future,
    builder:(context,snapshot) {
      if(snapshot.connectionState!=ConnectionState.done){
        return _Frame(kind:kind,content:const _Skeleton(),
            period:context.tr('جاري التحميل','Loading'));
      }
      if(snapshot.hasError){
        return _Frame(kind:kind,content:Center(
          child:Column(
            mainAxisAlignment:MainAxisAlignment.center,
            children:[
              const Icon(Icons.cloud_off_outlined,size:28),
              const SizedBox(height:7),
              Text(failureText(context,snapshot.error!),
                textAlign:TextAlign.center,maxLines:2,
                overflow:TextOverflow.ellipsis),
              TextButton.icon(onPressed:retry,icon:const Icon(Icons.refresh),
                label:Text(context.tr('إعادة المحاولة','Retry'))),
            ],
          ),
        ),period:context.tr('غير متصل','Unavailable'));
      }
      final data=snapshot.data!;
      return _Frame(
        kind:kind,period:data.period(context.app.ar),
        content:_InsightContent(kind:kind,data:data),
      );
    },
  );
}

class _Frame extends StatelessWidget {
  const _Frame({
    required this.kind,required this.content,required this.period,
  });
  final InsightKind kind;
  final Widget content;
  final String period;
  @override Widget build(BuildContext context){
    final cs=Theme.of(context).colorScheme;
    return Padding(
      padding:const EdgeInsets.fromLTRB(13,12,13,2),
      child:Column(children:[
        Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Container(width:37,height:37,
            decoration:BoxDecoration(
              color:cs.primary.withValues(alpha:.10),
              borderRadius:BorderRadius.circular(13)),
            child:Icon(kind.icon,color:cs.primary,size:21)),
          const SizedBox(width:9),
          Expanded(child:Column(
            crossAxisAlignment:CrossAxisAlignment.start,
            children:[
              Text(kind.title(context.app.ar),
                maxLines:1,overflow:TextOverflow.ellipsis,
                style:Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight:FontWeight.w900,fontSize:15)),
              Text(kind.subtitle(context.app.ar),
                maxLines:2,overflow:TextOverflow.ellipsis,
                style:Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize:10.2,height:1.2)),
            ],
          )),
          const SizedBox(width:4),
          Container(
            constraints:const BoxConstraints(maxWidth:87),
            padding:const EdgeInsets.symmetric(horizontal:8,vertical:5),
            decoration:BoxDecoration(
              color:cs.primary.withValues(alpha:.09),
              borderRadius:BorderRadius.circular(20)),
            child:Text(period,maxLines:2,
              textAlign:TextAlign.center,overflow:TextOverflow.ellipsis,
              style:TextStyle(color:cs.primary,fontSize:9.4,
                fontWeight:FontWeight.w800)),
          ),
        ]),
        const SizedBox(height:8),
        Expanded(child:content),
      ]),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override Widget build(BuildContext context){
    final color=Theme.of(context).colorScheme.onSurface.withValues(alpha:.09);
    Widget bar(double w,double h)=>Container(
      width:w,height:h,
      decoration:BoxDecoration(color:color,
        borderRadius:BorderRadius.circular(9)));
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      bar(130,29),const SizedBox(height:12),
      Row(children:[for(var i=0;i<3;i++)...[
        Expanded(child:bar(double.infinity,40)),
        if(i<2)const SizedBox(width:8),
      ]]),
      const SizedBox(height:17),
      Expanded(child:bar(double.infinity,double.infinity)),
      const SizedBox(height:13),
      bar(175,13),const SizedBox(height:8),
    ]);
  }
}

class _InsightContent extends StatelessWidget {
  const _InsightContent({required this.kind,required this.data});
  final InsightKind kind;
  final InsightSnapshot data;
  @override Widget build(BuildContext context) {
    final palette=Theme.of(context).colorScheme;
    final overview=kind==InsightKind.overview;
    final scaled=MediaQuery.textScalerOf(context).scale(16)/16;
    return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      if(!overview) ...[
        SizedBox(height:55,child:Row(children:[
          FittedBox(fit:BoxFit.scaleDown,child:Text(
            _format(context,data.headline,currency:data.currency),
            style:Theme.of(context).textTheme.headlineMedium?.copyWith(
              color:palette.primary,fontSize:27,fontWeight:FontWeight.w900),
          )),
          const SizedBox(width:9),
          Expanded(child:Text(data.headlineLabel(context.app.ar),
            maxLines:2,overflow:TextOverflow.ellipsis,
            style:Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight:FontWeight.w700,fontSize:11))),
        ])),
        const SizedBox(height:5),
      ],
      SizedBox(
        height:overview ? (scaled>1.4?151:93) : (scaled>1.4?104:64),
        child:_QuickStats(
          data.values,
          columns:overview?2:3,
        ),
      ),
      const SizedBox(height:8),
      Expanded(
        child:Material(
          color:palette.primary.withValues(alpha:.035),
          borderRadius:BorderRadius.circular(16),
          child:InkWell(
            borderRadius:BorderRadius.circular(16),
            onTap:()=>context.open(_detailsRoute(context,kind)),
            child:Padding(
              padding:const EdgeInsets.fromLTRB(9,8,9,5),
              child:_InsightGraph(kind:kind,data:data),
            ),
          ),
        ),
      ),
      const SizedBox(height:6),
      Row(children:[
        Expanded(child:Text(data.note(context.app.ar),
          maxLines:2,overflow:TextOverflow.ellipsis,
          style:Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize:9.6,height:1.25,
            color:palette.onSurfaceVariant))),
        TextButton(
          onPressed:()=>context.open(_detailsRoute(context,kind)),
          style:TextButton.styleFrom(
            padding:const EdgeInsets.symmetric(horizontal:5),
            minimumSize:const Size(46,42),
            tapTargetSize:MaterialTapTargetSize.shrinkWrap,
          ),
          child:Row(mainAxisSize:MainAxisSize.min,children:[
            Text(kind.action(context.app.ar),
              style:const TextStyle(fontSize:10,
                fontWeight:FontWeight.w800)),
            const SizedBox(width:3),
            Icon(Directionality.of(context)==TextDirection.rtl
                ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                size:14),
          ]),
        ),
      ]),
    ]);
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats(this.values,{required this.columns});
  final List<InsightValue> values;
  final int columns;
  @override Widget build(BuildContext context) {
    if(values.isEmpty) return Center(child:Text(
      context.tr('لا توجد مؤشرات موثقة','No verified metrics'),
      style:Theme.of(context).textTheme.bodySmall));
    final cs=Theme.of(context).colorScheme;
    return LayoutBuilder(builder:(context,bounds) {
      final rowsCount=(values.length/columns).ceil();
      final gap=5.0;
      final cellWidth=(bounds.maxWidth-(columns-1)*gap)/columns;
      final cellHeight=(bounds.maxHeight-(rowsCount-1)*gap)/rowsCount;
      return Wrap(spacing:gap,runSpacing:gap,children:[
        for(final stat in values)
          SizedBox(width:cellWidth,height:cellHeight,
            child:Container(
              padding:const EdgeInsets.symmetric(horizontal:7,vertical:4),
              decoration:BoxDecoration(
                color:cs.surface.withValues(alpha:.78),
                borderRadius:BorderRadius.circular(11),
                border:Border.all(color:cs.outline.withValues(alpha:.2)),
              ),
              child:Row(children:[
                Expanded(child:FittedBox(
                  fit:BoxFit.scaleDown,
                  alignment:AlignmentDirectional.centerStart,
                  child:Column(
                    mainAxisSize:MainAxisSize.min,
                    crossAxisAlignment:CrossAxisAlignment.start,
                    children:[
                      Text(_format(context,stat.value),
                        maxLines:1,style:TextStyle(
                          color:cs.primary,fontSize:15,
                          fontWeight:FontWeight.w900,
                        )),
                      Text(stat.label(context.app.ar),
                        maxLines:1,overflow:TextOverflow.ellipsis,
                        style:TextStyle(
                          color:cs.onSurfaceVariant,fontSize:9.1,
                          height:1.08,fontWeight:FontWeight.w700,
                        )),
                    ],
                  ),
                )),
              ]),
            ),
          ),
      ]);
    });
  }
}

/// The overview is already on Home; link it to an authorized work area.
String _detailsRoute(BuildContext context,InsightKind kind) {
  if(kind!=InsightKind.overview)return kind.route;
  final app=context.app;
  if(app.access.doctor)return 'C01';
  if(app.grant!=null)return 'T01';
  return 'H04';
}

String _format(BuildContext context,double? value,{String? currency}) {
  if(value==null)return '—';
  final numValue=value==value.roundToDouble()?value.toInt():value;
  final base=display(context,numValue);
  return currency==null || currency.isEmpty?base:base+' '+currency;
}

const _chartColors=[
  Color(0xFF1D9A74),Color(0xFF42B6AF),Color(0xFFE6AE55),
  Color(0xFF6D88B0),Color(0xFF9275A0),
];

class _InsightGraph extends StatelessWidget {
  const _InsightGraph({required this.kind,required this.data});
  final InsightKind kind;
  final InsightSnapshot data;

  @override Widget build(BuildContext context) {
    final positive=data.parts.where((v)=>(v.value??0)>0).toList();
    switch(kind){
      case InsightKind.overview:
      case InsightKind.pickup:
        return _SegmentedDistribution(parts:data.parts);
      case InsightKind.clinic:
        return _DonutGraph(parts:data.parts,
          center:_format(context,data.headline),
          caption:context.tr('نشطة','Active'));
      case InsightKind.sales:
        return data.series.isEmpty
          ? _NoGraph(message:context.tr('بيانات الرسم غير متاحة بصورة موثوقة',
              'No reliable chart data available'))
          : _WeekBars(values:data.series,labels:data.days,
              currency:data.currency);
      case InsightKind.field:
        return _AreaGraph(values:data.series,labels:data.days);
      case InsightKind.inventory:
        return _HorizontalStatuses(parts:data.parts);
      case InsightKind.finance:
        return data.series.isEmpty
          ? _NoGraph(message:context.tr('لم تتأكد أنواع الحركات لعرض المقارنة',
              'Movement categories are not verified'))
          : _WeekBars(values:data.series,other:data.secondary,
              labels:data.days,currency:data.currency);
      case InsightKind.auctions:
        return _StageTimeline(parts:data.parts);
      case InsightKind.purchasing:
        return _Pipeline(parts:data.parts);
      case InsightKind.proposals:
        return positive.fold<double>(0,(s,p)=>s+(p.value??0))<10
          ? _SegmentedDistribution(parts:data.parts)
          : _WaffleGraph(parts:data.parts);
      case InsightKind.sync:
        return _DonutGraph(parts:const [],
          center:'—%',caption:context.tr('غير متاحة','Unavailable'));
    }
  }
}

class _NoGraph extends StatelessWidget {
  const _NoGraph({required this.message});
  final String message;
  @override Widget build(BuildContext context)=>Center(
    child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
      Icon(Icons.query_stats_outlined,
          color:Theme.of(context).colorScheme.primary,size:27),
      const SizedBox(height:5),
      Text(message,textAlign:TextAlign.center,maxLines:2,
        overflow:TextOverflow.ellipsis,
        style:Theme.of(context).textTheme.bodySmall),
    ]),
  );
}

class _SegmentedDistribution extends StatelessWidget {
  const _SegmentedDistribution({required this.parts});
  final List<InsightValue> parts;
  @override Widget build(BuildContext context) {
    final total=parts.fold<double>(0,(sum,p)=>sum+(p.value??0).clamp(0,double.infinity));
    final cs=Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment:MainAxisAlignment.center,
      crossAxisAlignment:CrossAxisAlignment.stretch,
      children:[
      if(total==0)
        Container(height:23,decoration:BoxDecoration(
          color:cs.outline.withValues(alpha:.17),
          borderRadius:BorderRadius.circular(18)))
      else ClipRRect(
        borderRadius:BorderRadius.circular(17),
        child:SizedBox(width:double.infinity,height:23,child:Row(
          crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          for(var i=0;i<parts.length;i++)
            if((parts[i].value??0)>0) Expanded(
              flex:math.max(1,((parts[i].value??0)/total*1000).round()),
              child:ColoredBox(
                key:ValueKey('insight-segment-'+i.toString()),
                color:_chartColors[i%_chartColors.length]),
            ),
        ])),
      ),
      const SizedBox(height:10),
      Wrap(spacing:12,runSpacing:5,alignment:WrapAlignment.center,
        children:[for(var i=0;i<parts.length;i++)
          _Legend(parts[i].label(context.app.ar),
            _chartColors[i%_chartColors.length],
            _format(context,parts[i].value)),
        ]),
      if(parts.isEmpty) _NoGraph(message:context.tr(
        'لا توجد مؤشرات متاحة','No available metrics')),
    ]);
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.label,this.color,this.number);
  final String label,number;
  final Color color;
  @override Widget build(BuildContext context)=>ConstrainedBox(
    constraints:const BoxConstraints(maxWidth:174),
    child:SizedBox(height:18,child:FittedBox(
      fit:BoxFit.scaleDown,
      alignment:AlignmentDirectional.centerStart,
      child:Row(mainAxisSize:MainAxisSize.min,children:[
        Container(width:7,height:7,decoration:BoxDecoration(
          color:color,shape:BoxShape.circle)),
        const SizedBox(width:4),
        Text(label+' '+number,maxLines:1,
          style:Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize:9.2,fontWeight:FontWeight.w700)),
      ]),
    )),
  );
}

class _DonutGraph extends StatelessWidget {
  const _DonutGraph({required this.parts,required this.center,
    required this.caption});
  final List<InsightValue> parts;
  final String center,caption;
  @override Widget build(BuildContext context) {
    return Row(children:[
      Expanded(flex:3,child:LayoutBuilder(builder:(context,box)=>Center(
        child:SizedBox(
          width:math.min(box.maxWidth,box.maxHeight),
          height:math.min(box.maxWidth,box.maxHeight),
          child:Stack(fit:StackFit.expand,children:[
            CustomPaint(painter:_RingPainter(
              values:[for(final p in parts)(p.value??0).toDouble()],
            )),
            Center(child:Column(
              mainAxisSize:MainAxisSize.min,children:[
                FittedBox(child:Text(center,style:Theme.of(context)
                  .textTheme.titleLarge?.copyWith(
                    color:Theme.of(context).colorScheme.primary,
                    fontWeight:FontWeight.w900))),
                Text(caption,maxLines:1,
                  style:Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontSize:10)),
              ],
            )),
          ]),
        ),
      ))),
      const SizedBox(width:7),
      Expanded(flex:4,child:Column(
        mainAxisAlignment:MainAxisAlignment.center,
        crossAxisAlignment:CrossAxisAlignment.start,
        children:[
          for(var i=0;i<parts.length;i++) Padding(
            padding:const EdgeInsets.symmetric(vertical:4),
            child:_Legend(parts[i].label(context.app.ar),
              _chartColors[i%_chartColors.length],
              _format(context,parts[i].value)),
          ),
        ],
      )),
    ]);
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.values});
  final List<double> values;
  @override void paint(Canvas canvas,Size size) {
    final radius=math.min(size.width,size.height)*.38;
    final rect=Rect.fromCircle(center:size.center(Offset.zero),radius:radius);
    final brush=Paint()..style=PaintingStyle.stroke
      ..strokeWidth=math.max(8,radius*.27)
      ..strokeCap=StrokeCap.round;
    brush.color=const Color(0x35477A67);
    canvas.drawArc(rect,0,math.pi*2,false,brush);
    final total=values.fold<double>(0,(a,b)=>a+math.max(0,b));
    if(total<=0)return;
    var start=-math.pi/2;
    for(var i=0;i<values.length;i++){
      final sweep=math.max(0,values[i])/total*math.pi*2;
      if(sweep<=0)continue;
      brush.color=_chartColors[i%_chartColors.length];
      canvas.drawArc(rect,start,sweep,false,brush);
      start+=sweep;
    }
  }
  @override bool shouldRepaint(covariant _RingPainter old)=>
      old.values.toString()!=values.toString();
}

class _WeekBars extends StatefulWidget {
  const _WeekBars({required this.values,required this.labels,
    this.other=const [],this.currency});
  final List<double> values,other;
  final List<String> labels;
  final String? currency;
  @override State<_WeekBars> createState()=>_WeekBarsState();
}

class _WeekBarsState extends State<_WeekBars> {
  int selected=-1;
  @override Widget build(BuildContext context){
    final cs=Theme.of(context).colorScheme;
    final grouped=widget.other.isNotEmpty;
    final all=[...widget.values,...widget.other];
    final maxValue=math.max(1.0,all.fold<double>(0,math.max));
    return Column(children:[
      if(grouped) Padding(
        padding:const EdgeInsets.only(bottom:3),
        child:Wrap(spacing:11,children:[
          _Legend(context.tr('تحصيل','Inflow'),_chartColors[0],''),
          _Legend(context.tr('صرف','Outflow'),_chartColors[2],''),
        ]),
      ),
      Expanded(child:Row(crossAxisAlignment:CrossAxisAlignment.end,children:[
        for(var i=0;i<widget.values.length;i++)
          Expanded(child:GestureDetector(
            key:ValueKey('insight-day-'+i.toString()),
            // A short tap follows the graph's documented detail route.
            // Long press selects the day value without navigating.
            onLongPress:()=>setState(()=>selected=i),
            behavior:HitTestBehavior.opaque,
            child:Padding(
              padding:const EdgeInsets.symmetric(horizontal:3),
              child:Column(children:[
                SizedBox(height:20,child:selected==i
                  ? FittedBox(child:Text(_format(context,
                      widget.values[i]+(grouped?widget.other[i]:0),
                      currency:widget.currency),
                    style:TextStyle(color:cs.primary,fontSize:9,
                      fontWeight:FontWeight.w800)))
                  : const SizedBox.shrink()),
                Expanded(child:LayoutBuilder(builder:(context,b)=>Row(
                  crossAxisAlignment:CrossAxisAlignment.end,
                  mainAxisAlignment:MainAxisAlignment.center,
                  children:[
                    Expanded(child:_Bar(
                      value:widget.values[i],max:maxValue,height:b.maxHeight,
                      color:_chartColors[0],selected:selected==i)),
                    if(grouped)...[
                      const SizedBox(width:2),
                      Expanded(child:_Bar(
                        value:widget.other[i],max:maxValue,height:b.maxHeight,
                        color:_chartColors[2],selected:selected==i)),
                    ],
                  ],
                ))),
                const SizedBox(height:4),
                Text(i<widget.labels.length?widget.labels[i]:'',
                  maxLines:1,overflow:TextOverflow.ellipsis,
                  style:TextStyle(fontSize:8.8,color:cs.onSurfaceVariant)),
              ]),
            ),
          )),
      ])),
    ]);
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value,required this.max,
    required this.height,required this.color,required this.selected});
  final double value,max,height;
  final Color color;
  final bool selected;
  @override Widget build(BuildContext context)=>AnimatedContainer(
    duration:const Duration(milliseconds:220),
    height:math.max(3,height*value/max),
    decoration:BoxDecoration(
      color:selected?color:color.withValues(alpha:.76),
      borderRadius:const BorderRadius.vertical(top:Radius.circular(7)),
    ),
  );
}

class _AreaGraph extends StatelessWidget {
  const _AreaGraph({required this.values,required this.labels});
  final List<double> values;
  final List<String> labels;
  @override Widget build(BuildContext context)=>Column(children:[
    Expanded(child:CustomPaint(
      size:Size.infinite,
      painter:_AreaPainter(values:values,
        rtl:Directionality.of(context)==TextDirection.rtl,
        color:Theme.of(context).colorScheme.primary),
    )),
    const SizedBox(height:5),
    Row(children:[
      for(var i=0;i<values.length;i++)
        Expanded(child:Text(i<labels.length?labels[i]:'',
          maxLines:1,textAlign:TextAlign.center,
          style:Theme.of(context).textTheme.bodySmall
            ?.copyWith(fontSize:8.7))),
    ]),
  ]);
}

class _AreaPainter extends CustomPainter {
  _AreaPainter({required this.values,required this.color,required this.rtl});
  final List<double> values;
  final Color color;
  final bool rtl;
  @override void paint(Canvas canvas,Size size) {
    if(values.isEmpty)return;
    final maxV=math.max(1,values.fold<double>(0,math.max));
    final w=size.width,h=size.height;
    final baseline=h-9,top=11.0;
    final points=<Offset>[
      for(var i=0;i<values.length;i++)
        Offset(values.length==1?w/2:
          (rtl?w-i*w/(values.length-1):i*w/(values.length-1)),
          baseline-(values[i]/maxV)*(baseline-top)),
    ];
    final path=Path()..moveTo(points.first.dx,points.first.dy);
    for(var i=1;i<points.length;i++){
      final previous=points[i-1],next=points[i];
      final middle=(previous.dx+next.dx)/2;
      path.cubicTo(middle,previous.dy,middle,next.dy,next.dx,next.dy);
    }
    final filled=Path.from(path)
      ..lineTo(points.last.dx,baseline)
      ..lineTo(points.first.dx,baseline)..close();
    canvas.drawPath(filled,Paint()..shader=ui.Gradient.linear(
      Offset(0,top),Offset(0,baseline),
      [color.withValues(alpha:.32),color.withValues(alpha:.02)]));
    canvas.drawPath(path,Paint()..color=color
      ..strokeWidth=2.5..style=PaintingStyle.stroke
      ..strokeCap=StrokeCap.round);
    for(var i=0;i<points.length;i++){
      canvas.drawCircle(points[i],i==points.length-1?4.5:3,
        Paint()..color=color);
      canvas.drawCircle(points[i],i==points.length-1?2.4:1.5,
        Paint()..color=Colors.white);
    }
  }
  @override bool shouldRepaint(covariant _AreaPainter old)=>
      old.values.toString()!=values.toString()||old.color!=color||old.rtl!=rtl;
}

class _HorizontalStatuses extends StatelessWidget {
  const _HorizontalStatuses({required this.parts});
  final List<InsightValue> parts;
  @override Widget build(BuildContext context) {
    if(parts.isEmpty)return _NoGraph(message:context.tr(
        'لا توجد حالات معتمدة','No verified statuses'));
    final maximum=math.max(1,parts.fold<double>(0,(a,b)=>
      math.max(a,b.value??0)));
    return Column(mainAxisAlignment:MainAxisAlignment.center,children:[
      for(var i=0;i<parts.length;i++) Expanded(child:Padding(
        padding:const EdgeInsets.symmetric(vertical:3),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[
            Expanded(child:Text(parts[i].label(context.app.ar),
              maxLines:1,overflow:TextOverflow.ellipsis,
              style:Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontSize:9.7,fontWeight:FontWeight.w700))),
            Text(_format(context,parts[i].value),
              style:TextStyle(color:_chartColors[i%_chartColors.length],
                fontSize:10,fontWeight:FontWeight.w900)),
          ]),
          const SizedBox(height:3),
          Expanded(child:ClipRRect(
            borderRadius:BorderRadius.circular(8),
            child:Stack(fit:StackFit.expand,children:[
              ColoredBox(color:Theme.of(context).colorScheme
                .outline.withValues(alpha:.14)),
              FractionallySizedBox(
                alignment:AlignmentDirectional.centerStart,
                widthFactor:((parts[i].value??0)/maximum).clamp(0.0,1.0),
                child:ColoredBox(color:_chartColors[i%_chartColors.length]),
              ),
            ]),
          )),
        ]),
      )),
    ]);
  }
}

class _StageTimeline extends StatelessWidget {
  const _StageTimeline({required this.parts});
  final List<InsightValue> parts;
  @override Widget build(BuildContext context) {
    return Row(children:[
      for(var i=0;i<parts.length;i++)...[
        if(i>0)Expanded(child:Container(height:2,
          color:Theme.of(context).colorScheme.outline.withValues(alpha:.25))),
        Column(mainAxisAlignment:MainAxisAlignment.center,children:[
          Container(
            width:43,height:43,
            decoration:BoxDecoration(
              color:_chartColors[i%_chartColors.length].withValues(alpha:.13),
              shape:BoxShape.circle,
              border:Border.all(color:_chartColors[i%_chartColors.length])),
            child:Center(child:FittedBox(child:Text(
              _format(context,parts[i].value),
              style:TextStyle(fontWeight:FontWeight.w900,fontSize:17,
                color:_chartColors[i%_chartColors.length])))),
          ),
          const SizedBox(height:5),
          SizedBox(width:55,child:Text(parts[i].label(context.app.ar),
            maxLines:2,textAlign:TextAlign.center,overflow:TextOverflow.ellipsis,
            style:Theme.of(context).textTheme.bodySmall
              ?.copyWith(fontSize:9))),
        ]),
      ],
    ]);
  }
}

class _Pipeline extends StatelessWidget {
  const _Pipeline({required this.parts});
  final List<InsightValue> parts;
  @override Widget build(BuildContext context) {
    final cs=Theme.of(context).colorScheme;
    return Row(children:[
      for(var i=0;i<parts.length;i++)...[
        if(i>0)Icon(
          Directionality.of(context)==TextDirection.rtl
            ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
          size:11,color:cs.onSurfaceVariant),
        Expanded(child:Container(
          height:85,padding:const EdgeInsets.symmetric(vertical:7,horizontal:2),
          decoration:BoxDecoration(
            color:_chartColors[i%_chartColors.length].withValues(alpha:.13),
            borderRadius:BorderRadius.circular(11),
            border:Border.all(color:_chartColors[i%_chartColors.length]
              .withValues(alpha:.5))),
          child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
            FittedBox(child:Text(_format(context,parts[i].value),
              style:TextStyle(fontSize:18,fontWeight:FontWeight.w900,
                color:_chartColors[i%_chartColors.length]))),
            const SizedBox(height:5),
            Text(parts[i].label(context.app.ar),maxLines:2,
              textAlign:TextAlign.center,overflow:TextOverflow.ellipsis,
              style:Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontSize:8.8)),
          ]),
        )),
      ],
    ]);
  }
}

class _WaffleGraph extends StatelessWidget {
  const _WaffleGraph({required this.parts});
  final List<InsightValue> parts;
  @override Widget build(BuildContext context) {
    final total=parts.fold<double>(0,(s,p)=>s+(p.value??0));
    if(total<=0)return _NoGraph(message:context.tr(
        'لا توجد مقترحات في القائمة','No proposals in this list'));
    var end=0;
    final colors=<Color>[];
    for(var i=0;i<parts.length;i++) {
      final next=i==parts.length-1?100:
          (end+((parts[i].value??0)/total*100).round()).clamp(end,100).toInt();
      for(var j=end;j<next;j++) colors.add(_chartColors[i%_chartColors.length]);
      end=next;
    }
    while(colors.length<100)colors.add(_chartColors.last);
    return Row(children:[
      Expanded(flex:3,child:Center(child:AspectRatio(
        aspectRatio:1,
        child:GridView.builder(
          physics:const NeverScrollableScrollPhysics(),
          itemCount:100,
          gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:10,mainAxisSpacing:2,crossAxisSpacing:2),
          itemBuilder:(context,i)=>DecoratedBox(
            decoration:BoxDecoration(color:colors[i],
              borderRadius:BorderRadius.circular(2)),
          ),
        ),
      ))),
      const SizedBox(width:9),
      Expanded(flex:4,child:Column(
        mainAxisAlignment:MainAxisAlignment.center,
        crossAxisAlignment:CrossAxisAlignment.start,
        children:[
          for(var i=0;i<parts.length;i++) Padding(
            padding:const EdgeInsets.symmetric(vertical:3),
            child:_Legend(parts[i].label(context.app.ar),
              _chartColors[i%_chartColors.length],
              _format(context,parts[i].value)),
          ),
        ],
      )),
    ]);
  }
}
