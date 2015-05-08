package openfl._internal.renderer.canvas;


import openfl._internal.renderer.RenderSession;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

#if js
import js.html.CanvasRenderingContext2D;
import js.Browser;
#end

@:access(openfl.text.TextField)


class CanvasTextField {
	
	
	#if js
	private static var context:CanvasRenderingContext2D;
	#end
	
	
	public static inline function render (textField:TextField, renderSession:RenderSession):Void {
		
		#if js
		
		if (!textField.__renderable || textField.__worldAlpha <= 0) return;
		
		update (textField);
		
		if (textField.__canvas != null) {
			
			var context = renderSession.context;
			
			context.globalAlpha = textField.__worldAlpha;
			var transform = textField.__worldTransform;
			var scrollRect = textField.scrollRect;
			
			if (renderSession.roundPixels) {
				
				context.setTransform (transform.a, transform.b, transform.c, transform.d, Std.int (transform.tx), Std.int (transform.ty));
				
			} else {
				
				context.setTransform (transform.a, transform.b, transform.c, transform.d, transform.tx, transform.ty);
				
			}
			
			if (scrollRect == null) {
				
				context.drawImage (textField.__canvas, 0, 0);
				
			} else {
				
				context.drawImage (textField.__canvas, scrollRect.x, scrollRect.y, scrollRect.width, scrollRect.height, scrollRect.x, scrollRect.y, scrollRect.width, scrollRect.height);
				
			}
			
		}
		
		#end
		
	}
	
	
	private static inline function renderText (textField:TextField, text:String, format:TextFormat, offsetX:Float):Void {
		
		#if js
		
		context.font = textField.__getFont (format);
		context.textBaseline = "top";
		context.fillStyle = "#" + StringTools.hex (format.color, 6);
		
		var isFirefox:Bool = Browser.navigator.userAgent.indexOf("Firefox") != -1;
		var lines = text.split ("\n");
		var yOffset:Float = isFirefox ? 2 : 0;
		var i:Int = 0;
		var line:String;
		
		while(i < lines.length) {
			
			line = lines[i];
			
			if (yOffset + format.size * 1.185 > textField.__canvas.height - 2 && i > 0) {
				
				break;
			}
			
			switch (format.align) {
				
				case TextFormatAlign.CENTER:
					
					context.textAlign = "center";
					context.fillText (line, textField.__width / 2, 2 + yOffset/*, textField.__width - 4*/);
					
				case TextFormatAlign.RIGHT:
					
					context.textAlign = "end";
					context.fillText (line, textField.__width - 2, 2 + yOffset/*, textField.__width - 4*/);
					
				default:
					
					context.textAlign = "start";
					context.fillText (line, 2 + offsetX, 2 + yOffset/*, textField.__width - 4*/);
			}
			
			
			yOffset += format.size * 1.185;
			++i;
			
		}
		
		#end
		
	}
	
	
	public static function update (textField:TextField):Bool {
		
		#if js
		
		if (textField.__dirty) {
			
			var negativeSize:Bool = textField.width <= 0 || textField.height <= 0;
			var noAutoSize:Bool = textField.autoSize == TextFieldAutoSize.NONE;
			
			if((textField.__text == null || textField.__text == "") && !textField.background && !textField.border || negativeSize && noAutoSize /*|| negativeSize && !noAutoSize && textField.wordWrap*/) {
				
				textField.__canvas = null;
				textField.__context = null;
				textField.__dirty = false;
				
			} else {
				
				if (textField.__canvas == null) {
					
					textField.__canvas = cast Browser.document.createElement ("canvas");
					textField.__context = textField.__canvas.getContext ("2d");
					
				}
				
				var canvas = textField.__canvas;
				
				context = textField.__context;
				
				if (textField.__text != null && textField.__text != "") {
									
					var fullAutoSize = !textField.wordWrap && textField.autoSize != TextFieldAutoSize.NONE;
					var measurements = [];
					var textWidth = 0.0;
					var text:String = null;
					
					if (textField.wordWrap)
					{
						textField.__buildWrappedText ();
						text = textField.__wrappedText;
					}
					else
						text = textField.text;
					
					if (textField.displayAsPassword) {
						
						var length = text.length;
						var mask = "";
						
						for (i in 0...length) {
							var char = text.charAt(i);
							if (char != '\n')
								mask += "*";
							else
								mask += '\n';
							
						}
						
						text = mask;
						
					}
					
					if (textField.wordWrap && textField.autoSize != TextFieldAutoSize.NONE)
					{	
						if (textField.__width < 4)
						{
							textField.wordWrap = false;
							textField.__height = textField.textHeight+4;
							textField.wordWrap = true;
						} else 
						{
							textField.__height = textField.textHeight+4;
						}
						
					} else if (fullAutoSize)
					{	
						measurements =  textField.__measureText ();
						
						for (measurement in measurements) 
						{
							textWidth += measurement;
						}
						
						switch(textField.autoSize)
						{
							case TextFieldAutoSize.RIGHT:
									
									textField.x = textField.__x + textField.__width * textField.__scaleX - textWidth - 4;
									
							case TextFieldAutoSize.CENTER:
								
									textField.x = textField.__x + textField.__width * textField.__scaleX / 2 - (textWidth + 4) / 2;
									
							default:	0;
						}
						textField.__width = textWidth + 4;
						textField.__height = textField.textHeight + 4;
					}
					
					canvas.width = Math.ceil (textField.__width);
					canvas.height = Math.ceil (textField.__height);
					
					// first draw background
					var isBg:Bool = textField.border || textField.background;
					
					if (isBg) context.rect (0.5, 0.5, canvas.width - 1, canvas.height - 1);
					
					if (isBg && textField.background) {
						
						context.fillStyle = "#" + StringTools.hex (textField.backgroundColor, 6);
						context.fill ();
						
					}
					
					if (textField.__hasFocus && (textField.__selectionStart == textField.__cursorPosition) && textField.__showCursor) {
						
						var cursorOffset = textField.__getTextWidth (text.substring (0, textField.__cursorPosition));
						context.fillStyle = "#" + StringTools.hex (textField.__textFormat.color, 6);
						context.fillRect (cursorOffset, 5, 1, textField.__textFormat.size - 5);
						
					} else if (textField.__hasFocus && (Math.abs (textField.__selectionStart - textField.__cursorPosition)) > 0 && !textField.__isKeyDown) {
						
						var lowPos = Std.int (Math.min (textField.__selectionStart, textField.__cursorPosition));
						var highPos = Std.int (Math.max (textField.__selectionStart, textField.__cursorPosition));
						var xPos = textField.__getTextWidth (text.substring (0, lowPos));
						var widthPos = textField.__getTextWidth (text.substring (lowPos, highPos));
						
						context.fillStyle = "#" + StringTools.hex (textField.__textFormat.color, 6);
						context.fillRect (xPos, 5, widthPos, textField.__textFormat.size - 5);
						
					}
					
					// then draw text
					if (textField.__ranges == null) {
						
						renderText (textField, text, textField.__textFormat, 0);
					
					} else {
						
						var currentIndex = 0;
						var range;
						var offsetX = 0.0;
						
						if (!fullAutoSize)	measurements =  textField.__measureText ();
						
						for (i in 0...textField.__ranges.length) {
							
							range = textField.__ranges[i];
							
							renderText (textField, text.substring (range.start, range.end), range.format, offsetX);
							offsetX += measurements[i];
							
						}
						
					}
					
					// finaly draw border
					if (isBg && textField.border) {
							
						context.lineWidth = 1;
						context.strokeStyle = "#" + StringTools.hex (textField.borderColor, 6);
						context.stroke ();
						
					}
					
				} 
				else {
					
					if (textField.wordWrap && !noAutoSize) {
						
						textField.__width = 1;
						textField.__height = 4;
						
					} else if (!noAutoSize) {
						
						switch(textField.autoSize)
						{
							case TextFieldAutoSize.RIGHT:
									
									textField.x = textField.__x - 4 * textField.__scaleX;
									
							case TextFieldAutoSize.CENTER:
								
									textField.x = textField.__x - 2 * textField.__scaleX;
									
							default:	0;
						}
						
						textField.__width = 4;
						textField.__height = 4;
					}
					
					canvas.width = Math.ceil (textField.__width);
					canvas.height = Math.ceil (textField.__height);
					
					if (textField.border || textField.background) {
						
						if (textField.border) {
							
							context.rect (0.5, 0.5, canvas.width - 1, canvas.height - 1);
							
						} else {
							
							context.rect (0, 0, canvas.width, canvas.height);
							
						}
						
						if (textField.background) {
							
							context.fillStyle = "#" + StringTools.hex (textField.backgroundColor, 6);
							context.fill ();
							
						}
						
						if (textField.border) {
							
							context.lineWidth = 1;
							context.lineCap = "square";
							context.strokeStyle = "#" + StringTools.hex (textField.borderColor, 6);
							context.stroke ();
							
						}
						
					}
					
				}
				
				textField.__dirty = false;
				return true;
				
			}
			
		}
		
		#end
		
		return false;
		
	}
	
	
}