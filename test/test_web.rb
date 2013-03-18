# ruby-lsh
#
# Copyright (c) 2012 British Broadcasting Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'helper'
require 'rack/test'

ENV['RACK_ENV'] = 'test'

class TestWeb < Test::Unit::TestCase
  include Rack::Test::Methods

  def setup
    @parameters = {
      :dim => 10,
      :number_of_random_vectors => 8,
      :window => Float::INFINITY,
      :number_of_independent_projections => 50,
    }
    @index = LSH::Index.new(@parameters)
    @web = LSH::Web.new(@index)
  end

  def app
    @web
  end

  def test_home
    get '/'
    assert last_response.ok?
    assert_equal '{"index":"#<LSH index; dimension: 10; window size: Infinity; 8 random vectors; 50 independent projections>"}', last_response.body
  end

  def test_index
    v = @index.random_vector(10)
    post '/index', :data => v.to_json
    assert last_response.ok?
    assert_equal 'indexed', JSON.parse(last_response.body)['status']
  end

  def test_index_no_data
    post '/index'
    assert (not last_response.ok?)
  end

  def test_query
    v = @index.random_vector(10)
    post '/query', :data => v.to_json
    assert last_response.ok?
    assert JSON.parse(last_response.body)['results'].empty?
    post '/index', :data => v.to_json, :id => 'foo'
    post '/query', :data => v.to_json
    assert last_response.ok?
    assert_equal 1, JSON.parse(last_response.body)['results'].size
    assert_equal v, JSON.parse(last_response.body, :create_additions => true)['results'].first['data']
    assert_equal nil, JSON.parse(last_response.body)['results'].first['id'] # No id
    post '/query', :data => v.to_json, :include => 'id'
    assert last_response.ok?
    assert_equal 1, JSON.parse(last_response.body)['results'].size
    assert_equal v, JSON.parse(last_response.body, :create_additions => true)['results'].first['data']
    assert_equal 'foo', JSON.parse(last_response.body)['results'].first['id'] # id is included
  end

  def test_query_no_data
    post '/query'
    assert (not last_response.ok?)
  end

  def test_query_ids
    v = @index.random_vector(10)
    post '/query-ids', :data => v.to_json
    assert last_response.ok?
    assert JSON.parse(last_response.body)['results'].empty?
    post '/query-ids', :id => 'foo'
    assert (not last_response.ok?) # id doesn't exist
    post '/index', :data => v.to_json, :id => 'foo'
    post '/query-ids', :data => v.to_json
    assert last_response.ok?
    assert_equal ['foo'], JSON.parse(last_response.body)['results']
    post '/query-ids', :id => 'foo'
    assert last_response.ok?
    assert_equal ['foo'], JSON.parse(last_response.body)['results']
  end

end
