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

require 'helper'

class MathUtilTest < Test::Unit::TestCase

  def test_random_uniform
    20.times do |i|
      assert (LSH::MathUtil.random_uniform >= 0)
      assert (LSH::MathUtil.random_uniform <= 1)
    end
  end

  def test_random_gaussian_matrix
    assert_equal [5, 10], LSH::MathUtil.random_gaussian_matrix(5, 10).size
  end

  def test_dot
    assert_equal Float, LSH::MathUtil.dot(LSH::MathUtil.random_gaussian_matrix(1, 10), LSH::MathUtil.random_gaussian_matrix(1, 10).transpose).class
  end

  def test_norm
    v = LSH::MathUtil.random_gaussian_matrix(1, 10)
    assert_equal 1.0, LSH::MathUtil.norm(v / LSH::MathUtil.norm(v)).round(4)
  end

  def test_json
    v = LSH::MathUtil.random_gaussian_matrix(1, 10)
    assert_equal v, JSON.parse(v.to_json, :create_additions => true)
  end

  def test_hash
    # Testing that hash is preserved through serialisation/deserialisation
    v = LSH::MathUtil.random_gaussian_matrix(1, 10)
    assert_equal v.hash, JSON.parse(v.to_json, :create_additions => true).hash
  end

end
