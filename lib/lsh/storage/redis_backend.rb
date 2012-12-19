require 'redis'

module LSH

  module Storage

    class RedisBackend

      def initialize(params = { :redis => { :host => '127.0.0.1', :port => 6379 } })
        @redis = Redis.new(params[:redis])
      end

      def create_new_bucket
        @redis.incr "buckets"
      end

      def add_vector_to_bucket(bucket, hash, vector)
        @redis.sadd "#{bucket}:#{hash}", vector.to_json
      end

      def find_bucket(i)
        "bucket:#{i}" if @redis.get("buckets").to_i > i
      end

      def query_bucket(bucket, hash)
        @redis.smembers("#{bucket}:#{hash}").map { |vector_json| JSON.parse(vector_json) }
      end

    end

  end

end
