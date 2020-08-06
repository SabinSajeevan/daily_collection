import 'dart:convert';

import 'package:dailycollection/helpers/database_helper.dart';
import 'package:dailycollection/helpers/strings.dart';
import 'package:dailycollection/models/customers_model.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelectCustomerPage extends StatefulWidget {
  SelectCustomerPage({Key key, this.company_id}) : super(key: key);

  final String company_id;

  @override
  _SelectCustomerPageState createState() => _SelectCustomerPageState();
}

class _SelectCustomerPageState extends State<SelectCustomerPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  ScrollController _scrollController = ScrollController();

  List<Customer> customersList = List();

  List<String> _dropdownItems = ["Search By Name", "Search By Code"];

  String _selectedSearch = 'Search By Name';

  String filter;
  TextEditingController controller = new TextEditingController();
  bool isLoading = true;
  bool isEmpty = false;
  var latestDateFromLocalDB;

  initState() {
    checkForLatestCustomer();
    controller.addListener(() {
      setState(() {
        filter = controller.text;
      });
    });
    super.initState();
  }

  dispose() {
    super.dispose();
  }

  Future<void> checkForLatestCustomer() async {
    DatabaseHelper helper = DatabaseHelper.instance;
    latestDateFromLocalDB = await helper.getLatestCustomer(widget.company_id);
    print("latestDateFromLocalDB - " + latestDateFromLocalDB.toString());

    if (latestDateFromLocalDB.length == 0) {
      getCustomersFromOnline(widget.company_id);
    } else {
      getCustomersFromLocalDB(widget.company_id);
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        var token = prefs.getString("token");

        Map<String, String> headers = {
          "Content-Type": "application/x-www-form-urlencoded",
          "Authorization": "Bearer $token"
        };
        var body = {'company_id': widget.company_id};

        await http
            .post('${Resources.appURL}latest_date',
                headers: headers, body: body)
            .then((response) {
          if (response.statusCode == 200) {
            String latestDateFromOnlineDB =
                json.decode(response.body)['created_at']['created_at'];
            print("latestDateFromOnlineDB" + latestDateFromOnlineDB);
            print(latestDateFromLocalDB[0]['created_at']);
            if (latestDateFromLocalDB[0]['created_at'] !=
                latestDateFromOnlineDB) {
              getCustomersFromOnline(widget.company_id);
            }
          } else {
            _scaffoldKey.currentState.showSnackBar(SnackBar(
              content: Text(json.decode(response.body)['error']),
            ));
          }
          //print(json.decode(response.body));
        });
      } catch (e) {
        print(e);
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text(e.toString()),
        ));
      }
    }
  }

  getCustomersFromLocalDB(company_id) async {
    DatabaseHelper helper = DatabaseHelper.instance;
    var res = await helper.getCustomers(widget.company_id);
    if (res == null || res.length == 0) {
      setState(() {
        isEmpty = true;
        isLoading = false;
      });
    } else {
      setState(() {
        customersList = res;
        isLoading = false;
        isEmpty = false;
      });
    }
  }

  Future getCustomersFromOnline(company_id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      var token = prefs.getString("token");

      Map<String, String> headers = {
        "Content-Type": "application/x-www-form-urlencoded",
        "Authorization": "Bearer $token"
      };
      var body = {'company_id': company_id};

      await http
          .post('${Resources.appURL}customers', headers: headers, body: body)
          .then((response) {
        print(response.body);
        if (response.statusCode == 200) {
          List list = json.decode(response.body)['customers'];
          List<Customer> _cList = [];
          for (var i = 0; i < list.length; i++) {
            _cList.add(new Customer(
                customer_id: list[i]['customer_id'],
                name: list[i]['name'],
                address: list[i]['address'],
                phone: list[i]['phone'],
                mobile: list[i]['mobile'],
                code: list[i]['code'],
                company_id: widget.company_id,
                created_at: list[i]['created_at']));
          }
          insertIntoLocalDB(_cList);
          if (latestDateFromLocalDB.length == 0) {
            setState(() {
              customersList = _cList;
              isEmpty = customersList.length == 0 ? true : false;
              isLoading = false;
            });
          }
        } else {
          _scaffoldKey.currentState.showSnackBar(SnackBar(
            content: Text(json.decode(response.body)['error']),
          ));
          if (latestDateFromLocalDB.length == 0) {
            setState(() {
              isEmpty = true;
              isLoading = false;
            });
          }
        }
      });
    } catch (e) {
      print(e);
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text(e.toString()),
      ));
    }
  }

  Future<void> insertIntoLocalDB(list) async {
    DatabaseHelper helper = DatabaseHelper.instance;
    for (var i = 0; i < list.length; i++) {
      await helper.insertCustomer(list[i]);
    }
    if (latestDateFromLocalDB.length != 0) {
      getCustomersFromLocalDB(widget.company_id);
    }
  }

  Widget _buildListView(list) {
    return ListView.builder(
      itemCount: list.length,
      shrinkWrap: false,
      controller: _scrollController,
      itemBuilder: (BuildContext context, int index) {
        if (filter == null || filter == "") {
          return _buildRow(list[index], index);
        } else {
          if (_selectedSearch == "Search By Name" ? list[index].name
              .toLowerCase().contains(filter.toLowerCase()) :
          list[index].code == filter) {
            return _buildRow(list[index], index);
          } else {
            return new Container();
          }
        }
      },
    );
  }

  Widget _buildRow(Customer c, index) {
    return Container(
        decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey[300],
                blurRadius: 2.0,
              ),
            ],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[200])),
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 15),
        child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                Navigator.pop(context, c);
              },
              child: Column(
                children: <Widget>[
                  ListTile(
                    title: Row(
                      children: <Widget>[
                        Expanded(
                            child: Text(
                          toBeginningOfSentenceCase(c.name),
                        )),
                        Text("Code : ${c.code}")
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Icon(
                              Icons.home,
                              color: Colors.grey[300],
                            ),
                            SizedBox(
                              width: 3,
                            ),
                            Expanded(
                              child: Text(c.address),
                            )
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.phone_iphone,
                              color: Colors.grey[300],
                            ),
                            SizedBox(
                              width: 3,
                            ),
                            Expanded(
                              child: Text("${c.phone} , ${c.mobile}"),
                            )
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            )));
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
                    "Select Customer",
                    style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).primaryColorDark),
                    textAlign: TextAlign.center,
                  ),
                  Divider(),
                  isLoading
                      ? Container(
                          margin: EdgeInsets.only(top: 100),
                          alignment: Alignment.center,
                          child: CupertinoActivityIndicator(radius: 20),
                        )
                      : isEmpty
                          ? ListView(shrinkWrap: true, children: <Widget>[
                              SizedBox(
                                height: 100,
                              ),
                              Text(
                                "No Customers Yet!",
                                textAlign: TextAlign.center,
                              ),
                            ])
                          : Expanded(
                              child: Column(children: <Widget>[
                                Container(
                                  alignment: Alignment.topRight,
                                  margin: EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                      child: new DropdownButton<String>(
                                        items: _dropdownItems.map((
                                            String value) {
                                          return new DropdownMenuItem<String>(
                                            value: value,
                                            child: new Text(value),
                                          );
                                        }).toList(),
                                        value: _selectedSearch,
                                        onChanged: (newValue) {
                                          setState(() {
                                            _selectedSearch = newValue;
                                          });
                                        },
                                      )
                                  ),
                                ),
                                SizedBox(
                                  height: 50,
                                  child: Container(
                                      margin: EdgeInsets.symmetric(
                                          vertical: 6, horizontal: 20),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey[200],
                                      ),
                                      child: TextField(
                                      controller: controller,
                                      decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 15, vertical: 10),
                                          prefixIcon: Icon(
                                            Icons.search,
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                          hintText: "Search"),
                                    )),
                              ),
                              Flexible(
                                  child: DraggableScrollbar.semicircle(
                                      controller: _scrollController,
                                      child: _buildListView(customersList)))
                            ]))
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
        )) // This trailing comma makes auto-formatting nicer for build methods.
        );
  }
}
