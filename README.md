eli-budabe
==========

Using ELIs in Ruby

Author: Marc Wilhelm Küster

Dependencies
=============

Tested against Ruby 1.9.3

- rdf (http://rdf.rubyforge.org/)
```
sudo gem1.9 install rdf
```
- RDF/XML for RDF.rb (http://rdf.rubyforge.org/rdfxml/)
```
sudo gem1.9 install rdf-rdfxml 
```
- equivalent-xml and nokogiri (preferred by RDF/XML)
```
sudo gem1.9 install equivalent-xml nokogiri
```
- RDF/A for RDF.rb (http://rdf.rubyforge.org/rdfa/)
```
sudo gem1.9 install rdf-rdfa 
```
- RDF-turle for RDF.rb (https://github.com/ruby-rdf/rdf-turtle)
```
sudo gem1.9 install rdf-turtle
```
- SPARQL for RDF.rb (https://github.com/ruby-rdf/sparql)
```
sudo gem1.9 install sparql
```
- Sinatra and Thin
```
sudo gem1.9 install sinatra thin
```
- json
```
sudo gem1.9 install json
```

- Rest-client
```
gem1.9 install rest-client
```


Running of server
===================

In order to ensure sufficiently long-living connections, start thin directly with a suitable timeout (the default timeout of 30 seconds is insufficient):

```
thin -d -t 240 -p 4567 start
```

Fuseki as server backend
===========================
Download latest version of Fuseki and unzip. Run the server with
```
./fuseki-server -loc=/var/lib/fuseki/eli ---update /eli
```

Storage location chosen to be /var/lib/fuseki/eli (any other location will work just as well)

```
curl -v -XPUT -T 32012L0012.ttl --header "Content-type: text/turtle;charset=utf-8" http://localhost:3030/eli/data?graph=http%3A%2F%2Fpublications.europa.eu%2Fresource%2Fcelex%2F32012L0012

curl -v -XPUT -T 32012L0012R%2801%29.ttl --header "Content-type: text/turtle;charset=utf-8" http://localhost:3030/eli/data?graph=http%3A%2F%2Fpublications.europa.eu%2Fresource%2Fcelex%2F32012L0012R%2801%29

curl -v http://localhost:3030/eli/data?graph=http%3A%2F%2Fpublications.europa.eu%2Fresource%2Fcelex%2F32012L0012
```



