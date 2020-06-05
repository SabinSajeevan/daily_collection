import 'dart:convert';

import 'package:dailycollection/helpers/strings.dart';
import 'package:dailycollection/screens/home.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  bool isPasswordVisible = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  var _userIDController = TextEditingController();
  var _passwordController = TextEditingController();

  Future<void> showProgress() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child:  CupertinoActivityIndicator(radius: 20),);
        });
    var logged = await login();
    Navigator.pop(context);
    if(logged)
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
  }

  Future<bool> login() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var isLogin = false;

    if (_formKey.currentState.validate()) {
      var body = {'user_id': _userIDController.text.trim(), 'password': _passwordController.text.trim() };
      //String jsonBody = json.encode(body);

      //php -S 192.168.43.125:8000 -t public

      //php artisan make:migration create_users_table --create=users

      try {

        Map<String, String> headers = {
          "Content-Type": "application/x-www-form-urlencoded",
        };

        await http.post('${Resources.appURL}login', body: body,headers: headers).then((
            response) {
          print(response.body);
          if(response.statusCode == 200){
            prefs.setBool('isLogged',true);
            prefs.setString('token', json.decode(response.body)['token'] );
            prefs.setString('name', json.decode(response.body)['agent']['name']);
            prefs.setString('uuid', json.decode(response.body)['agent']['uuid'] );
            prefs.setString('user_id', json.decode(response.body)['agent']['user_id'] );
            isLogin = true;
          }else{
            _scaffoldKey.currentState.showSnackBar(SnackBar(
              content: Text(json.decode(response.body)['error']),
            ));
          }
          //print(json.decode(response.body));
        });
      }catch (e){
        print(e);
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text(e.toString()),
        ));
      }
    }

    return isLogin;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: 50.0,),
                  Padding(padding: EdgeInsets.only(left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Image.asset(
                        "images/logo.jpg", width: 100, fit: BoxFit.cover,),
                      Text("Welcome", style: TextStyle(fontSize: 35,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff234E6B))),
                      Text("Log in to Continue", style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                          fontSize: 15),),
                    ],
                  ),
                  ),
                  SizedBox(height: 80,),
          Form(
            key: _formKey,
            child:Column(
              children: <Widget>[
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200]
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        SizedBox(height: 5,),
                        Text("USER ID"),
                        TextFormField(
                          controller: _userIDController,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (term){
                            FocusScope.of(context).nextFocus();
                          },
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              hintText: "Enter UserID"
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 10,),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200]
                    ),
                    padding: EdgeInsets.only(top: 5,bottom: 5,left: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        SizedBox(height: 5,),
                        Text("PASSWORD"),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextFormField(
                                obscureText: !isPasswordVisible,
                                decoration: InputDecoration(
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    hintText: "Enter Password",
                                ),
                                textInputAction: TextInputAction.done,
                                controller: _passwordController,
                                onFieldSubmitted: (value){
                                  showProgress();
                                },
                              ),
                            ),
                            Material(
                                color: Colors.transparent,
                                child: InkWell(
                                    customBorder: CircleBorder(),
                                    onTap: (){
                                      setState(() {
                                        isPasswordVisible = !isPasswordVisible;
                                      });
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(20),
                                      child: Icon(isPasswordVisible ? Icons.visibility_off : Icons.visibility,color: Theme.of(context).primaryColor,),
                                    )
                                )
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 20,),
              ],
            )
          )
                ],
              ),
        ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(topRight: Radius.circular(30),bottomRight: Radius.circular(4)),
          color: Color(0xff234E6B),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: (){
                showProgress();
                //Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text("LOGIN", style: TextStyle(
                          fontSize: 20, color: Colors.white,fontWeight: FontWeight.w500)),
                      Image.asset("images/signin.png", width: 35,
                        height: 35,
                        fit: BoxFit.cover,)
                    ]),
              )
          ),
        ),
      ),
    );
  }
}
