$platform ||= RUBY_PLATFORM[/java/] || 'ruby'

Gem::Specification.new do |s|
  s.name = "lsh"
  s.version = "0.6.0"
  s.date = "2013-03-19"
  s.summary = "Locality Sensitive Hashing gem"
  s.email = "yves.raimond@bbc.co.uk"
  s.description = "An implementation of LSH in Ruby, using JBLAS for JRuby and GSL for MRI"
  s.homepage = 'https://github.com/bbcrd/ruby-lsh'
  s.has_rdoc = false
  s.authors = ['Yves Raimond']
  s.files = [
    "lib/lsh.rb", 
    "lib/lsh/index.rb", 
    "lib/lsh/math_util_gsl.rb",
    "lib/lsh/math_util_jblas.rb",
    "lib/lsh/web.rb", 
    "lib/lsh/storage/memory.rb",
    "lib/lsh/storage/redis_backend.rb",
  ]
  s.platform = $platform
  s.add_dependency 'jblas-ruby' if ($platform.to_s == 'java')
  s.add_dependency 'gsl' if ($platform.to_s == 'ruby')
  s.add_dependency 'json'
  s.add_dependency 'redis'
  s.add_dependency 'sinatra'
  
  s.add_development_dependency 'mock_redis'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'mocha'
end
