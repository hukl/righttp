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
      @body           = []
      @tcp_socket     = TCPSocket.new( @host, @port )
    end

    def generate_header_and_body
      update_body
      update_header
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

    def update_body
      @body
    end

    def determine_content_type
      if @params.values.map(&:class).include?( File )
        "multipart/form-data; boundary=#{boundary}"
      else
        "text/plain"
      end
    end

    def boundary
      @boundary ||= "----rigHTTPmultipart#{rand(2**32)}XZWCFOOBAR"
    end

    def header
      @header.to_s
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

end
