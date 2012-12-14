require_relative 'lsh/index.rb'
if RUBY_PLATFORM == 'java'
  require_relative 'lsh/math_util_jblas.rb'
else
  require_relative 'lsh/math_util_gsl.rb'
end
