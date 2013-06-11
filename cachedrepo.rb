require './repo'
require 'json'

TRIPLESTORE_URL = "http://localhost:3030/eli/"

class CachedRepo < Repo    
  def in_cache?(cellar_psi)
    #Check if there is already data on this cellar_psi in the local repository (if any)
    @graph_url = "#{TRIPLESTORE_URL}data?graph=#{CGI::escape(cellar_psi)}"
    find_graph_query = <<-sparql
PREFIX owl: <http://www.w3.org/2002/07/owl#>
SELECT DISTINCT ?gra
WHERE {
      GRAPH ?gra{
        {<#{cellar_psi}> owl:sameAs ?o}
          UNION
        {?s owl:sameAs <#{cellar_psi}>}
      } 
} LIMIT 1    
sparql
    query_url = "#{TRIPLESTORE_URL}query?query=#{CGI::escape(find_graph_query)}&output=json"
    puts query_url
    begin
      response = RestClient.get(query_url) do  |response, request, result |
        case response.code
        when 200 then
          res = JSON::parse(response.body)
          bindings = res["results"]["bindings"]
          if bindings.length > 0 then
            graph_uri = bindings[0]["gra"]["value"]
            #if the identifier was already bound to some other graph identifier, use that to avoid duplicating data
            @graph_url = "#{TRIPLESTORE_URL}data?graph=#{CGI::escape(graph_uri)}"
            true
          else
            false
          end
        else
          false
        end 
      end
    rescue
      puts "is_cache?: Cache not reachable or other issue"
      false
    end
  end
  
  def fetch_from_cache()
    add_to_repo!(@graph_url)
  end
  
  def add_to_cache()
    begin
      RestClient.put(@graph_url, RDF::Writer.for(:rdfxml).buffer do |writer| 
                       @repo.each_statement do |statement|
                         writer << statement
                       end
                     end, :content_type => 'application/rdf+xml')
    rescue
      puts "add_to_cache: Cache not reachable or other issue"
      false #Cache isn't reachable, we don't add anything
    end 
  end
  
  alias :uncached_repo_for_psi :repo_for_psi 

  def repo_for_psi(cellar_psi)
    "Initiates an RDF repository based on a remote, work-level Cellar production system identifier in the form of a URI"
    if in_cache?(cellar_psi) then
      puts "Had information on #{cellar_psi} cached"
      fetch_from_cache()
    else
      self.uncached_repo_for_psi(cellar_psi)
      add_to_cache()
    end
  end
end

def find_celex(typedoc, year, natural_number)
  eli_query = <<-sparql
PREFIX cdm: <http://publications.europa.eu/ontology/cdm#>

SELECT DISTINCT ?celex 
WHERE {
GRAPH ?g {
  ?manif cdm:manifestation_official-journal_part_information_number ?number .
  ?manif cdm:manifestation_official-journal_part_typedoc_printer "#{typedoc}" .
  ?manif cdm:manifestation_official-journal_part_is_corrigendum_printer "O" .
  ?work cdm:resource_legal_id_celex ?celex .
  FILTER(strlen(?number) > 0 && (regex(?number, "^#{year}/#{natural_number}$", "i") || regex(?number, "^#{natural_number}/#{year}$", "i") || regex(?number, "^#{year}/#{natural_number} ", "i") || regex(?number, "^#{natural_number}/#{year} ", "i")))
 }
}
LIMIT 2
sparql
  puts eli_query
  query_url = "#{TRIPLESTORE_URL}query?query=#{CGI::escape(eli_query)}&output=json"
  puts query_url
  response = RestClient.get(query_url) do  |response, request, result |
    case response.code
    when 200 then
      res = JSON::parse(response.body)
      bindings = res["results"]["bindings"]
      case bindings.length
      when 1 then
        bindings[0]["celex"]["value"]
      when 0 then
        nil
      else
        bindings
      end
    else
      nil
    end
  end
  response
end  
