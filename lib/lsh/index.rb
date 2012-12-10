require 'gsl'

module LSH

  class Index

    def initialize(dim, k, w = Float::INFINITY, l = 150)
      @random = GSL::Rng.alloc # default seed of 0
      @window = w
      @dim = dim
      @number_of_random_vectors = k
      @number_of_independent_projections = l
      @projections = generate_projections(dim, k, l)
      @buckets = []
      l.times { |i| @buckets << {} }
    end

    def add(vector)
      hashes(vector).each_with_index do |hash, i|
        if @buckets[i].has_key? hash
          @buckets[i][hash] << vector
        else
          @buckets[i][hash] = [vector]
        end
      end
    end

    def query(vector, number_of_buckets = 1)
      results = []
      hashes(vector).each_with_index do |hash, i|
        bucket = @buckets[i]
        sorted_keys = bucket.keys.sort { |k1, k2| (k1 - hash).abs <=> (k2 - hash).abs }
        sorted_keys = sorted_keys.first(number_of_buckets)
        sorted_keys.size.times.each do |k|
          results += bucket[sorted_keys[k]]
        end
      end
      results.uniq!
      results.sort { |r1, r2| vector * r2.col <=> vector * r1.col }
    end

    def hashes(vector)
      hashes = []
      @projections.each do |projection|
        hashes << hash(vector, projection)
      end
      hashes
    end

    def hash(vector, projection, bias = true)
      hash = []
      projection.each do |random_vector|
        dot_product = vector * random_vector.col
        if bias
          b = @random.uniform
        else
          b = 0.0
        end
        if @window == Float::INFINITY # Binary LSH
          if dot_product >= 0
            hash << 1
          else
            hash << 0
          end
        else
          b = bias ? @random.uniform : 0.0
          hash << (b + dot_product / @window).floor
        end
      end
      array_to_hash(hash)
    end

    def array_to_hash(array)
      # Derives a 28 bit hash value from an array of integers
      # http://stackoverflow.com/questions/2909106/python-whats-a-correct-and-good-way-to-implement-hash#2909572
      # TODO: Check it works for non-binary LSH
      return 0 if array.size == 0
      value = (array.first << 7)
      array.each do |v|
        value = (101 * value + v) & 0xffffff
      end
      value
    end

    def generate_projections(dim, k, l)
      projections = []
      l.times do |i|
        projections << generate_projection(dim, k)
      end
      projections
    end

    def generate_projection(dim, k)
      vectors = []
      k.times do |i|
        vectors << random_vector(dim)
      end
      vectors
    end

    def random_vector(dim)
      @random.gaussian(1, dim)
    end

  end

end
