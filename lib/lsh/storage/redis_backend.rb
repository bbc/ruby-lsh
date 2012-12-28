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

require 'redis'
require 'json'

module LSH

  module Storage

    class RedisBackend

      attr_reader :redis, :data_dir

      def initialize(params = { :redis => { :host => '127.0.0.1', :port => 6379 }, :data_dir => 'data' })
        @redis = Redis.new(params[:redis])
        @data_dir = params[:data_dir]
        Dir.mkdir(@data_dir) unless File.exists?(@data_dir)
      end

      def reset!
        @redis.flushall
        Dir.foreach(@data_dir) {|f| File.delete(File.join(@data_dir, f)) if f != '.' and f != '..' and f.end_with?('.dat')}
      end

      def has_index?
        projections and parameters and number_of_buckets > 0
      end

      def number_of_buckets
        @redis.get("buckets") || 0
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
        vector.save(File.join(@data_dir, vector.hash.to_s+'.dat')) # Writing vector to disk
        @redis.sadd "#{bucket}:#{hash}", vector.hash.to_s # Only storing vector's hash in Redis
      end

      def find_bucket(i)
        "bucket:#{i}" if @redis.get("buckets").to_i > i
      end

      def query_bucket(bucket, hash)
        results = []
        @redis.smembers("#{bucket}:#{hash}").map do |vector_hash|
          vector = MathUtil.zeros(parameters[:dim])
          vector.load(File.join(@data_dir, vector_hash+'.dat'))
          results << vector
        end
        results
      end

    end

  end

end
