require 'sinatra'
require 'json'
require 'time'

module LSH

  class Web < Sinatra::Base

    attr_reader :index

    def initialize(index)
      super
      @index = index
    end

    get '/' do
      content_type :json
      { :index => index.inspect }.to_json
    end

    post '/query' do
      raise "Missing query" unless params[:data]
      mime_type = (params[:mime_type] || 'application/json')
      if mime_type == 'application/json'
        t0 = Time.now
        vector = JSON.parse(params[:data])
        result_vectors = index.query(vector, params[:radius] || 0)
        results = []
        if params[:include] == 'id'
          result_vectors.each { |v| results << { :id => index.vector_to_id(v), :data => v } }
        else
          result_vectors.each { |v| results << { :data => v } }
        end
        content_type :json
        { "time" => Time.now - t0, "results" => results }.to_json
      else
        raise "Unrecognised mime-type"
      end
    end

    post '/query-ids' do
      if params[:data] # We're querying with a vector
        mime_type = (params[:mime_type] || 'application/json')
        if mime_type == 'application/json'
          t0 = Time.now
          vector = JSON.parse(params[:data])
          results = index.query_ids_by_vector(vector, params[:radius] || 0)
          content_type :json
          { "time" => Time.now - t0, "results" => results }.to_json
        else
          raise "Unrecognised mime-type"
        end
      elsif params[:id] # We're querying with an id
        raise "Unknown id" unless index.id_to_vector(params[:id])
        t0 = Time.now
        results = index.query_ids(params[:id], params[:radius] || 0)
        content_type :json
        { "time" => Time.now - t0, "results" => results }.to_json
      else
        raise "Missing query"
      end
    end

    post '/index' do
      raise "Missing data" unless params[:data]
      mime_type = (params[:mime_type] || 'application/json')
      if mime_type == 'application/json'
        t0 = Time.now
        vector = JSON.parse(params[:data])
        index.add(vector, params[:id])
        content_type :json
        { "time" => Time.now - t0, "status" => "indexed" }.to_json
      else
        raise "Unrecognised mime-type"
      end
    end

  end

end
