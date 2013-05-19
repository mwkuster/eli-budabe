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
thin -d -t 120 -p 4567 start
```

4store as server backend
===========================
Largely inspired by the excellent http://www.jenitennison.com/blog/node/152

```
4s-backend-setup eli (only once during the initial setup)
4s-backend eli
4s-httpd -p 8000 -U eli
```

Data physically stored under /var/lib/4store/eli/
