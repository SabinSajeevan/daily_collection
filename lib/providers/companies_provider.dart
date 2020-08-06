import 'dart:convert';

import 'package:dailycollection/helpers/strings.dart';
import 'package:dailycollection/models/companies_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CompaniesProvider with ChangeNotifier {

  List<Company> companiesList = new List();

  bool loading = true;
  bool isNoData = false;

  Future<void> getCompaniesList(key) async {
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
          print(response.body);
          Iterable list = json.decode(response.body)['company'];
          setCompanies(list.map((model) => Company.fromJson(model)).toList());
          if (companiesList.length == 0) {
            setEmptyData(true);
          } else {
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
      print(e.toString());
      setLoading(false);
      setEmptyData(true);
      setMessage("Something's went wrong.",key);
    }
  }

  set dataList(List<Company> list){
    companiesList = list;
    notifyListeners();
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


  void setCompanies(value) {
    companiesList = value;
    notifyListeners();
  }

  List<Company> getCompanies() {
    return companiesList;
  }

  void setUserUpdates(index) {
    print(getCompanies());
    // usersList[index].name = "sabzzz";
    notifyListeners();
  }

  void setMessage(msg,key){
    key.currentState.showSnackBar(SnackBar(
      content: Text(msg),
    ));
  }

}