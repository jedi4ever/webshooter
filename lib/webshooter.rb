require 'webshooter/webshotprocessor'

# We might handle redirection in the future
# http://shadow-file.blogspot.com/2009/03/handling-http-redirection-in-ruby.html

module Webshooter
	class Webshooter
	  def self.capture(uri, path, dimensions = "1024x768" )
	    webProcessor=WebShotProcessor.new
	    webProcessor.capture(uri,path,dimensions)
	  end
	end
end
