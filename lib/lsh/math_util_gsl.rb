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

    def self.zeros(k, l)
      GSL::Matrix.alloc(k, l)
    end

    def self.random_gaussian_vector(dim)
      @@gsl_random.gaussian(1, dim)
    end

    def self.random_gaussian_matrix(k, l)
      matrix = zeros(k, l)
      (0..(k - 1)).each do |i|
        matrix.set_row(i, random_gaussian_vector(l))
      end
      matrix
    end

    def self.dot(v1, v2)
      (v1 * v2)[0,0]
    end

    def self.norm(v)
      v.norm
    end

  end

end

module GSL

  class Matrix

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

    def save(file)
      fwrite(file)
    end

    def load(file)
      fread(file)
    end
  end

end
