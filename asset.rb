require_relative 'utils.rb'

EXTENSIONS = [
    /\.pdf$/, /\.docx$/, /\.txt$/, /\.c$/, /\.java$/, /\.class$/, /\.pptx$/, /\.ppt$/, /\.doc$/, /\.jar$/,
    /\.java\..*$/, /\.class\..*$/, /\.csv/, /\.tar\.gz/
]

class BBAsset
    attr_accessor :session
    attr_accessor :hash
    attr_accessor :url
    attr_accessor :name
    attr_accessor :path

    def initialize session, hash, url, name, path
        @session = session
        @hash = hash
        @url = url
        @name = name
        @path = path
    end

    def fqp
        "#{path}/#{friendly_filename(name)}_#{hash[0..6]}"
    end

    def download basepath
        folder = "#{basepath}/#{fqp}"
        FileUtils.mkdir_p folder

        url = @url
        head = @session.doHead(url)
        url = head["location"][1..-1] unless (head["location"].nil?)
        
        filename = File.basename(URI.parse(url).path)
        filepath = "#{folder}/#{filename}"
        unless File.exists? filepath
            validext = !EXTENSIONS.reject { |x| filename.scan(x).empty? }.empty?
            if validext
                File.open(filepath, 'wb') do |f|
                    f.write @session.doGet(url).body
                end
            else
                CIO.puts "-> invalid extension, skipped: #{filename}"
            end
        else
            CIO.puts "-> already downloaded!"
        end
    end

    def to_s
        "#{name} (#{hash[0..6]})"
    end
end