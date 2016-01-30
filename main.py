import pprint

from apiclient.discovery import build

def main():
  # Build a service object for interacting with the API.
  api_root = 'https://smart-container-1203.appspot.com/_ah/api'
  api = 'sensor'
  version = 'v1'
  discovery_url = '%s/discovery/v1/apis/%s/%s/rest' % (api_root, api, version)
  service = build(api, version, discoveryServiceUrl=discovery_url)

  # Fetch all greetings and print them out.
  response = service.data().create().execute()
  pprint.pprint(response)


if __name__ == '__main__':
  main()
