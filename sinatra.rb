require 'sinatra'
require 'thin'
require 'erb'
require './eli'
require 'open-uri'
require 'json'

get '/celex2eli' do
  @title = "Celex to ELI conversion"
  @psitype = "celex"
  erb :psi2eli
end

get '/oj2eli' do
  @title = "ID_JO to ELI conversion"
  @psitype = "oj"
  erb :psi2eli
end

get '/celex2eli/:psi' do
  begin
    Eli.build_eli("http://publications.europa.eu/resource/celex/" + URI::encode(params[:psi])).to_json
  rescue Exception => e
    status 404
    body e.to_json
  end
end

get '/oj2eli/:psi' do
  begin
    Eli.build_eli("http://publications.europa.eu/resource/oj/" + URI::encode(params[:psi])).to_json
  rescue Exception => e
    status 404
    body e.to_json
  end
end
