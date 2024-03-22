# frozen string literal: true
require 'yaml'

def parse_dictionary(path)
  File.open(path, 'r') do |file|
    (file.readlines.map(&:chomp).select { |word| word.length.between?(5, 12) })
  end
end

class Hangman
  attr_accessor :word, :word_length, :word_display, :guesses, :lives

  @@dictionary = parse_dictionary('dictionary.txt')
  def initialize
    @word = ''
    @word_length = 0
    @word_display = []
    @guesses = []
    @lives = 6
  end

  def load_data(obj)
    @word = obj.word
    @word_length = obj.word_length
    @word_display = obj.word_display
    @guesses = obj.guesses
    @lives = obj.lives
  end

  def save_game(name)
    Dir.mkdir 'saves' unless Dir.exist?('saves')
    File.open("saves/#{name}.yaml", 'w') do |file|
      file.write(YAML.dump(self))
    end
  end

  def get_entries(dir)
    begin
      entries = Dir.entries(dir)
      raise 'No entries found' if entries == ['.', '..']
    rescue StandardError => e
      puts e.message
      nil
    end
    entries
  end

  def get_user_save_input
    puts 'Which save would you like to load? (Enter the number)'
    entries = get_entries('saves')
    begin
      (entries.each_with_index do |file, index|
         puts "#{index + 1}. #{file}" unless ['.', '..'].include?(file)
       end)
      save_number = gets.chomp.to_i
      raise 'Invalid save number' if save_number < 1 || save_number > entries.length - 2
    rescue StandardError => e
      puts e.message
      retry
    end
    save_number - 1
  end

  def load_game
    save_number = get_user_save_input
    File.open("saves/#{Dir.entries('saves')[save_number]}", 'r') do |file|
      load_data(YAML.safe_load(file, permitted_classes: [self.class]))
    end
  end

  def start_data
    @word = @@dictionary.sample
    @word_length = @word.length
    @word_display = Array.new(@word_length, '_')
    @guesses = []
    @lives = 6
    puts 'The word has been chosen!'
    puts 'You have 6 lives to guess the word.'
    game_loop
  end

  def display_guess(guess)
    if @word.include?(guess)
      @word.split('').each_with_index do |letter, index|
        @word_display[index] = letter if letter == guess
      end
      puts 'Correct!'
    else
      puts 'Incorrect!'
      @lives -= 1
    end
  end

  def game_loop
    puts "To save the game type save 'savename' at any time. Ex: save game1"
    while @lives.positive?
      puts "Word: #{@word_display.join}"
      puts "Guesses: #{@guesses.join('-')}"
      puts "Lives: #{@lives}"
      puts 'Enter a letter or word:'
      guess = gets.chomp.downcase
      if guess.include? 'save'
        save_game(guess.split[1])
        puts 'Game saved!'
        return
      end
      if guess.length == 1
        display_guess(guess)
      elsif guess.length == @word_length
        if guess == @word
          @word_display = @word.split('')
          puts 'Correct!'
        else
          puts 'Incorrect!'
          @lives -= 1
        end
      else
        puts 'Invalid guess!'
      end
      @guesses.push(guess)
      break if @word_display.join == @word
    end
    puts "The word was: #{@word}"
    if @lives.zero?
      puts 'Game Over!'
    else
      puts 'You win!'
    end
  end

  def saved_games?
    Dir.exist?('saves') && Dir.entries('saves').length > 2
  end

  def play
    puts 'Welcome to Hangman!'
    if saved_games?
      puts 'Would you like to load a saved game? (y/n)'
      answer = gets.chomp
      load_game if answer == 'y'
    end
    if @word.empty?
      start_data
    else
      game_loop
    end
  end
end
hm = Hangman.new

hm.play
