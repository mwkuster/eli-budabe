require 'net/http'
require 'rdf/rdfxml'
require 'rdf/turtle'
require 'nokogiri'
require 'rest_client'

FUSEKI_URI = "http://localhost:3030/eli/data"

module Repo

  def Repo.sample_repo()
    sample_dir = Dir.new("samples/")
    sample_files = sample_dir.grep(/\.*\.rdf/)
    eli_repo = RDF::Repository.new
    sample_files.each { |file|
      eli_repo.load(File.join(sample_dir, file))
    }
    eli_repo
  end

  def Repo.add_to_repo!(repo, uri)
    begin
      #we need to explicitly set the accept header, otherwise unusable defaults kick in
      repo.load(uri, options={:headers => {"Accept" => "application/rdf+xml"}})    
    rescue OpenURI::HTTPError
      #if we can't access this object, so inform the user accordingly
      raise "URI #{uri} does not exist"
    end
  end

  def Repo.repo_for_psi(cellar_psi)
    "Initiates an RDF repository based on a remote, work-level Cellar production system identifier in the form of a URI"
    repo = RDF::Repository.new
    
    #Check if there is already data on this cellar_psi in the local repository (if any)
    graph_url = "#{FUSEKI_URI}?graph=#{CGI::escape(cellar_psi)}"
    puts graph_url
    response = RestClient.head(graph_url)  do |response, request, result|
      case response.code
      when 200
        puts "Had information on #{cellar_psi} cached"
        repo.load(graph_url, options={:headers => {"Accept" => "text/turtle;charset=utf-8"}})
        repo
      else #was not yet cached or does not exist for some other reason
        add_to_repo!(repo, cellar_psi)
        expr_sparql = <<-sparql
PREFIX cdm: #{Eli::CDM}

SELECT DISTINCT ?uri
WHERE {
{?work_uri cdm:work_has_expression ?uri }
UNION
{?work_uri cdm:resource_legal_published_in_official-journal ?uri}
}
sparql
        expressions = SPARQL.execute(expr_sparql, repo)
        raise "This work has no expressions" if expressions.length < 1
        expressions.each { |hit|
          expr_uri = hit[:uri]
          add_to_repo!(repo, expr_uri)
        }
        manif_sparql = <<-sparql
PREFIX cdm: #{Eli::CDM}

SELECT DISTINCT ?manif_uri
WHERE
{?expr_uri cdm:expression_manifested_by_manifestation ?manif_uri }
sparql
        manifestations = SPARQL.execute(manif_sparql, repo)
        raise "This work has no manifestations" if manifestations.length < 1
        manifestations.each { |hit|
          manif_uri = hit[:manif_uri]
          add_to_repo!(repo, manif_uri)
        }
        RestClient.put(graph_url, RDF::Writer.for(:rdfxml).buffer do |writer| 
                         repo.each_statement do |statement|
                           writer << statement
                         end
                       end, :content_type => 'application/rdf+xml')
        repo
      end
    end
  end
end
