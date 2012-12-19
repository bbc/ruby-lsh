module LSH

  module Storage

    class Memory

      attr_accessor :projections
      attr_accessor :parameters

      def has_index?
        projections and parameters and @buckets
      end

      def reset!
        @buckets = nil
      end

      def create_new_bucket
        @buckets ||= []
        @buckets << {}
        @buckets.size - 1 # Returns index of newly created bucket
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

      def query_bucket(bucket, hash)
        bucket[hash]
      end

    end

  end

end
