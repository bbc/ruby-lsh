require_relative '../lib/lsh'

index = LSH::Index.new(1000, 8, 50, 20)

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
  while k < results.size and similarities[k] == results[k] * vector.col
    k += 1
  end
  $stderr.puts "#{k} nearest neighbors appear in results"
end
