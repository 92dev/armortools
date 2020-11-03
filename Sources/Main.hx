package;

import kha.Window;
import kha.WindowOptions;
import kha.WindowMode;
import kha.System;
import iron.object.Object;
import iron.Scene;
import iron.RenderPath;
import arm.render.Inc;
import arm.render.RenderPathForward;
import arm.render.RenderPathDeferred;
import arm.render.Uniforms;
import arm.util.BuildMacros;
import arm.Config;
import arm.Context;
#if arm_vr
import arm.render.RenderPathForwardVR;
#end

class Main {

	public static var version = "0.8";
	public static var sha = BuildMacros.sha().substr(1, 7);
	public static var date = BuildMacros.date().split(" ")[0];

	static var tasks: Int;

	// Generating snapshot
	public static function main() {
		js.Syntax.code("globalThis.kickstart = Main.kickstart");
	}

	// Program startup
	@:keep
	public static function kickstart() {
		// Used to locate external application data folder
		Krom.setApplicationName("ArmorPaint");

		tasks = 1;
		tasks++; Config.load(function() { tasks--; start(); });
		#if arm_physics
		tasks++; arm.plugin.PhysicsWorld.load();
		#end
		tasks--; start();
	}

	static function start() {
		if (tasks > 0) return;

		Config.init();
		var c = Config.raw;

		var windowMode = c.window_mode == 0 ? WindowMode.Windowed : WindowMode.Fullscreen;
		var windowFeatures = None;
		if (c.window_resizable) windowFeatures |= FeatureResizable;
		if (c.window_maximizable) windowFeatures |= FeatureMaximizable;
		if (c.window_minimizable) windowFeatures |= FeatureMinimizable;
		var title = "untitled - ArmorPaint";
		var options: kha.SystemOptions = {
			title: title,
			window: {
				width: c.window_w,
				height: c.window_h,
				x: c.window_x,
				y: c.window_y,
				mode: windowMode,
				windowFeatures: windowFeatures
			},
			framebuffer: {
				samplesPerPixel: 1,
				verticalSync: c.window_vsync,
				frequency: c.window_frequency
			}
		};

		System.start(options, function(window: Window) {
			if (Config.raw.layout == null) Config.initLayout();
			Krom.setApplicationName("ArmorPaint");
			iron.App.init(function() {
				Scene.setActive("Scene", function(o: Object) {
					Uniforms.init();
					var path = new RenderPath();
					Inc.init(path);

					#if arm_vr
					RenderPathDeferred.init(path); // Allocate gbuffer
					RenderPathForward.init(path);
					RenderPathForwardVR.init(path);
					path.commands = RenderPathForwardVR.commands;
					#else
					if (Context.renderMode == RenderForward) {
						RenderPathDeferred.init(path); // Allocate gbuffer
						RenderPathForward.init(path);
						path.commands = RenderPathForward.commands;
					}
					else {
						RenderPathDeferred.init(path);
						path.commands = RenderPathDeferred.commands;
					}
					#end

					RenderPath.setActive(path);
					new arm.App();
					#if arm_physics
					o.addTrait(new arm.plugin.PhysicsWorld());
					#end
				});
			});
		});
	}
}
