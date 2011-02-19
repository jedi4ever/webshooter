# Inspired by http://railstips.org/blog/archives/2009/03/04/following-redirects-with-nethttp/
# But needs some of this - http://www.ruby-forum.com/topic/142745

require 'net/http'
require 'net/https'

module Webshooter
  
class RedirectFollower
  class TooManyRedirects < StandardError; end
  
  attr_accessor :url, :body, :redirect_limit, :response
  
  def initialize(url, limit=5)
    @url, @redirect_limit = url, limit
  end
  
  def resolve
    raise TooManyRedirects if redirect_limit < 0
    
    uri=URI.parse(url)
    
    http = Net::HTTP.new(uri.host, uri.port)

    if uri.scheme == "https"
      http.use_ssl = true
      #http.verify_mode = OpenSSL::SSL::VERIFY_NONE # Not setting this explicitly will result in an error and the value being set anyway
    end

    if (uri.path=="")
      request = Net::HTTP::Get.new("/")      
    else
      request = Net::HTTP::Get.new(uri.path)
    end
    self.response = http.start {|http| http.request(request) }

    if response.kind_of?(Net::HTTPRedirection)      
      self.url = redirect_url
      self.redirect_limit -= 1

      puts "redirect found, headed to #{url}"
      resolve
    end   
    return url
    
  end

  def redirect_url
    if response['location'].nil?
      response.body.match(/<a href=\"([^>]+)\">/i)[1]
    else
      response['location']
    end
  end
end

end

