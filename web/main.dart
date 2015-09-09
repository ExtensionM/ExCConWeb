// Copyright (c) 2015, sh4869. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library extension;

import 'dart:html';
import 'dart:convert';

InputElement passwordInput, usernameInput;
ButtonElement loginButton,
    rightButton,
    leftButton,
    upButton,
    downButton,
    takeButton;
ImageElement cameraImageElement;

var wsClient = new WebSocket(
    'ws://ec2-52-68-77-61.ap-northeast-1.compute.amazonaws.com:3000');
bool auth = false;

/// Camera Child ID
var cameraID = "";
/// Camera Servo Angle
int cameraUDValue = 90,
    cameraLRValue = 90;

/// Class of websocket message
class webSocketMessage {
  /// Message Type
  String type;
  /// Message Value
  Map value;

  @override
  String toString() {
    Map map = new Map();
    map["type"] = type;
    map["value"] = value;
    return JSON.encode(map);
  }

  webSocketMessage(this.type, this.value);

  factory webSocketMessage.fromJsonString(String message_str) {
    var data = JSON.decode(message_str);
    return new webSocketMessage(data["type"], data["value"]);
  }
}

void main() {
  //Initialize Element
  usernameInput = querySelector('#login-username');
  passwordInput = querySelector('#login-pass');
  loginButton = querySelector('#login-button');

  rightButton = querySelector('#right-button');
  upButton = querySelector('#up-button');
  downButton = querySelector('#down-button');
  leftButton = querySelector('#left-button');
  takeButton = querySelector('#take-button');

  cameraImageElement = querySelector('#camera-image');
  changeDisplayMessage("Hello!");
  loginButton.onClick.listen(loginRequest);
  rightButton.onClick.listen((Event e) {
    cameraServoMove(1, -5);
  });
  leftButton.onClick.listen((Event e) {
    cameraServoMove(1, 5);
  });
  upButton.onClick.listen((Event e) {
    cameraServoMove(2, 5);
  });
  downButton.onClick.listen((Event e) {
    cameraServoMove(2, -5);
  });
  takeButton.onClick.listen((Event e) {
    takePhoto();
  });

  wsClient.onMessage.listen(reciveWebsocketData);
}

/// Change Message of #message-text
void changeDisplayMessage(String text) {
  querySelector("#message-text").text = text;
}

/// Send Camera Take photo
void takePhoto() {
  changeDisplayMessage("take");
  callRequest("take", cameraID, null);
}

/// Send Camera Device
void cameraServoMove(int direction, int value) {
  var functionName = "";
  var angle = 0;
  switch (direction) {
    case 1:
      functionName = "angleX";
      angle = cameraUDValue + value;
      break;
    case 2:
      functionName = "angleY";
      angle = cameraLRValue + value;
      break;
    default:
      break;
  }

  changeDisplayMessage(functionName);
  var arg = {"angle": angle};
  callRequest(functionName, cameraID, arg);
}

///Send Login Request
void loginRequest(Event e) {
  var userName = usernameInput.value;
  var password = passwordInput.value;
  if (userName != "" && password != "") {
    Map value = new Map();
    value["username"] = userName;
    value["password"] = password;
    var send_message = new webSocketMessage("webAuth", value);
    //Send Data on Web Socket
    if (wsClient != null && wsClient.readyState == WebSocket.OPEN) {
      wsClient.send(send_message.toString());
      changeDisplayMessage("Send Message!");
    } else {
      changeDisplayMessage("Can't send...");
    }
  } else {
    changeDisplayMessage("Don't input password or username");
  }
}

/// Send Child List Request
void childListRequest() {
  var send_message = new webSocketMessage("list", null);
  wsClient.send(send_message.toString());
}

/// Send Call Request
void callRequest(String functionName, String childId, Map args) {
  var values = {"id": childId, "func": functionName};
  if (args != null) {
    values.addAll(args);
  }
  var message = new webSocketMessage("call", values);

  wsClient.send(message.toString());
}

///Check login message ( type : webauth )
void checkLogin(webSocketMessage message) {
  // value.result - 0:succeed Others: fail
  if (message.value["result"] == 0) {
    //TODO
    changeDisplayMessage("Succeeded in longing!");
    auth = true;
    childListRequest();
  } else {
    changeDisplayMessage("Failed to Login :" + message.value["error"]);
  }
}

/// Check Call Result
void checkCall(webSocketMessage message) {
  if (message.value['result'] != 0) {
    changeDisplayMessage(message.value['error']);
  }
}

/// Check Function Result
void checkResult(webSocketMessage message) {
  if (message.value["hasError"] == false) {
    switch (message.value["functionName"]) {
      case 'angleY':
        cameraLRValue = message.value["result"];
        changeDisplayMessage("X: " +
            cameraUDValue.toString() +
            " Y: " +
            cameraLRValue.toString());
        break;
      case 'angleX':
        cameraUDValue = message.value["result"];
        changeDisplayMessage("X: " +
            cameraUDValue.toString() +
            " Y: " +
            cameraLRValue.toString());
        break;
      case 'take':
        changeDisplayMessage("X: " +
            cameraUDValue.toString() +
            " Y: " +
            cameraLRValue.toString() +
            " take");
        break;
    }
  }
}

/// Display Photo Image
void displayCameraImage(webSocketMessage message) {
  if (message.value["result"] == 0) {
    cameraImageElement.src = message.value["data"]["data"];
  }
}

/// Find Camera Child from Child List Json Data
void findChildFromList(webSocketMessage message) {
  List<String> cameraChildIdList = new List();
  message.value["commands"].forEach((key, values) {
    if (key != "a" && key != "default") {
      if (values["name"] == "Camera") {
        cameraChildIdList.add(key);
      }
    }
  });

  if (cameraChildIdList.length == 1) {
    cameraID = cameraChildIdList[0];
    changeDisplayMessage("You have Camera Child: " + cameraID);
  } else if (cameraChildIdList == 0) {
    changeDisplayMessage("You don't have camera Children.");
  } else {
    //TODO 複数台あるときの選択ボタンなど
  }
}

/// Check Message
void reciveWebsocketData(MessageEvent event) {
  var message = new webSocketMessage.fromJsonString(event.data);
  switch (message.type) {
    case 'webAuth':
      checkLogin(message);
      break;
    case 'call':
      checkCall(message);
      break;
    case 'result':
      checkResult(message);
      break;
    case 'list':
      findChildFromList(message);
      break;
    case 'message':
      displayCameraImage(message);
      break;
    default:
      break;
  }
}
