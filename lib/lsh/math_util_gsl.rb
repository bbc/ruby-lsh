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

require 'gsl'
require 'json'

module LSH

  class MathUtil

    @@gsl_random = GSL::Rng.alloc

    def self.random_uniform
      @@gsl_random.uniform
    end

    def self.random_gaussian_vector(dim)
      @@gsl_random.gaussian(1, dim)
    end

    def self.random_gaussian_matrix(k, l)
      GSL::Matrix.randn(k, l)
    end

    def self.dot(v1, v2)
      v1 * v2.col
    end

    def self.norm(v)
      v.norm
    end

    def self.uniq(vs)
      # Can't use uniq as
      # [ v, JSON.parse(v.to_json) ].uniq.size == 2 with GSL
      results = []
      vs.each { |v| results << v unless results.member? v }
      results
    end

  end

end

module GSL

  class Vector

    def to_json(*a)
      {
        'json_class' => self.class.name,
        'data' => to_a,
      }.to_json(*a)
    end

    def self.json_create(o)
      alloc(*o['data'])
    end

    def hash
      to_a.hash
    end

  end

end
