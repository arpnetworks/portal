#!/usr/bin/env ruby
require 'rubygems'
require 'mysql2'

Mysql2::Client.default_query_options.merge!(:as => :array)
conn = Mysql2::Client.new(:host => 'localhost', :username => 'root', 
  :database => 'arp_customer_cp')

tables = conn.query("SHOW TABLES").map {|row| row[0] }

# See http://dev.mysql.com/doc/refman/5.0/en/charset-column.html
# One might want to include enum and set columns, but I don't
TYPES_TO_CONVERT = %w(char varchar text)
tables.each do |table|
  puts "converting #{table}"
  # Get all the columns and we'll filter for the ones we want
  columns = conn.query("DESCRIBE #{table}")
  columns_to_convert = columns.find_all {|row|
    TYPES_TO_CONVERT.include? row[1].gsub(/\(\d+\)/, '')
  }.map {|row| row[0]}
  next if columns_to_convert.empty?

  query = "UPDATE `#{table}` SET "
  query += columns_to_convert.map {|col|
    "`#{col}` = convert(cast(convert(`#{col}` using latin1) as binary) using utf8)"
  }.join ", "
  puts query
  conn.query query
end
