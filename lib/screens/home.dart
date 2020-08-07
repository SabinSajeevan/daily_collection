import 'package:dailycollection/helpers/database_helper.dart';
import 'package:dailycollection/helpers/strings.dart';
import 'package:dailycollection/models/collections_model.dart';
import 'package:dailycollection/providers/collections_provider.dart';
import 'package:dailycollection/providers/companies_provider.dart';
import 'package:dailycollection/screens/add_collection.dart';
import 'package:dailycollection/screens/collection_details.dart';
import 'package:dailycollection/screens/login.dart';
import 'package:device_id/device_id.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();

  //HomePage
  CollectionsProvider _collection;
  CompaniesProvider _company;

  var _isLoadingForFirstTime = true;
  String agentName = '';
  String user_id = '';
  int previousTotal = 0;

  var colorsList = [0xffc6e3f7, 0xffd9e3e5, 0xffefc5b5, 0xffeae3d2];

  TextEditingController controller = new TextEditingController();
  String filter;

  initState() {
    getUserDetails();
    controller.addListener(() {
      setState(() {
        filter = controller.text;
      });
    });
    super.initState();
  }

  getUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      agentName = prefs.getString("name");
      user_id = prefs.getString("user_id");
    });
  }

  @override
  void didChangeDependencies() {
    if (_isLoadingForFirstTime) {
      _collection = Provider.of<CollectionsProvider>(context);
      _collection.getAgentID(_scaffoldKey);
    }

    _isLoadingForFirstTime = false;
    super.didChangeDependencies();
  }

  dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget _buildListView(list) {
    return ListView.separated(
      itemCount: list.length + 1,
      shrinkWrap: true,
      reverse: true,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        if(index == list.length) {
          return SizedBox(
            height: 50,
            child: Container(
                margin: EdgeInsets.only(left: 20, right: 20, bottom: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).primaryColor,
                      ),
                      hintText: "Search"),
                )),
          );
        } else {
          if (filter == null || filter == "") {
            return _buildRow(list[index],index);
          } else {
            if (list[index].customer_name
                .toLowerCase()
                .contains(filter.toLowerCase())) {
              return _buildRow(list[index],index);
            } else {
              return new Container();
            }
          }
        }
      },
      separatorBuilder: (context,index){
        if (filter == null || filter == "") {
          return Divider(height: 1,);
        } else {
          if (list[index].customer_name
              .toLowerCase()
              .contains(filter.toLowerCase())) {
            return Divider();
          } else {
            return new Container(height: 1,);
          }
        }
      },
    );
  }

  Widget _buildRow(Collection c,index) {
    return new Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          title: Text(
            toBeginningOfSentenceCase(c.customer_name),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                "${c.amount}.00",
                style: TextStyle(color: Theme
                    .of(context)
                .accentColor, fontWeight: FontWeight.w500),
          ),
          Text(
            "${c.company_name} | ${c.collection_number}",
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
      leading: Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(colorsList[index > 3 ? index % 4 : index])),
          child: Text(
            c.customer_name.substring(0, 1).toUpperCase(),
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500, fontSize: 27),
          )),
      trailing: Text(
        DateFormat.jm().format(DateTime.parse(c.created_at)),
      ),
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CollectionDetailsPage(
                      collection: c,
                      color: Color(colorsList[index > 3 ? index % 4 : index]),
                    )));
      },
        )
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
    bool result = await logOut();
    Navigator.pop(context);
    if (result) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.clear();
      DatabaseHelper helper = DatabaseHelper.instance;
      helper.deleteAllFromTable();
      _collection.setPreviousTotal(0);
      _collection.setTodayTotal(0);
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => LoginPage()));
    }
  }

  Future<bool> logOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool res = false;
    try {
      var token = prefs.getString("token");

      Map<String, String> headers = {
        "Content-Type": "application/x-www-form-urlencoded",
        "Authorization": "Bearer $token"
      };
      String deviceid = await DeviceId.getID;

      var body = {'device_id': deviceid};
      await http
          .post('${Resources.appURL}delete_token', body: body, headers: headers)
          .then((response) {
        print(response.body);
        if (response.statusCode == 200) {
          res = true;
        }
      });
    } catch (e) {
      print(e);
      if (e.toString().contains("SocketException")) {
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text("Network error,Please try again later."),
        ));
      } else {
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text(e.toString()),
        ));
      }
    }
    return res;
  }

  @override
  Widget build(BuildContext context) {
    previousTotal = _collection.getPreviousTotal();

    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        body: Container(
            child:RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: (){
                return _collection.getUsersList(_scaffoldKey);
              },
              child: Stack(
                children: <Widget>[
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme
                                .of(context)
                                .primaryColor,
                            Theme
                                .of(context)
                                .primaryColorDark
                          ],
                        )
                    ),
                    width: MediaQuery
                        .of(context)
                        .size
                        .width,
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 30, right: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        MaterialButton(
                          onPressed: () {
                            showProgress();
                          },
                          child: Row(
                            children: <Widget>[
                              Text(
                                "LogOut ",
                                style: TextStyle(
                                    color: Colors.red, fontWeight: FontWeight.w500),
                              ),
                              Icon(
                                Icons.exit_to_app,
                                color: Colors.red,
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 70),
                    child: ListTile(
                      title: Text(
                        toBeginningOfSentenceCase(agentName),
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      subtitle: Text(
                        user_id,
                        style: TextStyle(fontSize: 15, color: Colors.white),
                      ),
                      leading: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: Colors.white),
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Theme
                              .of(context)
                              .primaryColor,
                        ),
                      ),
                    ),
                  ),
                  Container(
                      margin: EdgeInsets.only(top: 180),
                      decoration: BoxDecoration(
                          borderRadius:
                          BorderRadius.only(topLeft: Radius.circular(30)),
                          color: Colors.white),
                      child:
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            SizedBox(
                              height: 10,
                            ),
                            Text(
                              "Today's Collections",
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme
                                      .of(context)
                                      .primaryColorDark),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              "( ${DateFormat('MMM d, ''yyyy').format(
                                  DateTime.now())} )",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme
                                      .of(context)
                                      .primaryColorDark),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 20),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[200]),
                                  borderRadius: BorderRadius.circular(5)
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment
                                        .spaceBetween,
                                    children: <Widget>[
                                      Text("Prev : ${previousTotal}.00",
                                        style: TextStyle(
                                          color: Theme
                                              .of(context)
                                              .primaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),),
                                      Text("Today : ${_collection
                                          .getTodayTotal()}.00",
                                        style: TextStyle(
                                          color: Theme
                                              .of(context)
                                              .primaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),),
                                    ],
                                  ),
                                  SizedBox(height: 4,),
                                  Text("Total : ${(_collection.getTodayTotal() +
                                      previousTotal).toString()}.00",
                                    style: TextStyle(
                                        color: Theme
                                            .of(context)
                                            .accentColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16
                                    ),)
                                ],
                              ),
                            ),
                            _collection.isLoading() ? Container(
                              margin: EdgeInsets.only(top: 100),
                              alignment: Alignment.center,
                              child: CupertinoActivityIndicator(radius: 20),
                            ) : _collection.isEmpty() ? ListView(
                                shrinkWrap: true,
                                children: <Widget>[
                                  SizedBox(height: 100,),
                                  Text("No Collections Yet!",textAlign: TextAlign.center,),
                                ]):
                            Flexible(
                                child: SingleChildScrollView(
                                    child:
                                    _buildListView(_collection.getUsers())
                                )
                            )
                          ]
                      )),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Container(
                          margin: EdgeInsets.only(top: 150, right: 25),
                          child: FloatingActionButton(
                            mini: false,
                            onPressed: () {
                              Navigator.push(
                                  context, MaterialPageRoute(builder: (
                                  context) => AddCollectionPage()));
                            },
                            child: Icon(Icons.add),
                            backgroundColor: Theme
                                .of(context)
                                .accentColor,
                          ))
                    ],
                  )
                ],
              ),
            )
        ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme
                    .of(context)
                    .primaryColor,
                Theme
                    .of(context)
                    .primaryColorDark
              ],
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey[300],
                  offset: Offset(1, 1)
              ),
            ]
        ),
        padding: EdgeInsets.symmetric(vertical: 7, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text('TechnoSoft', style: TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w500),
            ),
            Text('Version 2.7.1', style: TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
