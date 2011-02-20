require 'osx/cocoa'
require 'logger'
require 'uri'

require 'webshooter/newnsurlrequest'
require 'webshooter/redirectfollower'

OSX.require_framework 'WebKit'

#Respond to URL not found....
#http://stackoverflow.com/questions/697108/testing-use-of-nsurlconnection-with-http-response-error-statuses
#http://www.gigliwood.com/weblog/Cocoa/Q__When_is_an_conne.html
#http://stackoverflow.com/questions/2236407/how-to-detect-and-handle-http-error-codes-in-uiwebview


module Webshooter

class WebShotProcessor 

    def initialize
      @logger = Logger.new(STDOUT)

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

      # Make a web @webView - the frame here is in window coordinates
      @webView = OSX::WebView.alloc.initWithFrame(rect)      
      
      # Use the screen stylesheet, rather than the print one.
      @webView.setMediaStyle('screen')
      # Make sure we don't save any of the prefs that we change.
      @webView.preferences.setAutosaves(false)
      # Set some useful options.
      @webView.preferences.setShouldPrintBackgrounds(true)
      @webView.preferences.setJavaScriptCanOpenWindowsAutomatically(true)
      @webView.preferences.setAllowsAnimatedImages(false)
      # Make sure we don't get a scroll bar.
      @webView.mainFrame.frameView.setAllowsScrolling(false)          

      # This @delegate will get a message when the load completes
      @delegate = SimpleLoadDelegate.alloc.init
      @delegate.webshooter = self

      @webView.setFrameLoadDelegate(@delegate)

      # Replace the window's content @webView with the web @webView
      @window.setContentView(@webView)
      @webView.release
    end

    def capture(uri, options )
      
      options[:width] ||= 1024
      options[:height] ||= 768
      options[:output] ||= "webshot.png" 
      options[:delay] ||= 2 
      
      @delegate.options = options
           
      snapshot_dimension=[ options[:width] , options[:height]]
      # Tell the frame to load the URL we want
      @webView.window.setContentSize(snapshot_dimension) 
      @webView.setFrameSize(snapshot_dimension)
    
      final_link = RedirectFollower.new(uri).resolve
      
      #puts "final link = #{final_link}"
      myURI = URI.parse(final_link)
       
      #Allow all https certificates
      NewNSURLRequest.setAllowsAnyHTTPSCertificate_forHost(true,myURI.host)
      
      #puts "Getting ready for the loadRequest"+uri
      @webView.mainFrame.loadRequest(NewNSURLRequest.requestWithURL(OSX::NSURL.URLWithString(final_link)))

      #
      # Run the main event loop until the frame loads
      @timeout=false
      result=OSX.CFRunLoopRunInMode(OSX::KCFRunLoopDefaultMode, 20, false)
      if (result == OSX::KCFRunLoopRunTimedOut)
        @timeout=true
      end

      #This is what we need but the upon_ also changes
      #OSX.CFRunLoopRun
      #puts "first loop enters here"
      
         
      upon_success do |view| # Capture the content of the view as an image

        view.window.orderFront(nil)
        #view.window.display
  
        #puts "We got success"
        @docview=view.mainFrame.frameView.documentView

        #We need the contents of the first frame
        #pp view.bounds
        #pp @docview.bounds

        if @docview.bounds.size.height == 0.0
          #pp "trying alternative"
          #pp @docview
          @docview= view.mainFrame.frameView.documentView
        else
          view.window.setContentSize(@docview.bounds.size)
          view.setFrame(@docview.bounds)
          if view.bounds.size.height > 300000
            #view.bounds.size.height=300000
            #puts "Adjusted maximum size to 300000"
          end
        end


        # Write the bitmap to a file as a PNG
        #
        #view.bounds=initialsize
        #view.window.setContentSize(view.bounds.size)
        
        view.setNeedsDisplay(true)
        view.displayIfNeeded
        if view.bounds.size.height < 300000
          view.lockFocus
          bitmap = OSX::NSBitmapImageRep.alloc.initWithFocusedViewRect(view.bounds)
          bitmap.representationUsingType_properties(OSX::NSPNGFileType, nil).writeToFile_atomically(options[:output], true)
          logger.info( "Webshot for #{final_link} => '#{options[:output]}' ")
          bitmap.release
          view.unlockFocus

        else
          puts "Something went wrong, the size became to big"
        end

      end

      upon_failure do |error, logger|
        logger.warn("Unable to load URI: #{final_link} (#{error})")
      end
      
      
    end

    def release
      #@window.release
      @delegate.release
    end

    attr_accessor :load_success, :load_error

    private

    def upon_success(&block)
      block.call(@webView) if @load_success
    end

    def upon_failure(&block)
      if (@timeout)
        block.call("Timeout error", @logger) unless @load_success
      else
        block.call(@load_error.localizedDescription, @logger) unless @load_success
      end
    end


    class SimpleLoadDelegate < OSX::NSObject

      attr_accessor :webshooter, :options

      def stopLoop
        mainLoop=OSX.CFRunLoopGetMain
        currentLoop=OSX.CFRunLoopGetCurrent
        OSX.CFRunLoopStop(mainLoop)
        OSX.CFRunLoopStop(currentLoop)
      end

      def webView_didFinishLoadForFrame(sender, frame)
  
        #This did the trick, we have to wait for the right frame to load, not other frames
        if (frame == sender.mainFrame)
          then
          #puts "Finish Load For Frame"
          #sleep 10
          #puts "#{  @options[:delay]}"
          sleep   @options[:delay]
          #puts "we got a finish"
          @webshooter.load_success = true; 

          stopLoop
        else
          #puts "WARN: the mainframe is not the frame"
          return
        end
      end

      # keeping track of all content being loaded
      # http://www.opensubscriber.com/message/webkitsdk-dev@lists.apple.com/2978556.html
      def webView_didCommitLoadForFrame(sender,frame)
        #puts "we got a commit"
      end
      
      def webView_didFailLoadWithError_forFrame(webview, load_error, frame)

        #puts "we got a failed"
        #This is trick # 2
        #We have to catch this stupid error
        if (load_error.code == OSX::NSURLErrorCancelled) 
          then
          #pp "WARN: did Fail with Error For Frame"
          #pp "WARN: we don't give up"
          return
        else
          #puts load_error.localizedDescription
        end

        @webshooter.load_success = false; @webshooter.load_error = load_error; 

        stopLoop
      end

      def webView_didFailProvisionalLoadWithError_forFrame(webview, load_error, frame)
        puts "we got a provisional load"
        if (load_error.code == OSX::NSURLErrorCancelled) 
          then
          #pp "WARN: did Fail PROVISIONAL LOAD WITH ERROR For Frame"
          #pp "WARN: we don't give up"
          return
        else
          #puts load_error.localizedDescription
        end
        @webshooter.load_success = false; @webshooter.load_error = load_error; 

        stopLoop
      end

    end

  end

end
