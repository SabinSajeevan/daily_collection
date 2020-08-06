import 'dart:convert';

import 'package:dailycollection/helpers/strings.dart';
import 'package:dailycollection/models/collections_model.dart';
import 'package:dailycollection/models/companies_model.dart';
import 'package:dailycollection/providers/companies_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CollectionsProvider with ChangeNotifier {
  List<Collection> usersList = new List();

  bool loading = true;
  bool isNoData = false;
  int previousTotal = 0;
  int todayTotal = 0;
  List<String> agentIDList = [];

  Future<void> getAgentID(key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var phone = prefs.getString("phone");

    Map<String, String> headers = {
      "Content-Type": "application/x-www-form-urlencoded",
      "Authorization": "Bearer $token"
    };

    var body = {'phone': phone};
    try {
      await http
          .post('${Resources.appURL}companies', headers: headers, body: body)
          .then((response) {
        if (response.statusCode == 200) {
          List list = json.decode(response.body)['company'];
          List<String> res = [];
          for (var i = 0; i < list.length; i++) {
            res.add(list[i]['agent_id']);
          }
          set_agent_id_list(res);
          getUsersList(key);
        } else {
          print(response.body);
          setLoading(false);
          setEmptyData(true);
          setMessage("error", key);
        }
        //print(json.decode(response.body));
      });
    } catch (e) {
      print(e.toString() + "sasa");
      setLoading(false);
      setEmptyData(true);
      setMessage("Something's went wrong.", key);
    }
  }

  Future getUsersList(key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      var token = prefs.getString("token");

      Map<String, String> headers = {
        "Content-Type": "application/x-www-form-urlencoded",
        "Authorization": "Bearer $token"
      };

      var date = DateFormat('yyyy-MM-d').format(DateTime.now());

      var body = {'agent_ids': getAgentIDList(), 'date': date};

      await http
          .post('${Resources.appURL}collections', headers: headers, body: body)
          .then((response) {
        if (response.statusCode == 200) {
          // var list = json.decode(response.body)['products'];

          Iterable list = json.decode(response.body)['collections'];
          setUsers(list.map((model) => Collection.fromJson(model)).toList());
          setTodayTotal(json.decode(response.body)['total']);
          getPreviousBalance(key);
          print(response.body);
          if(usersList.length == 0){
            setEmptyData(true);
          }else{
            setEmptyData(false);
          }
          setLoading(false);
        }else{
          print(response.body);
          setLoading(false);
          setEmptyData(true);
          setMessage("error",key);
        }
        //print(json.decode(response.body));
      });
    }catch (e){
      print(e.toString() + "11");
      setLoading(false);
      setEmptyData(true);
      setMessage("Something's went wrong.", key);
    }
  }

  Future getPreviousBalance(key) async {

    SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      var token = prefs.getString("token");

      Map<String, String> headers = {
        "Content-Type": "application/x-www-form-urlencoded",
        "Authorization": "Bearer $token"
      };

      var date = DateFormat('yyyy-MM-d').format(DateTime.now());

      var body = {'agent_ids': getAgentIDList(),
        'date': date};
      print(body);
      await http.post(
          '${Resources.appURL}previous_balance', headers: headers, body: body)
          .then((response) {
        if (response.statusCode == 200) {
          print(response.body);
          setPreviousTotal(json.decode(response.body)['total']);
        } else {
          print(response.body);
          setMessage("error", key);
        }
        //print(json.decode(response.body));
      });
    } catch (e) {
      print(e.toString());
      setLoading(false);
      setEmptyData(true);
      setMessage("Something's went wrong.", key);
    }
  }

  void set_agent_id_list(List<String> res) {
    agentIDList = res;
    notifyListeners();
  }

  String getAgentIDList() {
    return agentIDList.join(",");
  }

  void setLoading(value) {
    loading = value;
    notifyListeners();
  }

  bool isLoading() {
    return loading;
  }

  void setEmptyData(value) {
    isNoData = value;
    notifyListeners();
  }

  bool isEmpty() {
    return isNoData;
  }


  void setUsers(value) {
    usersList = value;
    notifyListeners();
  }

  void setPreviousTotal(value) {
    previousTotal = value;
    notifyListeners();
  }

  void setTodayTotal(value) {
    todayTotal = value;
    notifyListeners();
  }

  List<Collection> getUsers() {
    return usersList;
  }

  void setUserUpdates(index) {
    print(getUsers());
   // usersList[index].name = "sabzzz";
    notifyListeners();
  }

  int getPreviousTotal(){
   return previousTotal;
  }

  int getTodayTotal(){
    return todayTotal;
  }

  void setMessage(msg,key){
    key.currentState.showSnackBar(SnackBar(
      content: Text(msg),
    ));
  }

}