#!/usr/bin/env ruby
#
# Author: Garry
# Date  : 12-13-2010
#
# Utility to create IPv4 blocks and mark them as "available" for allocation

# Rails
APP_PATH = File.expand_path('../../../../config/application', __FILE__)
require_relative '../../../config/boot'
require APP_PATH
Rails.application.require_environment!

def usage
  puts "./create_available_ipv4_blocks.rb <supernet> <size> <num>"
  puts ""
  puts "  Ex: ./create_available_ipv4_blocks.rb 174.136.108.0/22 30 5"
  puts ""
  puts "      Will create 5 /30's within the 174.136.108.0/22 supernet"
end

@SUPERNET = ARGV[0]
@SIZE     = ARGV[1]
@NUM      = ARGV[2]

if ARGV.size < 3
  usage
  exit 1
end

@SIZE    = @SIZE.to_i

if @SIZE < 28
  puts "Did you really want to automatically allocate subnet(s) of size /#{@SIZE} with this scripts?"
  puts ""
  puts "Press enter to continue or CTRL-C to quit"

  $stdin.gets
end

supernet = IpBlock.find_by_cidr(@SUPERNET)

unless supernet
  puts "Cannot find supernet #{@SUPERNET}"
  exit 1
end

@blocks = supernet.subnets_available(@SIZE.to_i, :Strategy => :leftmost, :limit => @NUM.to_i)

@blocks.each do |block|
  if block
    puts "Marking #{block.cidr} as available..."

    block.parent_block = supernet # Set parent
    block.seq          = 100
    block.available    = true
    block.save!
  end
end
