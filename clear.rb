#!/usr/bin/env ruby

require 'sidekiq/api'

Sidekiq::RetrySet.new.clear
