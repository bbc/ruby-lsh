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
require 'tmpdir'

class TestStorageRedis < Test::Unit::TestCase

  def setup
    @redis = MockRedis.new
    Redis.expects(:new).returns(@redis)
    @storage = LSH::Storage::RedisBackend.new(:data_dir => File.join(Dir.tmpdir, 'ruby-lsh-test-data'))
    @parameters = {
      :dim => 10,
      :number_of_random_vectors => 8,
      :window => Float::INFINITY,
      :number_of_independent_projections => 5,
    }
  end

  def test_initialize
    assert_equal @redis, @storage.redis
    assert File.exists? File.join(Dir.tmpdir, 'ruby-lsh-test-data')
    assert File.exists? File.join(Dir.tmpdir, 'ruby-lsh-test-data', 'projections')
  end

  def test_has_index
    assert (not @storage.has_index?)
    index = LSH::Index.new(@parameters, @storage)
    assert (@storage.has_index?)
  end

  def test_reset
    index = LSH::Index.new(@parameters, @storage)
    v = index.random_vector(10)
    @storage.add_vector_to_bucket(@storage.find_bucket(0), 'hash', v)
    assert (@storage.has_index?)
    @storage.reset!
    assert (not @storage.has_index?)
    Dir.foreach(@storage.data_dir) { |f| assert (not f.end_with?('.dat')) } # No vectors
    Dir.foreach(File.join(@storage.data_dir, 'projections')) { |f| assert (not f.end_with?('.dat')) } # And no projections
  end

  def test_clear_data
    index = LSH::Index.new(@parameters, @storage)
    v = index.random_vector(10)
    @storage.add_vector_to_bucket(@storage.find_bucket(0), 'hash', v)
    @storage.clear_data!
    assert @storage.has_index? # Storage still has an index
    assert @storage.query_buckets(['hash']).empty? # But no data anymore
    Dir.foreach(@storage.data_dir) { |f| assert (not f.end_with?('.dat')) } # No vectors
  end

  def test_clear_projections
    index = LSH::Index.new(@parameters, @storage)
    assert @storage.has_index?
    @storage.clear_projections!
    assert (not @storage.has_index?)
    Dir.foreach(File.join(@storage.data_dir, 'projections')) { |f| assert (not f.end_with?('.dat')) } # And no projections
  end

  def test_projections
    assert_equal nil, @storage.projections
    index = LSH::Index.new(@parameters, @storage)
    assert_equal 5, @storage.projections.size
    v = LSH::MathUtil.zeros(8, 10)
    v.load(File.join(Dir.tmpdir, 'ruby-lsh-test-data', 'projections', 'projection_2.dat'))
    assert_equal v, @storage.projections[2]
  end

  def test_parameters
    assert_equal nil, @storage.parameters
    index = LSH::Index.new(@parameters, @storage)
    assert_equal Float::INFINITY, @storage.parameters[:window]
    assert_equal 10, @storage.parameters[:dim]
    assert_equal 8, @storage.parameters[:number_of_random_vectors]
    assert_equal 5, @storage.parameters[:number_of_independent_projections]
  end

  def test_create_new_bucket
    assert_equal nil, @redis.get("lsh:buckets")
    @storage.create_new_bucket
    assert_equal 1, @redis.get("lsh:buckets")
    @storage.create_new_bucket
    assert_equal 2, @redis.get("lsh:buckets")
  end

  def test_add_vector_to_bucket_find_query
    index = LSH::Index.new(@parameters, @storage)
    v = index.random_vector(10)
    @storage.add_vector_to_bucket(@storage.find_bucket(0), 'hash', v)
    assert_equal [v], @storage.query_buckets(['hash'])
  end

  def test_add_and_query_vector_id
    index = LSH::Index.new(@parameters, @storage)
    v = index.random_vector(10)
    @storage.add_vector_id(v, 'id')
    @storage.add_vector_to_bucket(@storage.find_bucket(0), 'hash', v)
    assert_equal 'id', @storage.vector_to_id(v)
    assert_equal v, @storage.id_to_vector('id')
  end

end

class MockRedis

  def initialize
    @data = {}
  end

  def get(key)
    @data[key]
  end

  def set(key, value)
    @data[key] = value
  end

  def incr(key)
    @data[key] ||= 0
    @data[key] += 1
  end

  def sadd(key, el)
    @data[key] ||= []
    @data[key] << el
  end

  def smembers(key)
    @data[key]
  end

  def keys(pattern)
    keys = @data.keys.select { |k| k =~ %r{#{pattern.gsub('*', '.*')}} }
    keys
  end

  def del(*keys)
    keys.flatten.each { |k| @data.delete(k) }
  end

end
