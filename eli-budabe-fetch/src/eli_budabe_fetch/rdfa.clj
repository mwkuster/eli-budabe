(ns eli-budabe-fetch.rdfa
  (:require [seabass.core :as rdf])
  (:use hiccup.core))

(def query-ordered-eli "PREFIX eli: <http://eurlex.europa.eu/eli#>\nSELECT ?s ?p ?o WHERE {?s ?p ?o. ?s a eli:resource_legal .} ORDER BY DESC(?s) DESC(?p) DESC(?o)")

(defn build-table [model]
  (let
      [sol (:data (rdf/bounce query-ordered-eli model))
       subj (:s (first sol))
       pred-partion (partition-by :p sol)]
    (html [:html 
           [:head 
            [:title subj]
            [:link {:rel "stylesheet" :href "/eli.css"}]] 
           [:body 
            [:div {:class "resource" :resource subj}
             [:h1 (str "ELI notice for " subj)]
             [:h2 subj]
             [:table 
              [:tr
               [:th "Type of metadata"]
               [:th "Value"]]
              (for [pred-obj pred-partion]
                (for [triple pred-obj]
                  [:tr
                   [:td (:p triple)]
                   [:td (let
                            [obj (:o triple)]
                          (if (and (string? obj) (.startsWith obj "http://"))
                            [:a {:href obj} obj]
                            obj))]]))]]]])))
              
            
    
    