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
      :path=>"/",
      :http_method=>"GET",
      :query => nil
    }
    assert_equal expected, request.options
  end

  test "method post" do
    assert_not_nil request = HTTP.post( "http://foobar.com" )
    expected = {
      :host=>"foobar.com",
      :port=>80,
      :path=>"/",
      :http_method=>"POST",
      :query => nil
    }
    assert_equal expected, request.options
  end

  test "method put" do
    assert_not_nil request = HTTP.put( "http://foobar.com" )
    expected = {
      :host=>"foobar.com",
      :port=>80,
      :path=>"/",
      :http_method=>"PUT",
      :query => nil
    }
    assert_equal expected, request.options
  end

  test "method delete" do
    assert_not_nil request = HTTP.delete( "http://foobar.com" )
    expected = {
      :host=>"foobar.com",
      :port=>80,
      :path=>"/",
      :http_method=>"DELETE",
      :query => nil
    }
    assert_equal expected, request.options
  end

  test "get request with advanced mode" do
    assert_not_nil request = HTTP.new(:host => "foobar.com")
    expected = {
      :host=>"foobar.com",
      :port=>80,
      :path=>"/",
      :http_method=>"GET",
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
      :path=>"/",
      :http_method=>"GET",
      :query => nil
    }
    assert_equal expected, request.options
  end

  test "mixed mode get with query params" do
    request = HTTP.get("http://foobar.com?foo=bar", :port => 3000)
    expected = {
      :host=>"foobar.com",
      :port=>3000,
      :path=>"/",
      :http_method=>"GET",
      :query => "foo=bar"
    }
    assert_equal expected, request.options
  end

  test "mixed mode get with query paramsi and inline port" do
    request = HTTP.get("http://foobar.com:3000?foo=bar")
    expected = {
      :host=>"foobar.com",
      :port=>3000,
      :path=>"/",
      :http_method=>"GET",
      :query => "foo=bar"
    }
    assert_equal expected, request.options
  end

  test "mixed mode get with query params and overriding port" do
    request = HTTP.get("http://foobar.com:2323?foo=bar", :port => 3000)
    expected = {
      :host=>"foobar.com",
      :port=>3000,
      :path=>"/",
      :http_method=>"GET",
      :query => "foo=bar"
    }
    assert_equal expected, request.options
  end 

  test "if multipart" do
    File.open(File.join(File.dirname(__FILE__), "fixtures", "yay.gif")) do |f|
      request = HTTP.post(
        "http://foo.com",
        :body => {:upload => f}
      )
      assert request.multipart?, "Should be multipart"
    end
  end

  test "if not multipart" do
    request = HTTP.post(
      "http://foo.com",
      :body => {:abstract => "bla", :title => "foo"}
    )
    assert !request.multipart?, "Should not be multipart"
  end

  test "http object has accessible options" do
    get = HTTP.new( {:host => "localhost", :query => {"foo" => "bar"}} )
    assert_not_nil get.options
    assert_equal ({"foo" => "bar"}), get.options[:query]
  end

  test "simple http object defaults to method GET" do
    get = HTTP.new( {:host => "localhost"} )
    assert_equal "GET", get.http_method
  end

  test "method of http object can be overridden" do
    post = HTTP.new( {:host => "localhost", :http_method => "POST"} )
    assert_equal "POST", post.http_method
  end

  test "path of a http object defaults to index" do
    get = HTTP.new( {:host => "localhost"} )
    assert_equal "/", get.options[:path]
  end

  test "path of http object can be set" do
    get = HTTP.new( {:host => "localhost", :path => "/posts"} )
    assert_equal "/posts", get.options[:path]
  end

  test "generate_header_and_body" do
    get = HTTP.new( {:host => "localhost", :path => "/posts"} )

    expected = "GET /posts HTTP/1.1\r\n"      \
               "Host: localhost\r\n"          \
               "Origin: localhost\r\n"        \
               "Content-Length: 0\r\n"        \
               "Content-Type: text/plain\r\n" \
               "Connection: close\r\n\r\n"

    assert_equal expected, get.header.to_s
  end

  #test "multipart body gets properly created" do
  #  post = HTTP.new(
  #    :host   => "localhost",
  #    :path   => "/photos",
  #    :http_method => "POST",
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
