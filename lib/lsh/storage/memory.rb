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

  module Storage

    class Memory

      attr_accessor :projections
      attr_accessor :parameters
      attr_reader   :buckets

      def has_index?
        projections and parameters and @buckets
      end

      def reset!
        @buckets = nil
        @vectors = nil
        @vector_hash_to_id = nil
        @id_to_vector = nil
      end

      def create_new_bucket
        @buckets ||= []
        @buckets << {}
      end

      def add_vector(vector, vector_hash)
        @vectors ||= {}
        @vectors[vector_hash] = vector
      end

      def add_vector_hash_to_bucket(bucket, hash, vector_hash)
        if bucket.has_key? hash
          bucket[hash] << vector_hash
        else
          bucket[hash] = [vector_hash]
        end
      end

      def add_vector_id(vector_hash, id)
        @vector_hash_to_id ||= {}
        @vector_hash_to_id[vector_hash] = id
        @id_to_vector ||= {}
        @id_to_vector[id] = vector_hash
      end

      def vector_hash_to_id(vector_hash)
        @vector_hash_to_id[vector_hash] if @vector_hash_to_id
      end

      def id_to_vector(id)
        @vectors[@id_to_vector[id]] if @id_to_vector
      end

      def find_bucket(i)
        @buckets[i]
      end

      def query_buckets(hashes)
        results_hashes = {}
        hashes.each_with_index do |hash, i|
          vectors_hashes_in_bucket = @buckets[i][hash]
          if vectors_hashes_in_bucket
            vectors_hashes_in_bucket.each do |vector_hash|
              results_hashes[vector_hash] = true
            end
          end
        end
        results_hashes.keys.map { |vector_hash| @vectors[vector_hash] }
      end

    end

  end

end
