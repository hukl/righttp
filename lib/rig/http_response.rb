module Rig
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
