require 'active_record'
require 'json'
require 'open-uri'
require 'pry'
require 'colorize'
require_relative './models/transaction'
require_relative './helpers/classify'

clear_line = "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b"

def db_configuration
  db_configuration_file = File.join(File.expand_path('..', __FILE__), '..', 'db', 'config.yml')
  YAML.load(File.read(db_configuration_file))
end

def get_transactions_block(offset = 0,last_timestamp)

  max_block_size = 20
  retry_pause = 30
  transaction_overlap = 1000
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
      t.destroy # Because duplicate zhash
    end

    transaction_time = Time.at(transaction['timestamp']).to_datetime.strftime('%I:%M%p %a %m/%d/%y')

    print "\n#{offset+index+1}. "
    print "#{transaction['hash'][0..10]}... ".colorize(:light_blue)
    print 'at '
    print "#{transaction_time} ".colorize(:yellow)
    print "timestamp: #{transaction['timestamp']} "
    print '/ '
    print "#{transaction['timestamp'] - last_timestamp} ".colorize(:blue)
 
    if t.valid?
      print "saved".colorize(:green)
    else
      print "not saved #{t.errors.messages}".colorize(:red)
    end
  end
  transactions.last['timestamp']
end

overlaps_to_stop = 20
offset_increment = 15
interval_server_down = 120
interval_threads_complete = 60
interval_increase = 3000
interval_increment = 3
interval_jobs = 14400

ActiveRecord::Base.establish_connection(db_configuration['development'])

# Parent loop to get new transactions every few hours
while 1 == 1
  # $job_complete = false
  offset = 0
  doubling_counter = 0
  interval_thread_launch = 4
  #last_timestamp = Transaction.maximum('timestamp')
  last_timestamp = 1609593782
  current_timestamp = Float::INFINITY
  
  print "\nGetting new transactions. Last timestamp is: #{last_timestamp}"
  # Main loop to get latest transactions (while job complete == false)
  while last_timestamp < current_timestamp
    # Launch a new thread - if the server is active
    current_timestamp = get_transactions_block(offset, last_timestamp)
    offset += offset_increment
  end
  print "\nFinished getting latest transactions."
  print " Current time is: #{DateTime.now.strftime('%I:%M%p %a %m/%d/%y')}."
  print " Waiting for #{interval_jobs/3600.0} hours..."
  sleep(interval_jobs)
end
