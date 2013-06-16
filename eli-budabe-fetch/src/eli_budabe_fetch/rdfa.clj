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
            [:p {:class "warning"} "This tool is purely experimental, privately maintained and certain to change. No guarantee for any of the ELIs generated."]
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
                                (case obj
                                  ((.startsWith obj "http://publications.europa.eu/resource/cellar/"))
                                  [:a {:property (:p triple) :href obj :onClick (str "this.removeAttribute('href');var loc = '/content/'+encodeURIComponent('" obj "'); window.location =  loc;")} obj]
                                  ((.startsWith obj "http://publications.europa.eu/resource/authority/"))
                                  [:a {:property (:p triple) :href obj :onClick (str "this.removeAttribute('href');var loc = 'http://publications.europa.eu/mdr/authority/index.html'")} obj]
                                  [:a {:property (:p triple) :href obj} obj])
                                [:span {:property (:p triple) :content obj} obj]))]]))]]))]])))
              
            
    
    