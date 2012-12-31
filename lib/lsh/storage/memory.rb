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
      end

      def create_new_bucket
        @buckets ||= []
        @buckets << {}
      end

      def add_vector_to_bucket(bucket, hash, vector)
        if bucket.has_key? hash
          bucket[hash] << vector
        else
          bucket[hash] = [vector]
        end
      end

      def find_bucket(i)
        @buckets[i]
      end

      def query_buckets(hashes)
        results = []
        hashes.each_with_index do |hash, i|
          bucket = find_bucket(i)
          in_bucket = bucket[hash]
          results += in_bucket if in_bucket
        end
        results
      end

    end

  end

end
