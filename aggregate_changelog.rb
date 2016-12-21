#!/usr/bin/env ruby

require 'net/http'
require 'optparse'
require 'fileutils'

@project_name = ENV['JOB_NAME']
@job_build_id = ENV['BUILD_ID']
@job_jenkins_url = ENV['JOB_URL']

# changelog_file is nil initially, we set it later
@changelog_file = nil
@job_workspace_path = nil
@job_project_branch = nil
@job_starting_reference = nil
@template_path = nil
@output_path = nil
@project_branch = nil
@options = {}
 
def main
    # check to ensure the correct number of arguments has been provided
    if @project_name == nil
        @project_name = "Project"
    end

    if @job_build_id == nil
        @job_build_id = 100
    end

    optionParser = OptionParser.new do |opts|
        @options[:post_path] = nil
        opts.on( '-e', '--endpoint URL', 'post to a provided URL') do |url|
            @options[:post_path] = url
        end
        opts.on( '-u', '--post-username username', 'username for any authentication encountered while posting the changelog') do |username|
            @options[:post_username] = username
        end
        opts.on( '-p', '--post-password password', 'password for any authentication encountered while posting the changelog') do |password|
            @options[:post_password] = password
        end

        opts.on( '-r', '--release-notes notes', 'curated changelog/release notes to prepend to the final output') do |release_notes|
            @options[:release_notes] = release_notes
        end
    end

    optionParser.parse!

    puts @options
    
    arg_check ARGV
    @job_workspace_path = ARGV[0]
    @job_project_branch = ARGV[1]
    @job_starting_reference = ARGV[2]
    @template_path = ARGV[3]
    @output_path = ARGV[4]
    

    out_vars = [@job_jenkins_url, @job_build_id, @job_workspace_path, @job_project_branch, @job_starting_reference]

    puts out_vars.to_s

    # open the changelog file for writing, or create it if it doesn't exist
    open_changelog_file(@output_path)

    # copy the template into the changelog
    copy_template_from_changelog

    # close the changelog
    #close_changelog_file @output_path

    # copy the changelog to a remote url?
    if @options[:post_path]
        post_to_url @options[:post_path]
    end
end

def usage
    return "Usage: aggregate_changelog.rb {WORKSPACE_PATH} {WORKING_BRANCH} {REFERENCE_BRANCH} {HTML_TEMPLATE_PATH} {OUTPUT_FILE}\n 
    No changelog has been written or modified.\n
    
    example: ruby changelog . . master changelog_template.html changelog.html\n"
end

def arg_check(input_args)
    if input_args.count < 3
        print usage
        exit
    end
end

def open_changelog_file(file_path)
    @changelog_file = File.open(file_path, "a+")
    if @changelog_file
        return @changelog_file.path
    else
        print "Changelog could not be opened. Exiting."
        exit
    end
end

def close_changelog_file(file_path)
    @changelog_file.close
end

def copy_template_from_changelog
    # set up the replacement sentinels
    changelog_curated_notes = "{{CURATED-RELEASE-NOTES}}"
    changelog_project_title_content = "{{PROJECT-TITLE}}"
    changelog_template_content = "{{CHANGELOG-CONTENT}}"
   

    # have curated release notes been provided?
    release_notes = ""
    if @options[:release_notes]
        unless File.extname(@options[:release_notes]).eql?(".md")
            print 'Attempted to read a changelog of non-markdown type. This is unexpected. Exiting!'
            exit
        end
        print 'Writing curated release notes'
        release_notes = File.read(@options[:release_notes])    
        puts release_notes
    end

    # open the template file
    template_file = File.open(@template_path, "r")
    template_lines = IO.readlines(template_file)
    branch = git_branch
    
    # iterate through the lines and copy them into the changelog.html of the project
    template_lines.each do |line|
        # is the line a body replacement sentiel line?
        if line.include? changelog_curated_notes
            line.replace release_notes
            @changelog_file.write line
        elsif line.include? changelog_template_content 
            line.replace git_log
            @changelog_file.write line
        elsif line.include? changelog_project_title_content 
            line.replace "##Changelog for #{@project_name}, buildId: #{@job_build_id} on branch #{branch}".strip! + "##"
            @changelog_file.write line
            @changelog_file.write "\n"
        else
            @changelog_file.write line
        end
    end
end

def git_log
    git_log_result = `git log --pretty=format:"* <span style='background:#f7f7ea; border: 1px solid #e5e5b9;'> %ad: <span style='color: #3e79a3;'>%h:</span> %an</span> - %s" --branches #{@job_project_branch} --source #{@job_reference_branch}`
    return git_log_result
end

def git_branch
    git_branch_result = `git branch | grep "*"`
    return git_branch_result
end

def post_to_url(url)
    content_for_post = File.read(@changelog_file)

    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    # create a new HTTP Put request for the provided URL
    request = Net::HTTP::Put.new(uri.request_uri)
    request.basic_auth(@options[:post_username], @options[:post_password])
    # set the form data
    request.set_form_data("content" => content_for_post, "syntax" => "markdown/1.1")
    # plain text, because we've written Markdown content
    request.content_type = 'application/x-www-form-urlencoded'
    response = http.request(request)
    puts response.code
    puts "Done!"
    @changelog_file.close
end

main
