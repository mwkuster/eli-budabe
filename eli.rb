require 'rdf'
require 'sparql'
require 'rdf/rdfxml'
require 'rdf/rdfa'
require 'cgi'

eli_iri = RDF::URI("http://eurlex.europa.eu/eli/function#to_eli")
SPARQL::Algebra::Expression.register_extension(eli_iri) do |literal|
  raise TypeError, "argument must be a literal" unless literal.literal?
  begin
    RDF::Literal(Eli.get_eli(literal.to_s))
  rescue
    #If the PSI reference does not exist, leave it unchanged
    RDF::Literal(literal.to_s)
  end  
end
resource_type_iri = RDF::URI("http://eurlex.europa.eu/eli/function#to_rt")
SPARQL::Algebra::Expression.register_extension(resource_type_iri) do |literal|
  raise TypeError, "argument must be a literal" unless literal.literal?
  begin
    RDF::Literal("http://publications.europa.eu/resource/authority/resource-type/" + Eli::TYPEDOC_RT_MAPPING[literal.to_s].upcase)
  rescue
    #If the PSI reference does not exist, leave it unchanged
    RDF::Literal("undefined")
  end  
end

module Eli
  TYPEDOC_RT_MAPPING = {"AGR" => "agree", 
    "COMMUNIC_COURT" => "communic",
    "DEC" => "dec", 
    "DECDEL" => "dec_del",
    "DECIMP" => "dec_impl", 
    "DIR" => "dir", 
    "DIRDEL" => "dir_del", 
    "DIRIMP" => "dir_impl", 
    "GENGUID" => "guideline", 
    "INFO" => "info", 
    "NOTICE" => "notice", 
    "PROC" => "proc_rules", 
    "PROT" => "prot", 
    "RDINFO" => "note", 
    "REC" => "rec", 
    "RECDEL" => "rec_del", 
    "REG" => "reg", 
    "REGDEL" => "reg_del", 
    "REGIMP" => "reg_impl", 
    "RESOLUTION" => "res", 
    "SAB" => "budget_suppl_amend"  }
  RT_TYPEDOC_MAPPING = TYPEDOC_RT_MAPPING.invert
  TYPEDOC_RT_MAPPING.default = "undefined"
  TYPEDOC_CB_MAPPING = {"CS" => "consil", "PE" => "EP", "COM" => "com", "BCE" => "ecb", "COM-UN" => "unece"}

  CDM = "<http://publications.europa.eu/ontology/cdm#>"
  ELI = "<http://eurlex.europa.eu/eli#>"
  XSD = "<http://www.w3.org/2001/XMLSchema>"

  def self.parse_number(number) 
    "Parse numbers of type 2010/24 (EU)"
    scan = number.scan(/(19\d{2}|20\d{2})\/(\d+)/)
    unless scan.empty?
      year, natural_number = scan[0]
    else #this is a hack, there are enough cases where this is ambiguous
      scan = number.scan(/(\d+)\/(19\d{2}|20\d{2})/)
      unless scan.empty?
        natural_number, year = scan[0] 
        [year, natural_number]
      else
        nil
      end
    end
  end 

  def self.eli(cellar_psi)
    "Build an ELI for a given Cellar production system identifier (PSI). If this PSI is nil, use a local sample repository for testing"
    uri = "http://localhost:3000/#{CGI::escape(cellar_psi)}"
    puts uri
    repo = RDF::Repository.new
    repo.load(uri, options={:format => :rdf, :headers => {"Accept" => "application/rdf+xml"}})
    puts repo

    eli_query = <<-sparql
PREFIX cdm: <http://publications.europa.eu/ontology/cdm#>

SELECT ?number ?typedoc ?is_corrigendum  ?pub_date
WHERE {
  ?manif cdm:manifestation_official-journal_part_information_number ?number .
  ?manif cdm:manifestation_official-journal_part_typedoc_printer  ?typedoc .
  ?manif cdm:manifestation_official-journal_part_is_corrigendum_printer ?is_corrigendum .
  ?work cdm:resource_legal_published_in_official-journal ?oj .
  ?oj  cdm:publication_general_date_publication ?pub_date .
  FILTER(strlen(?number) > 0) # && strlen(?typedoc) > 0 && strlen(?is_corrigendum) > 0)
} LIMIT 1
sparql
    solutions = SPARQL.execute(eli_query, repo)
    raise "No ELI could be built" if solutions.length < 1
    #raise "More than one ELI possible" unless solutions.length < 2
    sol = solutions[0]
    information_number = sol[:number].to_s
    typedoc = TYPEDOC_RT_MAPPING[sol[:typedoc].to_s]
    is_corrigendum = sol[:is_corrigendum].to_s
    langs = if is_corrigendum == 'C' then
              lang_query = <<-sparql
PREFIX cdm: <http://publications.europa.eu/ontology/cdm#>

SELECT DISTINCT ?lang_code
WHERE {
 ?expr cdm:expression_uses_language  ?lang .
 BIND(lcase(replace(str(?lang), ".*/([A-Z]{3})", "$1")) AS ?lang_code)
}
ORDER BY ?lang_code
sparql
              langs_sol = SPARQL.execute(lang_query, repo)
              lang_lst = langs_sol.collect do |sol| sol[:lang_code] end
              lang_lst.join("-")
            else
              ""
            end
    pub_date = sol[:pub_date].to_s
    year, natural_number = self.parse_number(information_number)
    
    eli = "http://eli.budabe.eu/eli/#{typedoc}/#{year}/#{natural_number}/#{if is_corrigendum == 'C' then 'corr-' + langs + '/' + pub_date + '/' end}oj"
    eli
  end


  @@elis = {}
  def self.get_eli(psi)
    if @@elis.has_key?(psi) then
      @@elis[psi]
    else
      begin
        el = RestClient.get("http://localhost:3000/eli4psi/#{CGI::escape(psi)}") do  |response, request, result |
          case response.code
          when 200 then
            response.body
          else
            psi
          end
        end
      rescue
        el = psi
      end
      @@elis[psi] = el
      el
    end
  end

  def self.metadata(cellar_psi)
    uri = "http://localhost:3000/eli4psi/#{CGI::escape(cellar_psi)}/metadata"
    puts uri
    repo = RDF::Repository.new
    repo.load(uri, options={:format => :rdf, :headers => {"Accept" => "application/rdf+xml"}})
    rdfa_xhtml = RDF::RDFa::Writer.buffer(:haml => RDF::RDFa::Writer::DEFAULT_HAML, :standard_prefixes => true, :base_uri => "") do |writer| 
      writer << repo
    end
    rdfa_xhtml
  end
end
