require 'socket'

module Rig

  CRLF = "\r\n"

  class HTTP

    attr_reader :tcp_socket, :params, :method, :path

    def initialize options
      @host           = options[:host]    || raise(ArgumentError, "No host specified")
      @port           = options[:port]    || 80
      @params         = options[:params]  || {}
      @method         = options[:method]  || "GET"
      @path           = options[:path]    || "/"
      @header         = HTTPHeader.new( "" => "#{@method} #{@path} HTTP/1.1" )
      @custom_header  = HTTPHeader.new( options[:header]  || {} )
      @body           = HTTPBody.new
      @tcp_socket     = TCPSocket.new( @host, @port )
    end

    def generate_header_and_body
      if @method == "GET"
        update_path_query_params
      else
        update_body
      end
      update_header
    end

    def send
      begin
        @tcp_socket.write( header + body )
        response = @tcp_socket.recvfrom(2**16)
      rescue => exception
        puts exception.message
      ensure
        @tcp_socket.close
      end

      response || exception.message
    end

    def update_header
      @header.merge!(
        "Host"            => "localhost",
        "Origin"          => "localhost",
        "Content-Length"  => @body.join.bytes.to_a.length,
        "Content-Type"    => determine_content_type
      ).merge!(
        @custom_header
      ).merge!(
        "Connection"      => "close"
      )
    end

    def update_path_query_params

    end

    def multipart?
      if defined? @multipart
        @multipart
      else 
        @multipart = @params.values.map(&:class).include?( File )
      end
    end

    def update_body
      if multipart?
        create_multipart_body
      else
        create_simple_body
      end
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
      part += CRLF
    end

    def create_multipart_body
      @params.each do |key, value|
        if value.is_a?( File )
          @body << new_file_multipart( key, value )
        elsif value.is_a?( String ) || value.responds_to?( :to_s )
          @body << new_text_multipart( key, value )
        else
          raise ArgumentError, "Invalid Parameter Value"
        end
      end

      @body << "--#{boundary}--\r\n"
    end

    def create_simple_body
      @body << @params.map {|key, value| "#{key}=#{value}"}.join("&")
    end

    def determine_content_type
      if multipart?
        "multipart/form-data; boundary=#{boundary}"
      else
        if @method == "POST"
          "application/x-www-form-urlencoded; charset=UTF-8"
        else
          "text/plain"
        end
      end
    end

    def boundary
      @boundary ||= "----rigHTTPmultipart#{rand(2**32)}XZWCFOOBAR"
    end

    def header
      @header.to_s
    end

    def body
      @body.to_s
    end
  end

  class HTTPHeader < Hash

    def initialize options
      super.merge! options
    end

    def to_s
      header_string = map do |field_name, value|
        if field_name == ""
          value
        else
          "#{field_name}: #{value}"
        end
      end

      header_string.join(CRLF) + CRLF + CRLF
    end

  end

  class HTTPBody < Array

    def to_s
      join
    end

  end

end
