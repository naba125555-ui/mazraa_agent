import 'dart:math';
import 'package:flutter/material.dart';
import 'scope.dart';
import 'widgets.dart';

class ChartValue {
  const ChartValue(this.label,this.value,this.color);
  final String label;final double value;final Color color;
}
/// Small dependency-free vector charts. Labels and exact values remain accessible.
class BarChartCard extends StatelessWidget{
  const BarChartCard({super.key,required this.title,required this.values,this.unit=''});
  final String title,unit;final List<ChartValue> values;
  @override Widget build(BuildContext context)=>Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(title,style:Theme.of(context).textTheme.titleMedium),const SizedBox(height:20),
    if(values.isEmpty||values.every((v)=>v.value==0))Empty(text:context.tr('لا توجد بيانات لهذه الفترة','No data for this period'),icon:Icons.bar_chart),
    if(values.any((v)=>v.value!=0))...[
      SizedBox(height:140,child:CustomPaint(size:const Size(double.infinity,140),painter:_Bars(values,Theme.of(context).colorScheme.outline))),
      const SizedBox(height:16),for(final v in values)Semantics(label:'${v.label}: ${v.value} $unit',child:Row(children:[
        Icon(Icons.circle,size:9,color:v.color),const SizedBox(width:8),Expanded(child:Text(v.label)),Text('${display(context,v.value)} $unit')]))],
  ]));
}
class _Bars extends CustomPainter{
  _Bars(this.values,this.grid);final List<ChartValue> values;final Color grid;
  @override void paint(Canvas canvas,Size size){
    final maximum=values.map((v)=>v.value.abs()).fold(1.0,max);
    final paint=Paint()..color=grid.withValues(alpha:.35)..strokeWidth=1;
    for(var i=0;i<4;i++){final y=size.height*i/3;canvas.drawLine(Offset(0,y),Offset(size.width,y),paint);}
    final slot=size.width/values.length;
    for(var i=0;i<values.length;i++){
      final h=values[i].value.abs()/maximum*(size.height-7);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(slot*i+slot*.22,size.height-h,slot*.56,h),const Radius.circular(6)),Paint()..color=values[i].color);
    }
  }
  @override bool shouldRepaint(covariant _Bars old)=>old.values!=values||old.grid!=grid;
}
class RingChartCard extends StatelessWidget{
  const RingChartCard({super.key,required this.title,required this.values});final String title;final List<ChartValue> values;
  @override Widget build(BuildContext context){final sum=values.fold(0.0,(s,v)=>s+v.value);
    return Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:Theme.of(context).textTheme.titleMedium),
      const SizedBox(height:20),Center(child:SizedBox.square(dimension:140,child:Stack(alignment:Alignment.center,children:[
        CustomPaint(size:const Size(140,140),painter:_Ring(values,Theme.of(context).colorScheme.outline)),Text(display(context,sum),style:Theme.of(context).textTheme.headlineSmall)]))),
      const SizedBox(height:20),for(final v in values)Padding(padding:const EdgeInsets.symmetric(vertical:4),child:Row(children:[
        Icon(Icons.circle,size:10,color:v.color),const SizedBox(width:8),Expanded(child:Text(v.label)),Text(display(context,v.value))])),
    ]));}
}
class _Ring extends CustomPainter{
  _Ring(this.values,this.empty);final List<ChartValue> values;final Color empty;
  @override void paint(Canvas canvas,Size size){
    final p=Paint()..style=PaintingStyle.stroke..strokeWidth=15..strokeCap=StrokeCap.butt;
    final rect=Rect.fromLTWH(10,10,size.width-20,size.height-20);final sum=values.fold(0.0,(s,v)=>s+max(0,v.value));
    if(sum==0){canvas.drawOval(rect,p..color=empty.withValues(alpha:.4));return;}
    var start=-pi/2;
    for(final v in values){final sweep=max(0,v.value)/sum*2*pi;canvas.drawArc(rect,start,max(0,sweep-.03),false,p..color=v.color);start+=sweep;}
  }
  @override bool shouldRepaint(covariant _Ring old)=>old.values!=values||old.empty!=empty;
}
