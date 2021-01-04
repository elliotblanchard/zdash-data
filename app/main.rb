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

def get_transactions_block(offset = 0,last_timestamp, log_file)

  trans_saved = 0
  trans_failed = 0
  max_block_size = 20
  retry_pause = 30
  max_retries = 20
  uri_base = 'https://api.zcha.in/v2/mainnet/transactions?sort=timestamp&direction=descending&limit='

  request_uri = "#{uri_base}#{max_block_size}&offset=#{offset}"

  begin
    retries ||= 0
    buffer = open(request_uri).read
  rescue => e
    if retries < max_retries
      retries += 1
      # print "\nError #{e.inspect}, retrying...".colorize(:cyan)
      sleep(retry_pause)
      # print 'retrying'
      # !!!! You need to have it stop and log failure after a certain number of retries !!! #
      retry
    else
      log_file.write("Max retries of #{max_retries} hit. Can't reach API. Shutting down.\n\n")
      exit(false)
    end
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
    print "#{transaction['hash'][0..5]}... ".colorize(:light_blue)
    print 'category '
    print "#{t['category']}. ".colorize(:light_blue)
    print 'at '
    print "#{transaction_time} ".colorize(:yellow)
    print "timestamp: #{transaction['timestamp']} "
    print '/ '
    print "#{transaction['timestamp'] - last_timestamp} ".colorize(:blue)
 
    if t.valid?
      # print "saved".colorize(:green) # keep count of number saved for log
      trans_saved += 1
    else
      # print "not saved #{t.errors.messages}".colorize(:red) # keep count of number not saved for log
      trans_failed += 1
    end
  end
  return_arr = [transactions.last['timestamp'], trans_saved, trans_failed]
end

offset_increment = 15
# interval_jobs = 7200 # 2 hours

ActiveRecord::Base.establish_connection(db_configuration['development'])

filename = '/Users/elliotblanchard/Development/code/react-redux-final-zdash/zdash-data/log/log.txt'

if File.exist?(filename)
  log_file = File.open(filename, 'a')
else
  log_file = File.new(filename, 'w+')
end

offset = 0
overlap = 300 # 5 minutes
trans_saved = 0
trans_failed = 0
last_timestamp = Transaction.maximum('timestamp')
current_timestamp = Float::INFINITY

log_file.write("Getting new transactions. Current time is: #{DateTime.now.strftime('%I:%M%p %a %m/%d/%y')}. Last timestamp is: #{last_timestamp}\n")
print("Getting new transactions. Last timestamp is: #{last_timestamp}\n")

while (last_timestamp - overlap) < current_timestamp
  return_data = get_transactions_block(offset, last_timestamp, log_file)
  current_timestamp = return_data[0]
  trans_saved += return_data[1]
  trans_failed += return_data[2]
  offset += offset_increment
end

log_file.write("Finished getting latest transactions. #{trans_saved} saved and #{trans_failed} failed.\n")
log_file.write("Current time is: #{DateTime.now.strftime('%I:%M%p %a %m/%d/%y')}.\n\n")
print("Current time is: #{DateTime.now.strftime('%I:%M%p %a %m/%d/%y')}.\n\n")
exit(true)
# print " Waiting for #{interval_jobs/3600.0} hours..."

