#!/usr/bin/env ruby

require 'rbconfig'
require 'optparse'

# define operating modes
OPERATING_MODE_DISPLAY_STDOUT = 0
OPERATING_MODE_COPY_TO_CLIPBOARD = 1
OPERATING_MODE_SHOW_HELP = 2

@operating_mode = OPERATING_MODE_DISPLAY_STDOUT
@system_information = {}

##
# Checks if the user has provided any arguments for our operating mode
##

def arg_check(args)
    if args.count == 1 && args[0].downcase == "help"
        @operating_mode = OPERATING_MODE_SHOW_HELP
        exit_usage
    elsif args.count == 1 && args[0].downcase = "copy"
        @operating_mode = OPERATING_MODE_COPY_TO_CLIPBOARD
    elsif args.count == 0
        # default mode, will simply output the ip from the first active interface to STDOUT
        @operating_mode = OPERATING_MODE_DISPLAY_STDOUT
    end
end

def exit_usage
    usage_string = "Usage: \n"
    puts usage_string
end

def main
    # Usage for anyone who wants to know
    arg_check ARGV

    describe_system
    if @operating_mode == OPERATING_MODE_DISPLAY_STDOUT
    elsif @operating_mode == OPERATING_MODE_COPY_TO_CLIPBOARD
    end

    poll_available_network_interfaces
end


##
# Describe the type of system the user is currently on. Initially support Unix variants:
# - Darwin
# - Linux
##
def describe_system
   
    # get the useful system information we want
    host_os = RbConfig::CONFIG['host_os'] # OS name
    is_windows = (host_os =~ /mswin|mingw|cygwin/).nil? ? false : true

    hostname = !is_windows ? `uname -n` : `hostname` # network node name

    @system_information = {:host_os => host_os, :is_windows => is_windows, :hostname => hostname}

    puts @system_information[:host_os]
    puts @system_information[:hostname]
    return @system_information
end

def poll_available_network_interfaces
    # get all of the interfaces on the system - they'll be separated by spaces, so put them in an array
    @if_list = []
    all_interfaces_str = `ifconfig -l`
    all_interfaces = all_interfaces_str.split(" ")
    all_interfaces.each do |interface|
        iface = {:name => interface, :ip => ""}
        @if_list.push(iface)
    end
    puts @if_list
end

main
