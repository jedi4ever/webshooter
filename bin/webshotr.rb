#!/usr/bin/env ruby

require 'webshotr'
require 'bundler'

#Ruby CLI tool - http://rubylearning.com/blog/2011/01/03/how-do-i-make-a-command-line-tool-in-ruby/


url=ARGV[0]
filename=ARGV[1]
size=ARGV[2]

webshotr=Webshotr.new
webshotr.capture(url, filename, size )
