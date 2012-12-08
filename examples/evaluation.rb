require_relative '../lib/lsh'

index = LSH::Index.new(1000, 8, 10, 150)

# Test dataset
vectors = []
500.times { |i| vectors << index.random_vector(1000) } 

# Adding to index
vectors.each { |v| index.add(v) }

# Nearest neighbors in query result?
vectors.each_with_index do |vector, i|
  results = index.query(vector)
  $stderr.puts "#{results.count} results for vector #{i}"
  similarities = vectors.map { |v| vector * v.col }
  similarities.sort!.reverse!
  k = 0
  results_similarities = results.map { |r| r * vector.col }
  while k < results.size and results_similarities.member? similarities[k]
    k += 1
  end
  $stderr.puts "Nearest neightbours up to #{k} appear in results"
end
