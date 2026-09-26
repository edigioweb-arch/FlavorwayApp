import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flavorapps/screens/support_tickets_screen.dart';
import 'package:flavorapps/services/support_ticket_service.dart';

class TicketFake extends SupportTicketService {
  final requests=<Map<String,dynamic>>[];
  @override
  Future<Map<String,dynamic>> request(String suffix,{Map<String,dynamic>? body,int page=1}) async {
    if(body!=null){requests.add(body);return {'data':{'id':7}};}
    if(suffix.isEmpty)return {'data':[],'next_page':null};
    return {'data':{'id':7,'reference':'SUP-TEST','subject':'Localisation','status':'new'},'messages':[{'body':'Nous vérifions','role':'support','mine':false,'created_at':'2026-09-26T10:00:00Z'}],'next_page':null};
  }
}
void main(){
 testWidgets('Order context opens a ticket then shows the Support response',(tester)async{
  final api=TicketFake();
  await tester.pumpWidget(MaterialApp(home:SupportTicketsScreen(service:api,orderReference:'FW-TEST')));await tester.pumpAndSettle();
  await tester.tap(find.text('Ouvrir un ticket'));await tester.pumpAndSettle();
  expect(find.text('FW-TEST'),findsOneWidget);
  await tester.enterText(find.byType(TextFormField).at(1),'Localisation');
  await tester.enterText(find.byType(TextFormField).at(2),'Mon bon repère');
  await tester.ensureVisible(find.text('Envoyer au Support'));await tester.tap(find.text('Envoyer au Support'));await tester.pumpAndSettle();
  expect(api.requests.single['order_reference'],'FW-TEST');expect(api.requests.single['body'],'Mon bon repère');
  expect(find.text('SUP-TEST'),findsOneWidget);expect(find.text('Nous vérifions'),findsOneWidget);
 });
}
