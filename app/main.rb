require 'active_record'
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

def get_transactions_block(offset = 0,last_timestamp)

  max_block_size = 20
  retry_pause = 30
  uri_base = 'https://api.zcha.in/v2/mainnet/transactions?sort=timestamp&direction=descending&limit='

  request_uri = "#{uri_base}#{max_block_size}&offset=#{offset}"

  begin
    retries ||= 0
    buffer = open(request_uri).read
  rescue => e
    retries += 1
    print "\nError #{e.inspect}, retrying...".colorize(:cyan)
    sleep(retry_pause)
    print 'retrying'
    # !!!! You need to have it stop and log failure after a certain number of retries !!! #
    retry
  end

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

    category = Classify.classify_transaction(t)
    unless t.update(category: category)
      t.destroy # Because duplicate zhash 2:04
    end

    transaction_time = Time.at(transaction['timestamp']).to_datetime.strftime('%I:%M%p %a %m/%d/%y')

    print "\n#{offset+index+1}. "
    print "#{transaction['hash'][0..5]}... ".colorize(:light_blue)
    print 'category '
    print "#{transaction['category']}. ".colorize(:light_blue)
    print 'at '
    print "#{transaction_time} ".colorize(:yellow)
    print "timestamp: #{transaction['timestamp']} "
    print '/ '
    print "#{transaction['timestamp'] - last_timestamp} ".colorize(:blue)
 
    if t.valid?
      print "saved".colorize(:green) # keep count of number saved for log
    else
      print "not saved #{t.errors.messages}".colorize(:red) # keep count of number not saved for log
    end
  end
  transactions.last['timestamp']
end

offset_increment = 15
interval_jobs = 7200 # 2 hours

ActiveRecord::Base.establish_connection(db_configuration['development'])

# Parent loop to get new transactions every few hours
while 1 == 1
  offset = 0
  overlap = 900 # 15 minutes
  last_timestamp = Transaction.maximum('timestamp')
  current_timestamp = Float::INFINITY
  
  print "\nGetting new transactions. Last timestamp is: #{last_timestamp}"
  # Main loop to get latest transactions (while job complete == false)
  while ((last_timestamp - overlap) < current_timestamp)
    # Launch a new thread - if the server is active
    current_timestamp = get_transactions_block(offset, last_timestamp)
    offset += offset_increment
  end
  print "\nFinished getting latest transactions."
  print " Current time is: #{DateTime.now.strftime('%I:%M%p %a %m/%d/%y')}."
  print " Waiting for #{interval_jobs/3600.0} hours..."
  sleep(interval_jobs)
end
