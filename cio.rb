ORIGINALPUTS = Proc.new { |x| puts x }

module CIO
    def self.push
        @indent ||= 0
        @indent += 1
    end

    def self.pop
        @indent ||= 1
        @indent -= 1
    end

    def self.puts text=""
        @indent ||= 0
        ORIGINALPUTS.call "#{(["\t"]*@indent).join("")}#{text}"
    end

    def self.with &block
        push
        yield
        pop
    end
end