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

def get_transactions_block(offset = 0)
  max_block_size = 20

  request_uri = "https://api.zcha.in/v2/mainnet/transactions?sort=timestamp&direction=descending&limit=#{max_block_size}&offset=#{offset}"
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

    print "#{index+1}. Transaction "
    print "#{transaction['hash'][0..10]}... ".colorize(:light_blue)
    print "at "
    print "#{transaction_time} ".colorize(:yellow)
 
    if t.valid?
      print "saved \n".colorize(:green)
    else
      print "not saved #{t.errors.messages} \n".colorize(:red)
    end
  end
end

ActiveRecord::Base.establish_connection(db_configuration['development'])

# REMEMBER to rate limit API calls
# NO - transactions can/do share timestamps Use the timestamp to see when you can stop? It's to the SECOND only
# Perhaps you can overshoot so you know you can stop when you're a minute past the last timestamp of the PREVIOUS
# last entry in the DB before you start your pass or something like that.
# Probably better to go through the entire DAY the last transaction in the DB was on so you minimize missed entries

t1 = Thread.new{ get_transactions_block(0) }
t1.join # waits for the thread to finish before ending the program (otherwise program ends before anything is recieved / printed)