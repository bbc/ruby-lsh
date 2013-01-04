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

module LSH

  class Index

    attr_reader :projections, :buckets, :storage

    def initialize(parameters = {}, storage = LSH::Storage::Memory.new)
      @storage = storage
      unless storage.has_index?
        storage.parameters = parameters
        # Initializing projections and buckets
        storage.projections = generate_projections(
          parameters[:dim], 
          parameters[:number_of_random_vectors], 
          parameters[:number_of_independent_projections]
        )
        parameters[:number_of_independent_projections].times { |i| storage.create_new_bucket }
      end
    end

    def self.load(storage)
      Index.new(storage.parameters, storage) if storage.has_index? 
    end

    def add(vector, id = nil)
      storage.add_vector_id(vector, id) if id
      hashes(vector).each_with_index do |hash, i|
        hash_i = array_to_hash(hash)
        bucket = storage.find_bucket(i)
        storage.add_vector_to_bucket(bucket, hash_i, vector)
      end
    end

    def vector_id(vector)
      storage.vector_id(vector)
    end

    def query(vector, multiprobe_radius = 0)
      hash_arrays = hashes(vector)
      hashes = hash_arrays.map { |a| array_to_hash(a) }
      results = storage.query_buckets(hashes)
      # Multiprobe LSH
      # Take query hashes, move them around at radius r, and use them to do another query
      # TODO: only works for binary LSH atm
      if multiprobe_radius > 0
        mp_arrays = multiprobe_hashes_arrays(hash_arrays, multiprobe_radius)
        mp_arrays.each do |probes_arrays|
          probes_hashes = probes_arrays.map { |a| array_to_hash(a) }
          results += storage.query_buckets(probes_hashes)
        end
      end
      results = MathUtil.uniq(results)
      order_vectors_by_similarity(vector, results)
    end

    def multiprobe_hashes_arrays(hash_arrays, multiprobe_radius)
      mp_arrays = []
      (1..multiprobe_radius).to_a.each do |radius|
        (0..(storage.parameters[:number_of_random_vectors] - 1)).to_a.combination(radius).each do |flips|
          probes = Marshal.load(Marshal.dump(hash_arrays))
          probes.each { |probe| flips.each { |d| probe[d] = (probe[d] == 1) ? 0 : 1 } }
          mp_arrays << probes
        end
      end
      mp_arrays
    end

    def order_vectors_by_similarity(vector, vectors)
      vectors.map { |v| [ v, similarity(vector, v) ] } .sort_by { |v, sim| sim } .reverse .map { |vs| vs[0] }
    end

    def hashes(vector)
      hashes = []
      storage.projections.each do |projection|
        hashes << hash(vector, projection)
      end
      hashes
    end

    def hash(vector, projection, bias = true)
      hash = []
      projection.each do |random_vector|
        dot_product = similarity(vector, random_vector)
        window = storage.parameters[:window]
        if window == Float::INFINITY # Binary LSH
          if dot_product >= 0
            hash << 1
          else
            hash << 0
          end
        else
          b = bias ? MathUtil.random_uniform : 0.0
          hash << (b + dot_product / window).floor
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
      r /= MathUtil.norm(r)
    end

    def random_vector(dim)
      MathUtil.random_gaussian_vector(dim)
    end

    def similarity(v1, v2)
      MathUtil.dot(v1, v2)
    end

    def inspect
      "#<LSH index; dimension: #{storage.parameters[:dim]}; window size: #{storage.parameters[:window]}; #{storage.parameters[:number_of_random_vectors]} random vectors; #{storage.parameters[:number_of_independent_projections]} independent projections>"
    end

  end

end
