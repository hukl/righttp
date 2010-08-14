require 'socket'
require 'uri'

module Rig

  CRLF = "\r\n"
  HTTPMethods = %w(GET POST PUT DELETE)

  class HTTP
    attr_reader :options

    def initialize *options

      @options = normalize_options( options )
    end

    def normalize_options options
      options.flatten!

      case HTTP.options_mode( options )
      when :simple
        uri = URI.parse( options.first )
        return {:host => uri.host, :port => uri.port, :path => uri.path}
      when :mixed
        uri = URI.parse( options.first )
        uri_options = {:host => uri.host, :port => uri.port, :path => uri.path}
        return uri_options.merge( options.last )
      when :advanced
        puts "avanced"
        return options
      else
        raise ArgumentError
      end

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
          self.new( args.push( :method => name ) )
        when :mixed
          args.last.merge!( :method => name )
          self.new( args )
        when :advanced
          self.new( args.first.merge( :method => name ) )
        end
      else
        super
      end
    end
  end

end


class NoHostProvided < ArgumentError; end;
