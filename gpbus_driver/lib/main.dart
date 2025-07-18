// ignore_for_file: prefer_const_constructors

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'widgets/infoTextBox.dart';
import 'pages/homePage.dart';

Future<bool> autenticateDriver(Dio httpClient, int id, String password)async{
  try{
    final response = await httpClient.get(
      //DEBUG
      "https://gpbus-psql-python-rest-api.onrender.com/authenticateDriver/",
      queryParameters: {
        'driverId': id.toString(),
        'driverPassword': password.toString()
      }
    );

    return bool.parse(json.decode(response.toString())["hasAccess"].toString().toLowerCase());
  }on DioException catch (e){
    if(jsonDecode(e.response.toString())["detail"] == "Server overload"){
      throw Exception("Servidor cheio");
    }else{
      throw Exception("Erro desconhecido: "+ e.toString());
    }
  }
  
}
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    
      title: 'login',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 247, 194, 97)),
      ),
      home: FormContainer(),
    );
}

class FormContainer extends StatefulWidget{
  final String errorMsg;
  const FormContainer({super.key, this.errorMsg = ""});

  @override
  State<FormContainer> createState() =>_FormContainerState();
}

class _FormContainerState extends State<FormContainer>{
  void nextPage(int id, String pswd){
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BusDriverPage(
          theme: Theme.of(context),
          driverId: id,
          driverPassword: pswd,
        ),
      ),
    );
  }

  InputDecoration retornar_dec_campo_texto(String nome_campo) => InputDecoration(
      labelText: nome_campo,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      isDense: true,
    );

  
 
  static const Color contrasteFormText = Color.fromARGB(132, 104, 73, 34);
  static const Color contrasteFormContainers = Color.fromARGB(132, 255, 212, 160);
  late Dio httpClient;
  bool _isLoading = false;
  TextEditingController _idController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  String errorMsg = "";
  @override
  void initState() {
    httpClient=Dio();
    errorMsg= widget.errorMsg;
    print("widget.errorMsg "+ widget.errorMsg);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: false,
    body: Center(
      child: SizedBox(
        width: 300,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "GPBus para motoristas",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: contrasteFormText,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 15),
            Icon(
              Icons.lock,
              size:80,
              color: contrasteFormText
            ),
            SizedBox(height: 20,),
            TextField(
              controller: _idController,
              decoration: retornar_dec_campo_texto("id do motorista"),
            ),
            SizedBox(height: 20,),
            TextField(
              controller: _passwordController,
              decoration: retornar_dec_campo_texto("senha"),
            ),
            SizedBox(height: 20,),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () async{
                  if(!_isLoading){
                    setState(() {
                      _isLoading = true;
                      errorMsg="";
                    });
                    int id;
                    String password = _passwordController.text;
                    try{
                      id = int.parse(_idController.text);
                    }catch (e){
                      setState(() {
                        errorMsg="Não existe nenhum motorista com esse id e essa senha";
                        _isLoading=false;
                      });
                      return;
                    }
                    try{
                      bool fezLogin = await autenticateDriver(httpClient, id, password);
                      if(fezLogin){
                        nextPage(id,password);
                      }else{
                        setState(() {
                          errorMsg="Não existe nenhum motorista com esse id e essa senha";
                        });
                      }
                      //ir para a proxima pagina
                    }catch (e){
                      late String msg;
                      if(e.toString() == "Exception: Servidor cheio"){
                        msg = "Servidor cheio, tente novamente mais tarde";
                      }else{
                        msg= e.toString();
                      }
                      setState(() {
                        errorMsg=msg;
                      });
                    }finally{
                      setState(() {
                        _isLoading=false;
                      });
                    }
                    
                  }
                  
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: contrasteFormContainers,
                ),
                child: buttonContentBuilder(_isLoading,contrasteFormText) 
              )
            ),
            SizedBox(height: 20,),

            if(infoTextBox(errorMsg,-1)!=null) infoTextBox(errorMsg,-1)!
          ],
        ) 
      ),
    ),
  );
}

SizedBox buttonContentBuilder(bool isloading, Color contrasteFormbg)=>
  SizedBox(
    child: Padding(padding: EdgeInsets.all(5), 
      child: isloading 
      ? CircularProgressIndicator(color: contrasteFormbg) 
      : Text('Acessar',style: TextStyle(fontSize: 20, color: contrasteFormbg)))
  );
