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

require_relative 'lsh/index.rb'
require_relative 'lsh/storage/memory.rb'
require_relative 'lsh/storage/redis_backend.rb'
if RUBY_PLATFORM == 'java'
  require_relative 'lsh/math_util_jblas.rb'
else
  require_relative 'lsh/math_util_gsl.rb'
end
