This library uses the Webkit Ruby Cocoa library to take headless webshots

# Ruby cocoa working
- This means it will only work on the system ruby on mac
- rvm use system (to activate it)

# Installation
gem install webshooter --pre

# Usage 

## From within ruby
require 'webshooter'
Webshooter.capture('http://www.jedi.be',{ :output => 'jedi.png', :width => '1024' , :height => '768' , :delay => '2')

## As a commandline tool
webshooter 'http://www.jedi.be' --width=1024 --height=786 --delay=2 --output=jedi.png

# Limitations
- does not handle redirects currently
- create more configurable options
- cleanup code
- only support png

# Inspiration

This library is a compilation of various parts I found on the web
The research was done a few years ago, so unfortunatly I don't have all the references anymore

- webkit2png - http://www.paulhammond.org/webkit2png/
- http://cocoadevblog.com/webkit-screenshots-cocoa-objective-c


- Darkroom -  Copyright (c) 2007 Justin Palmer.
  - https://gist.github.com/34824 
  - https://gist.github.com/86435

- Thanks to the heavy lifting done by others:
 -  https://gist.github.com/244948
 - http://pastie.caboo.se/69235
 - http://pastie.caboo.se/68511
 - https://gist.github.com/248077 Webview to PDF
 - http://www.bencurtis.com/wp-content/uploads/2008/05/snapper.rb
