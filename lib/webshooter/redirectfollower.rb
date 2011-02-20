# Inspired by http://railstips.org/blog/archives/2009/03/04/following-redirects-with-nethttp/
# But needs some of this - http://www.ruby-forum.com/topic/142745

require 'net/http'
require 'net/https'
require 'nokogiri'

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
      request = Net::HTTP::Get.new("#{ '/' + (uri.query ? ('?' + uri.query) : '')}")      
    else
    
      # http://intertwingly.net/blog/2006/08/19/Quack-Squared
      request = Net::HTTP::Get.new(uri.path + (uri.query ? ('?' + uri.query) : '') )
    end
    
    
    self.response = http.start {|http| http.request(request) }

    if response.kind_of?(Net::HTTPRedirection)      
      self.url = redirect_url
      self.redirect_limit -= 1

      puts "redirect found, headed to #{url}"
      resolve
    end 
  
    meta_link=meta_parse
    if !meta_link.nil?
      self.url = meta_link
      self.redirect_limit -= 1
      puts "metalink found, headed to #{url}"
      resolve
    end
      
    return url
    
  end

  def meta_parse
    # http://stackoverflow.com/questions/5003367/mechanize-how-to-follow-or-click-meta-refreshes-in-rails/5012684#5012684
    html=response.body.to_s.downcase
    #puts html
    doc = Nokogiri::HTML(html)
    meta_tag=doc.at('meta[http-equiv="refresh"]')
    if !meta_tag.nil?
      meta_link = meta_tag['content'][/url=(.+)/, 1]
    else  
      meta_link=nil
    end
    meta_link # => "http://www.example.com/"
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

