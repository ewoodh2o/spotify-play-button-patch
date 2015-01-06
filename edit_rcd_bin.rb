#!/usr/bin/env ruby
#
# Author: Elliott Wood, with thanks to Farhan Ahmad
# Website: https://github.com/ewoodh2o/spotify-play-button-patch
# Description: This patches the iTunes launch commands in the rcd binary. This
#   program is expected to be executed by the provided Patch.command driver.
#
#   Makes the following changes:
#     * When no remote apps are open, launch Spotify on Play/Pause
#       press rather than iTunes.
#     * Send Play/Pause presses to Spotify instead of iTunes
#     * Send next track to Spotify instead of iTunes
#     * Send previous track to Spotify instead of iTunes
#     * Look for active Spotify executable instead of QuickTimePlayerX. If
#       found, call iTunes handler for rcd events instead of QuickTimePlayerX.
#       This effectively kills remote control of QuickTimePlayerX, but the
#       iTunes handler will get rcd events when Spotify is running
#       (which are then mostly handed to Spotify)
#
#   For more information please see the website for this project.
#
# Revision history:
#  2010-11-28, fa: Created
#  2015-01-02, ew: Converted to Ruby, and altered for Spotify

# Make sure expected argument was received
if ARGV.length != 1
  puts "Usage: #{__FILE__} rcd_filepath"
  exit 1
end
rcd_filepath = ARGV[0]

# Make sure argument exists
unless File.exists?(rcd_filepath)
  print "'%s' is not a valid file." % rcd_filepath
  exit 2
end

# AppleScript commands and other strings to be replaced
REPLACEMENTS = {
  'tell application id "com.apple.iTunes" to launch' =>
    "tell application \"Spotify\" to launch\0",
  'tell application id "com.apple.iTunes" to get player state' =>
    "tell application \"Spotify\" to get player state\0",
  'tell application id "com.apple.iTunes" to playpause' =>
    "tell application \"Spotify\" to playpause\0",
  'tell application id "com.apple.iTunes" to next track' =>
    "tell application \"Spotify\" to next track\0",
  'tell application id "com.apple.iTunes" to back track' =>
    "tell application \"Spotify\" to previous track\0",
  "\0com.apple.QuickTimePlayerX\0" =>
  "\0com.spotify.client\0"
}.freeze

# Track which replacements were made
instances = {}

# Read file to RAM for searching
haystack = IO.binread(rcd_filepath)

# Open file for updating
File.open(rcd_filepath, "r+b") do |file|
  # Iterate over each search/sub pair and replace
  REPLACEMENTS.each do |search, substitution|
    pos = 0
    while pos = haystack.index(search, pos)
      file.seek(pos)
      file.write(substitution)
      instances[pos] = search
      pos = pos + 1
    end
  end

  # Patch _QuickTimePlayerXHandleHIDEvent to call _ITunesHandleHIDEvent instead
  #####################################################################

  # Find address for _ITunesHandleHIDEvent function
  nm = `nm -arch x86_64 #{rcd_filepath}`
  unless match = nm.match(/00000001([0-9a-f]{8}) T _ITunesHandleHIDEvent/)
    puts "Could not find symbol address for _ITunesHandleHIDEvent" and exit 3
  end
  itunes_addr = match[1].to_i(16)

  # Find "callq _QuickTimePlayerXHandleHIDEvent" in otool output
  otool = `otool -tV #{rcd_filepath}`
  unless match = otool.match(/00000001([0-9a-f]{8})\tcallq\t_QuickTimePlayerXHandleHIDEvent/)
    puts "Could not find callq instruction for _QuickTimePlayerXHandleHIDEvent" and exit 4
  end
  callq_addr = match[1].to_i(16)

  # Calculate next instruction address for offset base
  # (callq instruction is "E8" + 4-byte offset pointer, for total of 5 bytes)
  offset_base = callq_addr + 5

  # Calculate offset to _ITunesHandleHIDEvent address
  offset = itunes_addr - offset_base # (may be negative)

  # Write new address in place of original callq
  # (Effectively substitutes "callq _ITunesHandleHIDEvent" for "callq _QuickTimePlayerXHandleHIDEvent"
  file.seek(callq_addr)
  file.write("\xE8") # instruction opcode
  file.write([offset].pack('V')) # offset in little-endian
  instances[callq_addr] = "_QuickTimePlayerXHandleHIDEvent => _ITunesHandleHIDEvent"

  file.flush
end

puts "\n   Made the following replacements:"
instances.each do |pos, msg|
  puts "   %08s: %s" % [ pos.to_s(16), msg ]
end

if instances.length != REPLACEMENTS.length + 1
  puts "ERROR: could not replace all expected strings"
  exit 5
end

exit 0
