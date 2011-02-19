# crafterm@redartisan.com, with major help from vastheman :)

require 'osx/cocoa'
require 'logger'

OSX.require_framework 'WebKit'

class Shooter

  def initialize
    @logger = Logger.new(STDOUT)
    
    @pool = OSX::NSAutoreleasePool.alloc.init

    # get NSApplication code ready for action
    OSX.NSApplicationLoad

    #	Make an offscreen window
    # The frame is in screen coordinates, but it's irrelevant since we'll never display it
    # We want a buffered backing store, simply so we can read it later
    #	We don't want to defer, or it won't draw until it gets on the screen
    @window = OSX::NSWindow.alloc.initWithContentRect_styleMask_backing_defer(
                OSX::NSRect.new(0, 0, 1024, 768), OSX::NSBorderlessWindowMask, OSX::NSBackingStoreBuffered, false
             )

    # Make a web @view - the frame here is in window coordinates
    @view = OSX::WebView.alloc.initWithFrame(OSX::NSRect.new(0, 0, 1024, 768))
    @view.mainFrame.frameView.setAllowsScrolling(false)

    # This @delegate will get a message when the load completes
    @delegate = SimpleLoadDelegate.alloc.init
    @delegate.shooter = self
    @view.setFrameLoadDelegate(@delegate)

    # Replace the window's content @view with the web @view
    @window.setContentView(@view)
    @view.release
  end
  
  def capture(uri, path)
    # Tell the frame to load the URL we want
    @view.mainFrame.loadRequest(OSX::NSURLRequest.requestWithURL(OSX::NSURL.URLWithString(uri)))
    
    # Run the main event loop until the frame loads
    OSX.CFRunLoopRun
    
    upon_success do |view| # Capture the content of the view as an image
      view.setNeedsDisplay(true)
      view.displayIfNeeded
      view.lockFocus
      bitmap = OSX::NSBitmapImageRep.alloc.initWithFocusedViewRect(view.bounds)
      view.unlockFocus
      
      # Write the bitmap to a file as a PNG
      bitmap.representationUsingType_properties(OSX::NSPNGFileType, nil).writeToFile_atomically(path, true)
      bitmap.release
    end
    
    upon_failure do |error, logger|
      logger.warn("Unable to load URI: #{uri} (#{error})")
    end
  end
  
  def release
    @window.release
    @delegate.release
    @pool.release
  end
  
  attr_accessor :load_success, :load_error
  
  private
  
  def upon_success(&block)
    block.call(@view) if @load_success
  end
  
  def upon_failure(&block)
    block.call(@load_error.localizedDescription, @logger) unless @load_success
  end

  class SimpleLoadDelegate < OSX::NSObject

    attr_accessor :shooter

    def webView_didFinishLoadForFrame(sender, frame)
      @shooter.load_success = true; OSX.CFRunLoopStop(OSX.CFRunLoopGetCurrent)
    end
    
    def webView_didFailLoadWithError_forFrame(webview, load_error, frame)
      @shooter.load_success = false; @shooter.load_error = load_error; OSX.CFRunLoopStop(OSX.CFRunLoopGetCurrent)
    end

    def webView_didFailProvisionalLoadWithError_forFrame(webview, load_error, frame)
      @shooter.load_success = false; @shooter.load_error = load_error; OSX.CFRunLoopStop(OSX.CFRunLoopGetCurrent)
    end

  end
  
end

