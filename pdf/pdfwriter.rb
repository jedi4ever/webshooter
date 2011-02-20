begin
  require 'pdf/writer'
rescue LoadError => le
  if le.message =~ %r{pdf/writer$}
    $LOAD_PATH.unshift("../lib")
    require 'pdf/writer'
  else
    raise
  end
end

pdf = PDF::Writer.new
i0 = pdf.image "webshot.jpg"

pdf.text "Chunky Bacon!!", :font_size => 72, :justification => :center

pdf.save_as("webshot.pdf")
