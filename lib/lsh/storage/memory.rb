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

      def initialize
        reset!
      end

      def has_index?
        projections and parameters and @buckets
      end

      def reset!
        @buckets = []
        @vectors = {}
        @next_id = 0
      end

      def create_new_bucket
        @buckets << {}
      end

      def generate_id
        @next_id += 1
      end

      def add_vector(vector, id)
        @vectors[id] = vector
      end

      def add_vector_id_to_bucket(bucket, hash, vector_id)
        if bucket.has_key? hash
          bucket[hash] << vector_id
        else
          bucket[hash] = [vector_id]
        end
      end

      def id_to_vector(id)
        @vectors[id]
      end

      def find_bucket(i)
        @buckets[i]
      end

      def query_buckets(hashes)
        result_ids = {}
        hashes.each_with_index do |hash, i|
          vectors_hashes_in_bucket = @buckets[i][hash]
          if vectors_hashes_in_bucket
            vectors_hashes_in_bucket.each do |vector_id|
              result_ids[vector_id] = true
            end
          end
        end
        result_ids.keys.map do |vector_id|
          { 
            :data => @vectors[vector_id], 
            :id => vector_id, 
          }
        end
      end

    end

  end

end
