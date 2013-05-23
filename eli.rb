require 'rdf'
require 'sparql'
require 'rdf/rdfxml'
require 'rdf/rdfa'
require './cachedrepo'

class Eli
  attr_reader :repo, :psi

  TYPEDOC_RT_MAPPING = {"DIR" => "dir", "REG" => "reg", "REGIMP" => "reg_impl", "DEC" => "dec", "DECDEL" => "dec_del", "DIRIMP" => "dir_impl", "GENGUID" => "guideline", "INFO" => "info", "NOTICE" => "notice", "OP.COM.COM" => "opin", "PROC" => "proc_rules", "PROT" => "prot", "RDINFO" => "note", "REC" => "rec", "RECDEL" => "rec_del", "REGIMP" => "reg_impl", "RESOLUTION" => "res", "SAB" => "budget_suppl_amend", "TREATY" => "treaty", "AGR" => "agree", "COMMUNIC_COURT" => "communic", "OP.COM.CES" => "opin" }
  TYPEDOC_RT_MAPPING.default = "undefined"
  TYPEDOC_CB_MAPPING = {"CS" => "consil", "PE" => "EP", "COM" => "com", "BCE" => "ecb", "COM-UN" => "unece"}

  CDM = "<http://publications.europa.eu/ontology/cdm#>"
  ELI = "<http://eurlex.europa.eu/eli#>"
  XSD = "<http://www.w3.org/2001/XMLSchema>"

  def initialize(psi = nil)
    r = CachedRepo.new(psi)
    @repo = r.repo
    @psi = if psi then psi else "32010L0024" end #test case
    @eli = nil

    eli_iri = RDF::URI("http://eurlex.europa.eu/eli/function#to_eli")
    SPARQL::Algebra::Expression.register_extension(eli_iri) do |literal|
      raise TypeError, "argument must be a literal" unless literal.literal?
      begin
        RDF::Literal(Eli.new(literal.to_s).eli)
      rescue
        #If the PSI reference does not exist, leave it unchanged
        RDF::Literal(literal.to_s)
      end  
    end
  end

  def parse_number(number) 
    "Parse numbers of type 2010/24 (EU)"
    scan = number.scan(/(\d{4})\/(\d+)/)
    unless scan.empty?
      year, natural_number = scan[0]
    else #this is a hack, there are enough cases where this is ambiguous
      scan = number.scan(/(\d+)\/(\d{4})/)
      unless scan.empty?
        natural_number, year = scan[0] 
        [year, natural_number]
      else
        nil
      end
    end
  end 

  def eli()
    "Build an ELI for a given Cellar production system identifier (PSI). If this PSI is nil, use a local sample repository for testing"
    if(@eli)
      @eli
    else
      eli_query = <<-sparql
PREFIX cdm: <http://publications.europa.eu/ontology/cdm#>

SELECT DISTINCT ?number ?typedoc ?is_corrigendum  ?pub_date
WHERE {
  ?manif cdm:manifestation_official-journal_part_information_number ?number .
  ?manif cdm:manifestation_official-journal_part_typedoc_printer  ?typedoc .
  ?manif cdm:manifestation_official-journal_part_is_corrigendum_printer ?is_corrigendum .
  ?work cdm:resource_legal_published_in_official-journal ?oj .
  ?oj  cdm:publication_general_date_publication ?pub_date .
  FILTER(strlen(?number) > 0) # && strlen(?typedoc) > 0 && strlen(?is_corrigendum) > 0)
}
sparql
      solutions = SPARQL.execute(eli_query, @repo)
      raise "No ELI could be built" if solutions.length < 1
      raise "More than one ELI possible" unless solutions.length < 2
      sol = solutions[0]
      information_number = sol[:number].to_s
      @typedoc = TYPEDOC_RT_MAPPING[sol[:typedoc].to_s]
      is_corrigendum = sol[:is_corrigendum].to_s
      lang_query = <<-sparql
PREFIX cdm: <http://publications.europa.eu/ontology/cdm#>

SELECT DISTINCT ?lang_code
WHERE {
 ?expr cdm:expression_uses_language  ?lang .
 BIND(lcase(replace(str(?lang), ".*/([A-Z]{3})", "$1")) AS ?lang_code)
}
ORDER BY ?lang_code
sparql
      langs = if is_corrigendum == 'C' then
        langs_sol = SPARQL.execute(lang_query, @repo)
        lang_lst = langs_sol.collect { |sol| 
          sol[:lang_code] 
        }
        lang_lst.join("-")
      else
        ""
      end
      pub_date = sol[:pub_date].to_s
      year, natural_number = parse_number(information_number)
    
      @eli = "http://eli.budabe.eu/eli/#{@typedoc}/#{year}/#{natural_number}/#{if is_corrigendum == 'C' then 'corr-' + langs + '/' + pub_date + '/' end}oj"
      @eli
    end
  end

  def legal_resource_query()
    eli_uri = "<" + self.eli + ">"
    query = File.read("sparql/eli_md.rq")
    query.gsub("<http://eli.budabe.eu/eli/dir/2010/24/oj>", eli_uri)
  end

  def metadata()
    graph = SPARQL.execute(self.legal_resource_query, @repo)
    g2 = SPARQL.execute("CONSTRUCT {?s ?p ?o} WHERE {?s ?p ?o} ORDER BY ?s ?p ?o", graph)
    rdfa_xhtml = RDF::RDFa::Writer.buffer(:haml => RDF::RDFa::Writer::DEFAULT_HAML, :standard_prefixes => true, :base_uri => "") do |writer| 
      writer << g2
    end
    rdfa_xhtml
  end
end
