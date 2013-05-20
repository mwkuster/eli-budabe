require './repo'

TRIPLESTORE_URL = "http://localhost:3030/eli/data"

class CachedRepo < Repo    
  def in_cache?(cellar_psi)
    #Check if there is already data on this cellar_psi in the local repository (if any)
    @graph_url = "#{TRIPLESTORE_URL}?graph=#{CGI::escape(cellar_psi)}"
    begin
      response = RestClient.head(@graph_url) do  |response, request, result |
        case response.code
        when 200 then
          true
        else
          false
        end
      end
    rescue
      puts "Cache not reachable or other issue"
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
      puts "Cache not reachable or other issue"
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
