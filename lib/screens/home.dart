import 'package:dailycollection/models/collections_model.dart';
import 'package:dailycollection/providers/collections_provider.dart';
import 'package:dailycollection/screens/add_collection.dart';
import 'package:dailycollection/screens/collection_details.dart';
import 'package:dailycollection/screens/login.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  new GlobalKey<RefreshIndicatorState>();

  CollectionsProvider _collection;
  var _isLoadingForFirstTime = true;
  String agentName = '';
  String user_id = '';

  var colorsList = [0xffc6e3f7,0xffd9e3e5,0xffefc5b5,0xffeae3d2];

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
      _collection.getUsersList(_scaffoldKey);
    }
    _isLoadingForFirstTime = false;
    super.didChangeDependencies();
  }

  dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget _buildListView(list) {
    var total = 0;
    return ListView.separated(
        itemCount: list.length + 1,
        shrinkWrap: true,
        reverse: true,
        physics: NeverScrollableScrollPhysics(),
        itemBuilder: (BuildContext context, int index) {
          if(index != list.length)
            total = total + int.parse(list[index].amount);
          if(index == list.length) {
            return Text(
              "Total amount : \u20B9$total.00", textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme
                      .of(context)
                      .primaryColor, fontWeight: FontWeight.w500, fontSize: 16
              ),);
          }else {
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
          return Divider();
        } else {
          if (list[index].customer_name
              .toLowerCase()
              .contains(filter.toLowerCase())) {
            return Divider();
          } else {
            return new Container();
          }
        }
      },
    );
  }

  Widget _buildRow(Collection c,index) {
    return new ListTile(
      title: Text(
        toBeginningOfSentenceCase(c.customer_name),
      ),
      subtitle: Text(
        "\u20B9${c.amount}.00",
        style: TextStyle(color: Theme.of(context).primaryColor),
      ),
      leading: Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: Color(colorsList[index > 3 ? index % 4 : index])),
          child: Text(
            c.customer_name.substring(0,1).toUpperCase(),style: TextStyle(color: Colors.white,fontWeight: FontWeight.w500,fontSize: 27),
          )
      ),
      trailing: Text(DateFormat.jm().format(DateTime.parse(c.created_at)),),
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (context) => CollectionDetailsPage(collection: c,color: Color(colorsList[index > 3 ? index % 4 : index]),)));
      },
    );
  }

  Future<void> logOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
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
                color: Theme.of(context).primaryColor,
                width: MediaQuery.of(context).size.width,
              ),
              Padding(
                padding: EdgeInsets.only(top: 40, right: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    MaterialButton(
                      onPressed: () {
                        logOut();
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
/*            Container(
              margin: EdgeInsets.only(top: 70,left: 20),
              child: Text("Welcome,",style: TextStyle(color: Colors.white,fontStyle: FontStyle.italic,fontWeight: FontWeight.w500,fontSize: 16),)
            ),*/
              Container(
                margin: EdgeInsets.only(top: 100),
                child: ListTile(
                  title: Text(
                    toBeginningOfSentenceCase(agentName),
                    style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  subtitle: Text(
                    user_id,
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  ),
                  leading: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: Colors.white),
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
              Container(
                  margin: EdgeInsets.only(top: 230),
                  decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.only(topLeft: Radius.circular(30)),
                      color: Colors.white),
                  child:
                  Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          SizedBox(
                            height: 15,
                          ),
                          Text(
                            "Today's Collections",
                            style: TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            "( ${DateFormat('MMM d, ''yyyy').format(DateTime.now())} )",
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          SizedBox(
                            height: 50,
                            child: Container(
                            margin: EdgeInsets.symmetric(
                                vertical: 6,horizontal: 20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[200],
                            ),
                            child:
                            TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 15,vertical: 10),
                                prefixIcon: Icon(Icons.search,color: Theme.of(context).primaryColor,),
                                hintText: "Search"
                              ),
                            )
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
                      margin: EdgeInsets.only(top: 202, right: 25),
                      child: FloatingActionButton(
                        mini: false,
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => AddCollectionPage()));
                        },
                        child: Icon(Icons.add),
                        backgroundColor: Colors.redAccent,
                      ))
                ],
              )
            ],
          ),
          )
        ) // This trailing comma makes auto-formatting nicer for build methods.
        );
  }
}