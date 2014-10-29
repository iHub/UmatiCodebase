import requests
import json
JSON_HEADERS = {'Content-type': 'application/json', 'Accept': 'text/plain'}

def posneg(text):
    data_dict = json.dumps({'text': text})
    response = requests.post("http://api.indico.io/sentiment", data=data_dict, headers=JSON_HEADERS)
    response_dict = response.json()
    if 'Sentiment' not in response_dict:
      raise ValueError(response_dict.values()[0])
    else:
      return response_dict['Sentiment']
