require 'active_record'
require 'activerecord-import'
require 'json'
require 'open-uri'
require 'pry'
require 'colorize'
require_relative './models/transaction'
require_relative './helpers/classify'

def db_configuration
  db_configuration_file = File.join(File.expand_path('..', __FILE__), '..', 'db', 'config.yml')
  YAML.load(File.read(db_configuration_file))
end

ActiveRecord::Base.establish_connection(db_configuration['development'])

offset = 0
offset_increment = 15
overlap = 300 # 5 minutes
last_timestamp = Transaction.maximum('timestamp')
current_timestamp = Float::INFINITY
trans_saved = 0
trans_failed = 0
max_block_size = 20
retry_pause = 30
max_retries = 20
latest_transactions = []
uri_base = 'https://api.zcha.in/v2/mainnet/transactions?sort=timestamp&direction=descending&limit='
filename = '/Users/elliotblanchard/Development/code/react-redux-final-zdash/zdash-data/log/log.txt'

if File.exist?(filename)
  log_file = File.open(filename, 'a')
else
  log_file = File.new(filename, 'w+')
end

log_file.write("Getting new transactions. Current time is: #{DateTime.now.strftime('%I:%M%p %a %m/%d/%y')}. Last timestamp is: #{last_timestamp}\n")
print("Getting new transactions. Last timestamp is: #{last_timestamp}\n")

while (last_timestamp - overlap) < current_timestamp
  #return_data = get_transactions_block(offset, last_timestamp, log_file)
  #current_timestamp = return_data[0]
  #trans_saved += return_data[1]
  #trans_failed += return_data[2]

  request_uri = "#{uri_base}#{max_block_size}&offset=#{offset}"

  begin
    retries ||= 0
    buffer = open(request_uri).read
  rescue => e
    if retries < max_retries
      retries += 1
      sleep(retry_pause)
      print("Retrying API request.\n")
      retry
    else
      log_file.write("Max retries of #{max_retries} hit. Can't reach API. Shutting down.\n\n")
      exit(false)
    end
  end

  transactions = JSON.parse(buffer)

  transactions.each_with_index do |transaction, index|
    t = Transaction.new(
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

    t.category = Classify.classify_transaction(t)
    latest_transactions << t
    
    #unless t.save
    #  t.destroy # Because duplicate zhash
    #end
 
    transaction_time = Time.at(transaction['timestamp']).to_datetime.strftime('%I:%M%p %a %m/%d/%y')

    print "\n#{offset + index + 1}. "
    print "#{transaction['hash'][0..5]}... ".colorize(:light_blue)
    print 'category '
    print "#{t['category']}. ".colorize(:light_blue)
    print 'at '
    print "#{transaction_time} ".colorize(:yellow)
    print "timestamp: #{transaction['timestamp']} "
    print '/ '
    print "#{transaction['timestamp'] - last_timestamp} ".colorize(:blue)
 
    #if t.valid?
    #  trans_saved += 1
    #else
    #  trans_failed += 1
    #end  
  end
  offset += offset_increment
  current_timestamp = transactions.last['timestamp']
end

Transaction.import latest_transactions # Import all transactions to the db at same time to speed things up

log_file.write("Finished getting latest transactions. #{latest_transactions.length} processed.\n")
log_file.write("Current time is: #{DateTime.now.strftime('%I:%M%p %a %m/%d/%y')}.\n\n")
print("Current time is: #{DateTime.now.strftime('%I:%M%p %a %m/%d/%y')}.\n\n")
exit(true)