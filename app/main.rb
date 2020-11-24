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

current_result = result[0]
transaction = Transaction.create(
    zhash: current_result['hash'], 
    mainChain: current_result['mainChain'],
    fee: current_result['fee'], 
    ttype: current_result['type'],
    shielded: current_result['shielded'],
    index: current_result['index'],
    blockHash: current_result['blockHash'],
    blockHeight: current_result['blockHeight'],
    version: current_result['version'],
    lockTime: current_result['lockTime'],
    timestamp: current_result['timestamp'],
    time: current_result['time'],
    vin: current_result['vin'],
    vout: current_result['vout'],
    vjoinsplit: current_result['vjoinsplit'],
    vShieldedOutput: current_result['vShieldedOutput'],
    vShieldedSpend: current_result['vShieldedSpend'],
    valueBalance: current_result['valueBalance'],
    value: current_result['value'],
    outputValue: current_result['outputValue'],
    shieldedValue: current_result['shieldedValue'],
    overwintered: current_result['overwintered']
)

if transaction.valid?
  print 'transaction saved'
else
  print 'transaction invalid'
end

# binding.pry

# REMEMBER to rate limit API calls
# Use the timestamp to see when you can stop? Is it to the millisecond?