require 'socket'
require 'uri'

module Rig

  CRLF = "\r\n"
  HTTPMethods = %w(GET POST PUT DELETE)

  class HTTP
    attr_reader :options, :header, :body

    def initialize *options
      @options      = normalize_options( options )
      @body         = HTTPBody.new( prepare_body )
      @header       = HTTPHeader.new( prepare_header )
    end

    def http_method
      @options[:http_method] || "GET"
    end

    def boundary
      @boundary ||= "----rigHTTPmultipart#{rand(2**32)}XZWCFOOBAR"
    end

    def prepare_body
      if %w(POST PUT).include?( http_method ) && @options[:body]
        if multipart?
          return create_multipart_body
        else
          return create_simple_body
        end
      else
        []
      end
    end

    def multipart?
      if defined? @multipart
        @multipart
      elsif @options[:body]
        @multipart = @options[:body].values.any? do |element|
          element.respond_to?( :read )
        end
      else
        @multipart = false
      end
    end

    def create_simple_body
      [@options[:body].map {|key, value| "#{key}=#{value}"}.join("&")]
    end

    def create_multipart_body
      body = []

      @options[:body].each do |key, value|
        if value.respond_to?( :read )
          body << new_file_multipart( key, value )
        elsif value.is_a?( String ) || value.respond_to?( :to_s )
          body << new_text_multipart( key, value )
        else
          raise ArgumentError, "Invalid Parameter Value"
        end
      end

      body << "--#{boundary}--\r\n"
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

    def prepare_header

      header = {
        ""                => "#{@options[:http_method]} #{path} HTTP/1.1",
        "Host"            => @options[:host],
        "Origin"          => "localhost",
        "Content-Length"  => @body.join.bytes.to_a.length,
        "Content-Type"    => determine_content_type
      }.merge(
        (@options[:custom_header] || {})
      ).merge(
        "Connection"      => "close"
      )
    end

    def determine_content_type
      if multipart?
        "multipart/form-data; boundary=#{boundary}"
      else
        if %w(POST PUT).include?( http_method )
          "application/x-www-form-urlencoded; charset=UTF-8"
        else
          "text/plain"
        end
      end
    end

    def normalize_options options
      options.flatten!

      options = case HTTP.options_mode( options )
      when :simple
        uri = URI.parse( options.first )
        {
          :host   => uri.host,
          :port   => uri.port,
          :path   => uri.path,
          :query  => uri.query
        }
      when :mixed
        uri = URI.parse( options.first )
        uri_options = {
          :host   => uri.host,
          :port   => uri.port,
          :path   => uri.path,
          :query  => uri.query
        }
        uri_options.merge( options.last )
      when :advanced
        {
          :http_method  => options.first[:http_method]  || "GET",
          :host         => options.first[:host],
          :port         => options.first[:port]         || 80,
          :path         => options.first[:path]         || "/",
          :query        => options.first[:query]
        }
      else
        raise ArgumentError
      end

      if options[:path].nil? || options[:path].empty?
        options[:path] = "/"
      end

      options
    end

    def generate_uri options
      if options.first.is_a?( String )
        URI.parse( options.first )
      elsif options.first.is_a?( Hash )
        host = options[:host]

        raise NoHostProvided unless host

        port = (options[:port] || 80)
        path = (options[:path] || "").gsub(/^\//, "")

        URI.parse( "#{host}:#{port}/#{path}" )
      end
    end

    def method_missing name, *args, &block
      if options[name]
        return options[name]
      else
        super
      end
    end

    def self.options_mode options
      if    options.length == 1 && options.first.is_a?( String )
        :simple
      elsif options.length == 2 && options.map(&:class) == [String, Hash]
        :mixed
      elsif options.length == 1 && options.first.is_a?( Hash )
        :advanced
      else
        :error
      end
    end

    def self.method_missing name, *args, &block
      name = name.to_s.upcase

      if HTTPMethods.include?( name )
        case options_mode( args )
        when :simple
          self.new( args.push( :http_method => name ) )
        when :mixed
          args.last.merge!( :http_method => name )
          self.new( args )
        when :advanced
          self.new( args.first.merge( :http_method => name ) )
        end
      else
        super
      end
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


class NoHostProvided < ArgumentError; end;
