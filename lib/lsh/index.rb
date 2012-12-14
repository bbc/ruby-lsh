# ruby-lsh
#
# Copyright (c) 2011 British Broadcasting Corporation
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

module LSH

  class Index

    attr_reader :projections, :buckets

    def initialize(dim, k, w = Float::INFINITY, l = 150)
      @math = MathUtil.new
      @window = w
      @dim = dim
      @number_of_random_vectors = k
      @number_of_independent_projections = l
      @projections = generate_projections(dim, k, l)
      @buckets = []
      l.times { |i| @buckets << {} }
    end

    def add(vector)
      hashes(vector).each_with_index do |hash, i|
        hash_i = array_to_hash(hash)
        if @buckets[i].has_key? hash_i
          @buckets[i][hash_i] << vector
        else
          @buckets[i][hash_i] = [vector]
        end
      end
    end

    def query(vector, multiprobe_radius = 0)
      results = []
      hashes(vector).each_with_index do |hash, i|
        hash_i = array_to_hash(hash)
        bucket = @buckets[i]
        # Take query hash, move it around at radius r, hash it and use the result as a query
        # TODO: only works for binary LSH atm
        results += bucket[hash_i] if bucket[hash_i]
        if multiprobe_radius > 0
          (1..multiprobe_radius).to_a.each do |radius|
            (0..(@number_of_random_vectors - 1)).to_a.combination(radius).each do |flips|
              probe = hash.clone
              flips.each { |d| probe[d] = (probe[d] == 1) ? 0 : 1  }
              probe_hash = array_to_hash(probe)
              results += bucket[probe_hash] if bucket.has_key?(probe_hash)
            end
          end
        end
      end
      results.uniq!
      order_vectors_by_similarity(vector, results)
    end

    def order_vectors_by_similarity(vector, vectors)
      vectors.map { |v| [ v, similarity(vector, v) ] } .sort_by { |v, sim| sim } .reverse .map { |vs| vs[0] }
    end

    def hashes(vector)
      hashes = []
      @projections.each do |projection|
        hashes << hash(vector, projection)
      end
      hashes
    end

    def hash(vector, projection, bias = true)
      hash = []
      projection.each do |random_vector|
        dot_product = similarity(vector, random_vector)
        if @window == Float::INFINITY # Binary LSH
          if dot_product >= 0
            hash << 1
          else
            hash << 0
          end
        else
          b = bias ? @math.random_uniform : 0.0
          hash << (b + dot_product / @window).floor
        end
      end
      hash
    end

    def array_to_hash(array)
      return array.hash
      # Derives a 28 bit hash value from an array of integers
      # http://stackoverflow.com/questions/2909106/python-whats-a-correct-and-good-way-to-implement-hash#2909572
      # TODO: Check it works for non-binary LSH
      #return 0 if array.size == 0
      #value = (array.first << 7)
      #array.each do |v|
      #  value = (101 * value + v) & 0xffffff
      #end
      #value
    end

    def generate_projections(dim, k, l)
      projections = []
      l.times do |i|
        projections << generate_projection(dim, k)
      end
      projections
    end

    def generate_projection(dim, k)
      vectors = []
      k.times do |i|
        vectors << random_vector(dim)
      end
      vectors
    end

    def random_vector_unit(dim)
      r = random_vector(dim)
      r /= @math.norm(r)
    end

    def random_vector(dim)
      @math.random_gaussian_vector(dim)
    end

    def similarity(v1, v2)
      @math.dot(v1, v2)
    end

  end

end
