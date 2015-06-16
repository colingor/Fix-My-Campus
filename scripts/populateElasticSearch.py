import json
from pprint import pprint
import time
from elasticsearch import Elasticsearch
import argparse



parser = argparse.ArgumentParser(description="""Script to read estates.json into ElasticSearch index. To change path to estates.json
        buildings file or ElasticSearch host and port please modify class variables directly. Note that you have to install the
        elasticsearch module with 'pip install elasticsearch' to use this script""")
results = parser.parse_args()

class PopulateElasticSearch:

   INDEX_NAME = 'estates'
   BUILDING_JSON = 'estates.json'

   ES_HOST = 'localhost'
   ES_PORT = '9200'

   def __init__(self):
       self.es = Elasticsearch([{'host': self.ES_HOST, 'port': self.ES_PORT}])

   def loadEstatesBuildings(self):

       with open(self.BUILDING_JSON, 'rU') as data_file:
          data = json.load(data_file)
          i = 1
          for loc in data['locations']:
              # Have to modify the locations to ensure they're stored in the correct format for es spatial searching
              name = loc.get('name');
              if name:
                  latitude = loc['latitude'];
                  longitude = loc['longitude'];
                  location = ('%s, %s' % (latitude, longitude))
                  loc['location'] = location;
                  loc.pop('latitude')
                  loc.pop('longitude')

                  # Add to index
                  self.es.index(index=self.INDEX_NAME, doc_type='location', id=i, body=loc)
                  i += 1


   def recreateElasticSearchIndex(self):
     try:
         # For now we'll delete and recreate the index
         self.es.indices.delete(index=self.INDEX_NAME)
     except Exception:
         # Ignore exception caused when no index to delete
         pass

     # have to specify mapping so geo_points are indexed correctly
     mapping = {
             "mappings": {
                 "location": {
                     "properties": {
                         "abbreviation": {
                             "type": "string"
                             },
                         "address": {
                             "type": "string"
                             },
                         "campuses": {
                             "type": "string"
                             },
                         "categories": {
                             "type": "string"
                             },
                         "location": {
                             "type": "geo_point"
                             },
                         "name": {
                             "type": "string"
                             }
                         }
                     }
                 }
             }

     self.es.indices.create(index=self.INDEX_NAME, body=mapping)

# Begin
loader = PopulateElasticSearch()
loader.recreateElasticSearchIndex()
loader.loadEstatesBuildings()

# print loader.es.get(index=loader.INDEX_NAME, doc_type="location", id=42)
time.sleep(2)
res = loader.es.search(index=loader.INDEX_NAME, body={"query": {"match_all": {}}})
print("Done : Indexed %d buildings" % res['hits']['total'])
