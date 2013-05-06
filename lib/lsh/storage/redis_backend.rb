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
        Dir.mkdir(File.join(@data_dir, 'projections')) unless File.exists?(File.join(@data_dir, 'projections'))
      end

      def reset!
        clear_data!
        clear_projections!
      end

      def clear_data!
        keys = @redis.keys("lsh:bucket:*")
        @redis.del(keys) unless keys.empty?
        delete_dat_files_in_dir(@data_dir)
      end

      def clear_projections!
        @redis.del("lsh:parameters")
        @redis.del("lsh:buckets")
        delete_dat_files_in_dir(File.join(@data_dir, 'projections'))
      end

      def delete_dat_files_in_dir(dir)
        Dir.foreach(dir) {|f| File.delete(File.join(dir, f)) if f != '.' and f != '..' and f.end_with?('.dat')}
      end

      def has_index?
        parameters and projections and number_of_buckets > 0
      end

      def number_of_buckets
        @redis.get("lsh:buckets").to_i || 0
      end

      def projections=(projections)
        # Saving the projections to disk
        # (too slow to serialize and store in Redis for
        # large number of dimensions/projections)
        projections.each_with_index do |projection, i|
          projection.save(File.join(@data_dir, 'projections', "projection_#{i}.dat"))
        end
      end

      def projections
        return unless parameters
        @projections ||= (
          projections = []
          parameters[:number_of_independent_projections].times do |i|
            m = MathUtil.zeros(parameters[:number_of_random_vectors], parameters[:dim])
            m.load(File.join(@data_dir, 'projections', "projection_#{i}.dat"))
            projections << m
          end
          projections
        )
      end

      def parameters=(parms)
        parms[:window] = 'Infinity' if parms[:window] == Float::INFINITY
        @redis.set "lsh:parameters", parms.to_json
      end

      def parameters
        begin
          @parms ||= (
            parms = JSON.parse(@redis.get "lsh:parameters")
            parms.keys.each { |k| parms[k.to_sym] = parms[k]; parms.delete(k) }
            parms[:window] = Float::INFINITY if parms[:window] == 'Infinity'
            parms
          )
        rescue TypeError
          nil
        end 
      end

      def create_new_bucket
        @redis.incr "lsh:buckets"
      end

      def save_vector(vector)
        path = File.join(@data_dir, vector.hash.to_s+'.dat')
        vector.save(path) unless File.exists?(path)
      end

      def load_vector(hash)
        vector = MathUtil.zeros(1, parameters[:dim])
        vector.load(File.join(@data_dir, hash+'.dat'))
        vector
      end

      def add_vector_to_bucket(bucket, hash, vector)
        save_vector(vector) # Writing vector to disk if not already there
        @redis.sadd "#{bucket}:#{hash}", vector.hash.to_s # Only storing vector's hash in Redis
      end

      def add_vector_id(vector, id)
        save_vector(vector) # Writing vector to disk if not already there
        @redis.set "lsh:vector_to_id:#{vector.hash}", id
        @redis.set "lsh:id_to_vector:#{id}", vector.hash.to_s
      end

      def vector_to_id(vector)
        @redis.get "lsh:vector_to_id:#{vector.hash}"
      end

      def id_to_vector(id)
        vector_hash = @redis.get "lsh:id_to_vector:#{id}"
        load_vector(vector_hash)
      end

      def find_bucket(i)
        "lsh:bucket:#{i}"
      end

      def query_buckets(hashes)
        vector_hashes = []
        hashes.each_with_index do |hash, i|
          bucket = find_bucket(i)
          results = @redis.smembers("#{bucket}:#{hash}")
          vector_hashes += results if results
        end
        # Making sure we don't load the same vectors twice if they match
        # in different random projections
        vector_hashes.uniq!
        results = []
        vector_hashes.each do |vector_hash|
          vector = load_vector(vector_hash)
          results << vector
        end
        results
      end

    end

  end

end
