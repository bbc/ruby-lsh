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
