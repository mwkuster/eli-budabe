require 'net/http'
require 'rdf/rdfxml'
require 'rdf/turtle'
require 'nokogiri'
require 'rest_client'

class Repo
  def initialize(psi = nil)
    @repo = RDF::Repository.new        
    if psi then 
      self.repo_for_psi(psi) 
    else
      self.sample_repo 
    end
  end

  def repo()
    @repo
  end

  def sample_repo()
    sample_dir = Dir.new("samples/")
    sample_files = sample_dir.grep(/\.*\.rdf/)
    sample_files.each { |file|
      @repo.load(File.join(sample_dir, file))
    }
  end

  def add_to_repo!(uri)
    begin
      #we need to explicitly set the accept header, otherwise unusable defaults kick in
      @repo.load(uri, options={:headers => {"Accept" => "application/rdf+xml"}})    
    rescue OpenURI::HTTPError
      #if we can't access this object, so inform the user accordingly
      raise "URI #{uri} does not exist"
    end
  end

  def repo_for_psi(cellar_psi)
    "Initiates an RDF repository based on a remote or local, work-level Cellar production system identifier in the form of a URI"

    add_to_repo!(cellar_psi)

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
      add_to_repo!(expr_uri)
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
      add_to_repo!(manif_uri)
    }  
  end
end
