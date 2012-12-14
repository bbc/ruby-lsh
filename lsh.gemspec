Gem::Specification.new do |s|
  s.name = "lsh"
  s.version = "0.0.1"
  s.date = "2012-12-13"
  s.summary = "Locality Sensitive Hashing gem"
  s.email = "yves.raimond@bbc.co.uk"
  s.description = "An implementation of LSH in Ruby, using GSL"
  s.has_rdoc = false
  s.authors = ['Yves Raimond']
  s.files = [
    "lib/lsh.rb", 
    "lib/lsh/index.rb", 
  ]
  if RUBY_PLATFORM == 'java'
    s.add_dependency 'jblas'
  else
    s.add_dependency 'gsl'
  end
end
