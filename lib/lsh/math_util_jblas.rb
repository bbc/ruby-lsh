# ruby-lsh
#
# Copyright (c) 2011 British Broadcasting Corporation
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

require 'jblas'

module LSH

  class MathUtil

    def self.random_uniform
      JBLAS.rand[0,0]
    end

    def self.random_gaussian_vector(dim)
      JBLAS.randn(1, dim)
    end

    def self.random_gaussian_matrix(k, l)
      JBLAS.randn(k, l)
    end

    def self.dot(v1, v2)
      (v1 * v2.t)[0,0]
    end

    def self.norm(v)
      v.norm2
    end

  end

end


module JBLAS

  class DoubleMatrix

    def to_json(*a)
      {
        'json_class' => 'JBLAS::DoubleMatrix',
        'data' => to_a,
      }.to_json(*a)
    end

    def self.json_create(o)
      from_array(o['data']).t
    end

  end

end

