(ns eli-budabe-fetch.routing
  (:use eli-budabe-fetch.core)
  (:use compojure.core)
  (:require [clj-http.client :as client])
  (:require [cheshire.core :as json])
  (:use  eli-budabe-fetch.rdfa)
  (:require [compojure.route :as route])
  (:require [compojure.handler :as handler])
  (:require
        [ring.util.response :as resp])
  (:require [ring.adapter.jetty :as jetty]))

(defn parse-int [s]
  (Integer. (re-find #"[0-9]*" s)))
  
(defroutes app-routes
  (GET "/eli4psi" []
       (resp/redirect "/psi2eli.html"))

  (GET "/eli/:typedoc/:year/:natural_number/oj" [typedoc year natural_number]
       (let
           [sector 
            (case typedoc
              ("dir" "dir_impl" "dir_del") "L"
              ("reg" "reg_impl" "reg_del") "R"
              ("dec" "dec_impl" "dec_del") "D"
              nil)
            celex-psi (if sector
                        (format "http://publications.europa.eu/resource/celex/3%s%s%04d" year sector  (parse-int natural_number))
                        nil)]
         (println "celex-psi: " celex-psi)
         (if celex-psi
           (build-rdfa (build-model-from-string (eli-metadata celex-psi)))
           (route/not-found (format "<h1>Document type %s not yet supported</h1>" typedoc)))))

  (GET "/eli/:typedoc/:year/:natural_number/oj/:lang" [typedoc year natural_number lang]
       (resp/redirect (format "/eli/%s/%s/%s/oj" typedoc year natural_number)))

  (GET "/eli/:typedoc/:year/:natural_number/oj/:lang/:format" [typedoc year natural_number lang format]
       (resp/redirect (format "/eli/%s/%s/%s/oj" typedoc year natural_number)))
         
  (GET "/eli4celex/:celex" [celex]
       (resp/redirect (str "/eli4psi/http%3A%2F%2Fpublications.europa.eu%2Fresource%2Fcelex%2F" celex)))

 (GET "/eli4id_jo/:oj" [oj]
       (resp/redirect (str "/eli4psi/http%3A%2F%2Fpublications.europa.eu%2Fresource%2Foj%2F" oj)))
  
  (GET ["/eli4psi/:psi", :psi #"[^/;?]+"] [psi] 
       (println "/eli4psi/:psi" psi)
       (json/generate-string (eli4psi psi)))

  (GET  ["/eli4psi/:psi/metadata", :psi #"[^/;?]+"] [psi] 
       (println "/eli4psi/:psi/metadata" psi)
       (try
         (build-rdfa (build-model-from-string (eli-metadata psi)))
         (catch clojure.lang.ExceptionInfo e
           (route/not-found "<h1>#{psi} not found</h1>"))))

  (GET ["/content/:psi", :psi #"[^/;?]+"] [psi] 
       (let
           [response (get-content psi)]
         ;(println response)
         (println (:headers response))
         (println (get (:headers response) "content-type"))
         (if (= (:status response) 200)
           {:status 200, :headers {"Content-Type" 
                                    (get (:headers response) "content-type")}, :body (:body response)}
           (route/not-found "<h1>Content for #{psi} not found</h1>"))))

  (GET [":psi", :psi #"[^/;?]+"] [psi] 
       (println "/:psi" psi)
       (try
         (model-to-string (fetch-work psi))
         (catch clojure.lang.ExceptionInfo e
           (route/not-found "<h1>#{psi} not found</h1>"))))
  (route/files "/" {:root "public"})
  (route/not-found "<h1>Page not found</h1>"))

(defn wrap-prn-request [handler]
  (fn [request]
    (prn request)
    (handler request)))

(def app
  (-> (handler/api app-routes)
      (wrap-prn-request)))

(defn increase-timeout [server]
  (doseq [connector (.getConnectors server)]
    (.setMaxIdleTime connector (* 5 60 1000))))

(jetty/run-jetty app {:port 3000 :configurator increase-timeout})
