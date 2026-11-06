import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'scope.dart';
import 'widgets.dart';

Future<String?> scanCode(BuildContext context)=>Navigator.push<String>(context,MaterialPageRoute(builder:(_)=>const ScanCapture()));
class ScanCapture extends StatefulWidget{
  const ScanCapture({super.key});
  @override State<ScanCapture> createState()=>_ScanCaptureState();
}
class _ScanCaptureState extends State<ScanCapture> with WidgetsBindingObserver{
  final controller=MobileScannerController();final text=TextEditingController();bool returned=false;
  @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);}
  @override void dispose(){WidgetsBinding.instance.removeObserver(this);controller.dispose();text.dispose();super.dispose();}
  @override void didChangeAppLifecycleState(AppLifecycleState state){if(state==AppLifecycleState.resumed){controller.start();}else{controller.stop();}}
  void finish(String value){if(returned||value.trim().isEmpty)return;returned=true;controller.stop();Navigator.pop(context,value.trim());}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(context.tr('مسح باركود أو QR','Scan barcode or QR')),actions:[
    IconButton(onPressed:()=>controller.toggleTorch(),icon:const Icon(Icons.flashlight_on_outlined)),IconButton(onPressed:()=>controller.switchCamera(),icon:const Icon(Icons.cameraswitch_outlined))]),
    body:Column(children:[Expanded(child:ClipRRect(borderRadius:BorderRadius.circular(24),child:MobileScanner(controller:controller,
      onDetect:(capture){final value=capture.barcodes.firstOrNull?.rawValue;if(value!=null)finish(value);},errorBuilder:(c,e)=>Empty(icon:Icons.no_photography_outlined,
        text:context.tr('تعذر تشغيل الكاميرا. يمكنك إدخال الرمز يدويًا.','Camera unavailable. Enter the code manually below.'))))),
      SafeArea(top:false,child:Padding(padding:const EdgeInsets.all(18),child:Column(children:[
        TextField(controller:text,textDirection:TextDirection.ltr,decoration:InputDecoration(labelText:context.tr('الباركود أو الرمز التسلسلي','Barcode or serial number'))),const SizedBox(height:12),
        SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>finish(text.text),child:Text(context.tr('استخدام الرمز','Use code')))),
      ]))),
    ]));
}
