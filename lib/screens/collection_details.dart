import 'dart:convert';

import 'package:dailycollection/helpers/strings.dart';
import 'package:dailycollection/models/collections_model.dart';
import 'package:dailycollection/providers/collections_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CollectionDetailsPage extends StatefulWidget {
  CollectionDetailsPage({Key key, this.collection,this.color}) : super(key: key);

  final Collection collection;
  final Color color;

  @override
  _CollectionDetailsPageState createState() => _CollectionDetailsPageState();
}

class _CollectionDetailsPageState extends State<CollectionDetailsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  CollectionsProvider _collection;

  _showDialog() {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(// StatefulBuilder
            builder: (context, changeState) {
              return AlertDialog(
                title: Text("Confirm Delete"),
                content: Text("Are you sure you want to delete this Collection?"),
                actions: <Widget>[
                  FlatButton(
                    onPressed: (){
                      Navigator.pop(context);
                    },
                    child: Text("Cancel"),
                  ),
                  FlatButton(
                    onPressed: (){
                      showProgress();
                      Navigator.pop(context);
                    },
                    child: Text("DELETE"),
                  ),
                ],
              );
            });
      },
    );
  }

  Future<void> showProgress() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CupertinoActivityIndicator(radius: 20),
          );
        });
    await delete();
    Navigator.pop(context);
  }

  Future<void> delete() async {

      SharedPreferences prefs = await SharedPreferences.getInstance();

      try {
        var token = prefs.getString("token");

        Map<String, String> headers = {
          "Content-Type": "application/x-www-form-urlencoded",
          "Authorization": "Bearer $token"
      };

        var body = {
          'uuid': widget.collection.uuid
        };

        await http.post('${Resources.appURL}delete_collection', body: body,headers: headers).then((
            response) {
          print(response.body);
          if(response.statusCode == 200){

            _scaffoldKey.currentState.showSnackBar(SnackBar(
              content: Text("Collection Deleted Successfully !"),
            ));
            _collection = Provider.of<CollectionsProvider>(context,listen: false);
            _collection.getUsersList(_scaffoldKey);
            Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        body: Container(
          child: Stack(
            children: <Widget>[
              Container(
                height: 300,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColorDark
                  ],
                )),
                width: MediaQuery.of(context).size.width,
              ),
              Container(
                  margin: EdgeInsets.only(top: 100),
                  decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.only(topRight: Radius.circular(30)),
                      color: Colors.white),
                  child: Column(children: <Widget>[
                    SizedBox(
                      height: 15,
                    ),
                    Text(
                      "Collection Details",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme
                              .of(context)
                              .primaryColorDark),
                      textAlign: TextAlign.center,
                    ),
                    Divider(),
                    Expanded(
                      child: SingleChildScrollView(
                          child: Column(
                        children: <Widget>[
                          SizedBox(
                            height: 10,
                          ),
                          Container(
                              margin: EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[100]),
                              child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                      onTap: () {},
                                      borderRadius: BorderRadius.circular(8),
                                      child: Column(
                                        children: <Widget>[
                                          ListTile(
                                            title: Text(
                                              toBeginningOfSentenceCase(widget.collection.customer_name),
                                            ),
                                            subtitle: Text(
                                              "${widget.collection.amount}.00",
                                              style: TextStyle(color: Theme
                                                  .of(context)
                                                  .accentColor,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                            leading: Container(
                                                width: 50,
                                                height: 50,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                    shape: BoxShape.circle, color: widget.color),
                                                child: Text(
                                                  widget.collection.customer_name.substring(0,1).toUpperCase(),style: TextStyle(color: Colors.white,fontWeight: FontWeight.w500,fontSize: 27),
                                                )
                                            ),
                                          ),
                                          Divider(),
                                          ListTile(
                                            title: Text("Company"),
                                            subtitle: Text(widget.collection.company_name),
                                          ),
                                          ListTile(
                                            title: Text("Collection Type"),
                                            subtitle: Text(widget.collection.collection_type_name),
                                          ),
                                          widget.collection.sub_type == null ? Container() :
                                          ListTile(
                                            title: Text("Collection Sub Type"),
                                            subtitle: Text(widget.collection.sub_type),
                                          ),
                                          ListTile(
                                            title: Text("Created On"),
                                            subtitle: Text(widget.collection.created_at),
                                          )
                                        ],
                                      )))),
                          SizedBox(
                            height: 25,
                          ),
                          FlatButton(
                            color: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: EdgeInsets.symmetric(
                                vertical: 15, horizontal: 60),
                            onPressed: () {
                              _showDialog();
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  "DELETE",
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.redAccent),
                                ),
                                SizedBox(width: 5,),
                                Icon(Icons.delete,color: Colors.redAccent,)
                              ],
                            )
                          ),
                          SizedBox(
                            height: 10,
                          ),
                        ],
                      )),
                    )
                  ])),
              Container(
                margin: EdgeInsets.only(top: 70, left: 10),
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Icon(Icons.close),
                ),
              ),
            ],
          ),
        ) // This trailing comma makes auto-formatting nicer for build methods.
        );
  }
}
