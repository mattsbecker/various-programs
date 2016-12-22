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
@player_name = nil
@player_password = nil
@remaining_attempts = 4

def bootstrap
    # print game initialization fun, make them enter their name - "username"
    print_char_by_char "Word Mastermind v 0.0.1 - (C) Matt S Becker \n"
    print_char_by_char "Enter username: "
    @player_name = gets.chomp

    # make them enter a password that will fail
    print_char_by_char "Username '#{@player_name}' \nEnter password: "

    @player_password = gets.chop

    #password invalid, now they're in the game
    print_char_by_char "Password invalid. Please try again: (Attempt(s) left: #{@remaining_attempts} ):"
    start_curses

end

def print_char_by_char(final_output)
    i = 0
    thread = Thread.new do
        until i == final_output.size
            out = final_output[i]
            print out
            i+=1
            sleep 0.025
        end
    end
    thread.join
end

# start up the main program
def main
    bootstrap
end

main
