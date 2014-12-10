#!/usr/bin/env ruby

require 'open3'

class GitLog
  def self.log(type, str)
    type = type.to_s.upcase

    str.to_s.each_line do |line|
      target.write type
      target.write ' '
      target.write line

      unless line.to_s.end_with?("\n")
        target.write " NOBREAK" if type.start_with?('STD')
        target.write "\n"
      end
    end
    target.flush
  end

  def self.target
    @target ||= File.open('git.log', 'ab')
  end
end

def read_from_io(input, output, name)
  begin
    block = input.read_nonblock(1024)
    GitLog.log(name, block)
    output.print block
    output.flush
  rescue EOFError
    input.close
    GitLog.log(:error, "#{name} EOF")
  end
end

GitLog.log(:cmd, ['ssh', '-x', *ARGV].join(' '))

Open3.popen3('ssh', '-x', *ARGV) do |stdin, stdout, stderr, wait_thr|
  i = 0
  while wait_thr.alive? && i < 100 do
    std_collection = [$stdin, stdout, stderr].reject(&:closed?)
    readers, writers, errors = IO.select(std_collection, [], [], 1)

    if readers
      read_from_io($stdin, stdin, :stdin) if readers.include? $stdin
      read_from_io(stdout, $stdout, :stdout) if readers.include? stdout
      read_from_io(stderr, $stderr, :stderr) if readers.include? stderr
    end

    i += 1
  end
  GitLog.log(:sys, wait_thr.value)
end
