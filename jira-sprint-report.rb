#!/usr/bin/env ruby

require 'net/http'
require 'JSON'
require 'date'
require 'csv'

@jira_base_endpoint = nil # SET BASE JIRA ENDPOINT with trailing slash https://yourjira.domain.com/
@jira_agile_base_endpoint = "rest/agile/1.0/"

@board_context = ""
@isLast = false
@current_date = DateTime.now.strftime('%m-%d-%Y %H:%M:%S')
@num_results = 0
@num_exported_sprints = 0
@max = 250
@cumulative_sprints_array = Array.new
@csv_file_name = nil

# writes the parsed (JSON -> Hash) to a provided output csv
def write_results_to_array(parsed_results)
    # get the array of sprints for the project
    sprints = parsed_results['values']
    # open a CSV with the name created above
    sprints.each do |sprint|
        # output the each line that we're writing to the CSV
        puts "Sprint: #{sprint['name']}\n"
        unless sprint['startDate'].nil?
            puts "\t started: #{DateTime.parse(sprint['startDate']).strftime("%m/%d/%Y")}" 
        else
            puts "\tHas not started - will not be exported"
        end
        unless sprint['endDate'].nil? 
            puts "\t ended: #{DateTime.parse(sprint['endDate']).strftime("%m/%d/%Y")}" 
        else
            puts "\tHas not ended - will not be exported"
        end

        # set a default start and end date of 0-0-0 (easily identifiable so they can be removed later)
        startDate = "0-0-0"
        endDate = "0-0-0"

        # format start and end dates
        unless sprint['startDate'].nil?
            startDate = DateTime.parse(sprint['startDate']).strftime('%m-%d-%Y %l:%M:%S %p')
        end

        unless sprint['endDate'].nil?
            endDate = DateTime.parse(sprint['endDate']).strftime('%m-%d-%Y %l:%M:%S %p')
        end

        #push results to an array that we'll use when writing to the csv later...
        @cumulative_sprints_array.push([sprint['name'], startDate, endDate, sprint['state']])
    end
end

def write_sprints_to_file
    if @csv_file_name.nil?
        @csv_file_name = "sprint-report-#{@current_date.to_s}-#{@board_context}.csv"
    end
    CSV.open(@csv_file_name, "wb") do |csv|
        @cumulative_sprints_array.each do |sprint|
            # don't bother writing out lines for sprints that haven't been started
            unless sprint[1] == "0-0-0"
                csv << [sprint[0], sprint[1], sprint[2], sprint[3]]
            end
        end
    end
end

def get_sprints_for_board(user, password, board_id)
    if @jira_base_endpoint.nil?
        print "Jira base endpoint is nil. Please set @jira_base_endpoint \n"
        exit
    end 
    # set a context for reference
    @board_context = board_id
    # build a url string and URI, print the result so we know what we're using
    
    url_string = @jira_base_endpoint + @jira_agile_base_endpoint + "board/" + board_id.to_s + "/sprint?maxResults=50"
    url_string += "&startAt=#{@num_results}"

    uri = URI(url_string)
    puts url_string

    # create a new request with basic auth w/ credentials supplied by the user
    request = Net::HTTP::Get.new(uri)
    request.basic_auth user, password

    # perform the request to Jira
    Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        http.request(request) do |response|
                #puts "Entering response block"
                # parse the results to a hash
                parsed_results = JSON::parse(response.body)

                # do we need to go out and get more? isLast is provided by Jira when more pages of data are available...
                @isLast = parsed_results['isLast']
                #puts parsed_results['isLast']

                # unless isLast has been set to true, go out and get the next set of data
                write_results_to_array parsed_results
                unless @isLast
                    @num_results += 50
                    puts "need to get more from the Jira API #{@num_results}"
                    get_sprints_for_board user, password, board_id
                else
                    puts "Stopped looking for more results"
                    write_sprints_to_file
                    puts "Finished! Final output file name is #{@csv_file_name}"
                end
        end
    end
end

#main method
def main(user,password,board_id)
    get_sprints_for_board user, password, board_id
end


# fire off the main method with the supplied args

if ARGV.count < 3
    puts "Usage: ruby sprint-report.rb jira-username jira-password jira-project-board-id output-file-name.csv (optional)\n \n example: matt my-password 19 sprint-report.csv"

    exit
end

user = ARGV[0]
password = ARGV[1]
board_id = ARGV[2]
preferred_filename = ARGV[3]

unless preferred_filename.nil?
    @csv_file_name = preferred_filename
end

main user, password, board_id

# handle params (Project that we want to get sprints for)
