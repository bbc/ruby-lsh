ruby-lsh
========

A first try at implementing LSH in Ruby. Uses JBlas on JRuby and GSL on any other Ruby.

Usage
-----

See examples/evaluation.rb

    require 'lsh'
    index = LSH::Index.new({
      :dim => 100, 
      :number_of_random_vectors => 8, 
      :window => Float::Infinity, 
      :number_of_independent_projections => 150
    }) # Creates an in-memory binary LSH index for 100-dim vectors, 8 bits, 150 independent projections
    v1 = index.random_vector(100)
    v2 = index.random_vector(100)
    v3 = index.random_vector(100) # Creating three random vectors
    index.add v1
    index.add v2
    index.add v3 # Adding the three vectors to the index
    index.query(v1) # Query the index for vectors that fall in the same LSH bucket as v1
    index.query(v2, 1) # Query the index for vectors that fall in the same LSH bucket as v2, and in buckets at hamming distance 1 of that bucket


Using the Redis backend
-----------------------

By default, the LSH index will be stored in memory. A Redis-backed storage is also available, and can
be constructed as follows:

    storage = LSH::Storage::RedisBackend.new
    index = LSH::Index.new({
      :dim => 100,
      :number_of_random_vectors => 8,
      :window => Float::Infinity,
      :number_of_independent_projections => 150
    }, storage)

Once created, the index can then be reused:

    storage = LSH::Storage::RedisBackend.new
    index = LSH::Index.new(storage.parameters, storage) if storage.has_index?

This will connect to a Redis backend on localhost and store binary dumps of the vectors (including the projections) in a 'data' directory.
This can be overridden as follow:

    storage = LSH::Storage::RedisBackend.new(:redis => { :host => '127.0.0.1', :port => 6379 }, :data_dir => 'data')

The Redis-backed LSH index is faster using the MRI than JRuby, due to the time it takes to load vectors from their
binary representations on disk. GSL is much faster than JBLAS on that point.


Using the Web frontend
----------------------

This gem includes a minimal Web API, built using Sinatra. See examples/config.ru for an example setup.

    $ cd examples
    $ rackup
    $ curl --data-urlencode data@vector.json http://localhost:9292/index # Adds a vector to the index
    $ curl --data-urlencode data@vector.json http://localhost:9292/query # Query the index

Or you can associate your vectors with ids and query using them.

    $ cd examples
    $ rackup
    $ curl --data-urlencode data@vector.json -d'id=foo' http://localhost:9292/index # Adds a vector with id 'foo' to the index
    $ curl -d'id=foo' http://localhost:9292/query-ids # Query the index

GSL notes
---------

If you get a compilation error when installing GSL, try this version:

  https://github.com/romanbsd/rb-gsl

As you will need a version of GSL that includes this patch:

  https://gist.github.com/1217974


Licensing terms and authorship
------------------------------

See 'COPYING' and 'AUTHORS' files.
