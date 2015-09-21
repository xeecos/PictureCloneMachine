package cc.makeblock.views
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	public class GCSwitch extends Sprite
	{
		private var _title:String = "";
		private var _onColor:uint;
		private var _offColor:uint;
		private var _borderColor:uint;
		private var _isBorder:Boolean;
		private var _width:uint = 60;
		private var _height:uint = 22;
		private var _textField:TextField = new TextField();
		private var _isOn:Boolean = false;
		public function GCSwitch(title:String = "",onColor:uint = 0xffcc00,offColor:uint = 0x999999,borderColor:uint = 0xffcc00,isBorder:Boolean = false)
		{
			super();
			_title = title;
			_onColor = onColor;
			_offColor = offColor; 
			_borderColor = borderColor;
			_isBorder = isBorder;
			this.addChild(_textField);
			this.mouseChildren = false;
			this.buttonMode = true;
			this.addEventListener(MouseEvent.MOUSE_OVER,onRollOver);
			this.addEventListener(MouseEvent.MOUSE_OUT,onRollOut);
			this.addEventListener(MouseEvent.CLICK,onMouseClick);
			this.addEventListener(Event.ADDED_TO_STAGE,init);
			onRollOut(null);
		}
		private function onMouseClick(evt:MouseEvent):void{
			this.on = !_isOn;
		}
		public function get on():Boolean{
			return _isOn;
		}
		public function set on(v:Boolean):void{
			_isOn = v;
			onRollOut();
			this.dispatchEvent(new Event(Event.CHANGE));
		}
		private function init(evt:Event):void{
			var tf:TextFormat = new TextFormat;
			tf.font = "Arial";
			tf.size = 14;
			tf.align = TextFormatAlign.CENTER;
			_textField.width = _width;
			_textField.height = _height;
			_textField.y = (_height - _textField.height)/2;
			_textField.defaultTextFormat = tf;
			_textField.text = _title;
			_textField.selectable = false;
		}
		public function setTitle(title:String):void{
			_title = title;
			_textField.text = _title;
		}
		public function get title():String{
			return _title;
		}
		public function setHeight(height:uint):void{
			_height = height;
			_textField.y = (_height - _textField.height)/2;
			onRollOut();
		}
		public function setWidth(width:uint):void{
			_width = width;
			_textField.width = _width;
			_textField.x = (_width - _textField.width)/2;
			onRollOut();
		}
		private function onRollOver(evt:MouseEvent):void{
			this.graphics.clear();
			if(_isBorder){
				this.graphics.lineStyle(1,_borderColor,1);
			}
			this.graphics.beginFill(_offColor,1);
			this.graphics.drawRect(0,0,_width,_height);
			this.graphics.endFill();
			this.graphics.beginFill(_onColor,1);
			this.graphics.drawRect(_isOn?0:_width/2,0,_width/2,_height);
			this.graphics.endFill();
		}
		private function onRollOut(evt:MouseEvent=null):void{
			this.graphics.clear();
			if(_isBorder){
				this.graphics.lineStyle(1,_borderColor,1);
			}
			this.graphics.beginFill(_offColor,1);
			this.graphics.drawRect(0,0,_width,_height);
			this.graphics.endFill();
			this.graphics.beginFill(_onColor,1);
			this.graphics.drawRect(_isOn?0:_width/2,0,_width/2,_height);
			this.graphics.endFill();
		}
	}
}

