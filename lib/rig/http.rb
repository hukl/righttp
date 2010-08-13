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
      @path           = (options[:path]    || "/") + update_path_query_params
      @header         = HTTPHeader.new( "" => "#{@method} #{@path} HTTP/1.1" )
      @custom_header  = HTTPHeader.new( options[:header]  || {} )
      @body           = HTTPBody.new
      @tcp_socket     = TCPSocket.new( @host, @port )
    end

    def generate_header_and_body
      if @method == "POST" || @method == "PUT"
        update_body
      end
      update_header
    end

    def send
      begin
        generate_header_and_body
        @tcp_socket.write( header + body )
        response = @tcp_socket.read
      rescue => exception
        puts exception.message
      ensure
        @tcp_socket.close
      end

      HTTPResponse.new( response ) || exception.message
    end

    def update_header
      @header.merge!(
        "Host"            => @host,
        "Origin"          => "localhost",
        "Content-Length"  => @body.join.bytes.to_a.length,
        "Content-Type"    => determine_content_type
      ).merge!(
        @custom_header
      ).merge!(
        "Connection"      => "close"
      )
    end

    # TODO Refactor this mess!
    def update_path_query_params
      if @method == "GET"
        if @params.is_a?( Hash ) && !@params.empty?
          return "?" + @params.map {|key, value| "#{key}=#{value}"}.join("&")
        elsif @params.is_a?( String ) && !@params.empty?
          return "?" + @params
        else
          return ""
        end
      else
        return ""
      end
    end

    def multipart?
      if defined? @multipart
        @multipart
      else
        multipart_params = @params.values.select {|p| p.respond_to?( :read ) }
        @multipart = !multipart_params.empty?
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
      file.close
      part += CRLF
    end

    def create_multipart_body
      @params.each do |key, value|
        if value.respond_to?( :read )
          @body << new_file_multipart( key, value )
        elsif value.is_a?( String ) || value.respond_to?( :to_s )
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

  class HTTPResponse

    attr_reader :header, :body

    def initialize response
      @header, @body = response.split(CRLF + CRLF)

      parse_header

      if @header["Transfer-Encoding"] == "chunked"
        parsed_body = ""
        @body = StringIO.new( @body )
        read_chunked( parsed_body )

        @body = parsed_body
      end
    end

    def parse_header
      @header = @header.gsub(/^HTTP\/\d\.\d\s\d\d\d.+\r\n/, "")
      @header = @header.split(CRLF)
      @header = @header.map { |element| element.split(": ") }
      @header = @header.inject({}) do |result, element|
        result[element.first] = element.last
        result
      end
    end

    def read_chunked(dest)
      len = nil
      total = 0
      while true
        line = @body.readline
        hexlen = line.slice(/[0-9a-fA-F]+/) or
          raise HTTPBadResponse, "wrong chunk size line: #{line}"
        len = hexlen.hex
        break if len == 0
        @body.read len, dest; total += len
        @body.read 2   # \r\n
      end
    end

  end

end
