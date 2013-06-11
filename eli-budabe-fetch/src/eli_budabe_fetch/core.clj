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

(defroutes app
  (GET "/:psi" [psi] 
       (println psi)
       (model-to-string (fetch-work psi)))
  (route/not-found "<h1>Page not found</h1>"))

(defn -main [cellar-psi & args]
  (let
      [m (fetch-work cellar-psi)]
    (save-model m (str "/tmp/" (URLEncoder/encode cellar-psi) ".rdf"))))  