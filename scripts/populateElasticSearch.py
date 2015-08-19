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

   # INDEX_NAME = 'estates'
   INDEX_NAME = 'buildings'
   BUILDING2_JSON = 'estates.json'
   BUILDING_JSON = 'uoe-estates-buildings.json'

   ES_HOST = 'dlib-brown.edina.ac.uk'
   ES_PORT = '9200'

   def __init__(self):
       self.es = Elasticsearch([{'host': self.ES_HOST, 'port': self.ES_PORT}])


   def loadEstatesBuildings(self):

       i = 1
       with open(self.BUILDING_JSON, 'rU') as data_file:
          data = json.load(data_file)
          # for loc in data['locations']:
          for loc in data['features']:
              # Have to modify the locations to ensure they're stored in the correct format for es spatial searching
              loc['geometry']['location'] =  loc['geometry'].pop('coordinates')

              # Add to index
              self.es.index(index=self.INDEX_NAME, doc_type='building', id=i, body=loc)
              i += 1

       with open(self.BUILDING2_JSON, 'rU') as data_file:
          data = json.load(data_file)
          for loc in data['locations']:
              # Have to modify the locations to ensure they're stored in the correct format for es spatial searching
              name = loc.get('name');
              if name:
                  latitude = loc['latitude'];
                  longitude = loc['longitude'];

                  # Populate expected template
                  location = {
                     "geometry":{
                        "location":[float(longitude), float(latitude)],
                         "type": "Point"
                      },
                     "properties":{
                         "area": loc.get('campuses'),
                         "image":"",
                         "subtitle": loc.get('address'),
                         "title": name,
                         "information":[{
                                 "area":"General",
                                 "items":[{
                                     "description":"",
                                     "image": "",
                                     "notes": "",
                                     "type" : ""
                                     }]
                        }]
                      },
                     "type":"Feature"
                     }


                  # Add to index
                  self.es.index(index=self.INDEX_NAME, doc_type='building', id=i, body=location)
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
                 "building": {
                     "properties": {
                         "geometry": {
                             "properties": {
                                 "location": {
                                     "type": "geo_point"
                                     },
                                 "type": {
                                     "type": "string"
                                     }
                                 }
                             },
                         "properties": {
                             "properties": {
                                 "area": {
                                     "type": "string"
                                     },
                                 "image": {
                                     "type": "string"
                                     },
                                 "information": {
                                     "properties": {
                                         "area": {
                                             "type": "string"
                                             },
                                         "items": {
                                             "type": "nested",
                                             "properties": {
                                                 "description": {
                                                     "type": "string"
                                                     },
                                                 "image": {
                                                     "type": "string"
                                                     },
                                                 "notes": {
                                                     "type": "string"
                                                     },
                                                 "type": {
                                                     "type": "string"
                                                     }
                                                 }
                                             }
                                         }
                                     },
                                 "subtitle": {
                                     "type": "string"
                                     },
                                 "title": {
                                     "type": "string"
                                     }
                                 }
                             },
                         "type": {
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

# print loader.es.get(index=loader.INDEX_NAME, doc_type="building", id=1)
time.sleep(2)
res = loader.es.search(index=loader.INDEX_NAME, body={"query": {"match_all": {}}})
print("Done : Indexed %d buildings" % res['hits']['total'])
