#!/usr/bin/env ruby

require 'open3'

$git_log = File.open('git.log', 'ab')
$stdin_log = File.open('git_stdin.log', 'wb')

def git_log(type, str)
  type = type.to_s.upcase

  if type == 'STDIN'
    $stdin_log.write str
  end

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

  pid = wait_thr.pid

  until false do
    #git_log(:iter, i)

    std_collection = [$stdin, stdout, stderr].reject(&:closed?)
    readers, writers, errors = IO.select(std_collection, [], [], 1)

    #if readers
      #readers.each do |reader|
        #line = reader.readline
        #type = [$stdin, stdout, stderr].detect { |io| io == reader }
        #git_log(type, line)
      #end
    #end

    #if i > 5
      #git_log(:test, $stdin.eof?)
    #end

    #git_log(:read, readers.inspect + "\n")
    #git_log(:proc, [wait_thr.alive?, wait_thr.class.to_s, wait_thr.inspect].join(' '))
    #git_log(:fiha, [$stdin, $stdout, $stderr, stdin, stdout, stderr].map(&:closed?).inspect)

    unless wait_thr.alive?
      git_log(:sys, "Thread is dead #{wait_thr.value}")
      exit
    end

    if readers.nil? && i > 5
      #$stdin.close
      #stdin.close
      #
      git_log(:sys, "Closing STDIN")
      stdin.close
    end

    if i > 45
      git_log(:sys, "45 iterations")
      exit
    end

    #git_log(:writ, writers.inspect)
    #git_log(:erro, errors.inspect)

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
