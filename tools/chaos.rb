#!/usr/bin/env ruby

require 'droplet_kit'
require 'optparse'
require 'byebug'

def main()
  opts = parse_command_line_opts()
  the_center_does_not_hold(opts)
end

def parse_command_line_opts()
  parsed_options = {}

  # Set defaults
  parsed_options[:environment] = 'testing'
  parsed_options[:mercy] = []
  parsed_options[:smite] = []
  parsed_options[:wait] = 1000
  parsed_options[:chance] = 10

  OptionParser.new do |cfg|
    cfg.banner = "Usage: chaos.rb [options]"

    #   prod or testing
    cfg.on("-p", "--production", "Run against production env") do |e|
      parsed_options[:environment] = 'production'
    end
    cfg.on("-t", "--testing", "Run against testing env") do |e|
      parsed_options[:environment] = 'testing'
    end

    #   group(s) to have mercy on 
    cfg.on("-mGROUP", "--mercy GROUP", "Spare GROUP from chaos") do |m|
      parsed_options[:mercy] << m
    end

    #   groups to smite
    cfg.on("-sGROUP", "--smite GROUP", "Ensure chaos hits GROUP") do |s|
      parsed_options[:smite] << s
    end

    #   sleep time
    cfg.on("-wMSEC", "--wait MSEC", "Wait MSEC milliseconds between droplets", OptionParser::DecimalInteger) do |w|
      parsed_options[:wait] = w
    end

    #   chance of chaos
    cfg.on("-cPCT", "--chance PCT", "Percent (1-100) chance of chaos.", OptionParser::DecimalInteger) do |c|
      parsed_options[:chance] = c
    end
    
  end.parse!
  return parsed_options

end

def dropname2groupname(dname)
  # testing-vm-#{group name}.vm.io 
  return dname.split('.')[0].split('-')[-1]
end

def dropname2envname(dname)
  # testing-vm-#{group name}.vm.io 
  return dname.split('.')[0].split('-')[0]
end

def log (level, msg)
  time = DateTime.now().strftime('%H:%M:%S')
  puts sprintf('%5s - %s - %s',level.to_s.upcase(), time, msg) 
end


def the_center_does_not_hold(opts)
  log(:info, "Connecting to DO")
  dk = DropletKit::Client.new(access_token: ENV['DIGITALOCEAN_ACCESS_TOKEN'])

  # Loop forever
  while true do
    #   Fetch a list of running droplets
    log(:info, "Fetching droplet list")
    drops = dk.droplets.all.sort { |a,b| a.name <=> b.name }

    #   Filter based on status
    inactive = drops.select { |d| d.status != 'active' }
    drops -= inactive

    #   Filter based on mercy
    pardoned = drops.select { |d| opts[:mercy].include?(dropname2groupname(d.name)) }
    drops -= pardoned

    #   Filter based on prod or testing
    nimby = drops.select { |d| opts[:environment] != dropname2envname(d.name) }
    drops -= nimby

    # TODO: report on counts   


    #   Loop over droplets
    drops.each do |drop|
      log(:debug, "Examining droplet #{drop.name}")
      # byebug
#     Connect via SSH
#        check for running service
#          if running
#            roll dice
#            based on dice and smite
#            halt service
#     sleep
    end
  end
end

Signal.trap('SIGINT') do
  puts "Exiting"
  exit(0)
end

main()
