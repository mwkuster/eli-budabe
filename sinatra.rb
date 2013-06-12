require 'sinatra'
require 'thin'
require 'erb'
require './eli'
require 'open-uri'
require 'json'
require './cachedrepo'

def psiencode(psi)
  URI::encode(psi).gsub(/\(/, "%28").gsub(/\)/, "%29")
end

get '/eli4psi' do
  erb :psi2eli
end

get '/eli4celex/:psi' do
  begin
    Eli.get_eli("http://publications.europa.eu/resource/celex/" + psiencode(params[:psi])).to_json
  rescue Exception => e
    status 404
    body e.to_json
  end
end

get '/eli4celex/:psi/metadata' do
  begin
    psi = "http://publications.europa.eu/resource/celex/" + psiencode(params[:psi])
    Eli.metadata(psi)
  rescue Exception => e
    status 404
    body e.to_json
  end
end

get '/eli4id_jo/:psi' do
  begin
    Eli.get_eli("http://publications.europa.eu/resource/oj/" +  psiencode(params[:psi])).to_json
  rescue Exception => e
    status 404
    body e.to_json
  end
end

get '/eli4id_jo/:psi/metadata' do
  begin
    psi = "http://publications.europa.eu/resource/oj/" + psiencode(params[:psi])
    Eli.metadata(psi)
  rescue Exception => e
    status 404
    body e.to_json
  end
end

get '/eli/:typedoc/:year/:natural_number/oj' do
  begin
    celex = find_celex(Eli::RT_TYPEDOC_MAPPING[params[:typedoc]], params[:year], params[:natural_number])
    psi = "http://publications.europa.eu/resource/celex/#{celex}"
    Eli.metadata(psi)
  rescue Exception => e
    status 404
    body e.to_json
  end
end
