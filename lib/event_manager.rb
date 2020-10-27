require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(phone_number)
  # Remove anything that is not an integer from the string.
  integer_string = phone_number.gsub(/[^0123456789]/,'')

  # If it's less than 10 digits or more than 11 it is a bad number.
  if integer_string.length < 10 || integer_string.length > 11
    "Invalid number"

  # If it's 10 digits assume it's good.
  elsif integer_string.length == 10
    integer_string

  # If it is 11 digits and the first number is 1, remove the 1 and use the
  # first 10 digits.
  elsif integer_string.length == 11 && integer_string[0] == "1"
    integer_string[1..-1]

  # If it is 11 digits and doesn't start with a 1. It is invalid.
  elsif integer_string.length == 11
    "Invalid number"
  end

end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir("output") unless Dir.exist?("output")

  filename = "output/thanks_#{id}.html"

  File.open(filename,'w') do |file|
    file.puts form_letter
  end
end

def save_phone_number(phone_number, name)
  File.open('output/phone_numbers.txt', 'a') do |file|
    file.write("#{name}: #{phone_number}\n")
  end
end

def save_registraion_hours(registration_times)
  sorted_times = registration_times.sort_by { |k, v| -v }
  File.open('output/registration_times.txt', 'a') do |file|
    sorted_times.each do |time, count|
      file.write "#{time}: #{count}\n"
    end
  end
end

puts "EventManager initialized."

# Make a hash to store registration times.
registration_times = Hash.new(0)

contents = CSV.open 'event_attendees.csv', headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  # Save personalized thank you letters for each person.
  save_thank_you_letter(id,form_letter)

  # Save each name with the person's phone number to file.
  phone_number = clean_phone_number(row[:homephone])
  save_phone_number(phone_number, name)

  # Make a DateTime object for each person's registration.
  registration_date_and_time = DateTime.strptime(row[:regdate], '%m/%d/%y %k:%M')

  # Increment hash value for registration hour.
  registration_times[registration_date_and_time.hour] += 1
end

# Save file showing registrations by hour.
save_registraion_hours(registration_times)