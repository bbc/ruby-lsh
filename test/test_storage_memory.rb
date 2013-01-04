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

class TestStorageMemory < Test::Unit::TestCase

  def setup
    @storage = LSH::Storage::Memory.new
  end

  def test_has_index
    assert (not @storage.has_index?)
    @storage.expects(:projections).returns(true)
    @storage.expects(:parameters).returns(true)
    @storage.create_new_bucket
    assert @storage.has_index?
  end

  def test_reset
    assert_equal nil, @storage.buckets
    @storage.create_new_bucket
    assert (not @storage.buckets.empty?)
    @storage.reset!
    assert_equal nil, @storage.buckets
  end

  def test_create_new_bucket_and_find_bucket
    @storage.create_new_bucket
    assert_equal 1, @storage.buckets.size
    assert_equal [], @storage.find_bucket(0).to_a
  end

  def test_add_vector_to_bucket_and_query_buckets
    @storage.create_new_bucket
    v = LSH::MathUtil.random_gaussian_vector(10)
    @storage.add_vector_to_bucket(@storage.find_bucket(0), 'hash', v)
    assert_equal v, @storage.buckets[0]['hash'].first
    assert_equal [v], @storage.query_buckets(['hash'])
  end

  def test_add_and_query_vector_id
    @storage.add_vector_id('foo', 'id')
    assert_equal 'id', @storage.vector_to_id('foo')
    assert_equal 'foo', @storage.id_to_vector('id')
  end

end
