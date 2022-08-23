
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_auth_ui/flutter_auth_ui.dart';
import 'package:flutter_barber_booking/screens/home_screen.dart';
import 'package:flutter_barber_booking/state/state_management.dart';
import 'package:flutter_barber_booking/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //firebase
  await Firebase.initializeApp();
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      onGenerateRoute: (settings){
        switch(settings.name){
          case '/home':
            return PageTransition(
                settings: settings,
                child: HomePage(),
                type: PageTransitionType.fade);
            break;
          default:return null;
        }
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home:  MyHomePage(),
    );
  }
}




class MyHomePage extends ConsumerWidget {
  // final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();



  processLogin(BuildContext context)  {
    var user = FirebaseAuth.instance.currentUser;
    if(user == null){ // kullanıcı login değilse. login ekranını göster

      FlutterAuthUi.startUi(
          items: [AuthUiProvider.phone],
          tosAndPrivacyPolicy: TosAndPrivacyPolicy(
              tosUrl: "https://google.com",
              privacyPolicyUrl: "https://youtube.com"),
          androidOption: AndroidOption(
              enableSmartLock: false,
              showLogo: true,
              overrideTheme: true
          )
      ).then((firebaseuser) async{
        // scaffoldMessengerKey.currentState!.showSnackBar(
        //     SnackBar(content: Text("Giriş başarılı ${FirebaseAuth.instance.currentUser!.phoneNumber}")));
        //Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        await checkLoginState(context,true,scaffoldMessengerKey);
      }).catchError((e){
        if(e is PlatformException){
          scaffoldMessengerKey.currentState!.showSnackBar(
              SnackBar(content: Text("${e.toString()}"))
          );
        }
      });

    }
    else{

    }
  }

  @override
  Widget build(BuildContext context, watch) {
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage("assets/images/my_bg.png"),
                fit: BoxFit.cover
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                width: MediaQuery.of(context).size.width,
                child: FutureBuilder(
                  future:checkLoginState(context,false,scaffoldMessengerKey),
                  builder: (context,snapshot){
                    if(snapshot.connectionState == ConnectionState.waiting){
                      return Center(child: CircularProgressIndicator(),);
                    }
                    else{
                      var userState = snapshot.data as LOGIN_STATE;
                      if(userState == LOGIN_STATE.LOGGED){
                        return Container();
                      }
                      else{
                        return ElevatedButton.icon(
                          onPressed: () => processLogin(context),
                          icon: Icon(Icons.phone,color: Colors.white,),
                          label: Text("Telefonla giriş yap",
                            style: GoogleFonts.jetBrainsMono(color: Colors.white,),),
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(Colors.black),
                          ),
                        );
                      }
                    }
                  },
                ),
              )
            ],
          ),
        ),
      ),);
  }

  Future<LOGIN_STATE> checkLoginState(BuildContext context, bool fromLogin,GlobalKey<ScaffoldMessengerState> scaffoldMessengerState) async {
   if(!context.read(forceReload).state){
     await Future.delayed(Duration(seconds: fromLogin == true ? 0 :3)).then((value) => {
       FirebaseAuth.instance.currentUser!.getIdToken().then((token) async {
         //eğer token varsa yazdıracaz
         print('$token');
         // context.read<userToken>().state = token;
         context.read(userToken).state = token;

         // Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
         //user zaten login se, yeni ekrana başlatacağız.

         CollectionReference userRef = FirebaseFirestore.instance.collection("User");
         DocumentSnapshot snapshotUser = await userRef.doc(FirebaseAuth.instance.currentUser!.phoneNumber).get();
         context.read(forceReload).state = true;
         if(snapshotUser.exists){
           //user zaten login se, yeni ekrana başlatacağız.
           Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
         }
         else{
           //eğer kullanıcı bilgilerine erişim yoksa, dialog gösterecez
           var nameController = TextEditingController();
           var addressController = TextEditingController();
           AlertDialog(
             title : Text("PROFİL GÜNCELLEME"),
             content: Column(
               children: [
                 TextField(
                   decoration: InputDecoration(
                     icon: Icon(Icons.account_circle),
                     labelText: "Ad",
                   ),
                   controller: nameController,
                 ),
                 TextField(
                   decoration: InputDecoration(
                     icon: Icon(Icons.home),
                     labelText: "Adres",
                   ),
                   controller: addressController,
                 ),
               ],
             ),
             actions: [
               TextButton(child: Text("İPTAL"),onPressed: () => Navigator.pop(context) ),
               TextButton(child: Text("İPTAL"), onPressed: () {
                 //server güncelleyeceğiz
                 userRef.doc(FirebaseAuth.instance.currentUser!.phoneNumber)
                     .set({
                   "name" : nameController.text,
                   "address" : addressController.text
                 }).then((value) async {
                   Navigator.pop(context);
                   ScaffoldMessenger.of(scaffoldMessengerState.currentContext!)
                       .showSnackBar(SnackBar(content: Text("PROFİL GÜNCELLEME BAŞARILI")));
                   await Future.delayed(Duration(seconds: 1),(){
                     Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                   });
                 })
                     .catchError((e){
                   Navigator.pop(context);
                   ScaffoldMessenger.of(scaffoldMessengerState.currentContext!)
                       .showSnackBar(SnackBar(content: Text('$e')));
                 });
               }),
             ],
           );
         }
       })
     });
   }

    return FirebaseAuth.instance.currentUser != null
        ? LOGIN_STATE.LOGGED
        : LOGIN_STATE.NOT_LOGIN;
  }
}
