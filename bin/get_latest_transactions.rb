#!/usr/bin/env ruby
require 'active_record'
require 'activerecord-import'
require 'json'
require 'open-uri'
require 'pry'
require 'colorize'
require_relative '../app/models/transaction'
require_relative '../app/helpers/classify'

def db_configuration
  db_configuration_file = File.join(File.expand_path('..', __FILE__), '..', 'db', 'config.yml')
  YAML.load(File.read(db_configuration_file))
end

ActiveRecord::Base.establish_connection(db_configuration['development'])

puts Transaction.maximum('timestamp')