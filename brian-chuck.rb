# coding: utf-8

class Instance
    attr_accessor :tape, :code, :ip

    OPERATORS = {
        '+'.ord  => :inc,
        '-'.ord  => :dec,
        '>'.ord  => :right,
        '<'.ord  => :left,
        '}'.ord  => :scan_right,
        '{'.ord  => :scan_left,
        '?'.ord  => :toggle,
        ','.ord  => :input,
        '.'.ord  => :output,
        '!'.ord  => :debug,
        '@'.ord  => :debug_terminate
    }

    OPERATORS.default = :nop

    def initialize(src)
        @code = src.chars.map(&:ord)
        @code = [0] if code.empty?

        @ip = 0
    end

    def tick
        result = :continue
        case OPERATORS[@code[@ip]]
        when :inc
            @tape.set(@tape.get + 1)
        when :dec
            @tape.set(@tape.get - 1)
        when :right
            @tape.move_right
        when :left
            @tape.move_left
        when :scan_right
            @tape.move_right while @tape.get != 0
        when :scan_left
            @tape.move_left while @tape.ip > 0 && @tape.get != 0
        when :toggle
            if @tape.get != 0
                @tape.move_right
                result = :toggle
            end
        when :input
            input
        when :output
            output
        when :debug
            result = :debug
        when :debug_terminate
            result = :debug_terminate
        end

        return :terminate if result != :toggle && @ip == @code.size - 1

        move_right if result != :toggle

        return result
    end

    def move_right
        @ip += 1
        if @ip >= @code.size
            @code << 0
        end
    end

    def move_right
        @ip += 1
        if @ip >= @code.size
            @code << 0
        end
    end

    def move_left
        @ip -= 1 if @ip > 0
    end

    def get
        @code[@ip]
    end

    def set value
        @code[@ip] = value
    end

    def input() end
    def output() end

    def to_s
        str = self.class.name + ": \n"
        ip = @ip
        @code.map{|i|(i%256).chr}.join.lines.map do |l|
            str << l.chomp << $/
            str << ' '*ip << "^\n" if 0 <= ip && ip < l.size
            ip -= l.size
        end
        str
    end
end

class Brian < Instance
    def input
        byte = STDIN.read(1)
        @tape.set(byte ? byte.ord : -1)
    end
end

class Chuck < Instance
    def output
        $> << (@tape.get % 256).chr
    end
end

class BrianChuck

    class ProgramError < Exception; end

    def self.run(src, debug_level=0)
        new(src, debug_level).run
    end

    def initialize(src, debug_level=false)
        @debug_level = debug_level

        src.gsub!('_',"\0")

        if src[/```/]
            brian, chuck = src.split('```', 2).map(&:strip)
        else
            brian, chuck = src.lines.map(&:chomp)
        end

        chuck ||= ""

        brian = Brian.new(brian)
        chuck = Chuck.new(chuck)

        brian.tape = chuck
        chuck.tape = brian

        @instances = [brian, chuck]
    end

    def run
        (puts @instances; puts) if @debug_level > 1

        loop do
            result = current.tick

            toggle if result == :toggle
            
            (puts @instances; puts) if @debug_level > 1 || @debug_level > 0 && (result == :debug || result == :debug_terminate)
            
            break if result == :terminate || @debug_level > 0 && result == :debug_terminate
        end
    end

    private

    def current
        @instances[0]
    end

    def toggle
        @instances.reverse!
    end
end

case ARGV[0]
when "-d"
    debug_level = 1
when "-D"
    debug_level = 2
else
    debug_level = 0
end

if debug_level > 0
    ARGV.shift
end

BrianChuck.run(ARGF.read, debug_level)