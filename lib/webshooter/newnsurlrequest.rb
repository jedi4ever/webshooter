module Webshooter
	# We want to allow any https certificate
	# OSX::NSURLRequest.setAllowsAnyHTTPSCertificate(true,myURI.host) has method missing
	# Therefore we create a wrapper object
	# NewRequest.setAllowsAnyHTTPSCertificate_forHost(true,OSX::NSURL.URLWithString(uri))

	class NewNSURLRequest < OSX::NSURLRequest
	end
end
