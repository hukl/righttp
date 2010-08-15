module Rig
  class HTTPBody < Array

    def initialize options
      @options = options[:body] || {}

      if multipart?
        create_multipart_body
      else
        create_simple_body
      end
    end

    def boundary
      @boundary ||= "----rigHTTPmultipart#{rand(2**32)}XZWCFOOBAR"
    end

    def multipart?
      if defined? @multipart
        @multipart
      elsif @options
        @multipart = @options.values.any? do |element|
          element.respond_to?( :read )
        end
      else
        @multipart = false
      end
    end

    def create_simple_body
      push @options.map {|key, value| "#{key}=#{value}"}.join("&")
    end

    def create_multipart_body
      @options.each do |key, value|
        if value.respond_to?( :read )
          push new_file_multipart( key, value )
        elsif value.is_a?( String ) || value.respond_to?( :to_s )
          push new_text_multipart( key, value )
        else
          raise ArgumentError, "Invalid Parameter Value"
        end
      end

      push "--#{boundary}--\r\n"
    end

    def new_text_multipart field_name, text
      part = ""
      part += "--#{boundary}"
      part += CRLF
      part += "Content-Disposition: form-data; name=\"#{field_name}\""
      part += CRLF
      part += CRLF
      part += text
      part += CRLF
    end

    def new_file_multipart field_name, file
      content_type = %x[file --mime-type -b #{file.path}].chomp

      part = ""
      part += "--#{boundary}"
      part += CRLF
      part += "Content-Disposition: form-data; name=\"#{field_name}\"; "
      part += "filename=\"#{File.basename( file )}\""
      part += CRLF
      part += "Content-Type: #{content_type}"
      part += CRLF
      part += CRLF
      part += file.read
      file.close
      part += CRLF
    end

    def to_s
      join
    end

  end
end
