require 'active_record'
require 'json'
require 'open-uri'
require 'pry'
require 'colorize'
require_relative './models/transaction'

def db_configuration
  db_configuration_file = File.join(File.expand_path('..', __FILE__), '..', 'db', 'config.yml')
  YAML.load(File.read(db_configuration_file))
end

def get_transactions_block(offset = 0,last_timestamp)
  max_block_size = 20
  uri_base = 'https://api.zcha.in/v2/mainnet/transactions?sort=timestamp&direction=descending&limit='

  request_uri = "#{uri_base}#{max_block_size}&offset=#{offset}"
  buffer = open(request_uri).read
  transactions = JSON.parse(buffer)

  transactions.each_with_index do |transaction, index|
    t = Transaction.create(
      zhash: transaction['hash'],
      mainChain: transaction['mainChain'],
      fee: transaction['fee'],
      ttype: transaction['type'],
      shielded: transaction['shielded'],
      index: transaction['index'],
      blockHash: transaction['blockHash'],
      blockHeight: transaction['blockHeight'],
      version: transaction['version'],
      lockTime: transaction['lockTime'],
      timestamp: transaction['timestamp'],
      time: transaction['time'],
      vin: transaction['vin'],
      vout: transaction['vout'],
      vjoinsplit: transaction['vjoinsplit'],
      vShieldedOutput: transaction['vShieldedOutput'],
      vShieldedSpend: transaction['vShieldedSpend'],
      valueBalance: transaction['valueBalance'],
      value: transaction['value'],
      outputValue: transaction['outputValue'],
      shieldedValue: transaction['shieldedValue'],
      overwintered: transaction['overwintered']
    )

    transaction_time = Time.at(transaction['timestamp']).to_datetime.strftime('%I:%M%p %a %m/%d/%y')

    print "\n#{offset+index+1}. "
    print "#{transaction['hash'][0..10]}... ".colorize(:light_blue)
    print "at "
    print "#{transaction_time} ".colorize(:yellow)
    print "/ "
    print "#{transaction['timestamp'].to_i - (last_timestamp - 3600)} ".colorize(:blue)
 
    if t.valid?
      print "saved \n".colorize(:green)
    else
      print "not saved #{t.errors.messages} \n".colorize(:red)
    end

    # If timestamp of last transaction was last_timestamp - 3600 (seconds = 1 hour), set job_complete to TRUE so loop ends
    if transaction['timestamp'].to_i < (last_timestamp - 3600)
      print 'Job COMPLETE'.colorize(:green)
      $job_complete = true
    end
  end
end

ActiveRecord::Base.establish_connection(db_configuration['development'])

# REMEMBER to RATE LIMIT API calls
# NO - transactions can/do share timestamps Use the timestamp to see when you can stop? It's to the SECOND only
# Perhaps you can overshoot so you know you can stop when you're a minute past the last timestamp of the PREVIOUS
# last entry in the DB before you start your pass or something like that.
# Probably better to go through the entire DAY the last transaction in the DB was on so you minimize missed entries

# Get the LAST (first) entry from Transactions
# See what the TIMESTAMP was, set that to last_timestamp
last_timestamp = Transaction.last.timestamp

# Set job_complete to false
$job_complete = false

# Set offset to 0
offset = 0

# Start while loop (while job complete == false)
#for i in 0..5
while $job_complete == false
  # Launch a new thread
  Thread.new{ get_transactions_block(offset, last_timestamp) }

  # WAIT 1/5 second
  sleep(1)

  # Increase offset by 15
  offset += 15
end

# WAIT 10 seconds for all threads to complete
sleep(30)

#binding.pry

#t1 = Thread.new{ get_transactions_block(0) }
#t1.join # waits for the thread to finish (otherwise program ends before anything is rec'ed / printed)