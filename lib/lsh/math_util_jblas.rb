require 'jblas'

module LSH

  class MathUtil

    def random_uniform
      JBLAS.rand[0,0]
    end

    def random_gaussian_vector(dim)
      JBLAS.randn(dim, 1)
    end

    def dot(v1, v2)
      (v1.t * v2)[0,0]
    end

    def norm(v)
      v.norm2
    end

  end

end
