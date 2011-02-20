require 'prawn' 
Prawn::Document.generate('webshot.pdf') do |pdf| 
  pdf.image"webshot.png", :width => 1080 , :height => 2280
end
