require 'redis'
require 'json'

module LSH

  class RedisIndex < Index
    # A LSH index backed by Redis

    def initialize(dim, k, w = Float::INFINITY, l = 150, redis_params = { :host => '127.0.0.1', :port => 6379 })
      connect(redis_params)
      super(dim, k, w, l)
    end

    def connect(params)
      @redis = Redis.new(params)
    end

    def create_new_empty_bucket
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
