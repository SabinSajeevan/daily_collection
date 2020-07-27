import 'dart:convert';

import 'package:dailycollection/helpers/strings.dart';
import 'package:dailycollection/models/collection_types_model.dart';
import 'package:dailycollection/models/companies_model.dart';
import 'package:dailycollection/models/customers_model.dart';
import 'package:dailycollection/providers/collections_provider.dart';
import 'package:dailycollection/providers/companies_provider.dart';
import 'package:dailycollection/screens/select_customer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddCollectionPage extends StatefulWidget {
  @override
  _AddCollectionPageState createState() => _AddCollectionPageState();
}

class _AddCollectionPageState extends State<AddCollectionPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();

  CompaniesProvider _company;
  CollectionsProvider _collection;

  var _isLoadingForFirstTime = true;

  List<Company> companiesList = List();
  List<Customer> customersList = List();
  List<CollectionType> collectionTypesList = List();
  List<String> collectionSubTypesList = List();

  final List<ListTile> items = [];
  var colorsList = [0xffc6e3f7, 0xffd9e3e5, 0xffefc5b5, 0xffeae3d2];
  var selectedCompany;
  var selectedCustomer;
  var selectedCollectionType;
  var selectedCollectionSubType;

  String filter;
  TextEditingController controller = new TextEditingController();
  TextEditingController amountController = new TextEditingController();
  initState() {
    controller.addListener(() {
      setState(() {
        filter = controller.text;
      });
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (_isLoadingForFirstTime) {
      _company = Provider.of<CompaniesProvider>(context);
      _company.getCompaniesList(_scaffoldKey);
    }
    companiesList = _company.getCompanies();
    _isLoadingForFirstTime = false;
    if(!companiesList.isEmpty && companiesList.length == 1){
      setCompanySelected(companiesList[0]);
    }
    super.didChangeDependencies();
  }

  dispose() {
    super.dispose();
  }

  void setCompanySelected(company){
    selectedCompany = company;
    selectedCustomer = null;
    selectedCollectionType = null;
    selectedCollectionSubType = null;

    customersList = [];
    collectionTypesList = [];
    collectionSubTypesList = [];

    getCollectionTypes(selectedCompany.uuid);
  }


  List<Widget> listItems(list, type) {
    List<Widget> widgetList = new List();
    if(list.length == 0){
      widgetList.add(SizedBox(height: 100,
        child: Text("No items found."),));
    }
    for (var i = 0; i < list.length; i++) {
      widgetList.add(ListTile(
        title: Text(
          type == "company" ? list[i].name : type == "collection_type" ? list[i].type : list[i],
          style: TextStyle(
              fontWeight: FontWeight.w500,
              color: (type == "company" && selectedCompany == list[i]
                  || type == "collection_type" && selectedCollectionType == list[i]
                  || type == "collection_sub_type" && selectedCollectionSubType == list[i])
                  ? Theme.of(context).accentColor
                  : null),
        ),
        onTap: () {
          setState(() {
            if (type == "company") {
              setCompanySelected(list[i]);

            }else if (type == "collection_type") {
              selectedCollectionType = list[i];
              selectedCollectionSubType = null;
              getSubTypes(selectedCollectionType.sub_type);
            }else{
              selectedCollectionSubType = list[i];
            }
          });
          Navigator.of(context).pop();
        },
      ));
    }
    return widgetList;
  }

  List<Widget> listCustomerItems(list, type) {
    List<Widget> widgetList = new List();
    if(list.length == 0){
      widgetList.add(SizedBox(height: 100,
      child: Text("No items found."),));
    }else {
      widgetList.add(
        SizedBox(
          height: 50,
          child: Container(
              margin: EdgeInsets.symmetric(vertical: 6, horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme
                          .of(context)
                          .primaryColor,
                    ),
                    hintText: "Search"),
              )),
        ),
      );
    }
    for (var i = 0; i < list.length; i++) {
      if (filter == null || filter == "") {
        widgetList.add(_buildRow(i));
        widgetList.add(Divider());
      } else {
        if (customersList[i]
            .name
            .toLowerCase()
            .contains(filter.toLowerCase())) {
          widgetList.add(_buildRow(i));
          widgetList.add(Divider());
        } else {
          widgetList.add(Container());
        }
      }
    }
    widgetList.add(SizedBox(
      height: 15,
    ));
    return widgetList;
  }

  Widget _buildRow(i) {
    return ListTile(
      title: Text(
        toBeginningOfSentenceCase(customersList[i].name),
        style: TextStyle(
            color: (selectedCustomer == customersList[i])
                ? Theme.of(context).accentColor
                : null),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.home,
                color: Colors.grey,
                size: 15,
              ),
              SizedBox(
                width: 5,
              ),
              Text(customersList[i].address),
            ],
          ),
          SizedBox(
            height: 4,
          ),
          Row(
            children: <Widget>[
              Icon(
                Icons.phone_iphone,
                color: Colors.grey,
                size: 15,
              ),
              SizedBox(
                width: 5,
              ),
              Text(customersList[i].phone),
            ],
          )
        ],
      ),
      leading: Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(colorsList[i > 3 ? i % 4 : i])),
          child: Text(
            customersList[i].name.substring(0, 1).toUpperCase(),
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500, fontSize: 27),
          )),
      onTap: () {
        setState(() {
          selectedCustomer = customersList[i];
          filter = "";
          controller.text = "";
        });
        Navigator.of(context).pop();
      },
    );
  }

  _showDialog(title, list, type) {
    // flutter defined function
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(// StatefulBuilder
            builder: (context, changeState) {
          return Material(
              color: Colors.transparent,
              child: Center(
                  child: ConstrainedBox(
                      constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height - 100),
                      child: IntrinsicHeight(
                          child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        alignment: Alignment.center,
                        margin:
                            EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Padding(
                              padding:
                                  EdgeInsets.only(left: 10, right: 10, top: 7),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                          color:
                                              Theme.of(context).primaryColor),
                                    ),
                                  ),
                                  Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey[300],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.pop(context);
                                          },
                                          customBorder: CircleBorder(),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                            ),
                                            padding: EdgeInsets.all(5),
                                            child: Icon(Icons.close),
                                          ),
                                        ),
                                      ))
                                ],
                              ),
                            ),
                            Divider(),
                            Flexible(
                                child: SingleChildScrollView(
                                    child: Column(
                              children: type == "customer"
                                  ? listCustomerItems(list, type)
                                  : listItems(list, type),
                            )))
                          ],
                        ),
                      )))));
        });
      },
    );
  }

  Future getCustomers(company_id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      var token = prefs.getString("token");

      Map<String, String> headers = {
        "Content-Type": "application/x-www-form-urlencoded",
        "Authorization": "bearer $token"
      };
      var body = {'company_id': company_id};

      await http
          .post('${Resources.appURL}customers', headers: headers, body: body)
          .then((response) {
        print(response.body);
        if (response.statusCode == 200) {
          setState(() {
            Iterable list = json.decode(response.body)['customers'];
            customersList =
                list.map((model) => Customer.fromJson(model)).toList();
          });
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

  Future getCollectionTypes(company_id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      var token = prefs.getString("token");

      Map<String, String> headers = {
        "Content-Type": "application/x-www-form-urlencoded",
        "Authorization": "bearer $token"
      };
      var body = {'company_id': company_id};

      await http
          .post('${Resources.appURL}collection_types', headers: headers, body: body)
          .then((response) {
        print(response.body);
        if (response.statusCode == 200) {
          setState(() {
            Iterable list = json.decode(response.body)['collection_types'];
            collectionTypesList =
                list.map((model) => CollectionType.fromJson(model)).toList();
            if (collectionTypesList.length == 1) {
              selectedCollectionType = collectionTypesList[0];
              selectedCollectionSubType = null;
              getSubTypes(selectedCollectionType.sub_type);
            }
          });
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

  void getSubTypes(sub_type){
    collectionSubTypesList = [];
    if(sub_type != null){
      var split = sub_type.split(",");
      for (var i = 0; i < split.length; i++) {
        setState(() {
          collectionSubTypesList.add(split[i]);
        });
      }
      if (collectionSubTypesList.length == 1) {
        setState(() {
          selectedCollectionSubType = collectionSubTypesList[0];
        });
      }
    }
  }

  Future<void> showProgress() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child:  CupertinoActivityIndicator(radius: 20),);
        });
    await save();
    Navigator.pop(context);
  }

  Future<bool> save() async {

    var isLogin = false;

    if (selectedCompany != null && selectedCustomer != null && selectedCollectionType != null && amountController.text != '') {

      SharedPreferences prefs = await SharedPreferences.getInstance();

      try {
        var token = prefs.getString("token");
        var agent_id = prefs.getString("uuid");

        Map<String, String> headers = {
          "Content-Type": "application/x-www-form-urlencoded",
          "Authorization": "bearer $token"
        };

        var body = {
          'company_id': selectedCompany.uuid,
          'agent_id': agent_id,
          'customer_id': selectedCustomer.customer_id,
          'collection_type': selectedCollectionType.uuid,
          'sub_type': selectedCollectionSubType == null ? '' : selectedCollectionSubType,
          'amount': amountController.text.trim()
        };

        await http.post('${Resources.appURL}create_collection', body: body,headers: headers).then((
            response) {
          print(response.body);
          if(response.statusCode == 200){
            setState(() {
              selectedCustomer = null;
              if (collectionTypesList.length != 1)
                selectedCollectionType = null;
              if (collectionSubTypesList.length != 1)
                selectedCollectionSubType = null;
              amountController.text = '';
            });
            _scaffoldKey.currentState.showSnackBar(SnackBar(
              content: Text("Collection Added Successfully !"),
            ));
            _collection = Provider.of<CollectionsProvider>(context,listen: false);
            _collection.getUsersList(_scaffoldKey);
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
    } else {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text("Please fill all mandatory fields."),
      ));
    }

    return isLogin;
  }

  void navigateToSelectCustomer() {
    if (selectedCompany != null) {
      var result = Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => SelectCustomerPage(
                    company_id: selectedCompany.uuid,
                  ))).then((value) {
        if (value != null) {
          setState(() {
            selectedCustomer = value;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        body: Container(
            child: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: () {
            return _company.getCompaniesList(_scaffoldKey);
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
                      "Add Collection",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme
                              .of(context)
                              .primaryColorDark),
                      textAlign: TextAlign.center,
                    ),
                    Divider(),
                    _company.isLoading() ? Container(
                      margin: EdgeInsets.only(top: 100),
                      alignment: Alignment.center,
                      child: CupertinoActivityIndicator(radius: 20),
                    ) : _company.isEmpty() ? ListView(
                        shrinkWrap: true,
                        children: <Widget>[
                          SizedBox(height: 100,),
                          Text("No Companies Yet!",textAlign: TextAlign.center,),

                        ]): Expanded(
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
                                      color: Colors.grey[200]),
                                  child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                          onTap: () {
                                            _showDialog("Select Company",
                                                companiesList, "company");
                                          },
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 10),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: <Widget>[
                                                SizedBox(
                                                  height: 5,
                                                ),
                                                Text("COMPANY*"),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 7,
                                                      horizontal: 3),
                                                  child: Row(
                                                    children: <Widget>[
                                                      Expanded(
                                                        child: Padding(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal:
                                                                      5),
                                                          child: Text(
                                                            selectedCompany ==
                                                                    null
                                                                ? "Select Company"
                                                                : selectedCompany
                                                                    .name,
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontSize: 16),
                                                          ),
                                                        ),
                                                      ),
                                                      Icon(Icons.expand_more)
                                                    ],
                                                  ),
                                                )
                                              ],
                                            ),
                                          )))),
                              SizedBox(
                                height: 12,
                              ),
                              Container(
                                  margin: EdgeInsets.symmetric(horizontal: 20),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.grey[200]),
                                  child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                          onTap: () {
                                            /*_showDialog("Select Customer",
                                                customersList, "customer");*/
                                            navigateToSelectCustomer();
                                          },
                                          borderRadius:
                                          BorderRadius.circular(8),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 10),
                                            child: Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                              children: <Widget>[
                                                SizedBox(
                                                  height: 5,
                                                ),
                                                Text("CUSTOMER*"),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 7,
                                                      horizontal: 3),
                                                  child: Row(
                                                    children: <Widget>[
                                                      Expanded(
                                                        child: Padding(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal:
                                                                      5),
                                                          child: Text(
                                                            selectedCustomer ==
                                                                    null
                                                                ? "Select customer"
                                                                : selectedCustomer
                                                                    .name,
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontSize: 16),
                                                          ),
                                                        ),
                                                      ),
                                                      Icon(Icons.expand_more)
                                                    ],
                                                  ),
                                                )
                                              ],
                                            ),
                                          )))),
                              SizedBox(
                                height: 12,
                              ),
                              Container(
                                  margin: EdgeInsets.symmetric(horizontal: 20),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.grey[200]),
                                  child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                          onTap: () {
                                            _showDialog("Select Collection Type",
                                                collectionTypesList, "collection_type");
                                          },
                                          borderRadius:
                                          BorderRadius.circular(8),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 10),
                                            child: Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                              children: <Widget>[
                                                SizedBox(
                                                  height: 5,
                                                ),
                                                Text("COLLECTION TYPE*"),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 7,
                                                      horizontal: 3),
                                                  child: Row(
                                                    children: <Widget>[
                                                      Expanded(
                                                        child: Padding(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                              horizontal:
                                                              5),
                                                          child: Text(
                                                            selectedCollectionType ==
                                                                null
                                                                ? "Select collection type"
                                                                : selectedCollectionType
                                                                .type,
                                                            style: TextStyle(
                                                                fontWeight:
                                                                FontWeight
                                                                    .w500,
                                                                fontSize: 16),
                                                          ),
                                                        ),
                                                      ),
                                                      Icon(Icons.expand_more)
                                                    ],
                                                  ),
                                                )
                                              ],
                                            ),
                                          )))),
                              SizedBox(
                                height: 12,
                              ),
                              Container(
                                  margin: EdgeInsets.symmetric(horizontal: 20),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.grey[200]),
                                  child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                          onTap: () {
                                            _showDialog("Select Collection Sub Type",
                                                collectionSubTypesList, "collection_sub_type");
                                          },
                                          borderRadius:
                                          BorderRadius.circular(8),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 10),
                                            child: Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                              children: <Widget>[
                                                SizedBox(
                                                  height: 5,
                                                ),
                                                Text("COLLECTION SUB TYPE"),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 7,
                                                      horizontal: 3),
                                                  child: Row(
                                                    children: <Widget>[
                                                      Expanded(
                                                        child: Padding(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                              horizontal:
                                                              5),
                                                          child: Text(
                                                            selectedCollectionSubType ==
                                                                null
                                                                ? "Select collection sub type"
                                                                : selectedCollectionSubType,
                                                            style: TextStyle(
                                                                fontWeight:
                                                                FontWeight
                                                                    .w500,
                                                                fontSize: 16),
                                                          ),
                                                        ),
                                                      ),
                                                      Icon(Icons.expand_more)
                                                    ],
                                                  ),
                                                )
                                              ],
                                            ),
                                          )))),
                              SizedBox(
                                height: 12,
                              ),
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey[200]),
                                padding: EdgeInsets.only(
                                    top: 5, bottom: 5, left: 10),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Text("AMOUNT*"),
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: TextField(
                                            controller: amountController,
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              errorBorder: InputBorder.none,
                                              disabledBorder: InputBorder.none,
                                              hintText: "Enter amount",
                                            ),
                                            keyboardType: TextInputType.number,
                                            inputFormatters: <TextInputFormatter>[
                                              WhitelistingTextInputFormatter.digitsOnly
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 25,
                              ),
                              RaisedButton(
                                color: Theme
                                    .of(context)
                                    .accentColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding: EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 60),
                                onPressed: () {
                                  showProgress();
                                },
                                child: Text(
                                  "SAVE",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
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
        )) // This trailing comma makes auto-formatting nicer for build methods.
        );
  }
}
