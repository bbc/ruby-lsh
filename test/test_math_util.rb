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

require 'helper'

class MathUtilTest < Test::Unit::TestCase

  def test_random_uniform
    math = LSH::MathUtil.new
    20.times do |i|
      assert (math.random_uniform >= 0)
      assert (math.random_uniform <= 1)
    end
  end

  def test_random_gaussian_vector
    math = LSH::MathUtil.new
    assert_equal 10, math.random_gaussian_vector(10).size
  end

  def test_dot
    math = LSH::MathUtil.new
    assert_equal Float, math.dot(math.random_gaussian_vector(10), math.random_gaussian_vector(10)).class
  end

  def test_norm
    math = LSH::MathUtil.new
    v = math.random_gaussian_vector(10)
    assert_equal 1.0, math.norm(v / math.norm(v)).round(4)
  end

end
