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
import flash.events.KeyboardEvent;
import flash.events.NetStatusEvent;
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
/******** camera variables(Recording Service) **********/
public var cam0:Camera;
public var cam1:Camera;	
public var mic0:Microphone;
public var mic1:Microphone;
public var video0:Video;
public var video1:Video;
public var videoHolder:UIComponent;
/******** net variables(Recording Service) **********/
public var nc0:NetConnection;
public var nc1:NetConnection;
public var ncLive:NetConnection;
public var nr:Responder;
public var ns0:NetStream;
public var ns1:NetStream;
public var ns2:NetStream;
public var ns3:NetStream;
public var ns4:NetStream;
public var ns5:NetStream;
public var nsLive:NetStream;
public var nsArray:Array = new Array();
public var nsUsedArray:Array = new Array();
//public var appServer0:String="rtmp://localhost/Record";
//public var appServer1:String="rtmp://localhost/Broadcast";
//public var appServerLive:String="rtmp://localhost/liveVideo";
public var appServer0:String="rtmp://ialab.tw/Record";
public var appServer1:String="rtmp://ialab.tw/Broadcast";
public var appServerLive:String="rtmp://ialab.tw/liveVideo";
/******** program variables(Recording Service) **********/
public var currentCam:int;
public var hasCam0:Boolean;
public var hasCam1:Boolean;
public var hasMic0:Boolean;
public var hasMic1:Boolean;
public var isRecord:Boolean;
public var videoQuality:Number;
public var recordWidth:Number;
public var recordHeight:Number;
public var recordFPS:Number;
public var bufferTime:Number;
public var bufferTimeLive:Number;
public var nsCounter:Number;
public var recordLock:Boolean;
public var fileName:Number;
public var fileNameLive:Number;
public var bandWidth:Number;
public var urlOpenWindowArray:Array = new Array();///////////////////////////
/******** net variables(Tagging Service) **********/
public var nc2:NetConnection;
//public var appServer2:String="rtmp://localhost/Tag";
public var appServer2:String="rtmp://ialab.tw/Tag";
public var so:SharedObject;
/******** hyperlink variables ********/
public var urlStr:String = "(http(s)?:\/\/)(([a-z]+[a-z0-9\-]*[.])?([a-z0-9]+[a-z0-9\-]*[.])+[a-z]{2,3}|localhost)(\/[a-z0-9_-]+[a-z0-9_ -]*)*\/?(\\?[a-z0-9_-]+=[a-z0-9 ',.-]*(&amp;[a-z0-9_-]+=[a-z0-9 ',.-]*)*)?(#[a-z0-9/_-]*)?$";
public var urlPattern:RegExp = new RegExp(urlStr, "i");
public var matchUrl:Array = new Array();
/******************************/
/******** initialize **********/
/******************************/
//initialize
public function init():void
{
	Security.allowDomain("*");
	resetVar();	
	initCamera();
	initMic();
	initRecordingService();
	debug();
	amchartcontainer.visible = false;
	txt_ps.addEventListener(KeyboardEvent.KEY_DOWN,myKeyDownHandler);
	txt_et.addEventListener(KeyboardEvent.KEY_DOWN,myKeyDownHandler);
	txt_ed.addEventListener(KeyboardEvent.KEY_DOWN,myKeyDownHandler);
}
//used to show data on UI
public function debug():void
{
	trace("nsCounter = "+nsCounter.toString());
	trace("recordLock = "+recordLock.toString());
	trace("nsUsedArray[0] = "+nsUsedArray[0]);
	trace("nsUsedArray[1] = "+nsUsedArray[1]);
	trace("nsUsedArray[2] = "+nsUsedArray[2]);
	trace("nsUsedArray[3] = "+nsUsedArray[3]);
	trace("nsUsedArray[4] = "+nsUsedArray[4]);
	trace("nsUsedArray[5] = "+nsUsedArray[5]);
	trace("fileName = "+fileName.toString());
	trace("currentCam = "+currentCam.toString());
	trace("isRecord = "+isRecord.toString());
}
//reset all variables
public function resetVar():void
{
	//reset parameters
	currentCam = 0;
	videoQuality = 70;
	recordWidth = 1280;
	recordHeight = 720;
	recordFPS = 30;
	bufferTime = 600;
	bufferTimeLive = 0;
	nsCounter = 0;
	fileName = 0;
	fileNameLive = 0;
	//reset flags
	recordLock = false;
	hasCam0 = false;
	hasCam1 = false;
	hasMic0 = false;
	hasMic1 = false;
	isRecord = false;
	//reset NetStream array
	nsArray[0] = ns0;
	nsArray[1] = ns1;
	nsArray[2] = ns2;
	nsArray[3] = ns3;
	nsArray[4] = ns4;
	nsArray[5] = ns5;
	for (var i:Number=0; i<nsArray.length; i++)
		nsUsedArray[i] = false;
	//recycle NetStream
	recycleNetStream();
	txt.editable = false;
	lockAllUI();
}
/*****************************************/
/*********** recycleNetStream ************/
/*****************************************/
//used to recycle idle NetStreams
public function recycleNetStream():void
{
	for (var i:Number=0; i<nsArray.length; i++)
	{
		if(nsUsedArray[i]==true && nsArray[i].bufferLength==0)
		{
			//close netstream
			nsArray[i].play(false);
			nsArray[i].close();
			nsUsedArray[i]=false;
			recordLock = false;		
		}
	}
	//update UI
	debug();
}
//evaluate NetStreams and find an available NetStream
public function evaluateNsCounter():void
{
	var start:Number = 0;
	start = nsCounter;	
	while(true)
	{
		nsCounter++;
		if(nsCounter>=nsArray.length) nsCounter=0;
		if(nsCounter==start)
		{
			recordLock = true;
			Alert.show("Current net streams are all busy. Please wait...");
			break;
		}
		if(nsUsedArray[nsCounter]==false) break;
	}
}
/******************************/
/******** net status **********/
/******************************/
//initilize recording service
public function initRecordingService():void
{
	nc0 = new NetConnection();
	nc0.addEventListener(NetStatusEvent.NET_STATUS,netStatusHandler0);				
	nc0.connect(appServer0);
	nc0.client = this;
}
//connect recording service
public function netStatusHandler0(evt:NetStatusEvent):void
{
	if ( evt.info.code=="NetConnection.Connect.Success" )
	{
		txt_recording.text = "Succeed.";
		//initialize broadcasting Service
		initBroadcastingService();
	}
	else if(evt.info.code == "NetConnection.Connect.Failed")
	{
		txt_recording.text = "Failed.";
		Alert.show("ERROR: Recording service connection failed... Restart application.");
	}
}
//initialize broadcasting Service
public function initBroadcastingService():void
{
	nc1 = new NetConnection();
	nc1.addEventListener(NetStatusEvent.NET_STATUS,netStatusHandler1);				
	nc1.connect(appServer1);
	nc1.client = this;
}
//connect broadcasting Service
public function netStatusHandler1(evt:NetStatusEvent):void
{
	if ( evt.info.code=="NetConnection.Connect.Success" )
	{
		//call server and set filename
		nc1.call("storeFileName", null, null);
		initLiveService();
	}
	else if(evt.info.code == "NetConnection.Connect.Failed")
	{
		txt_broadcasting.text = "Failed.";
		Alert.show("ERROR: Broadcasting service connection failed... Restart application.");
	}
}
//initialize live Service
public function initLiveService():void
{
	ncLive = new NetConnection();
	ncLive.addEventListener(NetStatusEvent.NET_STATUS,netStatusHandlerLive);				
	ncLive.connect(appServerLive);
	ncLive.client = this;
}
//connect live Service
public function netStatusHandlerLive(evt:NetStatusEvent):void
{
	if ( evt.info.code=="NetConnection.Connect.Success" )
	{
		txt_broadcasting.text = "Succeed.";
		//unlock UI
		txt_et.enabled = true;
		txt_ed.enabled = true;
		txt_ps.enabled = true;
		btn_record.enabled = true;
		if(hasCam1 == true) btn_swapcam.enabled = false;
		btn_stoprecord.enabled = false;
		//btn_recycleNS.enabled = true;
	}
	else if(evt.info.code == "NetConnection.Connect.Failed")
	{
		txt_broadcasting.text = "Failed.";
		Alert.show("ERROR: Broadcasting service connection failed... Restart application.");
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
		txt_tagging.text = "Succeed.";
		//get remote SharedObject
		so = SharedObject.getRemote(fileName.toString(), nc2.uri, true);
		//add a synchronization event listener
		so.addEventListener(SyncEvent.SYNC, soSyncHandler);
		//connect FMS
		so.connect(nc2);
		//add event title and description
		tag();
	}
	else if(evt.info.code == "NetConnection.Connect.Failed")
	{
		Alert.show("ERROR: Tagging service connection failed... Restart application.");
		txt_tagging.text = "Failed.";
	}
	else if(evt.info.code == "NetConnection.Connect.Closed")
	{
		txt_tagging.text = "Closed.";
	}
	
}
//tagging service synchronization handler
public function soSyncHandler(evt:SyncEvent):void
{
	/*
	//new an array to catch data from remote SharedObject
	var tag:Array = new Array();
	//catch data from remote SharedObject
	if(so.data.tag!=null)
	{
		tag = so.data.tag;
		//display data in TextArea
		if(tag[2]!=null)
		{
			for (var i:int=tag.length-5; i<tag.length; i++)
			{
				if(tag[i]!=null)
				{
					if(i%5==2) txt.appendText("videoID: "+tag[i]+"\n");
					else if(i%5==3) txt.appendText("userID: "+tag[i]+"\n");
					else if(i%5==4) txt.appendText("Time: "+tag[i]+"\n");
					else if(i%5==0) txt.appendText("tagID: "+tag[i]+"\n");
					else if(i%5==1)
					{
						txt.appendText("Content: "+tag[i]+"\n");
						txt.appendText("------------------------------\n");
					}
				}
			}
		}
	}
	*/
	setAmchartData();
}
//set amcharts data
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
		trace("not null");
		tag = so.data.tag;
		if(tag[2]!=null)
		{
			//display data in TextArea
			txt.text = "";
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
		}//end of if(tag[2]!=null)
	}//end of if(so.data.tag!=null) 
}
//add event title and description
public function tag():void
{
	var tag:Array = new Array();
	//catch data from remote SharedObject
	if(so.data.tag!=null) tag = so.data.tag;
	//push event tile
	tag.push(txt_et.text);
	//push event description
	tag.push(txt_ed.text);
	//update shared object
	so.setProperty("tag",tag);	
	//call FMS to synchronize the sharedobject in each client
	so.setDirty("tag");
}
//close tagging service
public function closeTaggingService():void
{
	nc2.close();
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
/*****************************************/
/********** recording service ************/
/*****************************************/
//initialize cameras
public function initCamera():void 
{
	//initialize camera0
	if(Camera.getCamera("0")!=null)
	{	
		hasCam0 = true;
		cam0 = Camera.getCamera("0");		
		cam0.setMode(recordWidth,recordHeight,recordFPS);			
		cam0.setQuality(0,videoQuality);
		video0 = new Video(640,360);
		video0.smoothing = true;
		video0.attachCamera(cam0);
		txt_cam0.text = "Attached.";	
	}
	else txt_cam0.text = "Not attached.";
	
	//initialize camera1
	if(Camera.getCamera("1")!=null)
	{	
		hasCam1 = true;
		//set recording cam	
		cam1 = Camera.getCamera("1");
		cam1.setMode(recordWidth,recordHeight,recordFPS);
		cam1.setQuality(0,videoQuality);
		video1 = new Video(640,360);
		video1.smoothing = true;
		video1.attachCamera(cam1);
		txt_cam1.text = "Attached.";
	}
	else txt_cam1.text = "Not attached.";
	
	//creat videoHolder
	videoHolder = new UIComponent();
}
//initialize microphones
public function initMic():void
{
	//initialize microphone0
	if(Microphone.getMicrophone(0)!=null)
	{
		hasMic0 = true;
		//set recording mic
		mic0 = Microphone.getMicrophone(0);
		txt_mic0.text = "Attached.";		
	}
	else txt_mic0.text = "Not attached.";
	
	//initialize microphone1
	if(Microphone.getMicrophone(1)!=null)
	{
		hasMic1 = true;
		//set recording mic
		mic1 = Microphone.getMicrophone(1);	
		txt_mic1.text = "Attached.";
	}
	else txt_mic1.text = "Not attached.";
}
public function hasEvent():Boolean
{
	var pattern:RegExp = /[\s]*/;
	var matchEventTitle:Array = new Array();
	var matchEventDescription:Array = new Array();
	matchEventTitle = pattern.exec(txt_et.text);
	matchEventDescription = pattern.exec(txt_ed.text);
	if(txt_ps.text == "ialab")
	{
		if(matchEventTitle == null || matchEventTitle[0] == txt_et.text
			|| matchEventDescription == null || matchEventDescription[0] == txt_ed.text)
		{ 
			//Alert.show("ERROR: Please fill in event title and description.");
			//return false;
			txt_et.text = new Date().toDateString();
			txt_ed.text = "no description";
			return true;
		}
		else 
		{
			return true;
		}
	}
	else
	{
		Alert.show("Wrong password. Please contact administrator.");
		return false;
	}
}
//start recording service
public function startRecord():void
{
	//recycle NetStreams
	recycleNetStream();
	//choose NetStream 
	evaluateNsCounter();
	//start record
	if(isRecord == false && recordLock == false)
	{		
		//if match all the words in txt_et.text and txt_ed.text
		if(hasEvent() == true)
		{
			lockAllUI();
			txt.text = "";
			isRecord = true;
			//set fileCounter
			fileName = new Date().time;
			fileNameLive = fileName+1;
			//initilaize tagging service
			initTaggingService();
			//call server and set filename
			nc1.call("storeFileName", null, fileName.toString());
			nc1.call("storeFileNameLive", null, fileNameLive.toString());	
			//new netstream array
			nsArray[nsCounter] = new NetStream(nc0);
			nsArray[nsCounter].bufferTime = bufferTime;
			nsUsedArray[nsCounter] = true;
			//new live netstream
			nsLive = new NetStream(ncLive);
			nsLive.bufferTime = bufferTimeLive;
			//setup camera and microphone
			if(currentCam == 0)
			{		
				if(hasCam0 == true)
				{
					//text
					trace("Start recording cam0...");					
					//display video
					videoHolder.addChild(video0);
					cnvWebcam.addChild(videoHolder);
					//start recording
					nsArray[nsCounter].attachCamera(cam0);
					nsArray[nsCounter].attachAudio(mic0);
					//start live
					nsLive.attachCamera(cam0);
					nsLive.attachAudio(mic0);
				}
			}
			else if(currentCam == 1)
			{
				if(hasCam1 == true)
				{				
					//text
					trace("Start recording cam1...");			
					//display video
					videoHolder.addChild(video1);
					cnvWebcam.addChild(videoHolder);
					//start recording
					nsArray[nsCounter].attachCamera(cam1);
					nsArray[nsCounter].attachAudio(mic1);
					//start live
					nsLive.attachCamera(cam1);
					nsLive.attachAudio(mic1);
				}
			}
			//record file
			nsArray[nsCounter].client = this;
			nsArray[nsCounter].publish(fileName.toString(),"record");
			txt_recordfilename.text = fileName.toString();
			//live file
			nsLive.client = this;
			nsLive.publish(fileNameLive.toString(),"live");
			//unlock UI
			txt_et.enabled = false;
			txt_ed.enabled = false;
			txt_ps.enabled = false;
			btn_record.enabled = false;
			if(hasCam1 == true) btn_swapcam.enabled = true;
			btn_stoprecord.enabled = true;
			//btn_recycleNS.enabled = true;
		}//end of if(hasEvent()==true)
	}//end of if(isRecord == false)
	debug();
}
//stop recording service
public function stopRecord():void
{
	if(isRecord == true)
	{		
		lockAllUI();
		isRecord = false;
		//close tagging service
		closeTaggingService();
		//call server and set filename
		nc1.call("storeFileName", null, null);
		nc1.call("storeFileNameLive", null, null);
		//recycle NetStreams
		recycleNetStream();
		//stop recording
		nsArray[nsCounter].attachAudio(null);
		nsArray[nsCounter].attachCamera(null);
		//stop live
		nsLive.attachAudio(null);
		nsLive.attachCamera(null);
		//show buffer length
		trace("nsArray["+nsCounter+"].bufferLength = "+nsArray[nsCounter].bufferLength.toString());
		if(currentCam == 0)
		{
			if(hasCam0 == true)
			{
				//text
				trace("Stop recording cam0...");						
				//undisplay video
				cnvWebcam.removeChild(videoHolder);
				videoHolder.removeChild(video0);
			}
		}
		else if(currentCam == 1)
		{
			if(hasCam1 == true)
			{
				//text
				trace("Stop recording cam1...");		
				//undisplay video
				cnvWebcam.removeChild(videoHolder);
				videoHolder.removeChild(video1);
			}
		}
		//unlock UI
		txt_et.enabled = true;
		txt_ed.enabled = true;
		txt_ps.enabled = true;
		btn_record.enabled = true;
		if(hasCam1 == true) btn_swapcam.enabled = false;
		btn_stoprecord.enabled = false;
		//btn_recycleNS.enabled = true;
	}//end of if(isRecord == true)
	debug();
}
//swap camera
public function swapCamera():void
{
	if(isRecord == true)
	{
		lockAllUI();
		//stop recording
		nsArray[nsCounter].attachCamera(null);
		nsArray[nsCounter].attachAudio(null);
		//stop live
		nsLive.attachAudio(null);
		nsLive.attachCamera(null);
		
		if(currentCam == 0)
		{
			currentCam = 1;			
			//text
			trace("Swap from cam0 to cam1...");			
			//swap screen
			cnvWebcam.removeChild(videoHolder);
			videoHolder.removeChild(video0);
			videoHolder.addChild(video1);
			cnvWebcam.addChild(videoHolder);
			//swap recording
			nsArray[nsCounter].attachCamera(cam1);
			nsArray[nsCounter].attachAudio(mic1);
			//swap live
			nsLive.attachCamera(cam1);
			nsLive.attachAudio(mic1);			
		}
		else if(currentCam == 1)
		{
			currentCam = 0;
			//text
			trace("Swap from cam1 to cam0...");		
			//swap
			cnvWebcam.removeChild(videoHolder);
			videoHolder.removeChild(video1);
			videoHolder.addChild(video0);
			cnvWebcam.addChild(videoHolder);
			//swap recording
			nsArray[nsCounter].attachCamera(cam0);
			nsArray[nsCounter].attachAudio(mic0);
			//swap live
			nsLive.attachCamera(cam0);
			nsLive.attachAudio(mic0);
		}			
		//unlock UI
		txt_et.enabled = false;
		txt_ed.enabled = false;
		txt_ps.enabled = false;
		btn_record.enabled = false;
		if(hasCam1 == true) btn_swapcam.enabled = true;
		btn_stoprecord.enabled = true;
		//btn_recycleNS.enabled = true;
	}// end of if(isRecord == true)
	debug();
}
/*
//start replaying
public function startReplay():void
{
	lockAllUI();
	txt.text = "";
	nc2 = new NetConnection();
	nc2.addEventListener(NetStatusEvent.NET_STATUS,netStatusHandler3);				
	nc2.connect(appServer2);
	nc2.client = this;
}
//stop replaying
public function stopReplay():void
{
	lockAllUI();
	nc2.close();
}
public function netStatusHandler3(evt:NetStatusEvent):void
{
	if ( evt.info.code=="NetConnection.Connect.Success" )
	{
		txt_connection2.text = "Tagging service connection succeed.";
		//get remote SharedObject
		so = SharedObject.getRemote(txt_replayfilename.text, nc2.uri, true);
		//add a synchronization event listener
		so.addEventListener(SyncEvent.SYNC, soSyncHandler);
		//connect FMS
		so.connect(nc2);
		//new an array to catch data from remote SharedObject
		var tag:Array = new Array();
		//catch data from remote SharedObject
		if(so.data.tag!=null) tag = so.data.tag;		
		//display data in TextArea
		txt.text = "";
		for (var i:int=0; i<tag.length; i++)
		{
			if(i%5==0) txt.appendText("videoID: "+tag[i]+"\n");
			else if(i%5==1) txt.appendText("userID: "+tag[i]+"\n");
			else if(i%5==2) txt.appendText("Time: "+tag[i]+"\n");
			else if(i%5==3) txt.appendText("tagID: "+tag[i]+"\n");
			else if(i%5==4)
			{
				txt.appendText("Content: "+tag[i]+"\n");
				txt.appendText("------------------------------\n");
			}
		}
		//startReplay
		trace("Start replaying...");
		cnvWebcam.source=appServer0+"/"+txt_replayfilename.text;
		cnvWebcam.play();
		//unlock UI
		txt_replayfilename.enabled = false;
		btn_record.enabled = false;
		btn_swaptocam1.enabled = false;
		btn_stoprecord.enabled = false;
		btn_recycleNS.enabled = true;
	}
	else if(evt.info.code == "NetConnection.Connect.Failed")
	{
		Alert.show("ERROR: Tagging service connection failed... Restart application.");
		txt_connection2.text = "Tagging service connection failed.";
		//unlock UI
		txt_replayfilename.enabled = true;
		btn_record.enabled = true;
		btn_swaptocam1.enabled = false;
		btn_stoprecord.enabled = false;
		btn_recycleNS.enabled = true;
	}
	else if(evt.info.code == "NetConnection.Connect.Closed")
	{
		txt_connection2.text = "Tagging service connection closed.";
		txt.text = "";	
		//stopReplay
		trace("Stop replaying...");
		cnvWebcam.stop();
		//unlock UI
		txt_replayfilename.enabled = true;
		btn_record.enabled = true;
		btn_swaptocam1.enabled = false;
		btn_stoprecord.enabled = false;
		btn_recycleNS.enabled = true;
	}
}
*/
/**********************************/
/******** user interface **********/
/**********************************/
//lock all UI
public function lockAllUI():void
{
	txt_et.enabled = false;
	txt_ed.enabled = false;
	txt_ps.enabled = false;
	btn_record.enabled = false;
	btn_swapcam.enabled = false;
	btn_stoprecord.enabled = false;
	//btn_recycleNS.enabled = false;
}
public function myKeyDownHandler(event:KeyboardEvent):void
{
	if(event.charCode == 13) startRecord();
}
protected function btn_record_clickHandler(event:MouseEvent):void
{
	startRecord();
}
protected function btn_stoprecord_clickHandler(event:MouseEvent):void
{
	stopRecord();
}	
protected function btn_swapcam_clickHandler(event:MouseEvent):void
{
	swapCamera();
}
protected function btn_recycleNS_clickHandler(event:MouseEvent):void
{
	recycleNetStream();
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
	trace("bandwidth = " + bandWidth + " Kbps."); 
}