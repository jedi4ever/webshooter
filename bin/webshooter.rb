#!/usr/bin/env ruby


require 'webshooter'

module Webshooter
	class CLI
		#Ruby CLI tool - http://rubylearning.com/blog/2011/01/03/how-do-i-make-a-command-line-tool-in-ruby/
		def self.execute(args)
			url=args[0]
			filename=args[1]
			size=args[2]
			webshotr=Webshooter.capture(url, filename, size )
		end
	end
end

Webshooter::CLI.execute(ARGV)
