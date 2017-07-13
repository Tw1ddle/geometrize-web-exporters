package;

import haxe.Http;
import js.Browser;
import src.reader.ShapeJsonReader;
import src.shape.Shape;
import js.html.Element;

#if backend_canvas
import src.renderer.CanvasRenderer;
#elseif backend_threejs
import src.renderer.ThreeJsRenderer;
#end

/**
 * Encapsulates geometrized images (shapes) and a renderer that draws the data
 */
class GeometrizeWidget
{
	public static inline var GEOMETRIZE_WIDGET_TYPE_NAME:String = "geometrize_widget"; // Used for finding widgets on HTML pages or UI layouts
	
	private var shapes:Array<Shape> = [];
	
	// The renderer that draws the shapes
	#if backend_canvas
	private var renderer:CanvasRenderer;
	#elseif backend_threejs
	private var renderer:ThreeJsRenderer;
	#else
	#error "No renderer defined"
	#end
	
	/**
	 * Creates a new widget
	 * @param	shapes The shapes that will be rendered within the widget
	 * @param	attachmentPointId A unique id for the object to which the widget shall be attached
	 */
	public inline function new(shapes:Array<Shape>, attachmentPointId:String) {
		this.shapes = shapes;
		
		#if backend_canvas
		renderer = new CanvasRenderer(attachmentPointId);
		#elseif backend_threejs
		renderer = new ThreeJsRenderer(attachmentPointId);
		#end
	}
	
	public inline function render(dt:Float) {
		renderer.render(shapes);
	}
}

// TODO build macro?
class EmbeddedShapeData
{
}

/**
 * Code for drawing Geometrized images using different rendering backends
 * @author Sam Twidale (http://samcodes.co.uk/)
 */
class Main
{
	private static inline var WEBSITE_URL:String = "http://geometrize.co.uk/"; // Geometrize website URL
	private static inline var SHAPE_DATA_SOURCE_TAG:String = "data-source";
	
	private var widgets:Array<GeometrizeWidget> = [];
	
	private static function main():Void {
		var main = new Main();
	}
	
	private inline function new() {
		createWidgets(Browser.document.documentElement);
		
		Browser.window.onload = onWindowLoaded;
	}
	
	private inline function onWindowLoaded():Void {
		animate();
	}
	
	/**
	 * Main update loop.
	 */
	private function animate():Void {
		var nextFrameDelay = Std.int((1.0 / 30.0) * 1000.0); // Per-frame delay to avoid burning CPU
		
		update(50);
		
		Browser.window.setTimeout(function():Void {
			this.animate();
		}, nextFrameDelay);
	}
	
	/**
	 * Main update function
	 * @param	dt Delta time since last update
	 */
	private inline function update(dt:Float):Void {
		for (widget in widgets) {
			widget.render(dt);
		}
	}
	
	/**
	 * Creates all of the Geometrize shape widgets below the given element on the page
	 */
	private inline function createWidgets(root:Element):Void {
		var elements = root.getElementsByClassName(GeometrizeWidget.GEOMETRIZE_WIDGET_TYPE_NAME);
		
		for (element in elements) {
			var dataSourceElement = element.attributes.getNamedItem(SHAPE_DATA_SOURCE_TAG);
			if (dataSourceElement == null) {
				continue;
			}
			
			var dataSource:String = dataSourceElement.value;
			
			if (dataSource.length == 0) {
				continue;
			}
			
			loadShapeData(dataSource, element.id);
		}
	}
	
	/**
	 * Attempts to load JSON shape data from the source and create a widget from that data
	 * @param	url The URL to request shape data from
	 */
	private inline function loadShapeData(source:String, attachmentPointId:String):Void {
		// If the data is embedded already
		if (source.charAt(0) == ":") {
			var sourceId:String = source.substr(1);
			if (Reflect.hasField(EmbeddedShapeData, sourceId)) {
				var data = Reflect.field(EmbeddedShapeData, sourceId);
				var shapes:Array<Shape> = ShapeJsonReader.shapesFromJson(data);
				widgets.push(new GeometrizeWidget(shapes, attachmentPointId));
			}
			return;
		}
		
		// Data is a local file or web resource, request it
		requestData(source,
		function(data:String) {
			var shapes:Array<Shape> = ShapeJsonReader.shapesFromJson(data);
			widgets.push(new GeometrizeWidget(shapes, attachmentPointId));
		},
		function(error:String) {
			trace(error);
		});
	}
	
	/**
	 * Loads data pointed to at the given URL
	 * @param	url The URL of the data to load
	 * @param	onData Callback triggered if the data is received
	 * @param	onError Callback triggered if the data is not received due to an error
	 */
	private static inline function requestData(url:String, onData:String->Void, onError:String->Void):Void {
		var http = new haxe.Http(url);
		http.onData = onData;
		http.onError = onError;
		http.request();
	}
}