#!/usr/bin/env ruby

require 'rbconfig'
require 'optparse'

class IPGrabber
    # define operating modes
    OPERATING_MODE_DISPLAY_STDOUT = 0
    OPERATING_MODE_COPY_TO_CLIPBOARD = 1
    OPERATING_MODE_SHOW_HELP = 2
    REGEX_IPV4 = "^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$"

    def initialize
        @operating_mode = OPERATING_MODE_DISPLAY_STDOUT
        @system_information = {}
        @common_interface_names = "lo0\|en0\|en1\|eth0\|eth1"
        @ifaces = {}

        describe_system
        poll_available_network_interfaces
    end 

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

        # put the system information into a dictionary for retrieval
        @system_information = {:host_os => host_os, :is_windows => is_windows, :hostname => hostname}

        return @system_information
    end

    ##
    # Polls the available interfaces on the system and stores them in hash with the following format:
    # { "en0" =>
    #   "address" => IPv6 address & IPv4 address (String)
    #   "name" => interface_name
    ##

    def poll_available_network_interfaces
        # get all of the interfaces on the system - they'll be separated by spaces, so put them in a dictionary
        # only get the interfaces that are currently UP
        
        if_list_raw = `ifconfig -ul`.strip
        if_list = if_list_raw.split(" ")

        @interfaces = []
        if_list.each do |interface|
            iface = interface
            @interfaces.push(iface)
        end
        @interfaces.each do |interface| 
            ip_addresses = `ifconfig #{interface} | grep "inet" | awk '{print $2}'`.strip
            addresses = ip_addresses.split
            @ifaces[interface] = addresses[0]
            @ifaces["name"] = interface
        end
    end

    def grab
        # Usage for anyone who wants to know
        arg_check ARGV

        describe_system
        if @operating_mode == OPERATING_MODE_DISPLAY_STDOUT
        elsif @operating_mode == OPERATING_MODE_COPY_TO_CLIPBOARD
        end

        poll_available_network_interfaces
    end

    def get_interfaces
        # Get all of the active interfaces on the system
        # returns a hash with the following format:
        # { "en0" =>
        #   "address" => String containing IPv6 address and IPv4 addresses
        #   "name" => String containing the name of the interface
        # }

        return @ifaces
    end
end
