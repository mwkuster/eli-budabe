require 'rdf'
require 'sparql'
require 'rdf/rdfxml'
require 'rdf/rdfa'
require './repo'

module Eli
  TYPEDOC_RT_MAPPING = {"DIR" => "dir", "REG" => "reg", "REGIMP" => "reg_impl", "DEC" => "dec", "DECDEL" => "dec_del", "DIRIMP" => "dir_impl", "GENGUID" => "GUIDELINE", "INFO" => "info", "NOTICE" => "notice", "OP.COM.COM" => "opin", "PROC" => "proc_rules", "PROT" => "prot", "RDINFO" => "note", "REC" => "rec", "RECDEL" => "rec_del", "REGIMP" => "reg_impl", "RESOLUTION" => "res", "SAB" => "budget_suppl_amend", "TREATY" => "treaty", "AGR" => "agree" }
  TYPEDOC_RT_MAPPING.default = "undefined"
  TYPEDOC_CB_MAPPING = {"CS" => "consil", "PE" => "EP", "COM" => "com", "BCE" => "ecb", "COM-UN" => "unece"}

  CDM = "<http://publications.europa.eu/ontology/cdm#>"
  ELI = "<http://eurlex.europa.eu/eli#>"
  ELI_CONSTR = <<-sparql
PREFIX cdm: #{CDM}
PREFIX eli: #{ELI}
CONSTRUCT
{?subj eli:expression_title ?title }
WHERE
{ ?subj cdm:expression_title ?title .}
sparql


  def Eli.parse_number(number) 
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

  def Eli.build_eli(psi=nil)
    "Build an ELI for a given Cellar production system identifier (PSI). If this PSI is nil, use a local sample repository for testing"
    eli_query = <<-sparql
PREFIX cdm: #{CDM}
PREFIX eli: #{ELI}
SELECT DISTINCT ?number ?typedoc ?author ?format ?is_corrigendum
WHERE
{
?manif cdm:manifestation_official-journal_part_information_number ?number .
?manif cdm:manifestation_official-journal_part_typedoc_printer  ?typedoc .
?manif cdm:manifestation_official-journal_part_author_printer ?author .
?manif cdm:manifestation_official-journal_part_is_corrigendum_printer ?is_corrigendum .
}
sparql
    repo = if psi then Repo.repo_for_psi(psi) else Repo.sample_repo end
    solutions = SPARQL.execute(eli_query, repo)
    raise "No ELI could be built" if solutions.length < 1
    raise "More than one ELI possible" unless solutions.length <= 2 #2 authors maximum
    sol = solutions[0]
    information_number = sol[:number].to_s
    typedoc = TYPEDOC_RT_MAPPING[sol[:typedoc].to_s]
    author1 = TYPEDOC_CB_MAPPING[sol[:author].to_s]
    author2 = if solutions.length == 2 then "/" + TYPEDOC_CB_MAPPING[sol[1][:author]]  else "" end
    is_corrigendum = sol[:is_corrigendum].to_s
    year, natural_number = parse_number(information_number)
    
    "http://eli.budabe.eu/eli/#{typedoc}#{if is_corrigendum == 'C' then '-corr' end}/#{year}/#{natural_number}/#{author1}#{author2}/oj"
  end
end
