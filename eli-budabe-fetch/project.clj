(defproject eli-budabe-fetch "0.1.0-SNAPSHOT"
  :description "Fetching data from a local or remote RDF repository"
  :url "http://example.com/FIXME"
  :license {:name "Eclipse Public License"
            :url "http://www.eclipse.org/legal/epl-v10.html"}
  :main eli-budabe-fetch.core
  :dependencies [[org.clojure/clojure "1.4.0"] 
                 [clj-http "0.7.2"]
                 ;[clojure-saxon "0.9.3"]
                 [cheshire "5.2.0"]
                 [compojure "1.1.5"]
                 [enlive "1.1.1"]
                 [hiccup "1.0.3"]
                 [seabass "2.0"]]
  :plugins [[lein-ring "0.8.5"]]
  :ring {:handler eli-budabe-fetch.routing/app}
  :profiles
  {:dev {:dependencies [[ring-mock "0.1.5"]]}})
