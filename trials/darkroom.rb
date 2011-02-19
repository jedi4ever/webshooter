#!/usr/bin/env ruby
#
# DarkRoom
# Takes fullsize screenshots of a web page.
# Copyright (c) 2007 Justin Palmer.
#
# Released under an MIT LICENSE
#
# Usage
# ====
# ruby ./darkroom.rb http://activereload.net
# ruby ./darkroom.rb --output=google.png http://google.com
#
require 'optparse'
require 'osx/cocoa'
OSX.require_framework 'Webkit'

module ActiveReload
  module DarkRoom
    USER_AGENT = "DarkRoom/0.1"

    class Camera
      def self.shoot(options)
        app = OSX::NSApplication.sharedApplication
        delegate = Processor.alloc.init
        delegate.options = options
        app.setDelegate(delegate)        
        app.run
      end
    end

    class Processor < OSX::NSObject
      include OSX
      attr_accessor :options, :web_view
  
      def initialize
        rect = [-16000.0, -16000.0, 100, 100]
        win = NSWindow.alloc.initWithContentRect_styleMask_backing_defer(rect, NSBorderlessWindowMask, 2, 0)
    
        @web_view = WebView.alloc.initWithFrame(rect)
        @web_view.mainFrame.frameView.setAllowsScrolling(false)
        @web_view.setApplicationNameForUserAgent(USER_AGENT)
    
        NSNotificationCenter.defaultCenter.objc_send(:addObserver, self,
          :selector, :webview_progress_finished, 
          :name, WebViewProgressFinishedNotification,
          :object, @web_view)

        win.setContentView(@web_view) 
      end
      
      def webview_progress_finished(sender)
        viewport = web_view.mainFrame.frameView.documentView
        viewport.window.orderFront(nil)
        viewport.window.display
        viewport.window.setContentSize([@options[:width], (@options[:height] > 0 ? @options[:height] : viewport.bounds.height)])
        viewport.setFrame(viewport.bounds)
        sleep(@options[:delay]) if @options[:delay]
        capture_and_save(viewport)
      end
      
      def applicationDidFinishLaunching(notification)
        @options[:output] ||= "#{Time.now.strftime('%m-%d-%y-%H%I%S')}.png"
        @web_view.window.setContentSize([@options[:width], @options[:height]])
        @web_view.setFrameSize([@options[:width], @options[:height]])
        @web_view.mainFrame.loadRequest(NSURLRequest.requestWithURL(NSURL.URLWithString(@options[:website])))
      end
  
      def capture_and_save(view)
        print "we never get here"
        view.lockFocus
          bitmap = NSBitmapImageRep.alloc.initWithFocusedViewRect(view.bounds)
        view.unlockFocus
    
        bitmap.representationUsingType_properties(NSPNGFileType, nil).writeToFile_atomically(@options[:output], true)
        #NSApplication.sharedApplication.terminate(nil)
      end
    end
  end
end
#ActiveReload::DarkRoom::Photographer.new
