require 'socket'
require 'uri'
require 'rig/http_response'
require 'rig/http_header'
require 'rig/http_body'
require 'rig/http_exceptions'

module Rig

  CRLF = "\r\n"
  HTTPMethods = %w(GET POST PUT DELETE)

  class HTTP
    attr_reader :options, :header, :body

    def initialize *options
      @options      = normalize_options( options )
      @body         = HTTPBody.new( @options )

      @options.merge!(
        :content_type   => @body.content_type,
        :content_length => @body.content_length
      )
      @header       = HTTPHeader.new( @options )
    end

    def send
      begin
        tcp_socket = TCPSocket.new( @options[:host], @options[:port] )
        tcp_socket.write( @header.to_s + @body.to_s )
        response = tcp_socket.read
      rescue => exception
        puts exception.message
      ensure
        tcp_socket.close
      end

      HTTPResponse.new( response ) || exception.message
    end

    def with_body?
      %w(POST PUT).include?( options[:http_method] ) && options[:body]
    end

    def http_method
      @options[:http_method] || "GET"
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
        options.first[:http_method]  ||= "GET"
        options.first[:host]
        options.first[:port]         ||= 80
        options.first[:path]         ||= "/"
        options.first[:query]
        options.first
      else
        raise ArgumentError
      end

      if options[:path].nil? || options[:path].empty?
        options[:path] = "/"
      end

      options
    end

    def method_missing name, *args, &block
      if options[name]
        return options[name]
      else
        super
      end
    end

    def self.options_mode options
      if options.length == 1 && options.first.is_a?( String )
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

end
