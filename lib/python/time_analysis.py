import requests
from random import randrange 

#test local search time

url3 = "http://now-uat.herokuapp.com/events"
url4 = "http://localhost:3001/events"

payload3 = {'nowtoken' : '', 'debug_opt' : 'true'}

latitude = 40.717504
longitude = -74.001331

for i in range(0,10):
  r1 = randrange(-15,15)
  r2 = randrange(-15,15)
  f1 = 0.000001 * r1
  f2 = 0.000001 * r2

  latitude += f1
  longitude += f2
  payload3['lon_lat'] = str(longitude) + "," + str(latitude)
  print payload3
  r = requests.get(url4, data=payload3)
  print r.text
