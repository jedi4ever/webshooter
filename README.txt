This library uses the Webkit Ruby Cocoa library to take headless webshots

# Installation
gem install webshooter --pre

# Usage 

## From within ruby
require 'webshooter'
Webshooter.capture('http://www.jedi.be','jedi.png','1024x768')

## As a commandline tool
webshooter 'http://www.jedi.be' 'jedi.png' '1024x768'

# Limitations
- does not handle redirects currently
- create more configurable options
- cleanup code
- only support png

# Inspiration

This library is a compilation of various parts I found on the web
The research was done a few years ago, so unfortunatly I don't have all the references anymore

- Darkroom -  Copyright (c) 2007 Justin Palmer.
  - https://gist.github.com/34824 
  - https://gist.github.com/86435

- Thanks to the heavy lifting done by others:
 -  https://gist.github.com/244948
 - http://pastie.caboo.se/69235
 - http://pastie.caboo.se/68511
 - https://gist.github.com/248077 Webview to PDF
 - http://www.bencurtis.com/wp-content/uploads/2008/05/snapper.rb
