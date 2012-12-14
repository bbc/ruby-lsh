require 'helper'

class TestIndex < Test::Unit::TestCase

  def test_initialize_and_generate_projections
    index = LSH::Index.new(10, 8, Float::INFINITY, 50)
    projections = index.projections
    assert_equal 50, projections.size
    assert_equal 8, projections.first.size
    buckets  = index.buckets
    assert_equal 50, buckets.size
  end

  def test_binary_hash
    index = LSH::Index.new(10, 8, Float::INFINITY, 2)
    v1 = index.random_vector(10)
    hashes = index.hashes(v1)
    assert_equal 2, hashes.size # One hash per projection
    assert_equal 8, hashes.first.size # Each hash has 8 components
    hashes.first.each { |h| assert (h == 0 or h == 1) } # Float::INFINITY => binary LSH
    # Testing the first hash element
    if index.similarity(v1, index.projections.first.first) >= 0
      assert_equal 1, hashes.first.first
    else
      assert_equal 0, hashes.first.first
    end
  end

  def test_integer_hash
    index = LSH::Index.new(10, 8, 10, 2)
    v1 = index.random_vector(10)
    hashes = index.hashes(v1)
    assert_equal 2, hashes.size # One hash per projection
    assert_equal 8, hashes.first.size # Each hash has 8 components
    hashes.first.each { |h| assert h.class == Fixnum } # Continuous LSH
    # Testing the first hash element
    first_hash_value = (index.similarity(v1, index.projections.first.first) / 10).floor
    assert (hashes.first.first == first_hash_value or hashes.first.first == first_hash_value + 1)
  end

  def test_order_vectors_by_similarity
    index = LSH::Index.new(10, 8, Float::INFINITY, 2)
    100.times do |i|
      v1 = index.random_vector(10)
      v2 = index.random_vector(10)
      v3 = index.random_vector(10)
      d11 = index.similarity(v1, v1)
      d12 = index.similarity(v1, v2)
      d13 = index.similarity(v1, v3)
      if d11 > d12 and d12 > d13
        assert_equal [v1, v2, v3], index.order_vectors_by_similarity(v1, [v1,v2,v3])
      elsif d11 > d13 and d13 > d12
        assert_equal [v1, v3, v2], index.order_vectors_by_similarity(v1, [v1,v2,v3])
      end
    end
  end

  def test_add
    index = LSH::Index.new(10, 8, Float::INFINITY, 1)
    v1 = index.random_vector(10)
    index.add(v1)
    assert_equal [v1], index.buckets[0][index.array_to_hash(index.hashes(v1)[0])]
  end

  def test_query
    index = LSH::Index.new(10, 8, Float::INFINITY, 1)
    100.times do |i|
      v1 = index.random_vector_unit(10) # If not normed, there's no warranty another vector won't be more similar to v1 than itself
      index.add(v1)
      assert_equal v1, index.query(v1).first
    end
  end

end
