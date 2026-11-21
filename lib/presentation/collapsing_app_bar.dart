import 'package:flutter/material.dart';
import '../domain/models.dart';
import '../domain/screens.dart';
import 'design/login_scenery.dart';
import 'navigation.dart';
import 'navigation_registry.dart';
import 'shared/scope.dart';
import 'shared/widgets.dart';

/// Pinned brand toolbar and a wave-shaped photo hero on the home route.
/// NestedScrollView supplies the coordinated scroll: upward gestures collapse
/// this complete hero behind the pinned 66dp toolbar; downward gestures
/// re-expand it. No manual scroll jumps or screenshot backgrounds.
class AgentCollapsibleAppBar extends StatelessWidget {
  const AgentCollapsibleAppBar({super.key,required this.route,required this.title,required this.innerScrolled});
  final String route,title;
  final bool innerScrolled;
  bool get home => route=='H05'||route=='H01';

  @override Widget build(BuildContext context) {
    final rtl=Directionality.of(context)==TextDirection.rtl;
    final top=MediaQuery.paddingOf(context).top;
    final narrow=MediaQuery.sizeOf(context).width<365;
    final expanded=home?(narrow?375.0:342.0):70.0;
    return SliverAppBar(
      pinned:true,
      floating:false,
      stretch:true,
      forceElevated:innerScrolled,
      scrolledUnderElevation:0,
      elevation:0,
      toolbarHeight:70,
      expandedHeight:expanded,
      collapsedHeight:70,
      backgroundColor:Colors.transparent,
      surfaceTintColor:Colors.transparent,
      foregroundColor:Colors.white,
      automaticallyImplyLeading:false,
      flexibleSpace:LayoutBuilder(builder:(context,bounds) {
        final h=bounds.maxHeight;
        final amount=((h-top-70)/175).clamp(0.0,1.0);
        return Stack(fit:StackFit.expand,children:[
          if(home) Positioned.fill(child:LoginHeaderWave(
            dark:Theme.of(context).brightness==Brightness.dark,
            photoOnLeft:rtl,
            imageAsset:'assets/images/home_header_yemeni_veterinary_store_hero.webp',
          )),
          // The solid toolbar always survives the collapsing hero.
          Positioned(top:0,left:0,right:0,height:top+74,
            child:DecoratedBox(decoration:const BoxDecoration(
              gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,
                colors:[Color(0xFF00382D),Color(0xF7004938),Color(0xF2004938)])))),
          if(home&&amount>0) Positioned.fill(child:IgnorePointer(
            child:Opacity(opacity:amount,child:Stack(children:[
              PositionedDirectional(
                top:top+112,start:18,end:14,
                child:Align(alignment:AlignmentDirectional.centerStart,child:ConstrainedBox(
                  constraints:const BoxConstraints(maxWidth:300),
                  child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Text(_welcome(context),maxLines:2,overflow:TextOverflow.ellipsis,
                      style:const TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.w900,height:1.25,
                        shadows:[Shadow(color:Color(0x77001B12),blurRadius:8)])),
                    const SizedBox(height:6),
                    Text(context.tr('صحة الحيوان وتجارة الفرع في مساحة عمل واحدة',
                        'Animal care and branch commerce in one workspace'),
                      maxLines:2,overflow:TextOverflow.ellipsis,
                      style:const TextStyle(color:Color(0xFFF1FFF4),fontSize:12.4,height:1.55,
                        fontWeight:FontWeight.w600,
                        shadows:[Shadow(color:Color(0x99001B15),blurRadius:7)])),
                  ]),
                )),
              ),
            ])),
          )),
        ]);
      }),
      titleSpacing:0,
      centerTitle:true,
      title:InkWell(
        key:const ValueKey('agent-workspace-selector'),
        borderRadius:BorderRadius.circular(13),
        onTap:()=>_showWorkspaces(context),
        child:Padding(padding:const EdgeInsets.symmetric(horizontal:4,vertical:4),
          child:Row(mainAxisSize:MainAxisSize.min,children:[
            const BrandLogo(size:39),
            const SizedBox(width:9),
            Flexible(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
              Text(context.tr('مزرعتي','Mazraa'),maxLines:1,
                style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:23)),
              if(!home) Text(title,maxLines:1,overflow:TextOverflow.ellipsis,
                style:const TextStyle(color:Color(0xFFD3EADB),fontSize:10,height:1.15)),
            ])),
            const SizedBox(width:2),
            const Icon(Icons.keyboard_arrow_down_rounded,color:Color(0xFFD5E7DE),size:16),
          ]),
        ),
      ),
      leading:Navigator.of(context).canPop()
        ? IconButton(tooltip:context.tr('رجوع','Back'),icon:const Icon(Icons.arrow_back_rounded),
            onPressed:()=>Navigator.of(context).maybePop())
        : IconButton(tooltip:context.tr('حسابي','Account'),icon:const Icon(Icons.account_circle_outlined,size:29),
            onPressed:()=>context.open('H08')),
      actions:[
        IconButton(tooltip:context.tr('الإشعارات','Notifications'),
          icon:const Icon(Icons.notifications_none_rounded,size:26),
          onPressed:()=>context.open('H07')),
      ],
      bottom:home?PreferredSize(preferredSize:const Size.fromHeight(0),
        child:SizedBox(height:0,child:OverflowBox(
          alignment:Alignment.bottomCenter,minHeight:0,maxHeight:0,child:const SizedBox.shrink()))):null,
    );
  }

  String _welcome(BuildContext context) {
    final app=context.app;
    final name=str(app.user['name']??obj(app.profile['user'])['name']).trim();
    if(name.isEmpty)return context.tr('مرحبًا بك في مزرعتي','Welcome to Mazraa');
    return context.tr('مرحبًا، ','Welcome, ')+name;
  }

  void _showWorkspaces(BuildContext context) {
    final app=context.app;
    final choices=AgentNavigationRegistry.available(app);
    showModalBottomSheet<void>(
      context:context,
      showDragHandle:true,
      isScrollControlled:true,
      builder:(sheet)=>SafeArea(child:ConstrainedBox(
        constraints:BoxConstraints(maxHeight:MediaQuery.sizeOf(sheet).height*.72),
        child:ListView(shrinkWrap:true,padding:const EdgeInsets.fromLTRB(14,0,14,22),children:[
          ListTile(title:Text(context.tr('الأقسام ومساحات العمل','Workspaces'),
            style:Theme.of(sheet).textTheme.titleLarge),
            trailing:IconButton(tooltip:context.tr('الرئيسية','Home'),
              icon:const Icon(Icons.home_outlined),
              onPressed:(){Navigator.pop(sheet);context.open('H05');})),
          for(final workspace in choices) ListTile(
            leading:Icon(_workspaceIcon(workspace)),
            title:Text(AgentNavigationRegistry.title(workspace,app.ar)),
            trailing:const Icon(Icons.chevron_left),
            onTap:(){Navigator.pop(sheet);
              context.open(AgentNavigationRegistry.entry(app,workspace));},
          ),
        ]),
      )),
    );
  }

  IconData _workspaceIcon(AgentWorkspace workspace)=>switch(workspace){
    AgentWorkspace.home=>Icons.home_outlined,
    AgentWorkspace.clinic=>Icons.medical_services_outlined,
    AgentWorkspace.field=>Icons.location_on_outlined,
    AgentWorkspace.branch=>Icons.storefront_outlined,
    AgentWorkspace.account=>Icons.person_outline,
    AgentWorkspace.sales=>Icons.shopping_cart_outlined,
    AgentWorkspace.inventory=>Icons.inventory_2_outlined,
    AgentWorkspace.finance=>Icons.account_balance_wallet_outlined,
    AgentWorkspace.pickup=>Icons.local_shipping_outlined,
    AgentWorkspace.purchasing=>Icons.add_shopping_cart_outlined,
    AgentWorkspace.auctions=>Icons.gavel_outlined,
  };
}

/// Live warehouse scope and actual doctor availability from AgentApp.
/// Only PATCH is sent after explicit interaction; server remains authoritative.
class AgentHomeScopeStrip extends StatefulWidget {
  const AgentHomeScopeStrip({super.key});
  @override State<AgentHomeScopeStrip> createState()=>_AgentHomeScopeStripState();
}
class _AgentHomeScopeStripState extends State<AgentHomeScopeStrip> {
  bool busy=false;
  @override Widget build(BuildContext context) {
    final app=context.app;
    final available=payload(obj(app.profile['profile']))['isAvailable']==true;
    final doctor=app.access.doctor;
    return Align(
      alignment:AlignmentDirectional.centerStart,
      child:Wrap(alignment:WrapAlignment.start,crossAxisAlignment:WrapCrossAlignment.center,
        spacing:8,runSpacing:4,children:[
          Text(context.tr('النطاق الحالي','Current scope'),
            style:const TextStyle(color:Colors.white,fontSize:12,fontWeight:FontWeight.w800)),
          Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:7),
            decoration:BoxDecoration(color:const Color(0x4E9DCBAB),
              borderRadius:BorderRadius.circular(24)),
            child:Row(mainAxisSize:MainAxisSize.min,children:[
              const Icon(Icons.storefront_outlined,color:Color(0xFFE8F8E9),size:18),
              const SizedBox(width:5),
              Text(app.grant==null?context.tr('بدون فرع','No branch'):
                  context.tr('مخزن ','Warehouse ')+app.grant!.warehouse.toString(),
                style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700,fontSize:11)),
            ])),
          OutlinedButton(onPressed:()=>context.open('H06'),
            style:OutlinedButton.styleFrom(
              foregroundColor:const Color(0xFFFFE4A3),
              side:const BorderSide(color:Color(0xFFFFD68E),width:1.2),
              padding:const EdgeInsets.symmetric(horizontal:13),
              minimumSize:const Size(48,38),
              shape:const StadiumBorder()),
            child:Text(context.tr('تبديل','Change'),style:const TextStyle(fontWeight:FontWeight.w800,fontSize:12))),
          if(doctor) ...[
            Text(available?context.tr('متاح','Available'):context.tr('غير متاح','Unavailable'),
              style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:11.5)),
            Switch.adaptive(
              value:available,
              onChanged:busy?null:(value)async {
                setState(()=>busy=true);
                try {
                  await app.repo.write('PATCH','/api/agent/availability',{'available':value});
                  await app.refreshAccess();
                }catch(error) {
                  if(context.mounted)toast(context,failureText(context,error));
                }finally {
                  if(mounted)setState(()=>busy=false);
                }
              },
              activeTrackColor:const Color(0xFF17B876),
              activeThumbColor:Colors.white,
              inactiveTrackColor:const Color(0xFF51665F),
              inactiveThumbColor:const Color(0xFFE0E6E2),
              materialTapTargetSize:MaterialTapTargetSize.padded,
            ),
          ],
        ]),
    );
  }
}
