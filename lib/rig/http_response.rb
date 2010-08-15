require 'ruby-debug'
module Rig
  class HTTPResponse

    attr_reader :header, :body

    def initialize response
      parts = response.split(CRLF + CRLF)
      @header = parts.delete_at( 0 )
      @status = @header.match(/HTTP\/\d.\d\s(\d\d\d)/)[1]
      @body   = parts.join

      parse_header

      if @header["Transfer-Encoding"] == "chunked"
        parsed_body = ""
        @body = StringIO.new( @body )
        read_chunked( parsed_body )

        @body = parsed_body
      end
    end

    def status
      @status ? @status.to_i : 666
    end

    def parse_header
      status_line = @header[/HTTP\/\d\.\d\s\d\d\d.+\r\n/]
      @header = @header.gsub(status_line, "Status: #{status_line}")
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
