# import bundler
require 'bundler/setup'
# import gems
require 'csv'
require 'redis'
require 'pry'

class RestartableCSVImporter
  TTL_IN_SECONDS = 7 * 24 * 60 * 60

  def initialize(redis, file_id)
    @redis = redis
    @file_id = file_id
  end

  def import(csv_file_object, &block)
    puts "starting RestartableCSVImporter#import"
    start_line_number = (@redis.get(curr_line_number_key) || "0").to_i

    puts "skipping #{start_line_number} rows"

    csv_file_object.drop(start_line_number).each_with_index do |row, i|
      line_number = start_line_number + i + 1
      block.call(row, line_number)
      @redis.set(curr_line_number_key, line_number, ex: TTL_IN_SECONDS)
    end
    puts "completed RestartableCSVImporter#import"
  end

  def curr_line_number_key
    "#{@file_id}:curr_line_number"
  end
end

puts "starting importer"
RestartableCSVImporter.new(Redis.new, "ids4").import(CSV.new(File.open("./ids.csv"), headers: true)) do |row, i|
  puts ">>: #{[i, row]}"
  raise "boom" if i == 99
end
puts "ending importer"
