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
      attr_accessor :vector_cache, :cache_vectors

      def initialize(params = {})
        defaults = {:redis => {}, :data_dir => "data", :cache_vectors => TRUE}
        params = defaults.merge params
        @redis = Redis.new(params[:redis])
        @data_dir = params[:data_dir]
        Dir.mkdir(@data_dir) unless File.exists?(@data_dir)
        Dir.mkdir(File.join(@data_dir, 'projections')) unless File.exists?(File.join(@data_dir, 'projections'))
        @cache_vectors = params[:cache_vectors]
        @vector_cache = {}
      end

      def reset!
        clear_data!
        clear_projections!
      end

      def clear_data!
        keys = @redis.keys("lsh:bucket:*")
        @redis.del(keys) unless keys.empty?
        delete_dat_files_in_dir(@data_dir)
        @redis.set("lsh:max_vector_id", 0)
        @vector_cache = {}
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

      def generate_id
        (@redis.incr "lsh:max_vector_id").to_s
      end

      def save_vector(vector, vector_id)
        path = File.join(@data_dir, vector_id+'.dat')
        raise "File #{path} already exists" if File.exists?(path)
        vector.save(path) 
        @vector_cache[vector_id] = vector if @cache_vectors
      end

      def load_vector(vector_id)
        @vector_cache[vector_id] || (
          vector = MathUtil.zeros(1, parameters[:dim])
          vector.load(File.join(@data_dir, vector_id+'.dat'))
          @vector_cache[vector_id] = vector if @cache_vectors
          vector
        )
      end

      def add_vector(vector, vector_id)
        save_vector(vector, vector_id) # Writing vector to disk if not already there
      end

      def add_vector_id_to_bucket(bucket, hash, vector_id)
        @redis.sadd "#{bucket}:#{hash}", vector_id
      end

      def id_to_vector(vector_id)
        load_vector(vector_id)
      end

      def find_bucket(i)
        "lsh:bucket:#{i}"
      end

      def query_buckets(hashes)
        keys = hashes.each_with_index.map do |hash, i|
          bucket = find_bucket(i)
          "#{bucket}:#{hash}"
        end
        result_ids = @redis.sunion(keys)

        result_ids.map do |vector_id|
          {
            :data => load_vector(vector_id),
            :id   => vector_id
          }
        end
      end

    end

  end

end
