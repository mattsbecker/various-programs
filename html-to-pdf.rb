#!/usr/bin/env ruby

=begin
 this script requires the PDFKit gem, found on GitHub, here: https://github.com/pdfkit/pdfkit
 gem install pdfkit
 gem install wkhtmltopdf-binary
=end

require 'PDFKit'

fileArg = {}

def generate_pdf_from_file(input_file, output_file)
  # make sure there's an input file
  if input_file
    #create an output file from the PDFKit output – PDFKit input comes from the input_file param
    out_file = PDFKit.new(File.new(input_file))
    #output to the specified output file
    out_file.to_file(output_file)
  end
end


# ensure the proper number of arguments have been provided – if not, exit properly
if ARGV.count < 2
  puts "Usage: ruby html-to-pdf.rb <html-file-to-convert> <output-file-name.pdf> \n"
  exit
end

# get the input file and output file path from ARGV and pass them to the pdf generation function
input = ARGV[0]
output_file = ARGV[1]
puts "Reading file... #{input} and output file path: #{output_file}"

#generate the pdf!
generate_pdf_from_file(input,output_file)
