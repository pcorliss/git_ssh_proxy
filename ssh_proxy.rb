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

git_log(:cmd, ['ssh', '-x', *ARGV].join(' '))
Open3.popen3('ssh', '-x', *ARGV) do |stdin, stdout, stderr, wait_thr|
  i = 0
  while wait_thr.alive? && i < 100 do
    std_collection = [$stdin, stdout, stderr].reject(&:closed?)
    readers, writers, errors = IO.select(std_collection, [], [], 1)

    if readers && readers.include?($stdin)
      block = nil
      begin
        block = $stdin.read_nonblock(1024)
      rescue EOFError
        block = $stdin.read
        $stdin.close
        git_log(:error, "STDIN EOF: #{block} #{block.class} #{block.length}")
      end
      git_log(:stdin, block)
      stdin.print block
      stdin.flush
    end

    if readers && readers.include?(stdout)
      block = nil
      begin
        block = stdout.read_nonblock(1024)
      rescue EOFError
        block = stdout.read
        git_log(:error, "STDOUT EOF: #{block}")
      end
      git_log(:stdout, block)
      $stdout.print block
      $stdout.flush
    end

    if readers && readers.include?(stderr)
      block = nil
      begin
        block = stderr.read_nonblock(1024)
      rescue EOFError
        block = stderr.read
        git_log(:error, "STDERR EOF: #{block}")
      end
      git_log(:stderr, block)
      $stderr.print block
      $stderr.flush
    end

    i += 1
  end
end
