# -*- encoding: utf-8 -*-
require File.expand_path("../lib/webshooter/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "webshooter"
  s.version     = Webshooter::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Patrick Debois"]
  s.email       = ["patrick.debois@jedi.be"]
  s.homepage    = "http://github.com/jedi4ever/webshooter/"
  s.summary     = %q{Create webshot using webkit on MacOSX}
  s.description = %q{This library allows you to create webshots using webkit on MacOSX. A webshot is a screenshot taken inside the browser. The advantage of this library is that it is headless and gives you the real view not a parsed view}

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "webshooter"

  s.add_development_dependency "bundler", ">= 1.0.0"
  #s.add_dependency "responsalizr", "~>1.0.2"
  s.add_dependency "nokogiri", "~>1.4.4"

  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = 'lib'
end

