require 'webshooter/webshotprocessor'

# We might handle redirection in the future
# http://shadow-file.blogspot.com/2009/03/handling-http-redirection-in-ruby.html

module Webshooter
	class Webshooter
	  def self.capture(uri, options )
	    webProcessor=WebShotProcessor.new
	    webProcessor.capture(uri,options)
	  end
	end
end
