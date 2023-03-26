import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../fireui.dart';

class FireAccount {
  static FireAccount? current;
  final String uid;
  String _name;

  FireAccount._(this.uid, this._name);

  String get name => _name;

  set name(String newName) {
    http.post(
      Uri.parse('$fireApiUrl/user/$uid/update/name'),
      body: newName,
      headers: {
        "authorization": "Bearer ${apiKey}",
      },
    );
    _name = newName;
  }

  static Future<FireAccount?> getFromUid(String uid) async {
    dynamic response = await http.get(
      Uri.parse('$fireApiUrl/user/$uid'),
    );
    response = jsonDecode(response.body);
    return FireAccount._(response["uid"], response["name"]);
  }

  static Future<bool> isLoggedIn() async {
    FireService.send("getCurrentAccount", null);
    Completer currentAccountReceived = Completer();
    bool? isLoggedIn;
    service.once("currentAccount", (data) async {
      if (data["status"] == "loggedout") {
        isLoggedIn = false;
      } else if (data["status"] == "loggedin") {
        isLoggedIn = true;
        FireAccount.current = await FireAccount.getFromUid(data["uid"]);
      }
      currentAccountReceived.complete();
    });
    await currentAccountReceived.future;
    return isLoggedIn!;
  }

  static void logout() {
    current = null;
    FireService.send("logout", null);
  }
}

Future<String> sendAuthEmail(String emailAddress) async {
  service.emit("sendAuthEmail", emailAddress);

  Completer<String> authEmailSentReceived = Completer();
  service.once("authEmailSent", (authCode) {
    authEmailSentReceived.complete(authCode);
  });
  return await authEmailSentReceived.future;
}

Future<FireAccount?> login(String authCode, String loginCode) async {
  // TODO
  service.emit("login", {"authCode": authCode, "loginCode": loginCode});

  Completer<FireAccount?> loggedInStatusReceived = Completer();
  service.once("logged in", (uid) {
    if (uid != null) {
      FireAccount.getFromUid(uid).then((account) {
        loggedInStatusReceived.complete(account);
      });
    } else {
      loggedInStatusReceived.complete(null);
    }
  });
  return await loggedInStatusReceived.future;
}
