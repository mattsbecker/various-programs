#!/usr/bin/env ruby

=begin

Mastermind is a code-breaking game for two players. Player 1 (in this case, the computer) uses "code pegs" to choose a
four-charcter, color-coded code, in which Player 2 must guess. Each guess is stored in a one of 8-12 rows.

The codebreaker's guess is ranked by the codemaker by it's accuracy. A colored, or black key peg is used to indicate that
a codebreaker's peg was the correct color and in the right position. A white peg is used to indicate there was a correct
color placed in the wrong position.

This variation of Mastermind, instead of using colored pegs, will use words. I have a small obsession with Bethesda's
Fallout minigames, so this could be considered a crude reverse engineering of the "Hacking" minigame.

http://fallout.wikia.com/wiki/Terminal

This program uses the 10,000 most common English words, compiled by Google's Trillion Word Corpus. 
License information can be found here: https://github.com/first20hours/google-10000-english/blob/master/LICENSE.md


=end

require 'monitor'

trap("INT") {
    puts "Captured interrupt - shutting down"
    shut_down
}

# a simple timer class that will allow us to perform operations on a background thread and report results to the main thread
## Timer.new(0.025) do
#   function
#end
class Timer
    def initialize(interval, &handler)
        if interval < 0
            raise ArgumentError, "Invalid Interval of size less than 0" 
        end
        extend MonitorMixin

        @run = true
        @thread = Thread.new do
            time = Time.new
            while run?
                time += interval
                (sleep(time - Time.now) rescue nil) and handler.call rescue nil
            end
        end
    end

    def stop
        synchronize do
            @run = false
        end
        @thread.join
    end

    def run?
        synchronize do
            @run
        end
    end
end

@main_wordlist = []
@output_queue = []
@player_name = nil
@player_password = nil
@remaining_attempts = 4
@loading = false
@current_guess = nil
@game_terminating = false
@password_invalid_string = "Password invalid. Please try again: (Attempt(s) left: #{@remaining_attempts} ): "

def bootstrap
    puts `clear`
    #start_output_queue
    load_wordlist
    random_word_from_wordlist
    add_output_to_queue "Password is : #{@password} \n"
    # print game initialization fun, make them enter their name - "username"

    add_output_to_queue "Word Mastermind v 0.0.1 - (C) Matt S Becker \n"
    add_output_to_queue "Enter username: "
    @player_name = gets.chomp

    # make them enter a password that will fail
    add_output_to_queue "Username '#{@player_name}' \nEnter password: "

    @player_password = gets.chop

    #password invalid, now they're in the game
    add_output_to_queue @password_invalid_string

    @current_guess = gets.chomp
    add_output_to_queue "Current guess: #{@current_guess} Password: #{@password} \n"
    if @current_guess.eql? @password
        add_output_to_queue "Got it!"
    else
        puts "nope"
        @remaining_attempts -= 1
        add_output_to_queue @password_invalid_string
    end
end

def add_output_to_queue final_output
            i = 0
            until i == final_output.size
                out = final_output[i]
                print out
                i+=1
                sleep 0.025
            end

end

def start_output_queue
    # in a seprarate thread, always watch for shifts in our output queue
    @output_queue_thread = Thread.new do
        puts "thread! #{@queue_started}"
        puts "Queue size: #{@output_queue.length}"
        @queue_started = true
        while !@game_terminating 
            final_output = @output_queue[0]
            i = 0
            until i == final_output.size
                out = final_output[i]
                print out
                i+=1
                sleep 0.025
            end
            @output_queue.shift
        end
    end
end

def load_wordlist
    # load the main wordlist file into memory in a background thread
    thread = Thread.new do
        #word_list_file = File.open "words-short.txt"
        @main_wordlist = IO.readlines("words-short.txt")
    end
    thread.join
    add_output_to_queue "Intializing... \n"
    
end

def random_word_from_wordlist
    wordlist_count = @main_wordlist.length
    random_int = Random.new.rand(wordlist_count)
    @password = @main_wordlist[random_int].chomp
end

# start up the main program
def main
    bootstrap
end

def shut_down
    puts "Shutting down..."
    @output_queue_thread.join unless @output_queue_thread.nil?
    sleep 1
    exit
end

main


