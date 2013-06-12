(ns eli-budabe-fetch.core
  (:require [seabass.core :as rdf])
  (:require [clj-http.client :as client])
  (:require [saxon :as xml])
  (:require [cheshire.core :as json])
  (:use compojure.core)
  (:require [compojure.route :as route])
  (:import [com.hp.hpl.jena.rdf.model Model ModelFactory])
  (:import [com.hp.hpl.jena.reasoner.rulesys GenericRuleReasonerFactory Rule])
  (:import [com.hp.hpl.jena.vocabulary ReasonerVocabulary])
  (:import [java.io File OutputStreamWriter FileOutputStream])
  (:import [java.net URLEncoder])
  (:import [java.net URL]))

(defn save-model [model filename]
  (.write model (OutputStreamWriter. (FileOutputStream. filename) "UTF-8") "RDF/XML"))

(defn model-to-string [model]
  (let
      [sw (java.io.StringWriter.)]
    (.write model sw "RDF/XML")
    (.toString sw)))

(defn build-model [urls]
  "Build a model based on a number of URLs, heavily inspired by https://github.com/ryankohl/seabass/blob/master/src/seabass/impl.clj"
  (println urls)
  (let 
      [core (ModelFactory/createDefaultModel)
       model (ModelFactory/createDefaultModel)
       config (.addProperty (.createResource core)
                            ReasonerVocabulary/PROPruleMode
                            "hybrid")
       reasoner (.create (GenericRuleReasonerFactory/theInstance) config)]
    (doseq [url urls]
      (.add core (.read model 
                        (java.io.StringReader. 
                         (:body (client/get url {:headers {"Accept" "application/rdf+xml"}}))) "" "RDF/XML")))
    (ModelFactory/createInfModel reasoner core)))       

(def TYPEDOC_RT_MAPPING 
  {"AGR" "agree", 
    "COMMUNIC_COURT" "communic",
    "DEC" "dec", 
    "DECDEL"  "dec_del",
    "DECIMP" "dec_impl", 
    "DIR"  "dir", 
    "DIRDEL" "dir_del", 
    "DIRIMP" "dir_impl", 
    "GENGUID" "guideline", 
    "INFO" "info", 
    "NOTICE" "notice", 
    "PROC" "proc_rules", 
    "PROT" "prot", 
    "RDINFO" "note", 
    "REC" "rec", 
    "RECDEL" "rec_del", 
    "REG"  "reg", 
    "REGDEL"  "reg_del", 
    "REGIMP" "reg_impl", 
    "RESOLUTION"  "res", 
    "SAB" "budget_suppl_amend"  })

(def TYPEDOC_CB_MAPPING 
  {"CS" "consil", "PE" "EP", "COM" "com", "BCE" "ecb", "COM-UN" "unece"})

(def expression-query "PREFIX cdm: <http://publications.europa.eu/ontology/cdm#>\nSELECT DISTINCT ?uri\nWHERE {?work_uri cdm:work_has_expression ?uri}")

(def manifestation-query "PREFIX cdm: <http://publications.europa.eu/ontology/cdm#>\nSELECT DISTINCT ?uri WHERE {?u cdm:expression_manifested_by_manifestation ?uri}")

(defn in-cache? [cellar-psi]
  (let
      [find-graph-query (URLEncoder/encode (clojure.string/replace "PREFIX owl: <http://www.w3.org/2002/07/owl#>
SELECT DISTINCT ?gra WHERE { GRAPH ?gra{ {<#{cellar_psi}> owl:sameAs ?o} UNION {?s owl:sameAs <#{cellar_psi}>}} } LIMIT 1" "#{cellar_psi}" cellar-psi))
       query-url (str "http://localhost:3030/eli/query?query=" find-graph-query "&output=json")
       query-result (json/parse-string (:body (client/get query-url)))
       binding (first (get (get query-result "results")  "bindings"))]
    (if binding
      (get (get binding "gra") "value")
      nil)))
    

(defn fetch-work-remotely
  "Fetch a work-level Cellar PSI either remotely"
  [cellar-psi]
  (let
      [work-model (build-model (list cellar-psi))
       expression-model (build-model (map :uri (:data (rdf/bounce expression-query work-model))))
       manifestation-model (build-model (map :uri (:data (rdf/bounce manifestation-query expression-model))))]
    (rdf/build work-model expression-model manifestation-model)))

(defn fetch-work-from-cache 
  "Fetch a work-level Cellar PSI from cache"
  [graph-uri]
  (let
      [cache-uri (str "http://localhost:3030/eli/data?graph=" (URLEncoder/encode graph-uri))]
    (rdf/build [cache-uri "TTL"])))

(defn add-to-cache
  "Add a model to the cache"
  [cellar-psi model]
  (let
      [cache-uri (str "http://localhost:3030/eli/data?graph=" (URLEncoder/encode cellar-psi))]
    (client/put cache-uri  {:body (model-to-string model) :headers {"Content-Type" "application/rdf+xml"}})
    cache-uri))
      
(defn fetch-work 
  "Fetch a work-level Cellar PSI and all its metadata either from a local cache or remotely"
  [cellar-psi]
  (let
      [in-cache (in-cache? cellar-psi)
       model (if in-cache
               (fetch-work-from-cache in-cache)
               (fetch-work-remotely cellar-psi))]
    (if (not in-cache)
      (add-to-cache cellar-psi model))
    model))

(def eli-query "PREFIX cdm: <http://publications.europa.eu/ontology/cdm#>

SELECT ?number ?typedoc ?is_corrigendum  ?pub_date
WHERE {
  ?manif cdm:manifestation_official-journal_part_information_number ?number .
  ?manif cdm:manifestation_official-journal_part_typedoc_printer  ?typedoc .
  ?manif cdm:manifestation_official-journal_part_is_corrigendum_printer ?is_corrigendum .
  ?work cdm:resource_legal_published_in_official-journal ?oj .
  ?oj  cdm:publication_general_date_publication ?pub_date .
  FILTER(strlen(?number) > 0) # && strlen(?typedoc) > 0 && strlen(?is_corrigendum) > 0)
} LIMIT 1")


(defn parse-number
 "Parse numbers of type 2010/24 (EU). This implementation is a bit of a hack since we don't know in advance the sequence and there are ambiguous situations"
 [number]
 (let ;case year / number
     [year-number-parse (first (re-seq #"(19\d{2}|20\d{2})/(\d+)" number))]
   (if year-number-parse
     (list (nth year-number-parse 1) (nth year-number-parse 2))
     (let ;case number / year
         [number-year-parse (first (re-seq #"(\d+)/(19\d{2}|20\d{2})" number))]
       (println number-year-parse)
       (if number-year-parse
         (list (nth number-year-parse 2) (nth number-year-parse 1))
         (list "NO_YEAR" "NO_NUMBER"))))))

(defn eli4psi 
  "Transform where possible a Cellar PSI into an ELI"
  ([cellar-psi]
     (eli4psi cellar-psi (fetch-work cellar-psi)))
  ([cellar-psi model]
     (println cellar-psi)
     (let
         [solutions (rdf/bounce eli-query model)
          solution (first (:data solutions))]
       (println solutions)
       (if solution
         (let
             [number (:number solution)
              [year natural-number] (parse-number number)
              typedoc (get  TYPEDOC_RT_MAPPING (:typedoc solution))]
           (str "http://eli.budabe.eu/eli/" typedoc "/" year "/" natural-number "/oj"))
         (throw (java.lang.IllegalArgumentException. "Cannot build ELI")))
  )))

(defn eli-metadata
  "Return the ELI-encoded metadata for an object"
  [cellar-psi]
  (let
      [model (fetch-work cellar-psi)
       eli (eli4psi cellar-psi model)
       query (clojure.string/replace (slurp "sparql/eli_md.rq") "http://eli.eli/" eli)]
    (model-to-string (rdf/pull query model))))
    

(defroutes app
  (GET "/eli4psi/:psi" [psi] 
       (println "/eli4psi/:psi" psi)
       (str (eli4psi psi)))
  (GET "/eli4psi/:psi/metadata" [psi] 
       (println "/eli4psi/:psi/metadata" psi)
       (eli-metadata psi))
  (GET "/:psi" [psi] 
       (println "/:psi" psi)
       (model-to-string (fetch-work psi)))
  (route/not-found "<h1>Page not found</h1>"))

(defn -main [cellar-psi & args]
  (let
      [m (fetch-work cellar-psi)]
    (save-model m (str "/tmp/" (URLEncoder/encode cellar-psi) ".rdf"))))  