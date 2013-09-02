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

    attr_reader :storage

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
      id ||= storage.generate_id
      storage.add_vector(vector, id)
      hashes(vector).each_with_index do |hash, i|
        hash_i = hash_to_int(hash)
        bucket = storage.find_bucket(i)
        storage.add_vector_id_to_bucket(bucket, hash_i, id)
      end
      id
    end
    
    def id_to_vector(id)
      storage.id_to_vector(id)
    end

    def query(vector, multiprobe_radius = 0)
      hash_arrays = hashes(vector)
      hashes = hash_arrays.map { |a| hash_to_int(a) }
      results = storage.query_buckets(hashes)
      # Multiprobe LSH
      # Take query hashes, move them around at radius r, and use them to do another query
      # TODO: only works for binary LSH atm
      if multiprobe_radius > 0
        raise Exception.new("Non-zero multiprobe radius only implemented for binary LSH") unless hashes_are_binary?
        mp_arrays = multiprobe_hashes_arrays(hash_arrays, multiprobe_radius)
        mp_arrays.each do |probes_arrays|
          probes_hashes = probes_arrays.map { |a| hash_to_int(a) }
          results += storage.query_buckets(probes_hashes)
        end
        results.uniq! { |result| result[:id] }
      end
      order_results_by_similarity(vector, results)
    end

    def query_ids(id, multiprobe_radius = 0)
      vector = id_to_vector(id)
      query_ids_by_vector(vector, multiprobe_radius)
    end

    def query_ids_by_vector(vector, multiprobe_radius = 0)
      results = query(vector, multiprobe_radius)
      results.map { |result| result[:id] }
    end

    def multiprobe_hashes_arrays(hash_arrays, multiprobe_radius)
      mp_arrays = []
      (1..multiprobe_radius).to_a.each do |radius|
        (0..(storage.parameters[:number_of_random_vectors] - 1)).to_a.combination(radius).each do |flips|
          probes = hash_arrays.map { |probe| flips.inject(probe) { |probe, d| probe ^ (1 << d) } }
          mp_arrays << probes
        end
      end
      mp_arrays
    end

    def order_results_by_similarity(vector, results)
      vector_t = vector.transpose
      results.sort_by { |result| similarity(result[:data], vector_t) } .reverse
    end

    def hashes(vector)
      hashes = []
      storage.projections.each do |projection|
        hashes << hash(vector, projection)
      end
      hashes
    end
 
    def hash(vector, projection, bias = true)
      dot_products = (projection * vector.transpose).column(0).to_a
      window = storage.parameters[:window]

      if window == Float::INFINITY # Binary LSH
        dot_products.inject(0) do |hash, dot_product|
          (hash << 1) + (dot_product >= 0 ? 1 : 0)
        end
      else
        dot_products.map do |dot_product|
          b = bias ? MathUtil.random_uniform : 0.0
          (b + dot_product / window).floor
        end
      end
    end

    def hashes_are_binary?
      storage.parameters[:window] == Float::INFINITY
    end

    def random_vector(dim)
      MathUtil.random_gaussian_matrix(1, dim)
    end

    def random_vector_unit(dim)
      r = random_vector(dim)
      r /= MathUtil.norm(r)
    end

    def hash_to_int(hash)
      # Convert the output of 'hash' to an integer used in the index. For
      # binary lsh, we use the base-10 representation of the binary hash; for
      # integer lsh, use MD5 truncated to 32 bits.
      if storage.parameters[:window] == Float::INFINITY
        hash
      else
        Digest::MD5.new().digest(hash.to_json).slice(0,4).unpack('N')[0]
      end
    end

     def generate_projections(dim, k, l)
      projections = []
      l.times do |i|
        projections << generate_projection(dim, k)
      end
      projections
    end

    def generate_projection(dim, k)
      MathUtil.random_gaussian_matrix(k, dim)
     end

    def similarity(v1, v2)
      MathUtil.dot(v1, v2)
    end

    def inspect
      "#<LSH index; dimension: #{storage.parameters[:dim]}; window size: #{storage.parameters[:window]}; #{storage.parameters[:number_of_random_vectors]} random vectors; #{storage.parameters[:number_of_independent_projections]} independent projections>"
    end

  end

end
