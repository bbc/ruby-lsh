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
        unless File.exists?(@data_dir)
          Dir.mkdir(@data_dir)
          Dir.mkdir(File.join(@data_dir, 'projections'))
        end
      end

      def reset!
        @redis.flushall
        delete_dat_files_in_dir(@data_dir)
        delete_dat_files_in_dir(File.join(@data_dir, 'projections'))
      end

      def delete_dat_files_in_dir(dir)
        Dir.foreach(dir) {|f| File.delete(File.join(dir, f)) if f != '.' and f != '..' and f.end_with?('.dat')}
      end

      def has_index?
        parameters and projections and number_of_buckets > 0
      end

      def number_of_buckets
        @redis.get("buckets") || 0
      end

      def projections=(projections)
        # Saving the projections to disk
        # (too slow to serialize and store in Redis for
        # large number of dimensions/projections)
        projections.each_with_index do |projection, i|
          projection.each_with_index do |vector, j|
            vector.save(File.join(@data_dir, 'projections', "vector_#{i}_#{j}.dat"))
          end
        end
      end

      def projections
        return unless parameters
        @projections ||= (
          projections = []
          parameters[:number_of_independent_projections].times do |i|
            vectors = []
            parameters[:number_of_random_vectors].times do |j|
              v = MathUtil.zeros(parameters[:dim])
              v.load(File.join(@data_dir, 'projections', "vector_#{i}_#{j}.dat"))
              vectors << v
            end
            projections << vectors
          end
          projections
        )
      end

      def parameters=(parms)
        parms[:window] = 'Infinity' if parms[:window] == Float::INFINITY
        @redis.set "parameters", parms.to_json
      end

      def parameters
        begin
          @parms ||= (
            parms = JSON.parse(@redis.get "parameters")
            parms.keys.each { |k| parms[k.to_sym] = parms[k]; parms.delete(k) }
            parms[:window] = Float::INFINITY if parms[:window] == 'Infinity'
            parms
          )
        rescue TypeError
          nil
        end 
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

      def query_buckets(hashes)
        vector_hashes = []
        hashes.each_with_index do |hash, i|
          bucket = find_bucket(i)
          vector_hashes += @redis.smembers("#{bucket}:#{hash}")
        end
        vector_hashes.uniq!
        results = []
        vector_hashes.each do |vector_hash|
          vector = MathUtil.zeros(parameters[:dim])
          vector.load(File.join(@data_dir, vector_hash+'.dat'))
          results << vector
        end
        results
      end

    end

  end

end
