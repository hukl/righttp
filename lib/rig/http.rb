require 'socket'
require 'uri'

module Rig

  CRLF = "\r\n"
  HTTPMethods = %w(GET POST PUT DELETE)

  class HTTP

    def initialize *options
      raise ArgumentError if options.empty?

      puts options.inspect
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

    def self.method_missing name, *args, &block
      name = name.to_s.upcase

      if HTTPMethods.include?( name )

        if (args.length == 1 && args.first.is_a?( String )) || args.length > 1
          self.new( args.push( :method => name ) )
        elsif args.length == 1 && args.first.respond_to?(:merge)
          self.new( args.first.merge( :method => name ) )
        end

      else
        super
      end
    end
  end

end


class NoHostProvided < ArgumentError; end;
