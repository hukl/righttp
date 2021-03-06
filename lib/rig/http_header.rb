module Rig
  class HTTPHeader < Hash

    def initialize options
      http_method = options[:http_method] || "GET"
      path        = options[:path]        || "/"

      header = {
        ""                => "#{http_method} #{path} HTTP/1.1",
        "Host"            => options[:host],
        "Content-Length"  => options[:content_length],
        "Content-Type"    => options[:content_type]
      }.merge(
        (options[:custom_header] || {})
      ).merge(
        "Connection"      => "close"
      )

      merge!( header )
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
