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

  begin
    retries ||= 0
    buffer = open(request_uri).read
  rescue => e
    retries += 1
    print "\nError #{e.inspect}, retrying (attempt #{retries})...".colorize(:cyan)
    sleep(30)
    $server_error = true
    print "retrying"
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
    print "at "
    print "#{transaction_time} ".colorize(:yellow)
    print "/ "
    print "#{transaction['timestamp'].to_i - (last_timestamp - 3600)} ".colorize(:blue)
 
    if t.valid?
      print "saved".colorize(:green)
    else
      print "not saved #{t.errors.messages}".colorize(:red)
    end

    # If timestamp of last transaction was last_timestamp - 3600 (seconds = 1 hour), 
    # set job_complete to TRUE so loop ends
    if transaction['timestamp'].to_i < (last_timestamp - 3600)
      $job_complete = true
      break
    end
  end
end

ActiveRecord::Base.establish_connection(db_configuration['development'])

last_timestamp = Transaction.maximum('timestamp')

$job_complete = false
$server_error = false

offset = 0
rest_counter = 0

# Parent loop to get new transactions every few hours
while 1 == 1
    # Main loop to get latest transactions (while job complete == false)
    while $job_complete == false
        # Launch a new thread - if the server is active
        if $server_error == false
            Thread.new{ get_transactions_block(offset, last_timestamp) }

            # WAIT 1/5 second
            sleep(1)

            # Increase offset by 15
            offset += 15
            rest_counter += 1

            if rest_counter == 250
            print "\nPausing execution"
            sleep(60)
            rest_counter = 0
            end
        else
            print "\nServer is down. Pausing for 120 seconds"
            sleep(120)
            print "\nResuming"
            $server_error = false
        end
    end
    # WAIT 60 seconds for all threads to complete
    sleep(60)
    print "\nFinished getting latest transactions. Current time is: #{DateTime.now.strftime('%I:%M%p %a %m/%d/%y')}. Waiting for 5 hours..."
    sleep(5.hours)
end

# WAIT 60 seconds for all threads to complete
sleep(60)