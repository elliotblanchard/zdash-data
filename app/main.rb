require 'active_record'
require 'json'
require 'open-uri'
require 'pry'
require_relative './models/transaction'

def db_configuration
  db_configuration_file = File.join(File.expand_path('..', __FILE__), '..', 'db', 'config.yml')
  YAML.load(File.read(db_configuration_file))
end

ActiveRecord::Base.establish_connection(db_configuration['development'])

request_uri = 'https://api.zcha.in/v2/mainnet/transactions?sort=timestamp&direction=descending&limit=1&offset=0'
buffer = open(request_uri).read
result = JSON.parse(buffer)
binding.pry

# REMEMBER to rate limit API calls
# Use the timestamp to see when you can stop? Is it to the millisecond?