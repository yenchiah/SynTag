/***************************************************************************************
 This is a free software project named "SynTag".
 Copyright (C) 2011 by Yen-Chia Hsu, IA LAB, National Cheng Kung University, Taiwan
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 ***************************************************************************************/
/******** import **********/
import flash.events.MouseEvent;
import flash.events.SyncEvent;
import flash.media.*;
import flash.net.*;
import com.amcharts.chartClasses.GraphDataItem;
import com.amcharts.events.*;
import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.core.UIComponent;
/******** amchart variables **********/
[Bindable]
public var chartData:ArrayCollection = new ArrayCollection();
/******** net variables(Broadcasting Service) **********/
public var nc0:NetConnection;
public var nc1:NetConnection;
public var nsPlayer:NetStream;
//public var appServer0:String = "rtmp://localhost/liveVideo";
//public var appServer1:String = "rtmp://localhost/Broadcast";
public var appServer0:String="rtmp://ialab.tw/liveVideo";
public var appServer1:String="rtmp://ialab.tw/Broadcast";
/******** program variables(Broadcasting Service) **********/
public var vidPlayer:Video;
public var nr0:Responder = new Responder(onReply0);
public var nr1:Responder = new Responder(onReply1);
public var bandWidth:Number;
public var fileName:String = null;
public var fileNameLive:String = null;
public var eventIsWrite:Boolean = false;
public var dataIsWrite:Boolean = false;
public var urlOpenWindowArray:Array = new Array();//////////////////////////////
/******** net variables(Tagging Service) **********/
public var nc2:NetConnection;
public var nc3:NetConnection;
//public var appServer2:String="rtmp://localhost/Tag";//realtime
//public var appServer3:String="rtmp://localhost/Tag_";//not realtime
public var appServer2:String="rtmp://ialab.tw/Tag";//realtime
public var appServer3:String="rtmp://ialab.tw/Tag_";//not realtime
public var so:SharedObject;
public var so_:SharedObject;
/******** hyperlink variables ********/
public var urlStr:String = "(http(s)?:\/\/)(([a-z]+[a-z0-9\-]*[.])?([a-z0-9]+[a-z0-9\-]*[.])+[a-z]{2,3}|localhost)(\/[a-z0-9_-]+[a-z0-9_ -]*)*\/?(\\?[a-z0-9_-]+=[a-z0-9 ',.-]*(&amp;[a-z0-9_-]+=[a-z0-9 ',.-]*)*)?(#[a-z0-9/_-]*)?$";
public var urlPattern:RegExp = new RegExp(urlStr, "i");
public var matchUrl:Array = new Array();
/******************************/
/******** initialize **********/
/******************************/
public function init():void
{
	Security.allowDomain("*");
	txt_userID.addEventListener(KeyboardEvent.KEY_DOWN,myKeyDownHandler1);
	txt_Comment.addEventListener(KeyboardEvent.KEY_DOWN,myKeyDownHandler2);
	//unlock UI
	txt_userID.enabled = true;
	txt.editable = false;
	btn_StartBroadcasting.enabled = true;
	btn_StopBroadcasting.enabled = false;
	btn_good.enabled = false;
	btn_question.enabled = false;
	btn_disagree.enabled = false;
	btn_comment.enabled = false;
	btn_comment.enabled = false;
	amchartcontainer.visible = false;
}
/******************************/
/******** net status **********/
/******************************/
//start broadcasting service
public function startBroadcasting():void
{
	var userIdPattern:RegExp = /[a-zA-Z][0-9a-zA-Z]*/;
	var matchUserId:Array = new Array();
	matchUserId = userIdPattern.exec(txt_userID.text);
	//if match all the words in txt_userID.text	
	if(matchUserId!=null && matchUserId[0] == txt_userID.text)
	{
		lockAllUI();
		//connect broadcasting service
		nc1 = new NetConnection();
		nc1.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler1);
		nc1.connect(appServer1);
		nc1.client = this;
	}
	else
		Alert.show("ERROR: You can only use numbers and alphabets as UserID. First character must be an alphabet.");
}
//connect broadcasting service
public function netStatusHandler1(event:NetStatusEvent):void
{
	trace("onNetStatus1");
	trace(event.info.code);
	if(event.info.code == "NetConnection.Connect.Success")
	{
		//get broadcasting filename from server
		nc1.call("getFileName", nr0);
	}
	else if(event.info.code == "NetConnection.Connect.Failed")
	{
		Alert.show("ERROR: Broadcasting service connection failed... Restart application.");
		nc1.close();
		//unlock UI
		btn_StartBroadcasting.enabled = true;
		txt_userID.enabled = true;
	}
}
//when Responder get data from broadcasting service
public function onReply0(result:Object):void  
{  	
	if(result!=null)
	{
		trace("fileName = " + result.toString());
		fileName = result.toString();
		//get data from live service
		nc1.call("getFileNameLive", nr1);
	}
	else
	{
		Alert.show("ERROR: Broadcasting source not detected.");
		nc1.close();
		//unlock UI
		btn_StartBroadcasting.enabled = true;
		txt_userID.enabled = true;
	}
}
//when Responder get data from live service
public function onReply1(result:Object):void  
{  	
	if(result!=null)
	{
		trace("fileNameLive = " + result.toString());
		fileNameLive = result.toString();
		//initialize streaming service
		initStreamingService();
	}
	else
	{
		Alert.show("ERROR: Broadcasting source not detected.");
		nc1.close();
		//unlock UI
		btn_StartBroadcasting.enabled = true;
		txt_userID.enabled = true;
	}
}
//initialize streaming service
public function initStreamingService():void
{
	nc0 = new NetConnection();
	nc0.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler0);
	nc0.connect(appServer0);
	nc0.client = this;
}
//connect streaming service
public function netStatusHandler0(event:NetStatusEvent):void
{
	trace("onNetStatus0");
	trace(event.info.code);
	if(event.info.code == "NetConnection.Connect.Success")
	{
		//initialize tagging service
		initTaggingService();
	}
	else if(event.info.code == "NetConnection.Connect.Failed")
	{		
		Alert.show("ERROR: Streaming service connection failed... Restart application.");
		nc1.close();
		nc0.close();
		//unlock UI
		btn_StartBroadcasting.enabled = true;
		txt_userID.enabled = true;
	}
}
//initilaize tagging service
public function initTaggingService():void
{
	nc2 = new NetConnection();
	nc2.addEventListener(NetStatusEvent.NET_STATUS,netStatusHandler2);				
	nc2.connect(appServer2);
	nc2.client = this;
}
//connect tagging service
public function netStatusHandler2(evt:NetStatusEvent):void
{
	if ( evt.info.code=="NetConnection.Connect.Success" )
	{
		txt.text = "";
		txt_about.text = "";
		trace(evt.info.code);
		//get remote SharedObject
		so = SharedObject.getRemote(fileName, nc2.uri, true);
		//add a synchronization event listener
		so.addEventListener(SyncEvent.SYNC, soSyncHandler);
		//connect FMS
		so.connect(nc2);
		//start broadcasting
		setNetStream();
		startPlaying();
	}
	else if(evt.info.code == "NetConnection.Connect.Failed")
	{
		Alert.show("ERROR: Tagging service connection failed... Restart application.");
		nc2.close();
		nc1.close();
		nc0.close();
		//unlock UI
		btn_StartBroadcasting.enabled = true;
		txt_userID.enabled = true;
	}
}
//tagging service synchronization handler
public function soSyncHandler(evt:SyncEvent):void
{
	trace("soSyncHandler");
	setAmchartData();
	//unlock UI
	btn_StartBroadcasting.enabled = false;
	btn_StopBroadcasting.enabled = true;
	btn_good.enabled = true;
	btn_question.enabled = true;
	btn_disagree.enabled = true;
	btn_comment.enabled = true;
	btn_comment.enabled = true;
}
public function setAmchartData():void
{
	amchartcontainer.visible = true;
	//video time
	var timeSpan:Number = 10;//seconds
	var currentTime:Number = 0;
	var lastTime:Number = 0;
	var goodNum:Number = 0;
	var questionNum:Number = 0;
	var disagreeNum:Number = 0;
	var hyperlinkNum:Number = 0;
	var hyperlink:Array = new Array();///////////////////////////////////
	var hyperlinkStr:String = "@@@";///////////////////////////////////
	//new an array to catch data from remote SharedObject
	var tag:Array = new Array();
	//catch data from remote SharedObject
	if(so.data.tag!=null)
	{
		tag = so.data.tag;
		if(tag[2]!=null)
		{
			//display data in TextArea
			txt.text = "";
			txt_about.text = "";
			txt_about.appendText("-----------------------------------------------\n");
			txt_about.appendText("  " + tag[0] + "\n");
			txt_about.appendText("-----------------------------------------------\n");
			txt_about.appendText(tag[1]);
			chartData.removeAll();
			for (var i:int=2; i<tag.length; i=i+5)
			{
				currentTime = Math.ceil((tag[i+2]-tag[i])/1000);
				if(currentTime-lastTime<timeSpan)
				{
					if(tag[i+3]=="Good") goodNum++;
					else if(tag[i+3]=="Question") questionNum++;
					else if(tag[i+3]=="Disagree") disagreeNum++;
					else if(tag[i+3]=="Comment")
					{
						txt.appendText(tag[i+1]+" at "+currentTime+" sec says:\n");
						txt.appendText("      "+tag[i+4]+"\n\n");
						//hyperlink
						matchUrl = urlPattern.exec(tag[i+4]); 
						if(matchUrl!=null && matchUrl[0]==tag[i+4])
						{
							hyperlinkNum++;								
							hyperlink.push(tag[i+4]);///////////////////////////////////
						}
					}		
				}//end of if(currentTime==lastTime)
				else
				{
					while(hyperlink.length != 0) hyperlinkStr += hyperlink.pop()+"@@@";///////////////////////////////////
					chartData.addItem({hyperlinkStr:hyperlinkStr,videotime:lastTime,good:goodNum,question:questionNum,disagree:disagreeNum,hyperlink:hyperlinkNum});
					goodNum = 0;
					questionNum = 0;
					disagreeNum = 0;
					hyperlinkNum = 0;
					hyperlinkStr = "@@@";///////////////////////////////////
					if(tag[i+3]=="Good") goodNum++;
					else if(tag[i+3]=="Question") questionNum++;
					else if(tag[i+3]=="Disagree") disagreeNum++;
					else if(tag[i+3]=="Comment")
					{
						txt.appendText(tag[i+1]+" at "+currentTime+" sec says:\n");
						txt.appendText("      "+tag[i+4]+"\n\n");
						//hyperlink
						matchUrl = urlPattern.exec(tag[i+4]); 
						if(matchUrl!=null && matchUrl[0]==tag[i+4])
						{
							hyperlinkNum++;								
							hyperlink.push(tag[i+4]);///////////////////////////////////
						}
					}	
					lastTime = currentTime;
				}//end of else if(currentTime!=lastTime)
			}//end of for (var i:int=0; i<tag.length; i=i+5)
			while(hyperlink.length != 0) hyperlinkStr += hyperlink.pop()+"@@@";///////////////////////////////////
			chartData.addItem({hyperlinkStr:hyperlinkStr,videotime:lastTime,good:goodNum,question:questionNum,disagree:disagreeNum,hyperlink:hyperlinkNum});
		}// end of if(tag[2]!=null)
	}//end of if(so.data.tag!=null)
}
/****************************************/
/******** Broadcasting Service **********/
/****************************************/
public function setNetStream():void
{
	nsPlayer = new NetStream(nc0);
	vidPlayer = new Video();
	vidPlayer.width = 640;
	vidPlayer.height = 360;
	vidPlayer.attachNetStream(nsPlayer);
	cnvWebcam.addChild(vidPlayer);	
}
public function startPlaying():void
{	
	//play live stream
	nsPlayer.play(fileNameLive);
}
public function stopBroadcasting():void
{
	lockAllUI();
	eventIsWrite = false;
	dataIsWrite = false;
	//stop live stream
	nsPlayer.play(false);
	cnvWebcam.removeChild(vidPlayer);	
	nsPlayer.close();
	so.removeEventListener(SyncEvent.SYNC, soSyncHandler);
	so.close();
	nc0.close();
	nc1.close();
	nc2.close();	
	//unlock UI
	btn_StartBroadcasting.enabled = true;
	btn_StopBroadcasting.enabled = false;
	txt_userID.enabled = true;
	btn_good.enabled = false;
	btn_question.enabled = false;
	btn_disagree.enabled = false;
	btn_comment.enabled = false;
	btn_comment.enabled = false;
}
/*******************************************/
/******** Realtime Tagging Service *********/
/*******************************************/
//tag[0] is event title
//tag[1] is event description
//tag[i]
//if(i%5==2) videoID_str;
//if(i%5==3) userID_str;
//if(i%5==4) tagTimestamp_int;
//if(i%5==0) tagID_str;
//if(i%5==1) tagContent_str;
public function tagComment():void
{
	lockAllUI();
	var time:Number = new Date().time;
	//new an array to catch data from remote SharedObject
	var tag:Array = new Array();
	//catch data from remote SharedObject
	if(so.data.tag!=null) tag = so.data.tag;
	//push videoID_str
	tag.push(fileName);	
	//push userID_str
	tag.push(txt_userID.text);
	//push tagTimestamp_int
	tag.push(time);			
	//push tagID_str	
	tag.push("Comment");
	//push tagContent_str	
	tag.push(txt_Comment.text);
	//update shared object
	so.setProperty("tag",tag);	
	//call FMS to synchronize the sharedobject in each client
	so.setDirty("tag");
	//clean txt_Comment.text
	txt_Comment.text = "";
	//post to php
	postMethod(fileName,txt_userID.text,time,"Comment",txt_Comment.text);
}
public function tagGood():void
{
	lockAllUI();
	var time:Number = new Date().time;
	var tag:Array = new Array();
	if(so.data.tag!=null) tag = so.data.tag;
	tag.push(fileName);	
	tag.push(txt_userID.text);
	tag.push(time);				
	tag.push("Good");	
	tag.push("none");
	so.setProperty("tag",tag);	
	so.setDirty("tag");
	postMethod(fileName,txt_userID.text,time,"Good",txt_Comment.text);
}
public function tagQuestion():void
{
	lockAllUI();
	var time:Number = new Date().time;
	var tag:Array = new Array();
	if(so.data.tag!=null) tag = so.data.tag;
	tag.push(fileName);	
	tag.push(txt_userID.text);
	tag.push(time);				
	tag.push("Question");	
	tag.push("none");
	so.setProperty("tag",tag);	
	so.setDirty("tag");
	postMethod(fileName,txt_userID.text,time,"Question",txt_Comment.text);
}
public function tagDisagree():void
{
	lockAllUI();
	var time:Number = new Date().time;
	var tag:Array = new Array();
	if(so.data.tag!=null) tag = so.data.tag;
	tag.push(fileName);	
	tag.push(txt_userID.text);
	tag.push(time);				
	tag.push("Disagree");	
	tag.push("none");
	so.setProperty("tag",tag);	
	so.setDirty("tag");
	postMethod(fileName,txt_userID.text,time,"Disagree",txt_Comment.text);
}
//post to php
public function postMethod(videoID_str:String,userID_str:String,tagTimestamp_int:Number,tagID_str:String,tagContent_str:String):void
{
	var urlPost:String = "http://ialab.tw/hyperwall/tag_post.php?type=tag_post";
	var request:URLRequest = new URLRequest(urlPost);
	var requestVars:URLVariables = new URLVariables();
	var urlLoader:URLLoader = new URLLoader();
	urlLoader.addEventListener(Event.COMPLETE, loaderCompleteHandler);
	urlLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
	urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
	urlLoader.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
	//post
	requestVars.videoID_str = videoID_str;
	requestVars.userID_str = userID_str;
	requestVars.tagTimestamp_int = tagTimestamp_int;
	requestVars.tagID_str = tagID_str;
	requestVars.tagContent_str = tagContent_str;
	for (var prop:String in requestVars)
		trace("Sent: " + prop + " is: " + requestVars[prop]);
	request.data = requestVars;
	request.method = URLRequestMethod.POST;
	urlLoader = new URLLoader();
	urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
	try 
	{
		urlLoader.load(request);
	}
	catch (e:Error)
	{
		trace(e);
	}
}
public function loaderCompleteHandler(e:Event):void
{
	var responseVars:URLVariables = URLVariables( e.target.data );
	trace( "responseVars: " + responseVars );
}
public function httpStatusHandler( e:HTTPStatusEvent ):void
{
	trace("httpStatusHandler:" + e);
}
public function securityErrorHandler( e:SecurityErrorEvent ):void
{
	trace("securityErrorHandler:" + e);
}
public function ioErrorHandler( e:IOErrorEvent ):void
{
	trace("ORNLoader:ioErrorHandler: " + e);
	dispatchEvent( e );
}
//realtime tagging service
public function handleEventClick(event:GraphEvent):void
{
	trace(event.item.category.toString());
	trace(event.item.description);
	
	//url link
	var hyperlinkStr:String = event.item.description;
	var hyperlinkArray:Array = new Array();
	var hyperlink:String;
	hyperlinkArray = hyperlinkStr.split("@@@");
	while(hyperlinkArray.length != 0)
	{
		hyperlink = hyperlinkArray.pop();		
		urlOpenWindowArray.push(hyperlink);
	}
	openWindows(0);
}
private function openWindows(n:Number):void 
{ 
	trace("openWindows");
	trace(urlOpenWindowArray[n]);
	if (n < urlOpenWindowArray.length)
	{ 
		navigateToURL(new URLRequest(urlOpenWindowArray[n]), '_blank'); 
		callLater(callLater, [openWindows,[n+1]]);
	}
	else
	{
		while(urlOpenWindowArray.length!=0) urlOpenWindowArray.pop();
	}
	trace("openWindows end");
} 
/**********************************/
/******** user interface **********/
/**********************************/
public function lockAllUI():void
{
	txt_userID.enabled = false;
	btn_StartBroadcasting.enabled = false;
	btn_StopBroadcasting.enabled = false;
	btn_good.enabled = false;
	btn_question.enabled = false;
	btn_disagree.enabled = false;
	btn_comment.enabled = false;
	btn_comment.enabled = false;
}
protected function btn_StartBroadcasting_clickHandler(event:MouseEvent):void
{
	startBroadcasting();
}
protected function btn_StopBroadcasting_clickHandler(event:MouseEvent):void
{
	stopBroadcasting();
}
protected function btn_good_clickHandler(event:MouseEvent):void
{
	tagGood();
}
protected function btn_question_clickHandler(event:MouseEvent):void
{
	tagQuestion();
}
protected function btn_disagree_clickHandler(event:MouseEvent):void
{
	tagDisagree();
}
protected function btn_comment_clickHandler(event:MouseEvent):void
{
	tagComment();
}
public function myKeyDownHandler1(event:KeyboardEvent):void
{
	if(event.charCode == 13) startBroadcasting();
}
public function myKeyDownHandler2(event:KeyboardEvent):void
{
	if(event.charCode == 13) tagComment();
}
/***********************************/
/******** check bandwidth **********/
/***********************************/
//usage:
//nc1.call("checkBandwidth", null);
public function onBWCheck(... rest):Number 
{ 
	return 0; 
} 
public function onBWDone(... rest):void 
{ 
	var p_bw:Number; 
	if (rest.length > 0) p_bw = rest[0]; 
	// your application should do something here
	bandWidth = p_bw;
	// when the bandwidth check is complete
}