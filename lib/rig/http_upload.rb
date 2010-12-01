module Rig

  class Upload

    def initialize options = {}
      filename = uri_escape( File.basename( options[:path] ) )
      filesize = File.stat( options[:path] ).size

      @options = options

      @header = [
        "PUT /#{filename} HTTP/1.1",
        'User-Agent: Rig-HTTP',
        "Host: #{options[:host]}",
        'Accept: */*',
        "Content-Length: #{filesize}",
        'Connection: close',
        "\r\n"
      ]

      @header = @header.join("\r\n")
    end

    def send
      begin
        tcp_socket = TCPSocket.new( @options[:host], @options[:port] )
        tcp_socket.write( @header + File.open(@options[:path]) {|f| f.read} )

        response = tcp_socket.read
      rescue => excetption
        puts exception.message
      ensure
        tcp_socket.close
      end

      HTTPResponse.new( response ) || exception.message
    end

    def uri_escape url
      URI.escape(CGI.escape(url),'.')
    end

  end

end
