require 'sinatra'
require 'thin'
require 'erb'
require './eli'
require 'open-uri'
require 'json'

def psiencode(psi)
  URI::encode(psi).gsub(/\(/, "%28").gsub(/\)/, "%29")
end

get '/eli4psi' do
  erb :psi2eli
end

get '/eli4celex/:psi' do
  begin
    Eli.new("http://publications.europa.eu/resource/celex/" + psiencode(params[:psi])).eli.to_json
  rescue Exception => e
    status 404
    body e.to_json
  end
end

get '/eli4celex/:psi/metadata' do
  begin
    psi = "http://publications.europa.eu/resource/celex/" + psiencode(params[:psi])
    eli_obj = Eli.new(psi)
    eli_obj.metadata
  rescue Exception => e
    status 404
    body e.to_json
  end
end

get '/eli4id_jo/:psi' do
  begin
    Eli.new("http://publications.europa.eu/resource/oj/" +  psiencode(params[:psi])).eli.to_json
  rescue Exception => e
    status 404
    body e.to_json
  end
end

get '/eli4id_jo/:psi/metadata' do
  begin
    psi = "http://publications.europa.eu/resource/oj/" + psiencode(params[:psi])
    eli_obj = Eli.new(psi)
    eli_obj.metadata
  rescue Exception => e
    status 404
    body e.to_json
  end
end
