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
import com.amcharts.*;
import com.amcharts.chartClasses.AmCoordinateChart;
import com.amcharts.chartClasses.GraphDataItem;
import com.amcharts.events.*;
import com.amcharts.stock.events.StockBulletEvent;
import flash.net.NetConnection;
import flash.net.SharedObject;
import flash.net.URLRequest;
import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.events.IndexChangedEvent;
import mx.formatters.DateFormatter;
/******** amchart variables **********/
[Bindable]
private var chartData:ArrayCollection = new ArrayCollection(); 
[Bindable]
private var chartData_:ArrayCollection = new ArrayCollection();
[Bindable]
private var iStudioChartData:ArrayCollection = new ArrayCollection();
[Bindable]
private var othersChartData:ArrayCollection = new ArrayCollection();    
/******** net variables(Tagging Service) **********/
public var ncAmchartStock:NetConnection;
public var ncAmchart:NetConnection;
public var ncAmchart_:NetConnection;
public var nr:Responder = new Responder(onReply);
//public var appServer1:String="rtmp://localhost/Record";
//public var appServer2:String="rtmp://localhost/Tag";//realtime
//public var appServer3:String="rtmp://localhost/Tag_";//not realtime
public var appServer1:String="rtmp://ialab.tw/Record";
public var appServer2:String="rtmp://ialab.tw/Tag";//realtime
public var appServer2_:String="rtmp://ialab.tw/Tag_";//not realtime
public var soAmchartStock:SharedObject;
public var soAmchart:SharedObject;
public var soAmchart_:SharedObject;
/******** program variables **********/
public var fileName:Number;
public var urlOpenWindowArray:Array = new Array();//////////////////////////////////
/******** amchart stock variables ********/
public var fileListArray:Array = new Array();
public var evtArray:Array = new Array();
public var tempFileCount:int = 0;
public var startZoomDate:Date;
public var endZoomDate:Date;
public var isFirstSetAmchartData:Boolean;
public var isFirstSetAmchartData_:Boolean;
/******** hyperlink variables ********/
public var urlStr:String = "(http(s)?:\/\/)(([a-z]+[a-z0-9\-]*[.])?([a-z0-9]+[a-z0-9\-]*[.])+[a-z]{2,3}|localhost)(\/[a-z0-9_-]+[a-z0-9_ -]*)*\/?(\\?[a-z0-9_-]+=[a-z0-9 ',.-]*(&amp;[a-z0-9_-]+=[a-z0-9 ',.-]*)*)?(#[a-z0-9/_-]*)?$";
public var urlPattern:RegExp = new RegExp(urlStr, "i");
public var matchUrl:Array = new Array();
/******************************/
/******** initialize **********/
/******************************/
public function init():void
{
	txt.editable = false;
	txt_about.editable = false;
	initTaggingService();
	videoPlayer.autoPlay = false;
	txt_Comment.addEventListener(KeyboardEvent.KEY_DOWN,myKeyDownHandler);
}
//initilaize tagging service
public function initTaggingService():void
{
	ncAmchartStock = new NetConnection();
	ncAmchartStock.addEventListener(NetStatusEvent.NET_STATUS,netStatusHandlerAmchartStock);				
	ncAmchartStock.connect(appServer2);
	ncAmchartStock.client = this;
	ncAmchartStock.call("getFileList",nr);
}
//connect tagging service
public function netStatusHandlerAmchartStock(evt:NetStatusEvent):void
{
	if ( evt.info.code=="NetConnection.Connect.Success" )
	{
		trace("[AmchartStock] Tagging service connection succeed.");
	}
	else if(evt.info.code == "NetConnection.Connect.Facj iled")
	{
		Alert.show("ERROR: Tagging service connection failed... Restart application.");
		trace("[AmchartStock] Tagging service connection failed.");
	}
	else if(evt.info.code == "NetConnection.Connect.Closed")
	{
		trace("[AmchartStock] Tagging service connection closed.");
	}	
}
//when Responder get filelist from tagging service
public function onReply(result:Object):void  
{  	
	if(result!=null)
	{
		//for (var i:String in result)
		var fileListPattern:RegExp = /[0-9]{13}/;//13 numbers
		for (var i:Number = 0; i<result.length; i++)
		{
			fileListArray[i] = fileListPattern.exec(result[i].toString());
		}
		//get remote SharedObject
		soAmchartStock = SharedObject.getRemote(fileListArray[tempFileCount], ncAmchartStock.uri, true);
		//add a synchronization event listener
		soAmchartStock.addEventListener(SyncEvent.SYNC, soSyncHandlerAmchartStock);
		//connect FMS
		soAmchartStock.connect(ncAmchartStock);
		//get data
		soAmchartStock.setDirty("tag");
	}
	else
	{
		Alert.show("File directory error. Please contact the administrator.");
	}
}
public function soSyncHandlerAmchartStock(event:SyncEvent):void
{
	trace("soSyncHandlerAmchartStock");
	buildTimeLine();
}
public function buildTimeLine():void
{
	//new an array to catch data from remote SharedObject
	var tag:Array = new Array();
	//catch data from remote SharedObject
	if(soAmchartStock.data.tag!=null)
	{
		tag = soAmchartStock.data.tag;
		var evt:StockEvent = new StockEvent();
		var newDate:Date = new Date(Number(fileListArray[tempFileCount]));
		iStudioChartData.addItem({date:newDate,a:0});
		evt.date = newDate;
		evt.graph = g1;
		evt.type = "sign";//flag, sign, pin, triangleUp, triangleDown, triangleLeft, triangleRight
		evt.backgroundColor = 0x000000;
		if(tag.length>500) evt.backgroundAlpha = 0.9;
		else if(tag.length<=500 && tag.length>100) evt.backgroundAlpha = 0.4;
		else evt.backgroundAlpha = 0.1;
		evt.borderAlpha = 0;
		evt.rollOverColor = 0xFFD2D2;
		evt.text = "";
		evt.description = "--- TITLE ---\n"
						+ tag[0]
						+ "\n\n--- CONTENT ---\n"
						+ tag[1]
						+ "\n\n--- TIME ---\n"
						+ newDate.toDateString()+" "+newDate.toTimeString()
						+ "\n\n--- FILE ---\n"
						+ fileListArray[tempFileCount];
		evtArray.push(evt);
			
		if(tempFileCount==fileListArray.length-1)
		{	
			iStudioDataSet.stockEvents = evtArray;							
			startZoomDate = new Date(Number(fileListArray[tempFileCount])-604800000);//one week ago
			endZoomDate = newDate;
			trace(startZoomDate);
			trace(endZoomDate);
			soAmchartStock.removeEventListener(SyncEvent.SYNC, soSyncHandlerAmchartStock);
			soAmchartStock.close();
			ncAmchartStock.close();		
			trace("-------------end--------------");
		}
		else
		{
			iStudioDataSet.stockEvents = evtArray;
			trace(tempFileCount);
			trace(fileListArray[tempFileCount]);			
			soAmchartStock.close();
			tempFileCount++;
			soAmchartStock = SharedObject.getRemote(fileListArray[tempFileCount], ncAmchartStock.uri, true);
			soAmchartStock.addEventListener(SyncEvent.SYNC, soSyncHandlerAmchartStock);
			soAmchartStock.connect(ncAmchartStock);
			soAmchartStock.setDirty("tag");	
		}
	}
}
public function creationcomplete():void
{	
	iStudioDataSet.stockEvents = evtArray;
	stockchart.zoom(startZoomDate,endZoomDate);
}
private function handleStockEventClick(event:StockBulletEvent):void
{
	trace("handleStockEventClick");
	isFirstSetAmchartData = false;
	isFirstSetAmchartData_ = false;
	chartData.removeAll();	
	chartData_.removeAll();
	fileName = event.eventObject.date.time;
	trace(fileName);
	videoPlayer.source = appServer1+"/"+fileName.toString();
	connectRealtimeTag();
} 
private function connectRealtimeTag():void
{
	ncAmchart = new NetConnection();
	ncAmchart.addEventListener(NetStatusEvent.NET_STATUS,netStatusHandlerAmchart);				
	ncAmchart.connect(appServer2);
	ncAmchart.client = this;	
}
//connect realtime tagging service
public function netStatusHandlerAmchart(evt:NetStatusEvent):void
{
	if ( evt.info.code=="NetConnection.Connect.Success" )
	{
		trace("[Amchart RealTime] Tagging service connection succeed.");
		connectNotRealtimeTag();
	}
	else if(evt.info.code == "NetConnection.Connect.Failed")
	{
		Alert.show("ERROR: Tagging service connection failed... Restart application.");
		trace("[Amchart RealTime] Tagging service connection failed.");
	}
	else if(evt.info.code == "NetConnection.Connect.Closed")
	{
		trace("[Amchart RealTime] Tagging service connection closed.");
		ncAmchart_.close();
	}	
}
private function connectNotRealtimeTag():void
{
	ncAmchart_ = new NetConnection();
	ncAmchart_.addEventListener(NetStatusEvent.NET_STATUS,netStatusHandlerAmchart_);				
	ncAmchart_.connect(appServer2_);
	ncAmchart_.client = this;
}
public function netStatusHandlerAmchart_(evt:NetStatusEvent):void
{
	if ( evt.info.code=="NetConnection.Connect.Success" )
	{
		trace("[Amchart Not RealTime] Tagging service connection succeed.");
		//get RealTime Tag
		soAmchart = SharedObject.getRemote(fileName.toString(), ncAmchart.uri, true);
		soAmchart.addEventListener(SyncEvent.SYNC, soSyncHandlerAmchart);
		soAmchart.connect(ncAmchart);
		//soAmchart.setDirty("tag");
	}
	else if(evt.info.code == "NetConnection.Connect.Failed")
	{
		Alert.show("ERROR: Tagging service connection failed... Restart application.");
		trace("[Amchart Not RealTime] Tagging service connection failed.");
	}
	else if(evt.info.code == "NetConnection.Connect.Closed")
	{
		trace("[Amchart Not RealTime] Tagging service connection closed.");
		//swap screen
		amchartstockcontainer.visible = true;
	}	
}
public function soSyncHandlerAmchart(evt:SyncEvent):void
{
	trace("soSyncHandlerAmchart");
	if(isFirstSetAmchartData == false)
	{
		trace(isFirstSetAmchartData);
		isFirstSetAmchartData = true;
		setAmchartData();
		//get Not RealTime Tag
		soAmchart_ = SharedObject.getRemote(fileName.toString()+"_", ncAmchart_.uri, true);
		soAmchart_.addEventListener(SyncEvent.SYNC, soSyncHandlerAmchart_);
		soAmchart_.connect(ncAmchart_);
		//soAmchart_.setDirty("tag");
	}
	else
	{
		trace(isFirstSetAmchartData);		
		setAmchartData();		
	}
}
/*********************************
	Realtime Tagging Service
	tag[0] is event title
	tag[1] is event description
	tag[i]
	if(i%5==2) videoID_str;
	if(i%5==3) userID_str;
	if(i%5==4) tagTimestamp_int;
	if(i%5==0) tagID_str;
	if(i%5==1) tagContent_str;
**********************************/
public function setAmchartData():void
{
	trace("setAmchartData");
	if(tabNavigator.selectedIndex == 0)
	{
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
		if(soAmchart.data.tag!=null)
		{
			trace("not null");
			tag = soAmchart.data.tag;
			txt.text = "";
			txt_about.text = "";
			txt_about.appendText("-----------------------------------------------\n");
			txt_about.appendText("  " + tag[0] + "\n");
			txt_about.appendText("-----------------------------------------------\n");
			txt_about.appendText(tag[1]);
			if(tag[2]!=null)
			{
				//display data in TextArea
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
			}
		}//end of if(soAmchart.data.tag!=null)
	}//end of if(tabNavigator.selectedIndex == 0)
}
public function soSyncHandlerAmchart_(evt:SyncEvent):void
{
	trace("soSyncHandlerAmchart_");
	if(isFirstSetAmchartData_ == false)
	{
		trace(isFirstSetAmchartData_);		
		isFirstSetAmchartData_ = true;
		if(soAmchart_.data.tag!=null)
		{
			trace("not null");
			setAmchartData_();
		}
		else
		{
			trace("is null");
			//new an array to catch data from remote SharedObject
			var tagAmchart:Array = new Array();
			var tagAmchart_:Array = new Array();
			tagAmchart = soAmchart.data.tag;
			tagAmchart_.push(tagAmchart[0]);
			tagAmchart_.push(tagAmchart[1]);
			soAmchart_.setProperty("tag",tagAmchart_);			
		}
		//swap screen
		amchartstockcontainer.visible = false;
	}
	else
	{
		trace(isFirstSetAmchartData_);
		setAmchartData_();
		/*
		var tag:Array = new Array();
		//catch data from remote SharedObject
		if(soAmchart_.data.tag!=null)
		{
			tag = soAmchart_.data.tag;
			//display data in TextArea
			if(tag[2]!=null)
			{
				for (var i:int=2; i<tag.length; i++)
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
				}//end of for (var i:int=2; i<tag.length; i++)
			}//end of if(tag[2]!=null
		}//end of if(soAmchart_.data.tag!=null)
		*/
	}//end of else
	if(tabNavigator.selectedIndex == 0)
	{
		//unlock UI
		btn_returntotimeline.enabled = true;
		btn_good.enabled = false;
		btn_question.enabled = false;
		btn_disagree.enabled = false;
		btn_comment.enabled = false;
		btn_comment.enabled = false;
		txt_Comment.enabled = false;
	}
	if(tabNavigator.selectedIndex == 1)
	{
		//unlock UI
		btn_returntotimeline.enabled = true;
		btn_good.enabled = true;
		btn_question.enabled = true;
		btn_disagree.enabled = true;
		btn_comment.enabled = true;
		btn_comment.enabled = true;
		txt_Comment.enabled = true;
	}
}
/*********************************
	Not Realtime Tagging Service
	tag[0] is event title
	tag[1] is event description
	tag[i]
	if(i%5==0) videoID_str;
	if(i%5==1) userID_str;
	if(i%5==2) tagTimestamp_int;
	if(i%5==3) tagID_str;
	if(i%5==4) tagContent_str;
**********************************/
public function setAmchartData_():void
{
	trace("setAmchartData_");
	if(tabNavigator.selectedIndex == 1)
	{
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
		if(soAmchart_.data.tag!=null)
		{
			trace("not null");
			txt.text = "";
			tag = soAmchart_.data.tag;
			if(tag[2]!=null)
			{
				//display data in TextArea
				chartData_.removeAll();
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
							txt.appendText("Comment at "+currentTime+" sec:\n");
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
						chartData_.addItem({hyperlinkStr_:hyperlinkStr,videotime_:lastTime,good_:goodNum,question_:questionNum,disagree_:disagreeNum,hyperlink_:hyperlinkNum});
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
							txt.appendText("Comment at "+currentTime+" sec:\n");
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
				chartData_.addItem({hyperlinkStr_:hyperlinkStr,videotime_:lastTime,good_:goodNum,question_:questionNum,disagree_:disagreeNum,hyperlink_:hyperlinkNum});
			}
		}//end of if(soAmchart.data.tag!=null)
	}//end of if(tabNavigator.selectedIndex == 1)
}
//realtime tagging service
public function handleEventClick(event:GraphEvent):void
{
	trace(event.item.category.toString());
	trace(event.item.description);
	videoPlayer.seek(Number(event.item.category));
	
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
//not realtime tagging service
public function handleEventClick_(event:GraphEvent):void
{
	trace(event.item.category.toString());
	trace(event.item.description);
	videoPlayer.seek(Number(event.item.category));
	
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
public function AmchartTaggingTabChange(event:IndexChangedEvent):void
{
	trace("AmchartTaggingTabChange");
	lockAllUI();
	txt.text = "";
	if(event.newIndex == 0)
	{
		trace("realtimeTaggingTab");
		setAmchartData();
		//unlock UI
		btn_returntotimeline.enabled = true;
		btn_good.enabled = false;
		btn_question.enabled = false;
		btn_disagree.enabled = false;
		btn_comment.enabled = false;
		btn_comment.enabled = false;
		txt_Comment.enabled = false;
	}
	else if(event.newIndex == 1)
	{
		trace("notRealtimeTaggingTab");
		setAmchartData_();
		//unlock UI
		btn_returntotimeline.enabled = true;
		btn_good.enabled = true;
		btn_question.enabled = true;
		btn_disagree.enabled = true;
		btn_comment.enabled = true;
		btn_comment.enabled = true;
		txt_Comment.enabled = true;
	}
}
/***********************************************/
/******** Not Realtime Tagging Service *********/
/***********************************************/
//tag[i]
//if(i%5==0) videoID_str;
//if(i%5==1) userID_str;
//if(i%5==2) tagTimestamp_int;
//if(i%5==3) tagID_str;
//if(i%5==4) tagContent_str;
public function tagComment():void
{
	lockAllUI();
	//new an array to catch data from remote SharedObject
	var insertTagArray:Array = new Array();
	var oldTagArray:Array = new Array();
	var newTagArray:Array = new Array();
	//catch data from remote SharedObject
	if(soAmchart_.data.tag!=null) oldTagArray = soAmchart_.data.tag;
	//push videoID_str
	insertTagArray.push(fileName);	
	//push userID_str
	insertTagArray.push("txt_userID.text");
	//push tagTimestamp_int
	insertTagArray.push(Number(fileName)+videoPlayer.currentTime*1000);
	//push tagID_str	
	insertTagArray.push("Comment");
	//push tagContent_str	
	insertTagArray.push(txt_Comment.text);
	//insert insertTagArray to oldTagArray in time order
	newTagArray = tagInsert(insertTagArray,oldTagArray);
	//update shared object
	soAmchart_.setProperty("tag",newTagArray);	
	//call FMS to synchronize the sharedobject in each client
	soAmchart_.setDirty("tag");
	//post to php
	//postMethod(fileName,txt_userID.text,time,"Comment",txt_Comment.text);
	//clean txt_Comment.text
	txt_Comment.text = "";
}
public function tagGood():void
{
	lockAllUI();
	var insertTagArray:Array = new Array();
	var oldTagArray:Array = new Array();
	var newTagArray:Array = new Array();
	if(soAmchart_.data.tag!=null) oldTagArray = soAmchart_.data.tag;
	insertTagArray.push(fileName);	
	insertTagArray.push("txt_userID.text");
	insertTagArray.push(Number(fileName)+videoPlayer.currentTime*1000);			
	insertTagArray.push("Good");	
	insertTagArray.push("none");
	newTagArray = tagInsert(insertTagArray,oldTagArray);
	trace("####################oldTagArray#######################");
	for(var i:String in oldTagArray) trace(oldTagArray[i]);
	trace("###################insertTagArray########################");
	for(var j:String in insertTagArray) trace(insertTagArray[j]);
	trace("####################newTagArray######################");
	for(var k:String in newTagArray) trace(newTagArray[k]);
	trace("#######################################################");
	soAmchart_.setProperty("tag",newTagArray);	
	soAmchart_.setDirty("tag");
	//postMethod(fileName,txt_userID.text,time,"Good",txt_Comment.text);
}
public function tagQuestion():void
{
	lockAllUI();
	var insertTagArray:Array = new Array();
	var oldTagArray:Array = new Array();
	var newTagArray:Array = new Array();
	if(soAmchart_.data.tag!=null) oldTagArray = soAmchart_.data.tag;
	insertTagArray.push(fileName);	
	insertTagArray.push("txt_userID.text");
	insertTagArray.push(Number(fileName)+videoPlayer.currentTime*1000);			
	insertTagArray.push("Question");	
	insertTagArray.push("none");
	newTagArray = tagInsert(insertTagArray,oldTagArray);
	soAmchart_.setProperty("tag",newTagArray);	
	soAmchart_.setDirty("tag");
	//postMethod(fileName,txt_userID.text,time,"Question",txt_Comment.text);
}
public function tagDisagree():void
{
	lockAllUI();
	var insertTagArray:Array = new Array();
	var oldTagArray:Array = new Array();
	var newTagArray:Array = new Array();
	if(soAmchart_.data.tag!=null) oldTagArray = soAmchart_.data.tag;
	insertTagArray.push(fileName);	
	insertTagArray.push("txt_userID.text");
	insertTagArray.push(Number(fileName)+videoPlayer.currentTime*1000);			
	insertTagArray.push("Disagree");	
	insertTagArray.push("none");
	newTagArray = tagInsert(insertTagArray,oldTagArray);
	soAmchart_.setProperty("tag",newTagArray);	
	soAmchart_.setDirty("tag");
	//postMethod(fileName,txt_userID.text,time,"Disagree",txt_Comment.text);
}
//use binary search to insert insertTagArray to oldTagArray in time order
public function tagInsert(insertTag:Array,oldTag:Array):Array
{
	trace("tagInsert");
	var newTagArray:Array = new Array();
	var insertTagArray:Array = new Array();
	var oldTagArray:Array = new Array();
	var tagNumber:Number = 0;
	var insertStart:Number = 0;
	var insertEnd:Number = 0;
	var insertNumber:Number = 0;
	var insertIndex:Number = 0;
	//copy data (cannot use insertTagArray=insertTag because it passes by reference instead of by value)
	for(var token1:String in insertTag) insertTagArray[token1] = insertTag[token1];
	for(var token2:String in oldTag) oldTagArray[token2] = oldTag[token2];
	//count tag number
	tagNumber = (oldTagArray.length-2)/5;
	if(tagNumber==0)
	{
		//copy
		newTagArray = oldTagArray;
		//insert
		newTagArray.push(insertTagArray[0],insertTagArray[1],insertTagArray[2],insertTagArray[3],insertTagArray[4]);
	}
	else
	{
		insertStart = 4;
		insertEnd = 4 + (tagNumber-1)*5;
		while(true)
		{
			trace("tagInsertWhile");
			trace("oldTagArray.length = "+oldTagArray.length);
			trace("tagNumber = "+tagNumber);
			trace("insertStart = "+insertStart);
			trace("insertEnd = "+insertEnd);
			trace("insertNumber = "+insertNumber);
			trace("insertIndex = "+insertIndex);
			trace("insertTagArray[2] = "+insertTagArray[2]);
			trace("oldTagArray[insertIndex] = "+oldTagArray[insertIndex]);
			trace("oldTagArray[insertIndex+5] = "+oldTagArray[insertIndex+5]);			
			if(tagNumber%2==0)//even tagNumber
			{
				trace("tagInsertWhileEven");
				insertNumber = tagNumber/2;
				//count position in oldTagArray
				insertIndex = insertStart + (insertNumber-1)*5;
				//check time order
				if(insertTagArray[2]<oldTagArray[insertIndex])
				{
					trace("tagInsertWhileEven<");
					tagNumber = insertNumber;
					insertEnd = insertIndex;
					continue;
				}
				else if(insertTagArray[2]>oldTagArray[insertIndex+5])
				{
					trace("tagInsertWhileEven>");
					tagNumber = tagNumber - insertNumber;
					insertStart = insertIndex + 5;
					continue;
				}
				else if(insertTagArray[2]>=oldTagArray[insertIndex] && insertTagArray[2]<=oldTagArray[insertIndex+5])
				{
					trace("tagInsertWhileEven=");
					//copy
					for(var i:int=0; i<=insertIndex+2; i++)
						newTagArray.push(oldTagArray[i]);
					//insert
					newTagArray.push(insertTagArray[0],insertTagArray[1],insertTagArray[2],insertTagArray[3],insertTagArray[4]);
					//copy
					for(var j:int=insertIndex+3; j<=oldTagArray.length-1; j++)
						newTagArray.push(oldTagArray[j]);		
					break;
				}
			}//end of if(tagNumber%2==0)
			else//odd tagNumber
			{
				trace("tagInsertWhileOdd");
				insertNumber = Math.ceil(tagNumber/2);
				//count position in oldTagArray
				insertIndex = insertStart + (insertNumber-1)*5;
				//check time order
				if(insertTagArray[2]<oldTagArray[insertIndex])
				{
					trace("tagInsertWhileOdd<");
					if(insertStart==insertEnd)
					{
						//copy
						for(var a:int=0; a<=insertIndex-3; a++)
							newTagArray.push(oldTagArray[a]);
						//insert
						newTagArray.push(insertTagArray[0],insertTagArray[1],insertTagArray[2],insertTagArray[3],insertTagArray[4]);
						//copy
						for(var b:int=insertIndex-2; b<=oldTagArray.length-1; b++)
							newTagArray.push(oldTagArray[b]);			
						break;						
					}
					else
					{
						tagNumber = insertNumber;
						insertEnd = insertIndex;				
						continue;
					}
				}
				else if(insertTagArray[2]>oldTagArray[insertIndex])
				{
					trace("tagInsertWhileOdd>");
					if(insertStart==insertEnd)
					{
						//copy
						for(var c:int=0; c<=insertIndex+2; c++)
							newTagArray.push(oldTagArray[c]);
						//insert
						newTagArray.push(insertTagArray[0],insertTagArray[1],insertTagArray[2],insertTagArray[3],insertTagArray[4]);
						//copy
						for(var d:int=insertIndex+3; d<=oldTagArray.length-1; d++)
							newTagArray.push(oldTagArray[d]);
						break;						
					}
					else
					{
						tagNumber = tagNumber - insertNumber + 1;
						insertStart = insertIndex;
						continue;
					}
				}
				else if(insertTagArray[2]==oldTagArray[insertIndex])
				{
					trace("tagInsertWhileOdd=");
					//copy
					for(var m:int=0; m<=insertIndex+2; m++)
						newTagArray.push(oldTagArray[m]);
					//insert
					newTagArray.push(insertTagArray[0],insertTagArray[1],insertTagArray[2],insertTagArray[3],insertTagArray[4]);
					//copy
					for(var n:int=insertIndex+3; n<=oldTagArray.length-1; n++)
						newTagArray.push(oldTagArray[n]);
					break;					
				}				
			}//end of else
		}//end of while(true)
	}//end of else
	return newTagArray;
}
/**********************************/
/******** user interface **********/
/**********************************/
public function lockAllUI():void
{
	btn_returntotimeline.enabled = false;
	btn_good.enabled = false;
	btn_question.enabled = false;
	btn_disagree.enabled = false;
	btn_comment.enabled = false;
	btn_comment.enabled = false;
	txt_Comment.enabled = false;
}
protected function btn_returntotimeline_clickHandler(event:MouseEvent):void
{
	lockAllUI();
	videoPlayer.stop();	
	soAmchart.removeEventListener(SyncEvent.SYNC, soSyncHandlerAmchart);
	soAmchart_.removeEventListener(SyncEvent.SYNC, soSyncHandlerAmchart_);
	soAmchart.close();
	soAmchart_.close();
	ncAmchart.close();
	ncAmchart_.close();
	trace("-------------end--------------");
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
public function myKeyDownHandler(event:KeyboardEvent):void
{
	if(event.charCode == 13) tagComment();
}