#!/usr/bin/env ruby

require 'open3'

$git_log = File.open('git.log', 'ab')

def git_log(type, str)
  type = type.to_s.upcase

  str.to_s.each_line do |line|
    $git_log.write type
    $git_log.write ' '
    $git_log.write line

    unless line.to_s.end_with?("\n")
      $git_log.write " NOBREAK" if type.start_with?('STD')
      $git_log.write "\n"
    end
  end
  $git_log.flush
end

def read_from_io(input, output, name)
  begin
    block = input.read_nonblock(1024)
    git_log(name, block)
    output.print block
    output.flush
  rescue EOFError
    input.close
    git_log(:error, "#{name} EOF")
  end
end

git_log(:cmd, ['ssh', '-x', *ARGV].join(' '))
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
end
