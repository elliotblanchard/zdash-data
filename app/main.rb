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

  print "\nLaunching thread."
  print "\nOffeset is: #{offset}"
  print " Current time is: #{DateTime.now.strftime('%I:%M%p %a %m/%d/%y')}."

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
    print "timestamp: #{transaction['timestamp']} "
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
      $overlaps += 1
      print "\nOverlaps found: #{$overlaps}"
      break
    end
  end
end

overlaps_to_stop = 200
offset_increment = 15
interval_thread_launch = 2
interval_server_down = 120
interval_threads_complete = 60
interval_jobs = 18000

ActiveRecord::Base.establish_connection(db_configuration['development'])

# Parent loop to get new transactions every few hours
while 1 == 1
  # $job_complete = false
  $overlaps = 0
  $server_error = false
  offset = 0
  last_timestamp = Transaction.maximum('timestamp')
  print "\nGetting new transactions. Last timestamp is: #{last_timestamp}"
  # Main loop to get latest transactions (while job complete == false)
  while $overlaps < overlaps_to_stop
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
  # Kill all threads
  Thread.list.each do |thread|
    print "\nKilling thread"
    thread.exit unless thread == Thread.current
  end
  print "\nFinished getting latest transactions."
  print " Current time is: #{DateTime.now.strftime('%I:%M%p %a %m/%d/%y')}."
  print " Waiting for #{interval_jobs/3600.0} hours..."
  sleep(interval_jobs)
end

# WAIT for all threads to complete
sleep(interval_threads_complete)