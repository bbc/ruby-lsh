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
        results = index.query(vector)
        content_type :json
        { "time" => Time.now - t0, "results" => results }.to_json
      else
        raise "Unrecognised mime-type"
      end
    end

    post '/index' do
      raise "Missing data" unless params[:data]
      mime_type = (params[:mime_type] || 'application/json')
      if mime_type == 'application/json'
        t0 = Time.now
        vector = JSON.parse(params[:data])
        index.add(vector)
        content_type :json
        { "time" => Time.now - t0, "status" => "indexed" }.to_json
      else
        raise "Unrecognised mime-type"
      end
    end

  end

end
