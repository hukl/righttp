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

end
