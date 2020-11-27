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
  transaction_overlap = 3600
  uri_base = 'https://api.zcha.in/v2/mainnet/transactions?sort=timestamp&direction=descending&limit='

  request_uri = "#{uri_base}#{max_block_size}&offset=#{offset}"

  begin
    retries ||= 0
    buffer = open(request_uri).read
  rescue => e
    retries += 1
    print "\nError #{e.inspect}, retrying (attempt #{retries})...".colorize(:cyan)
    sleep(30)
    $server_error = true
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

    transaction_time = Time.at(transaction['timestamp']).to_datetime.strftime('%I:%M%p %a %m/%d/%y')

    print "\n#{offset+index+1}. "
    print "#{transaction['hash'][0..10]}... ".colorize(:light_blue)
    print 'at '
    print "#{transaction_time} ".colorize(:yellow)
    print '/ '
    print "#{transaction['timestamp'].to_i - (last_timestamp - transaction_overlap)} ".colorize(:blue)
 
    if t.valid?
      print "saved".colorize(:green)
    else
      print "not saved #{t.errors.messages}".colorize(:red)
    end

    # If timestamp of last transaction was last_timestamp - transaction_overlap
    # set job_complete to TRUE so loop ends. The overlap is to catch any transactions
    # that may have been missed in the last loop
    if transaction['timestamp'].to_i < (last_timestamp - transaction_overlap)
      $job_complete = true
      break
    end
  end
end

offset = 0
offset_increment = 15
interval_thread_launch = 0.2
interval_server_down = 120
interval_threads_complete = 60
interval_jobs = 18000

ActiveRecord::Base.establish_connection(db_configuration['development'])
last_timestamp = Transaction.maximum('timestamp')

# Parent loop to get new transactions every few hours
while 1 == 1
  $job_complete = false
  $server_error = false
  # Main loop to get latest transactions (while job complete == false)
  while $job_complete == false
    # Launch a new thread - if the server is active
    if $server_error == false
      Thread.new{ get_transactions_block(offset, last_timestamp) }
      sleep(interval_thread_launch)
      offset += offset_increment
    else
      print "\nServer is down. Pausing for #{interval_server_down} seconds"
      sleep(interval_server_down)
      print "\nResuming"
      $server_error = false
    end
  end
  # WAIT for all threads to complete
  sleep(interval_threads_complete)
  print "\nFinished getting latest transactions."
  print " Current time is: #{DateTime.now.strftime('%I:%M%p %a %m/%d/%y')}."
  print " Waiting for #{interval_jobs/3600} hours..."
  sleep(interval_jobs)
end

# WAIT for all threads to complete
sleep(interval_threads_complete)