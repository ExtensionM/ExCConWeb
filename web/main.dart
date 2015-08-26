// Copyright (c) 2015, sh4869. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library extension;

import 'dart:html';
import 'dart:convert';

InputElement passwordInput,usernameInput;
ButtonElement loginButton;
  
var wsClient = new WebSocket('ws://ec2-52-68-77-61.ap-northeast-1.compute.amazonaws.com:3000');

class webSocketMessage {

	String type;
	Map value;

	@override
	String toString(){
		Map map = new Map();
		map["type"] = type;
		map["value"] = value;
		return JSON.encode(map);
	}
	webSocketMessage(this.type,this.value);

	factory webSocketMessage.fromJsonString(String message_str){
		var data = JSON.decode(message_str);
		return new webSocketMessage(data["type"],data["value"]);
	}
}

void main() {
  //要素の初期化
  usernameInput = querySelector('#login-username');
  passwordInput = querySelector('#login-pass');
  loginButton = querySelector('#login-button');
  querySelector("#message-text").text = "Hello!";
  loginButton.onClick.listen(loginRequest);

  wsClient.onMessage.listen(reciveWebsocketData);
}

///Send Login Request 
void loginRequest(Event e){
	var userName = usernameInput.value;
	var password = passwordInput.value;
	Map value = new Map();
	value["username"] = userName;
	value["password"] = password;
	var send_message = new webSocketMessage("webAuth",value);

	//Send Data on Web Socket 
	if(wsClient != null && wsClient.readyState == WebSocket.OPEN){
		var message_str = send_message.toString();
		wsClient.send(message_str);
  		querySelector("#message-text").text = "Send Message!";
	} else {
  		querySelector("#message-text").text = "Can't send...";
	}
}

void checkLogin(webSocketMessage message){
	// value.result - 0:succeed Others: fail
	if(message.value["result"] == 0){
		//TODO
		querySelector("#message-text").text = "Succeeded in longing!";
	} else {
		querySelector("#message-text").text = "Failed to Login :" + message.value["error"];
	}
	
}

/// Check Message
void reciveWebsocketData(MessageEvent event){
	var message = new webSocketMessage.fromJsonString(event.data);
	switch(message.type){
		case 'webAuth':
			checkLogin(message);
			break;
		case 'call':
			break;
		case 'result':
			break;
		default:
  			querySelector("#message_text").text = "Error";
			break;
	}
}


