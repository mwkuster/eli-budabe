(ns eli-budabe-fetch.rdfa
  (:require [seabass.core :as rdf])
  (:use hiccup.core))

(def query-ordered-eli "PREFIX eli: <http://eurlex.europa.eu/eli#>\nSELECT ?w ?s ?p ?o WHERE {?s ?p ?o. ?w a eli:resource_legal . {?s a eli:resource_legal} UNION {?s a eli:interpretation} UNION {?s a eli:format}} ORDER BY DESC(?s) DESC(?p) DESC(?o)")

(defn build-rdfa [model]
  (let
      [sol (:data (rdf/bounce query-ordered-eli model))
       subj-partition (partition-by :s sol)
       work (:w (first sol))]
    (html [:html {:xmlns "http://www.w3.org/1999/xhtml"}
           [:head 
            [:meta {:charset "utf-8"}]
            [:base {:href ""}]
            [:title work]
            [:link {:rel "stylesheet" :href "/eli.css"}]] 
           [:body  {:class "md"}
            [:h1 {:class "md"} (str "ELI notice for " work)]
            (for [subj-pred subj-partition]
              (let
                  [pred-partition (partition-by :p subj-pred)
                   subj (:s (first (first pred-partition)))]
                [:div {:class "resource" :resource subj}
                 [:h2 subj]
                 [:table 
                  [:tr
                   [:th "Property"]
                   [:th "Value"]]
                  (for [pred-obj pred-partition]
                    (for [triple pred-obj]
                      [:tr 
                       [:td (:p triple)]
                       [:td (let
                                [obj (:o triple)]
                              (if (and (string? obj) (.startsWith obj "http://"))
                                [:a {:property (:p triple) :href obj} obj]
                                [:span {:property (:p triple) :content obj} obj]))]]))]]))]])))
              
            
    
    