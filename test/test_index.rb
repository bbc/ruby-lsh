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

class TestIndex < Test::Unit::TestCase

  def setup
    @parameters = {
      :dim => 10,
      :number_of_random_vectors => 8,
      :window => Float::INFINITY,
      :number_of_independent_projections => 50,
    }
    @index = LSH::Index.new(@parameters)
  end

  def test_initialize_and_generate_projections
    storage = LSH::Storage::Memory.new
    storage.expects(:create_new_bucket).times(50)
    index = LSH::Index.new(@parameters, storage)
    assert_equal 10, storage.parameters[:dim] 
    assert_equal 8, storage.parameters[:number_of_random_vectors]
    assert_equal Float::INFINITY, storage.parameters[:window]
    assert_equal 50, storage.parameters[:number_of_independent_projections] 
    projections = index.storage.projections
    assert_equal 50, projections.size
    assert_equal [8, 10], projections.first.size
  end

  def test_load
    storage = LSH::Storage::Memory.new
    storage.expects(:has_index?).at_least(1).returns(false)
    assert_equal nil, LSH::Index.load(storage)
    storage.expects(:has_index?).at_least(1).returns(true)
    storage.expects(:parameters).returns({})
    assert_equal storage, LSH::Index.load(storage).storage
  end

  def test_binary_hash
    v1 = @index.random_vector(10)
    hashes = @index.hashes(v1)
    assert_equal 50, hashes.size # One hash per projection
    assert_equal 8, hashes.first.size # Each hash has 8 components
    hashes.first.each { |h| assert (h == 0 or h == 1) } # Float::INFINITY => binary LSH
    # Testing the first hash element
    if (@index.storage.projections.first * v1.transpose)[0,0] >= 0
      assert_equal 1, hashes.first.first
    else
      assert_equal 0, hashes.first.first
    end
  end

  def test_integer_hash
    v1 = @index.random_vector(10)
    hashes = @index.hashes(v1)
    assert_equal 50, hashes.size # One hash per projection
    assert_equal 8, hashes.first.size # Each hash has 8 components
    hashes.first.each { |h| assert h.class == Fixnum } # Continuous LSH
    # Testing the first hash element
    first_hash_value = ( (@index.storage.projections.first * v1.transpose)[0,0]/ 10).floor
    assert (hashes.first.first == first_hash_value or hashes.first.first == first_hash_value + 1)
  end

  def test_order_vectors_by_similarity
    100.times do |i|
      v1 = @index.random_vector(10)
      v2 = @index.random_vector(10)
      v3 = @index.random_vector(10)
      d11 = @index.similarity(v1, v1)
      d12 = @index.similarity(v1, v2)
      d13 = @index.similarity(v1, v3)
      if d11 > d12 and d12 > d13
        assert_equal [v1, v2, v3], @index.order_vectors_by_similarity(v1, [v1,v2,v3])
      elsif d11 > d13 and d13 > d12
        assert_equal [v1, v3, v2], @index.order_vectors_by_similarity(v1, [v1,v2,v3])
      end
    end
  end

  def test_add
    v1 = @index.random_vector(10)
    @index.add(v1)
    assert_equal [v1], @index.storage.query_buckets([@index.array_to_hash(@index.hashes(v1)[0])])
  end

  def test_add_with_id
    v1 = @index.random_vector(10)
    @index.add(v1, 'id')
    assert_equal [v1], @index.storage.query_buckets([@index.array_to_hash(@index.hashes(v1)[0])])
    assert_equal 'id', @index.vector_to_id(v1)
    assert_equal v1, @index.id_to_vector('id')
  end

  def test_query
    100.times do |i|
      v1 = @index.random_vector_unit(10) # If not normed, there's no warranty another vector won't be more similar to v1 than itself
      @index.add(v1)
      assert_equal v1, @index.query(v1).first
    end
  end

  def test_query_ids_by_vector
    v1 = @index.random_vector(10)
    @index.add(v1, 'foo')
    assert_equal ['foo'], @index.query_ids_by_vector(v1)
  end

  def test_query_ids
    v1 = @index.random_vector(10)
    @index.add(v1, 'foo')
    assert_equal ['foo'], @index.query_ids('foo')
  end

  def test_multiprobe_hashes
    parms = @parameters.clone
    parms[:number_of_random_vectors] = 2
    index = LSH::Index.new(parms)
    h = [[1,0],[0,1]]
    assert_equal [], index.multiprobe_hashes_arrays(h, 0)
    assert_equal [[[0,0],[1,1]],[[1,1],[0,0]]], index.multiprobe_hashes_arrays(h, 1)
    assert_equal [[[0,0],[1,1]],[[1,1],[0,0]],[[0,1],[1,0]]], index.multiprobe_hashes_arrays(h, 2)
  end

  def test_multiprobe_query
    v1 = @index.random_vector(10)
    hash_array = @index.hashes(v1)[0]
    hash_array[0] = (hash_array[0] == 0) ? 1 : 0 # We flip the first bit of the first hash
    # We insert v1 at hamming distance 1 of its real hash
    bucket = @index.storage.find_bucket(0)
    @index.storage.add_vector_to_bucket(bucket, @index.array_to_hash(hash_array), v1)
    # But we should still be able to retrieve v1 with multiprobe radius 1
    assert_equal [v1], @index.query(v1, 1) 
    # It should return no results with no multiprobes
    assert @index.query(v1, 0).empty?
  end

  def test_multiprobe_query_non_binary
    parms = @parameters.clone
    parms[:window] = 2
    index = LSH::Index.new(parms)
    v = @index.random_vector(10)
    assert_raise Exception do
      index.query(v, 1)
    end
  end

end
