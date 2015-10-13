import json
from pprint import pprint
import time
from elasticsearch import Elasticsearch
import argparse
import requests


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

   API_BASE_URL = 'http://0.0.0.0:3001/api';

   def __init__(self):
       self.es = Elasticsearch([{'host': self.ES_HOST, 'port': self.ES_PORT}])

   def postImage(self, imageName, id):

       file = {'file': open('EstatesBuildingsImages/'+ imageName, 'rb')}
       url= '%s/images/%s/upload' %(self.API_BASE_URL, id)
       r = requests.post(url, files=file)
       print r.text


   def loadEstatesBuildings(self):
       headers = {'Content-Type':'application/json'};

       i = 1
       with open(self.BUILDING_JSON, 'rU') as data_file:
          data = json.load(data_file)
          # for loc in data['locations']:
          for loc in data['features']:
              # Have to modify the locations to ensure they're stored in the correct format for es spatial searching
              loc['geometry']['location'] = loc['geometry'].pop('coordinates')

              # Add to index
              self.es.index(index=self.INDEX_NAME, doc_type='building', id=i, body=loc)

              # Post a new image container for this building to loopback Estates-API
              url= '%s/images' %(self.API_BASE_URL)
              newImageContainer = {"name": str(i)};

              # Remove old image container and any images within
              requests.delete('%s/%s' % (url, str(i)), headers=headers)
              r = requests.post(url, headers=headers, data=json.dumps(newImageContainer))

              buildingImage = loc['properties']['image']

              self.postImage(buildingImage, i)

              areas= loc['properties']['information'];

              # POST the images for all facilities in each area
              for area in areas:

                  items = area['items'];

                  for item in items:
                      imageName = item['image'];
                      if imageName:
                          self.postImage(imageName, i)

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
                         "information":[]
                         },
                     "type":"Feature"
                     }


                  # Add to index
                  self.es.index(index=self.INDEX_NAME, doc_type='building', id=i, body=location)

                  requests.delete('%s/%s' % (url, str(i)), headers=headers)
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
                                             "type": "string",
                                             "fields": {
                                                 "raw":   { "type": "string", "index": "not_analyzed" }
                                                 }
                                             },
                                         "items": {
                                             "type": "nested",
                                             "include_in_parent": "true",
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
                                                     "type": "string",
                                                     "fields": {
                                                         "raw":   { "type": "string", "index": "not_analyzed" }
                                                         }
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
