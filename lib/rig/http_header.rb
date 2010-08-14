module Rig
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
