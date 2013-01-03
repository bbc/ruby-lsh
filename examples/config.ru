require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'lib', 'lsh.rb')

dim = 1000 # Dimension
random_dim = 20 # Number of actual random N(0,1) elements used to create random vector
hash_size = 8 # Hash size (in bits for binary LSH)
window_size = Float::INFINITY # Binary LSH
n_projections = 50 # Number of independent projections
multiprobe_radius = 0 # Multiprobe radius (set to 0 to disable multiprobe)
fms_limit = 5 # Number of items to take into account in the k-NN for f-measure evaluation
# storage = LSH::Storage::RedisBackend.new # Redis backend
storage = LSH::Storage::Memory.new # In-memory backend

storage.reset!
index = LSH::Index.new({
  :dim => dim,
  :number_of_random_vectors => hash_size,
  :window => window_size,
  :number_of_independent_projections => n_projections
}, storage)
web = LSH::Web.new(index)

File.open('vector.json', 'w') { |f| f.write(index.random_vector(dim).to_json) } # A test vector

run Rack::URLMap.new('/' => web)
