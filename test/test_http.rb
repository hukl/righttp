require 'helper'

class TestHttp < Test::Unit::TestCase

  test "create the simplest http get object" do
    assert_not_nil get = HTTP.new( {:host => "localhost"} )
  end

  test "to create a http object at least the host must be specified" do
    assert_raise(ArgumentError) { get = HTTP.new( {} ) }
  end

  test "http objects have accessible socket object" do
    get = HTTP.new( {:host => "localhost"} )
    assert_not_nil get.tcp_socket
  end

  test "http object has accessible params" do
    get = HTTP.new( {:host => "localhost", :params => {"foo" => "bar"}} )
    assert_not_nil get.params
    assert_equal ({"foo" => "bar"}), get.params
  end

  test "http object without params specified returns empty params" do
    get = HTTP.new( {:host => "localhost"} )
    assert_not_nil get.params
    assert_equal ({}), get.params
  end

  test "simple http object defaults to method GET" do
    get = HTTP.new( {:host => "localhost"} )
    assert_equal "GET", get.method
  end

  test "method of http object can be overridden" do
    post = HTTP.new( {:host => "localhost", :method => "POST"} )
    assert_equal "POST", post.method
  end

  test "path of a http object defaults to index" do
    get = HTTP.new( {:host => "localhost"} )
    assert_equal "/", get.path
  end

  test "path of http object can be set" do
    get = HTTP.new( {:host => "localhost", :path => "/posts"} )
    assert_equal "/posts", get.path
  end

  test "generate_header_and_body" do
    get = HTTP.new( {:host => "localhost", :path => "/posts"} )
    assert_not_nil get.generate_header_and_body

    expected = "GET /posts HTTP/1.1\r\n"      \
               "Host: localhost\r\n"          \
               "Origin: localhost\r\n"        \
               "Content-Length: 0\r\n"        \
               "Content-Type: text/plain\r\n" \
               "Connection: close\r\n\r\n"

    assert_equal expected, get.header
  end

  test "multipart body gets properly created" do
    post = HTTP.new(
      :host   => "localhost",
      :path   => "/photos",
      :method => "POST",
      :params => {
        "photo[title]"    => "Hello World",
        "photo[image]"    => File.open("/Users/hukl/Desktop/file1.png"),
        "photo[picture]"  => File.open("/Users/hukl/Desktop/file2.png")
      }
    )
    post.generate_header_and_body

    post.tcp_socket.write (post.header + post.body)
    response = post.tcp_socket.recvfrom(2**16)
    status = response.first.match(/HTTP\/1\.1\s(\d\d\d).+$/)[1]

    assert_equal 302, status.to_i
  end

  test "real get request" do
    get = HTTP.new(
      :host => "localhost",
      :path => "/photos"
    )

    get.tcp_socket.write (get.header + get.body)
    response = get.tcp_socket.recvfrom(2**16)
    status = response.first.match(/HTTP\/1\.1\s(\d\d\d).+$/)[1]

    assert_equal 200, status.to_i
  end
end
