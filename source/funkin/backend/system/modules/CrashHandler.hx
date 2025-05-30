package funkin.backend.system.modules;

import lime.system.System;
import funkin.backend.utils.NativeAPI;
import openfl.Lib;
import openfl.events.UncaughtErrorEvent;
import openfl.events.ErrorEvent;
import openfl.errors.Error;
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class CrashHandler {
	public static function init() {
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);
		#if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(onError);
		#elseif hl
		hl.Api.setErrorHandler(onError);
		#end
	}

	public static function onUncaughtError(e:UncaughtErrorEvent) {
		e.preventDefault();
		e.stopPropagation();
		e.stopImmediatePropagation();

		var m:String = e.error;
		if (Std.isOfType(e.error, Error)) {
			var err = cast(e.error, Error);
			m = '${err.message}';
		} else if (Std.isOfType(e.error, ErrorEvent)) {
			var err = cast(e.error, ErrorEvent);
			m = '${err.text}';
		}
		var stack = CallStack.exceptionStack();
		var stackLabel:String = "";
		for(e in stack) {
			switch(e) {
				case CFunction: stackLabel += "Non-Haxe (C) Function";
				case Module(c): stackLabel += 'Module ${c}';
				case FilePos(parent, file, line, col):
					switch(parent) {
						case Method(cla, func):
							stackLabel += '(${file}) ${cla.split(".").last()}.$func() - line $line';
						case _:
							stackLabel += '(${file}) - line $line';
					}
				case LocalFunction(v):
					stackLabel += 'Local Function ${v}';
				case Method(cl, m):
					stackLabel += '${cl} - ${m}';
			}
			stackLabel += "\r\n";
		}

		NativeAPI.showMessageBox("Codename Engine Crash Handler", 'Uncaught Error:$m\n\n$stackLabel', MSG_ERROR);
		#if sys
		saveErrorMessage('$m\n\n$stackLabel');
		Sys.exit(1);
		#end
	}

	#if (cpp || hl)
	private static function onError(message:Dynamic):Void
	{
		throw Std.string(message);
	}
	#end

	#if sys
	private static function saveErrorMessage(message:String):Void 
	{
		try {
			if (!FileSystem.exists(Sys.getCwd() + 'crash'))
				FileSystem.createDirectory(Sys.getCwd() + 'crash');

			File.saveContent(Sys.getCwd() + 'crash/'
				+ Date.now().toString().replace(' ', '-').replace(':', "'")
				+ '.log', message);
		}
	}
	#end
}