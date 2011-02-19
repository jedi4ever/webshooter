# This library is a compilation of various parts I found on the web
# The research was done a few years ago, so unfortunatly I don't have all the references anymore

require 'osx/cocoa'
require 'logger'
require 'pp'
require 'uri'

OSX.require_framework 'WebKit'


module Webshotr

#Respond to URL not found....
#http://stackoverflow.com/questions/697108/testing-use-of-nsurlconnection-with-http-response-error-statuses
#http://www.gigliwood.com/weblog/Cocoa/Q__When_is_an_conne.html
#http://stackoverflow.com/questions/2236407/how-to-detect-and-handle-http-error-codes-in-uiwebview

class NewRequest < OSX::NSURLRequest
    def allowsAnyHTTPSCertificateForHost2(host)
          puts "***** HERE WE ARE ****"
          return true
    end
end


class Webshotr

  def initialize
    @logger = Logger.new(STDOUT)
    
    @pool = OSX::NSAutoreleasePool.alloc.init

    # get NSApplication code ready for action
    OSX.NSApplicationLoad


    #	Make an offscreen window
    # The frame is in screen coordinates, but it's irrelevant since we'll never display it
    # We want a buffered backing store, simply so we can read it later
    #	We don't want to defer, or it won't draw until it gets on the screen
    rect = OSX::NSRect.new(-16000,-16000,100,100)
    @window = OSX::NSWindow.alloc.initWithContentRect_styleMask_backing_defer(
                rect , OSX::NSBorderlessWindowMask, OSX::NSBackingStoreBuffered, false
             )

    # Make a web @view - the frame here is in window coordinates
    @view = OSX::WebView.alloc.initWithFrame(rect)
    @view.mainFrame.frameView.setAllowsScrolling(false)

    # This @delegate will get a message when the load completes
    @delegate = SimpleLoadDelegate.alloc.init
    @delegate.webshotr = self
    @view.setFrameLoadDelegate(@delegate)
    
    # Replace the window's content @view with the web @view
    @window.setContentView(@view)
    @view.release
  end
  
  def dosomething(timer, info)
    puts "we did it"
  end

  def capture(uri, path)
    # Tell the frame to load the URL we want
    @view.window.setContentSize([ 1024,768]) 
    @view.setFrameSize([1024,768])
    #PDB: ignore certificates
    #OSX::NSURLRequest.setAllowsAnyHTTPSCertificate(true)
    #NewRequest.setAllowsAnyHTTPSCertificate_forHost(true,OSX::NSURL.URLWithString(uri))
    myURI = URI.parse(uri)
    NewRequest.setAllowsAnyHTTPSCertificate_forHost(true,myURI.host)
    puts "Getting ready for the loadRequest"+uri
    @view.mainFrame.loadRequest(NewRequest.requestWithURL(OSX::NSURL.URLWithString(uri)))

    #
    # Create timer
    timestamp= OSX.CFAbsoluteTimeGetCurrent()
    timeout=5
    firetime=timestamp+timeout
    pp firetime

    # allocator, NULL = default allocator
    # fireDate ( millisecond)
    # interval (0 = fire only once)
    # flags (0 = future compatibilty)
    # order (0 = ignore)
    # callout (callback function )
    # context (NULL, if no state is needed for the callout)
    timercallback = :dosomething
    #timercallback = TimerCallBack.alloc.init
    #myTimer= OSX.CFRunLoopTimerCreate(nil, firetime, 2, 0,0,timercallback, nil)
    
    #OSX.CFRunLoopAddTimer( OSX.CFRunLoopGetMain , myTimer, OSX::KCFRunLoopCommonModes)
    
    #
    # Run the main event loop until the frame loads
    @timeout=false
    result=OSX.CFRunLoopRunInMode(OSX::KCFRunLoopDefaultMode, 20, false)
    if (result == OSX::KCFRunLoopRunTimedOut)
      @timeout=true
    end

    #This is what we need but the upon_ also changes
    #OSX.CFRunLoopRun
    puts "first loop enters here"
    
    upon_success do |view| # Capture the content of the view as an image
      #PDB Resize window 
      view.window.orderFront(nil)
      view.window.display
      pp "-------------------------------------------------"
      pp "We got success"
      @docview=view.mainFrame.frameView.documentView

      #We need the contents of the first frame
      pp view.bounds
      pp @docview.bounds

      if @docview.bounds.size.height == 0.0
              pp "trying alternative"
              pp @docview
               @docview= view.mainFrame.frameView.documentView
      else
        view.window.setContentSize(@docview.bounds.size)
        view.setFrame(@docview.bounds)
        if view.bounds.size.height > 300000
          #view.bounds.size.height=300000
          pp "Adjusted maximum size to 300000"
        end
      end
      
    
      view.setNeedsDisplay(true)
      view.displayIfNeeded
        if view.bounds.size.height < 300000
          view.lockFocus
          bitmap = OSX::NSBitmapImageRep.alloc.initWithFocusedViewRect(view.bounds)
        bitmap.representationUsingType_properties(OSX::NSPNGFileType, nil).writeToFile_atomically(path, true)
        bitmap.release
        view.unlockFocus
      
        else
          pp "OOOOOOOOOOOOOOOOO -> skipped size"
        end
      
      # Write the bitmap to a file as a PNG
     #
      #view.bounds=initialsize
      #view.window.setContentSize(view.bounds.size)
      
    end
    
    upon_failure do |error, logger|
      logger.warn("Unable to load URI: #{uri} (#{error})")
    end
  end
  
  def release
    #@window.release
    @delegate.release
    #@pool.release
  end
  
  attr_accessor :load_success, :load_error
  
  private
  
  def upon_success(&block)
    block.call(@view) if @load_success
  end
  
  def upon_failure(&block)
    if (@timeout)
      block.call("Timeout error", @logger) unless @load_success
    else
      block.call(@load_error.localizedDescription, @logger) unless @load_success
    end
  end


  class TimerCallBack < OSX::NSObject
  end

  class SimpleLoadDelegate < OSX::NSObject

    attr_accessor :webshotr

    def stopLoop
          mainLoop=OSX.CFRunLoopGetMain
          currentLoop=OSX.CFRunLoopGetCurrent
          pp mainLoop
          pp currentLoop
          OSX.CFRunLoopStop(mainLoop)
          OSX.CFRunLoopStop(currentLoop)
    end

    def webView_didFinishLoadForFrame(sender, frame)
      #This did the trick, we have to wait for the right frame to load, not other frames
      if (frame == sender.mainFrame)
        then
          pp "Finish Load For Frame"
          @webshotr.load_success = true; 
          
          stopLoop
        else
          pp "WARN: the mainframe is not the frame"
          return
        end
    end
    
    def webView_didFailLoadWithError_forFrame(webview, load_error, frame)

      #This is trick # 2
      #We have to catch this stupid error
      if (load_error.code == OSX::NSURLErrorCancelled) 
      then
        #pp "WARN: did Fail with Error For Frame"
        #pp "WARN: we don't give up"
        return
      else
        pp "ERROR", load_error.localizedDescription
     end

      @webshotr.load_success = false; @webshotr.load_error = load_error; 
      
      stopLoop
    end

    def webView_didFailProvisionalLoadWithError_forFrame(webview, load_error, frame)
      if (load_error.code == OSX::NSURLErrorCancelled) 
      then
        #pp "WARN: did Fail PROVISIONAL LOAD WITH ERROR For Frame"
        #pp "WARN: we don't give up"
        return
      else
        pp "ERROR", load_error.localizedDescription
     end
      @webshotr.load_success = false; @webshotr.load_error = load_error; 
      
      stopLoop
    end

  end
  
end
end
