package
{
	import flash.desktop.NativeApplication;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.filters.BitmapFilter;
	import flash.filters.ColorMatrixFilter;
	import flash.filters.ConvolutionFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.net.SharedObject;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import cc.makeblock.geom.ColorMatrix;
	import cc.makeblock.geom.Grid;
	import cc.makeblock.utils.FileLoader;
	import cc.makeblock.views.GCButton;
	import cc.makeblock.views.GCSwitch;
	
	import fl.controls.ComboBox;
	import fl.data.DataProvider;
	
	public class PictureCloneMachine extends Sprite
	{
		private var _bmp:Bitmap = new Bitmap();
		private var _btLoad:GCButton = new GCButton("Preview");
		private var _btPrint:GCButton = new GCButton("Make It");
		private var _btConnect:GCButton = new GCButton("Connect");
		private var _btStop:GCButton = new GCButton("Stop");
		private var _fileLoader:FileLoader = new FileLoader();
		public static var app:PictureCloneMachine;
		public var shapes:Array = [];
		private var fileStream:FileStream = new FileStream();
		private var fileGCode:File = File.desktopDirectory.resolvePath("app.gcode");
		private var runningSpeed:uint = 4000;
		private var workingSpeed:uint = 4000;
		private var workingPower:uint = 127;
		private var vid:Video = new Video(640,480);
		private var bmpHEdge:uint = 100;
		private var bmpVEdge:uint = 80;
		private var cam:Camera;
		private var _sprite:Sprite = new Sprite;
		private var _btClose:Sprite = new Sprite;
		private var _combobox:ComboBox = new ComboBox();
		private var _isDebug:Boolean = false;
		private var _serial:AIRSerial = new AIRSerial;
		private var _window:Shape = new Shape();
		private var _cbxCamera:ComboBox = new ComboBox();
		private var _swLED:GCSwitch = new GCSwitch("");
		private var _so:SharedObject;
		public function PictureCloneMachine()
		{
			app = this;
			stage.align = "TL";
			stage.scaleMode = "noScale";
			if(!_isDebug){
				setTimeout(function():void{
					stage.displayState = StageDisplayState.FULL_SCREEN;
				},1000);
				vid.scaleY = -1;
				vid.scaleX = -1;
				
				_bmp.alpha = 0.5;
				_bmp.bitmapData = new BitmapData(640-bmpHEdge*2,480-bmpVEdge*2);
			}
			addChild(_btLoad);
			addChild(_btPrint);
			addChild(_btConnect);
			addChild(_btStop);
			_btStop.setWidth(60);
			addChild(vid);
			addChild(_bmp);
			addChild(_sprite);
			addChild(_combobox);
			addChild(_window);
			addChild(_btClose);
			addChild(_swLED);
			with(_window.graphics){
				lineStyle(5,0xffcc00,1);
				beginFill(0,0);
				drawRect(0,0,640-bmpHEdge*2,480-bmpVEdge*2);
				endFill();
			}
//			trace(Camera.names);
			
			stage.addEventListener(Event.RESIZE,onResized);
			_fileLoader.addEventListener(Event.COMPLETE,onBitmapLoaded);
			_btConnect.addEventListener(MouseEvent.CLICK,onClickConnect);
			_btConnect.setHeight(20);
			_btLoad.addEventListener(MouseEvent.CLICK,onClickLoad);
			_btPrint.addEventListener(MouseEvent.CLICK,onClickPrint);
			_btStop.addEventListener(MouseEvent.CLICK,onClickStop);
			_combobox.setSize(200,20);
			setTimeout(updateSerialPort,1000);
			_serial.addEventListener(Event.CHANGE,onReceived);
			NativeApplication.nativeApplication.addEventListener(Event.EXITING,onClose);
			var dp:DataProvider = new DataProvider;
			if(Camera.isSupported){
				for(var i:uint=0;i<Camera.names.length;i++){
					dp.addItem({label:Camera.names[i],data:i});
				}
				_cbxCamera.dataProvider = dp;
				_cbxCamera.addEventListener(Event.CHANGE,onCameraChanged);
				_so = SharedObject.getLocal("makeblock_cam","/");
				if(Camera.names.length==1){
					_cbxCamera.selectedIndex = 0;
					_cbxCamera.dispatchEvent(new Event(Event.CHANGE));
				}else{
					if(_so.data.cam){
						_cbxCamera.selectedIndex = _so.data.cam;
						_cbxCamera.dispatchEvent(new Event(Event.CHANGE));
						trace(_cbxCamera.selectedIndex);
					}
				}
			}
			addChild(_cbxCamera);
			_btClose.buttonMode = true;
			with(_btClose.graphics){
				beginFill(0,0);
				drawRect(0,0,70,70);
				endFill();
				lineStyle(1,0xffcc00,1);
				moveTo(0,0);
				lineTo(70,70);
				moveTo(70,0);
				lineTo(0,70);
			}
			_btClose.addEventListener(MouseEvent.CLICK,onCloseHandle);
			_swLED.addEventListener(Event.CHANGE,onLEDChanged);
		}
		private function onLEDChanged(evt:Event):void{
			if(_serial.isConnected){
				if(_swLED.on){
					_serial.writeString("M6 P150\n");
				}else{
					_serial.writeString("M6 P0\n");
				}
			}
		}
		private function onCameraChanged(evt:Event):void{
			vid.attachCamera(null);
			cam = Camera.getCamera(_cbxCamera.selectedIndex.toString());
			cam.setMode(640,480,30);
			vid.attachCamera(cam);
			_so.data.cam = _cbxCamera.selectedIndex;
			_so.flush(100);
		}
		private function onClose(evt:Event):void{
			_serial.dispose();
		}
		private function updateSerialPort():void{
			var list:Array = _serial.list().split(",");
			var dp:DataProvider = new DataProvider;
			for each(var s:String in list){
				if(s.length>3&&s.indexOf("Bluetooth")==-1){
					dp.addItem({label:s,data:s});
				}
			}
			_combobox.dataProvider = dp;
			if(_so.data.com){
				_combobox.selectedIndex = _so.data.com;
			}
		}
		private function onCloseHandle(evt:MouseEvent):void{
			NativeApplication.nativeApplication.exit();
		}
		private function onReceived(evt:Event):void{
			var len:uint = _serial.getAvailable();
			if(len>0){
				var bytes:ByteArray = _serial.readBytes();
				bytes.position = 0;
				var str:String = bytes.readUTFBytes(len).toLowerCase();
				if(str.indexOf("ok")>-1&&_btPrint.title.indexOf("Make")==-1){
					sendPrintCode();
				}
			}
		}
		private function onClickStop(evt:MouseEvent):void{
			if(_serial.isConnected){
				_prints = [];
				_btPrint.setTitle("Make It");
				_serial.writeString("M3 P0\n");
				_serial.writeString("G28\n");
				_serial.writeString("M3 P0\n");
				var s:Shape;
				for each(s in PictureCloneMachine.app.shapes){
					s.graphics.clear();
					_sprite.removeChild(s);
				}
			}
		}
		private function onClickLoad(evt: MouseEvent): void {
			if(_isDebug){
				_fileLoader.browse();
			}else{
				if(_serial.isConnected){
					_serial.writeString("G28\n");
					_serial.writeString("M3 P6\n");
				}
				var matrix:Matrix = new Matrix(1,0,0,1,0,0);
				matrix.scale(-1,-1);
				matrix.translate(640-bmpHEdge,480-bmpVEdge);
				_bmp.bitmapData.draw(vid,matrix);
				var colorMatrix:ColorMatrix = new ColorMatrix;
				colorMatrix.SetBrightnessMatrix(200);
				colorMatrix.SetContrastMatrix(255);
				var bmd:BitmapData = _bmp.bitmapData;
				var colorFilter:ColorMatrixFilter=new ColorMatrixFilter(colorMatrix.GetFlatArray());
				bmd.applyFilter(bmd, bmd.rect, new Point(), colorFilter);
				var tempArray:Array = [];
				for ( var i:int = 0; i < bmd.width; i++)
				{
					for (var j:int = 0; j < bmd.height; j++)
					{
						if(gray(bmd.getPixel(i,j))>240){
							
							bmd.setPixel(i,j, 0xffffff );
						}else{
							bmd.setPixel(i,j,0);
							tempArray.push(new Point(i,j));
						}
					}
				}
				findEdge(bmd);
				var p:Point;
				prePoints = [];
				for each(p in tempArray ){
					prePoints.push(p);
					//bmd.setPixel(p.x,p.y, 0x0000ff );
				}
				costTime = getTimer();
				ridgePixels = [];
				pixelIndex = 0;
				_bmp.bitmapData = bmd;
				setTimeout(processing,interval,bmd);
			}
		}
		private var _startTime:Number = 0;
		private function onClickPrint(evt:MouseEvent):void{
			if(_btPrint.title.indexOf("Printing")>-1){
				
			}else{
				if(_serial.isConnected){
					_startTime = getTimer();
					sendPrintCode();
				}
			}
		}
		private var _printIndex:uint = 0;
		private function sendPrintCode():void{
			if(_printIndex>=_prints.length){
				trace("finish");
				_btPrint.setTitle("Make It");
				_printIndex = 0;
			}else{
				var per:uint = Math.floor(_printIndex/_prints.length*100);
				_btPrint.setTitle("Printing "+per+"% - "+Math.floor((getTimer()-_startTime)/1000)+"s");
				_serial.writeString(_prints[_printIndex]+"\n");
				_printIndex++;
			}
		}
		private function onClickConnect(evt:MouseEvent):void{
			if(_btConnect.title == "Connect"){
				if(_combobox.dataProvider.length==0){
					return;
				}
				var result:uint = _serial.open(_combobox.getItemAt(_combobox.selectedIndex).label);
				if(result==0){
					_btConnect.setTitle("Disconnect");
					_so.data.com = _combobox.selectedIndex;
					_so.flush(100);
				}
			}else{
				_serial.close();
				_btConnect.setTitle("Connect");
			}
		}
		private function onResized(evt:Event):void{
			if(!_isDebug&&stage.displayState==StageDisplayState.NORMAL){
				setTimeout(function():void{
					stage.displayState = StageDisplayState.FULL_SCREEN;
				},4000);
			}
			var sh:uint = stage.stageHeight;
			var sw:uint = stage.stageWidth;
			this.graphics.clear();
			this.graphics.beginFill(0x000000,1);
			this.graphics.drawRect(0,0,sw,sh);
			this.graphics.endFill();
			vid.x = sw/2-320;
			_sprite.x = sw/2-100;
			_sprite.y = sh/2+240;
			_bmp.y = vid.y = sh/2-240;
			_window.x = _bmp.x = vid.x + bmpHEdge;
			_window.y = _bmp.y = vid.y + bmpVEdge;
			vid.y += vid.height;
			vid.x += vid.width;
			_btLoad.x = sw/2-320;
			_btPrint.y = _btLoad.y = sh/2+240+20;
			_btPrint.x = sw/2+320-_btPrint.width;
			_combobox.x = sw/2-320;
			_btConnect.x = _combobox.x+_combobox.width+10;
			_combobox.y = sh/2-240-30;
			_btConnect.y = _combobox.y;
			_btStop.x = _btPrint.x - 10 -_btStop.width;
			_btStop.y = _btPrint.y;
			_cbxCamera.y = _combobox.y;
			_cbxCamera.x = sw/2+320-_cbxCamera.width;
			_btClose.x = sw - 80;
			_btClose.y = 10;
			_swLED.x = _cbxCamera.x - _swLED.width - 10;
			_swLED.y = _cbxCamera.y;
		}
		private function gray(c:uint):uint{
			return ((c>>16)&0xff)*0.3+((c>>8)&0xff)*0.6+(c&0xff)*0.1;
		}
		private var prePoints:Array = [];
		private var edgePoints:Array = [];
		private function onBitmapLoaded(evt:Event):void{
			
			var colorMatrix:ColorMatrix = new ColorMatrix;
			colorMatrix.SetBrightnessMatrix(255);
			colorMatrix.SetContrastMatrix(255);
			var bmd:BitmapData = _fileLoader.bitmapData;
			var colorFilter:ColorMatrixFilter=new ColorMatrixFilter(colorMatrix.GetFlatArray());
			bmd.applyFilter(bmd, bmd.rect, new Point(), colorFilter);
			var tempArray:Array = [];
			for ( var i:int = 0; i < bmd.width; i++)
			{
				for (var j:int = 0; j < bmd.height; j++)
				{
					if(gray(bmd.getPixel(i,j))>200){
						
						bmd.setPixel(i,j, 0xffffff );
					}else{
						bmd.setPixel(i,j,0);
						tempArray.push(new Point(i,j));
					}
				}
			}
			findEdge(bmd);
			var p:Point;
			for ( i = 0; i < bmd.width; i++)
			{
				for ( j = 0; j < bmd.height; j++)
				{
					if(gray(bmd.getPixel(i,j))>100){
						bmd.setPixel(i,j, 0xffffff);
						for each(p in tempArray ){
							if(p.x==i&&p.y==j){
								delete tempArray[tempArray.indexOf(p)];
								//break;
							}
						}
					}else{
						bmd.setPixel(i,j,0);
					}
				}
			}
			prePoints = [];
			for each(p in tempArray ){
				prePoints.push(p);
				//bmd.setPixel(p.x,p.y, 0x0000ff );
			}
			costTime = getTimer();
			ridgePixels = [];
			pixelIndex = 0;
			_bmp.bitmapData = bmd;
			setTimeout(processing,interval,bmd);
			
		}
		private var costTime:uint = 0;
		private var pixelIndex:uint = 0;
		private var interval:uint = 10;
		private var pixelCount:uint = 400;
		private var ridgePixels:Array = [];
		private function processing(bmd:BitmapData):void{
			trace(pixelIndex/prePoints.length,(getTimer()-costTime)/1000);
			var prePoint:Point;
			var sortPoints:Array = [];
			var len:uint = Math.min(pixelIndex+pixelCount,prePoints.length);
			var dir:uint = 5;
			for(var i:uint = pixelIndex;i<len;i++){
				prePoint = prePoints[i];
				sortPoints = [];
				edgePoints = [];
				for (var ii:int = prePoint.x-dir; ii < prePoint.x+dir; ii++)
				{
					for ( var jj:int = prePoint.y-dir; jj <prePoint.y+dir; jj++)
					{
						if(gray(bmd.getPixel(ii,jj))>100){
							//bmd.setPixel(ii,jj, 0x0000ff );
							edgePoints.push(new Point(ii,jj));
						}else{
//							bmd.setPixel(ii,jj,0);
						}
					}
				}
				for(var j:uint=0;j<edgePoints.length;j++){
					var dist:Number = Point.distance(prePoint,edgePoints[j]);
//					if(dist>0&&dist<6){
						sortPoints.push({index:j,dist:dist});
//					}
				}
				var n:uint = 7;
				if(sortPoints.length<n){
					continue;
				}
				sortPoints.sortOn("dist",Array.NUMERIC);
//				var c:Number = Point.distance(edgePoints[sortPoints[0].index],edgePoints[sortPoints[1].index]);
//				var a:Number = sortPoints[0].dist;
//				var b:Number = sortPoints[1].dist;
				var r:Number = 0;
				for(var k:uint=0;k<n;k++){
					r+=sortPoints[k].dist;
				}
				r=r/n;
				var rr:Number = 0;
				for(k=0;k<n;k++){
					rr+=(sortPoints[k].dist-r)*(sortPoints[k].dist-r)/n;
				}
				
				//if(b!=0&&a!=0){
//					trace(a,Math.acos((a*a+b*b-c*c)/(2*a*b))*180/Math.PI);
//				var angle:Number = Math.acos((a*a+b*b-c*c)/(2*a*b))*180/Math.PI;
					if(rr<0.25){//(Math.abs(a-b)<1)&&(angle>90)){
						//if(prePoint.x%2==0||prePoint.y%2==0){
							bmd.setPixel(prePoint.x/4,prePoint.y/4,0xff0000);
							ridgePixels.push(prePoint);
						//}
					}
//				}
			}
			
			if(pixelIndex>=prePoints.length){
				bmd.fillRect(bmd.rect,0);
				
				var s:Shape;
				for each(s in shapes){
					s.graphics.clear();
					_sprite.removeChild(s);
				}
				shapes = [];
				_prints = [];
				_prints.push("G28");
				
				var w:Number = bmd.width;
				var div:Number = 2.0;
				var gcodeScale:Number = 2.4;
				var xPos:Number = 0;
				var yPos:Number = 0;
				i = findNearestZeroPoint();;
				len = ridgePixels.length;
				while(len>0){
					if(ridgePixels[i]==undefined){
						i = findNearestZeroPoint();
						//continue;
					}
					if(ridgePixels[i]==undefined){
						removeTool();
						continue;
					}
					var p:Point = new Point(ridgePixels[i].x,ridgePixels[i].y);
					delete ridgePixels[i];
					len--;
//					trace(i);
					i = findNearestPoint(p);
					var np:Point = ridgePixels[i];
					if(np){
						if(Point.distance(p,np)<5){
							s = new Shape();
							with(s.graphics){
								lineStyle(1,0x0000ff,1);
								moveTo(p.x/div,p.y/div);
								_prints.push("G01 X"+floorValue((w-p.x-xPos)/div/gcodeScale)+" Y"+floorValue((p.y-yPos)/div/gcodeScale)+" A"+runningSpeed);
								addTool(workingPower);
								lineTo(np.x/div,np.y/div);
//								_prints.push("G01 X"+floorValue((w-np.x-xPos)/div/gcodeScale)+" Y"+floorValue((np.y-yPos)/div/gcodeScale)+" A"+workingSpeed);
								
							}
							shapes.push(s);
							_sprite.addChild(s);
						}else{
							removeTool();
						}
					}else{
						removeTool();
					}
				}
				removeTool();
				_prints.push("G28");
				trace("lines:",ridgePixels.length,shapes.length);
				for (i = 0; i < bmd.width; i++)
				{
					for ( j = 0; j <bmd.height; j++)
					{
						if(gray(bmd.getPixel(i,j))>100){
							bmd.setPixel(i,j, 0x006600 );
						}
						//bmd.setPixel(i,j,0);
					}
				}
				_bmp.bitmapData = bmd;
			}else{
				setTimeout(processing,interval,bmd);
			}
			
			pixelIndex+=pixelCount;
		}
		private function findNearestZeroPoint():uint{
			var dist:Number = 5000;
			var nextPoint:Point;
			var index:uint = 0;
			var p:Point = new Point(0,0);
			for(var i:uint=0;i<ridgePixels.length;i++){
				var np:Point = ridgePixels[i];
				if(np){
					var d:Number = Point.distance(np,p);
					if(dist>d&&d>0.5){
						dist = d;
						index = i;
					}
				}
			}
			return index;
		}
		private function findNearestPoint(p:Point):uint{
			var dist:Number = 36;
			var nextPoint:Point;
			var index:uint = 0;
			for(var i:* in ridgePixels){
				var np:Point = ridgePixels[i];
				if(np){
					var d:Number = Point.distance(np,p);
					if(dist>d&&d>0.5){
						dist = d;
						index = i;
					}
				}
			}
			return index;
		}
		private function findEdge(bmd:BitmapData):void{
			var matrixX:Number = 3;  
			var matrixY:Number = 3;  
			var matrix:Array = [0,1,0,1,-4,1,0,1,0];
			var divisor:Number = 1;
			var bias:Number = 0;
			var filter:BitmapFilter = new ConvolutionFilter(matrixX, matrixY, matrix, divisor,bias);  
			bmd.applyFilter(bmd,bmd.rect,new Point(0,0),filter);  
		}
		private var points:Array = [];
		private var _prints:Array = [];
		private function addTool(power:uint):void{
			_prints.push("M3 P"+power);
			_prints.push("M3 P"+power);
//			fileStream.writeUTFBytes("M3 P"+power+"\n");
//			fileStream.writeUTFBytes("M3 P"+power+"\n");
		}
		private function removeTool():void{
			_prints.push("M3 P0");
			_prints.push("M3 P0");
//			fileStream.writeUTFBytes("M3 P0\n");
//			fileStream.writeUTFBytes("M3 P0\n");
		}
		
		private function floorValue(v:Number):String{
			var s:String = "";
			s+=Math.ceil(v*100)/100
			return s;
		}
	}
}
