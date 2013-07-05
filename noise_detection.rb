#!/usr/bin/ruby -w
#
# Copyright (C) 2013 Marco Mornati [http://www.mornati.net]
# Based on Thomer M. Gil First [http://thomer.com/] version template
#
# Oct  05, 2012: Initial version
#
# This program is free software. You may distribute it under the terms of
# the GNU General Public License as published by the Free Software
# Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
# Public License for more details.
#
# This program detects the presence of sound and invokes a program.
#

require 'getoptlong'
require 'optparse'

HW_DETECTION_CMD = "cat /proc/asound/cards"
# You need to replace MICROPHONE with the name of your microphone, as reported
# by /proc/asound/cards
SAMPLE_DURATION = 5 # seconds
FORMAT = 'S16_LE'   # this is the format that my USB microphone generates
THRESHOLD = 0.05


def check_required()
  if !File.exists?('/usr/bin/arecord')
    warn "/usr/bin/arecord not found; install package alsa-utils"
    exit 1
  end

  if !File.exists?('/usr/bin/sox')
    warn "/usr/bin/sox not found; install package sox"
    exit 1
  end

  if !File.exists?('/proc/asound/cards')
    warn "/proc/asound/cards not found"
    exit 1
  end
  
end

# Parsing script parameters
options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: noise_detection.rb -m ID [options]"

  opts.on("-m", "--microphone SOUND_CARD_ID", "REQUIRED: Set microphone id") do |m|
    options[:microphone] = m
  end
  opts.on("-s", "--sample SECONDS", "Sample duration") do |s|
    options[:sample] = s
  end
  opts.on("-n", "--threshold NOISE_THRESHOLD", "Set Activation noise Threshold. EX. 0.1") do |n|
    options[:threshold] = n
  end
  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end
  opts.on("-d", "--detect", "Detect your sound cards") do |d|
    options[:detection] = d
  end
  opts.on("-t", "--test SOUND_CARD_ID", "Test soundcard with the given id") do |t|
    options[:test] = t
  end
end.parse!

if options[:detection]
    puts "Detecting your soundcard..."
    puts `#{HW_DETECTION_CMD}`
    exit 0
end

#Check required binaries
check_required()

if options[:test]
    puts "Testing soundcard..."
    puts `/usr/bin/arecord -D plughw:#{options[:test]},0 -d 1 -f #{FORMAT} 2>/dev/null | /usr/bin/sox -t .wav - -n stat 2>&1`
    exit 0
end

if options[:sample]
    SAMPLE_DURATION = options[:sample]
end

if options[:threshold]
    THRESHOLD = options[:threshold].to_f
end

optparse.parse!

#Now raise an exception if we have not found a host option
raise OptionParser::MissingArgument if options[:microphone].nil?

if options[:verbose]
   puts "Script parameters configurations:"
   puts "SoundCard ID: #{options[:microphone]}"
   puts "Sample Duration: #{SAMPLE_DURATION}"
   puts "Output Format: #{FORMAT}"
   puts "Noise Threshold: #{THRESHOLD}"
end

loop do
  out = `/usr/bin/arecord -D plughw:#{options[:microphone]},0 -d #{SAMPLE_DURATION} -f #{FORMAT} 2>/dev/null | /usr/bin/sox -t .wav - -n stat 2>&1`
  out.match(/Maximum amplitude:\s+(.*)/m)
  amplitude = $1.to_f
  puts amplitude if options[:verbose]
  if amplitude > THRESHOLD
    # You need to replace this with the program you wish to run
    # system "echo 'detected sound!'"
    puts "Sound detected!!!"
  else
    puts "no sound"
  end
end
