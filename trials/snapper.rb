#!/usr/bin/env ruby

# Thanks to the heavy lifting done by others:
# http://pastie.caboo.se/69235
# http://pastie.caboo.se/68511

require 'osx/cocoa'
OSX.require_framework 'WebKit'

class Snapper < OSX::NSObject

  def init
    # This sets up some context that we need for creating windows.
    OSX::NSApplication.sharedApplication
    
    # Create an offscreen window into which we can stick our WebView.
    #@window = OSX::NSWindow.alloc.initWithContentRect_styleMask_backing_defer(
    #  [0, 0, 800, 600], OSX::NSBorderlessWindowMask, OSX::NSBackingStoreBuffered, false
    #)
    rect = [-16000.0, -16000.0, 100, 100]
    @window = OSX::NSWindow.alloc.initWithContentRect_styleMask_backing_defer(rect, OSX::NSBorderlessWindowMask, OSX::NSBackingStoreBuffered, false )



    # Create a WebView and stick it in our offscreen window.
    #@webView = OSX::WebView.alloc.initWithFrame([0, 0, 800, 600])
    @webView = OSX::WebView.alloc.initWithFrame(rect)
    @window.setContentView(@webView)
    
    # Use the screen stylesheet, rather than the print one.
    @webView.setMediaStyle('screen')
    # Make sure we don't save any of the prefs that we change.
    @webView.preferences.setAutosaves(false)
    # Set some useful options.
    @webView.preferences.setShouldPrintBackgrounds(true)
    @webView.preferences.setJavaScriptCanOpenWindowsAutomatically(false)
    @webView.preferences.setAllowsAnimatedImages(false)
    # Make sure we don't get a scroll bar.
    @webView.mainFrame.frameView.setAllowsScrolling(false)
    
    self
  end
  
  def fetch(url)
    # This sets up the webView_*  methods to be called when loading finishes.
    @webView.setFrameLoadDelegate(self)
    # Tell the webView what URL to load.
    @webView.setValue_forKey(url, 'mainFrameURL')
    # Pass control to Cocoa for a bit.
    OSX.CFRunLoopRun
    @succeeded
  end
  
  attr_reader :error
  
  def webView_didFinishLoadForFrame(view, frame)
    @succeeded = true
    
    # Resize the view to fit the page.
    @docView = @webView.mainFrame.frameView.documentView
    @docView.window.orderFront(nil)
    @docView.display
    @docView.window.setContentSize(@docView.bounds.size)
    @docView.setFrame(@docView.bounds)
    sleep(4) 
    # Return control to the fetch method.
    OSX.CFRunLoopStop(OSX.CFRunLoopGetCurrent)
  end
  
  def webView_didFailLoadWithError_forFrame(webview, error, frame)
    @error = error
    @succeeed = false
    # Return control to the fetch method.
    OSX.CFRunLoopStop(OSX.CFRunLoopGetCurrent)
  end
  
  def webView_didFailProvisionalLoadWithError_forFrame(webview, error, frame)
    @error = error
    @succeeed = false
    # Return control to the fetch method.
    OSX.CFRunLoopStop(OSX.CFRunLoopGetCurrent)
  end
  
  def save(filename, options = {})
    @docView.setNeedsDisplay(true)
    @docView.displayIfNeeded
    @docView.lockFocus
    bitmap = OSX::NSBitmapImageRep.alloc.initWithFocusedViewRect(@docView.bounds)
    @docView.unlockFocus

    # Write the bitmap to a file as a PNG
    bitmap.representationUsingType_properties(OSX::NSPNGFileType, nil).writeToFile_atomically(filename, true)
    bitmap.release
  end
  
end

