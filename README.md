ruby-lsh
========

A first try at implementing LSH in Ruby. Uses JBlas on JRuby and GSL on any other Ruby.

Usage
-----

See examples/evaluation.rb

    > require 'lsh'
    > index = LSH::Index.new({
        :dim => 100, 
        :number_of_random_vectors => 8, 
        :window => Float::Infinity, 
        :number_of_independent_projections => 150
      }) # Creates an in-memory binary LSH index for 100-dim vectors, 8 bits, 150 independent projections
    > v1 = index.random_vector(100)
    > v2 = index.random_vector(100)
    > v3 = index.random_vector(100) # Creating three random vectors
    > index.add v1
    > index.add v2
    > index.add v3 # Adding the three vectors to the index
    > index.query(v1) # Query the index for vectors that fall in the same LSH bucket as v1
    > index.query(v2, 1) # Query the index for vectors that fall in the same LSH bucket as v2, and in buckets at hamming distance 1 of that bucket

Licensing terms and authorship
------------------------------

See 'COPYING' and 'AUTHORS' files.
