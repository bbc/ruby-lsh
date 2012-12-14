require 'gsl'

module LSH

  class MathUtil

    def initialize
      @gsl_random = GSL::Rng.alloc
      @gsl_random.set(rand(1000)) # Overriding seed
    end

    def random_uniform
      @gsl_random.uniform
    end

    def random_gaussian_vector(dim)
      @gsl_random.gaussian(1, dim)
    end

    def dot(v1, v2)
      v1 * v2.col
    end

  end

end
