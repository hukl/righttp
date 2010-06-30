require 'socket'

module Rig

  class HTTP

    attr_reader :tcp_socket, :params, :method, :path

    def initialize options
      @host       = options[:host]    || raise(ArgumentError, "No host specified")
      @port       = options[:port]    || 80
      @params     = options[:params]  || {}
      @method     = options[:method]  || "GET"
      @path       = options[:path]    || "/"
      @header     = {}
      @body       = {}
      @tcp_socket = TCPSocket.new( @host, @port )
    end

  end

end
