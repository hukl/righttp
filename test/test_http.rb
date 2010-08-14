require 'helper'

class TestHttp < Test::Unit::TestCase

  test "cannot create HTTP object without any parameters" do
    assert_raise( ArgumentError) { HTTP.new }
  end

  test "request can be built with one argument" do
    assert_not_nil HTTP.new( "http://foobar.com" )
  end

  test "request can be built with two or more arguments" do
    assert_not_nil HTTP.new( "http://fooobar.com", :params => { 1 => 2} )
  end

  test "method get" do
    assert_not_nil request = HTTP.get( "http://foobar.com" )
    expected = {
      :host=>"foobar.com",
      :port=>80,
      :path=>"",
      :method=>"GET",
      :query => nil
    }
    assert_equal expected, request.options
  end

  test "method post" do
    assert_not_nil request = HTTP.post( "http://foobar.com" )
    expected = {
      :host=>"foobar.com",
      :port=>80,
      :path=>"",
      :method=>"POST",
      :query => nil
    }
    assert_equal expected, request.options
  end

  test "method put" do
    assert_not_nil request = HTTP.put( "http://foobar.com" )
    expected = {
      :host=>"foobar.com",
      :port=>80,
      :path=>"",
      :method=>"PUT",
      :query => nil
    }
    assert_equal expected, request.options
  end

  test "method delete" do
    assert_not_nil request = HTTP.delete( "http://foobar.com" )
    expected = {
      :host=>"foobar.com",
      :port=>80,
      :path=>"",
      :method=>"DELETE",
      :query => nil
    }
    assert_equal expected, request.options
  end

  test "other missing methods are delegated to super" do
    assert_raise( ArgumentError ) { HTTP.foobar( "http://foobar.com" ) }
  end

  test "mixed mode get" do
    request = HTTP.get("http://foobar.com", :port => 3000)
    expected = {
      :host=>"foobar.com",
      :port=>3000,
      :path=>"",
      :method=>"GET",
      :query => nil
    }
    assert_equal expected, request.options
  end

  test "mixed mode get with query params" do
    request = HTTP.get("http://foobar.com?foo=bar", :port => 3000)
    expected = {
      :host=>"foobar.com",
      :port=>3000,
      :path=>"",
      :method=>"GET",
      :query => "foo=bar"
    }
    assert_equal expected, request.options
  end

  test "mixed mode get with query paramsi and inline port" do
    request = HTTP.get("http://foobar.com:3000?foo=bar")
    expected = {
      :host=>"foobar.com",
      :port=>3000,
      :path=>"",
      :method=>"GET",
      :query => "foo=bar"
    }
    assert_equal expected, request.options
  end

  test "mixed mode get with query params and overriding port" do
    request = HTTP.get("http://foobar.com:2323?foo=bar", :port => 3000)
    expected = {
      :host=>"foobar.com",
      :port=>3000,
      :path=>"",
      :method=>"GET",
      :query => "foo=bar"
    }
    assert_equal expected, request.options
  end 

  #test "create the simplest http get object" do
  #  assert_not_nil get = HTTP.new( {:host => "localhost"} )
  #end

  #test "to create a http object at least the host must be specified" do
  #  assert_raise(ArgumentError) { get = HTTP.new( {} ) }
  #end

  #test "http objects have accessible socket object" do
  #  get = HTTP.new( {:host => "localhost"} )
  #  assert_not_nil get.tcp_socket
  #end

  #test "http object has accessible params" do
  #  get = HTTP.new( {:host => "localhost", :params => {"foo" => "bar"}} )
  #  assert_not_nil get.params
  #  assert_equal ({"foo" => "bar"}), get.params
  #end

  #test "http object without params specified returns empty params" do
  #  get = HTTP.new( {:host => "localhost"} )
  #  assert_not_nil get.params
  #  assert_equal ({}), get.params
  #end

  #test "simple http object defaults to method GET" do
  #  get = HTTP.new( {:host => "localhost"} )
  #  assert_equal "GET", get.method
  #end

  #test "method of http object can be overridden" do
  #  post = HTTP.new( {:host => "localhost", :method => "POST"} )
  #  assert_equal "POST", post.method
  #end

  #test "path of a http object defaults to index" do
  #  get = HTTP.new( {:host => "localhost"} )
  #  assert_equal "/", get.path
  #end

  #test "path of http object can be set" do
  #  get = HTTP.new( {:host => "localhost", :path => "/posts"} )
  #  assert_equal "/posts", get.path
  #end

  #test "generate_header_and_body" do
  #  get = HTTP.new( {:host => "localhost", :path => "/posts"} )
  #  assert_not_nil get.generate_header_and_body

  #  expected = "GET /posts HTTP/1.1\r\n"      \
  #             "Host: localhost\r\n"          \
  #             "Origin: localhost\r\n"        \
  #             "Content-Length: 0\r\n"        \
  #             "Content-Type: text/plain\r\n" \
  #             "Connection: close\r\n\r\n"

  #  assert_equal expected, get.header
  #end

  #test "multipart body gets properly created" do
  #  post = HTTP.new(
  #    :host   => "localhost",
  #    :path   => "/photos",
  #    :method => "POST",
  #    :params => {
  #      "photo[title]"    => "Hello World",
  #      "photo[image]"    => File.open("/Users/hukl/Desktop/file1.png"),
  #      "photo[picture]"  => File.open("/Users/hukl/Desktop/file2.png")
  #    }
  #  )
  #  post.generate_header_and_body

  #  post.tcp_socket.write (post.header + post.body)
  #  response = post.tcp_socket.recvfrom(2**16)
  #  status = response.first.match(/HTTP\/1\.1\s(\d\d\d).+$/)[1]

  #  assert_equal 302, status.to_i
  #end

  #test "real get request" do
  #  get = HTTP.new(
  #    :host => "localhost",
  #    :path => "/photos"
  #  )

  #  get.tcp_socket.write (get.header + get.body)
  #  response = get.tcp_socket.recvfrom(2**16)
  #  status = response.first.match(/HTTP\/1\.1\s(\d\d\d).+$/)[1]

  #  assert_equal 200, status.to_i
  #end
end
