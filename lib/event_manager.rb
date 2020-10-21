# frozen_string_literal: true

require 'csv'

puts 'EventManager Initialized!'

contents = CSV.open 'event_attendees.csv', headers: true, header_converters: :symbol
contents.each do |:first_name|
  name = row[2]
  puts name
end
