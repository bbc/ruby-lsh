require 'redis'
require 'json'

module LSH

  module Storage

    class RedisBackend

      attr_reader :redis

      def initialize(params = { :redis => { :host => '127.0.0.1', :port => 6379 } })
        @redis = Redis.new(params[:redis])
      end

      def reset!
        @redis.flushall
      end

      def has_index?
        projections and parameters and @redis.get("buckets") > 0
      end

      def projections=(projections)
        @redis.set "projections", projections.to_json
      end

      def projections
        begin
          @projections ||= JSON.parse(@redis.get "projections")
        rescue TypeError
          nil
        end
      end

      def parameters=(parms)
        parms[:window] = 'Infinity' if parms[:window] == Float::INFINITY
        @redis.set "parameters", parms.to_json
      end

      def parameters
        @parms ||= (
          parms = JSON.parse(@redis.get "parameters")
          parms.keys.each { |k| parms[k.to_sym] = parms[k]; parms.delete(k) }
          parms[:window] = Float::INFINITY if parms[:window] == 'Infinity'
          parms
        )
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
