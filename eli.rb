require 'rdf'
require 'sparql'
require 'rdf/rdfxml'
require 'rdf/rdfa'
require './repo'

class Eli
  attr_reader :repo, :psi

  TYPEDOC_RT_MAPPING = {"DIR" => "dir", "REG" => "reg", "REGIMP" => "reg_impl", "DEC" => "dec", "DECDEL" => "dec_del", "DIRIMP" => "dir_impl", "GENGUID" => "GUIDELINE", "INFO" => "info", "NOTICE" => "notice", "OP.COM.COM" => "opin", "PROC" => "proc_rules", "PROT" => "prot", "RDINFO" => "note", "REC" => "rec", "RECDEL" => "rec_del", "REGIMP" => "reg_impl", "RESOLUTION" => "res", "SAB" => "budget_suppl_amend", "TREATY" => "treaty", "AGR" => "agree" }
  TYPEDOC_RT_MAPPING.default = "undefined"
  TYPEDOC_CB_MAPPING = {"CS" => "consil", "PE" => "EP", "COM" => "com", "BCE" => "ecb", "COM-UN" => "unece"}

  CDM = "<http://publications.europa.eu/ontology/cdm#>"
  ELI = "<http://eurlex.europa.eu/eli#>"
  XSD = "<http://www.w3.org/2001/XMLSchema>"

  def initialize(psi = nil)
    @repo = if psi then Repo.repo_for_psi(psi) else Repo.sample_repo end
    @psi = if psi then psi else "32010L0024" end #test case
    @eli = nil
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
PREFIX cdm: #{CDM}
PREFIX eli: #{ELI}
SELECT DISTINCT ?number ?typedoc ?is_corrigendum ?lang
WHERE
{
?manif cdm:manifestation_official-journal_part_information_number ?number .
?manif cdm:manifestation_official-journal_part_typedoc_printer  ?typedoc .
?manif cdm:manifestation_official-journal_part_is_corrigendum_printer ?is_corrigendum .
}
sparql
      solutions = SPARQL.execute(eli_query, @repo)
      raise "No ELI could be built" if solutions.length < 1
      raise "More than one ELI possible" unless solutions.length < 2
      sol = solutions[0]
      information_number = sol[:number].to_s
      @typedoc = TYPEDOC_RT_MAPPING[sol[:typedoc].to_s]
      is_corrigendum = sol[:is_corrigendum].to_s
      year, natural_number = parse_number(information_number)
    
      @eli = "http://eli.budabe.eu/eli/#{@typedoc}#{if is_corrigendum == 'C' then '-corr' end}/#{year}/#{natural_number}/oj"
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
    rdfa_xhtml = RDF::RDFa::Writer.buffer(:haml => RDF::RDFa::Writer::DISTILLER_HAML, :base_uri => self.eli) do |writer| 
      writer << graph 
    end
    rdfa_xhtml
  end
end
