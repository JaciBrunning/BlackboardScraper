require 'digest'

require_relative 'asset.rb'
require_relative 'utils.rb'
require_relative 'cio.rb'

class BBContent
    attr_accessor :id
    attr_accessor :name
    attr_accessor :unit
    attr_accessor :contents
    attr_accessor :assets
    attr_accessor :path

    def initialize unit, id, name, path
        @unit = unit
        @id = id
        @name = name
        @path = path

        @contents = {}
        @assets = {}
    end

    def crawl
        CIO.puts "Crawling Content: #{to_s}"
        CIO.push

        html = @unit.session.doGet("webapps/blackboard/content/listContent.jsp?course_id=#{@unit.id}&content_id=#{id}&mode=reset").body
        page = Nokogiri::HTML(html)
        page.css("ul#content_listContainer li div.item h3 a").select { |x| x['href'].start_with?("/webapps/blackboard/content") }.each do |listing|
            CIO.puts "-> Found Content: #{listing.text}"
            CIO.push
            contentid = listing['href'].scan(/\&content_id=([-_0-9]+)/).last.first
            unless contentid == @id
                @contents[contentid] = BBContent.new(unit, contentid, listing.text, "#{path}/#{id}_#{friendly_filename(name)}")
                @contents[contentid].crawl
            else
                CIO.puts "[ content not added (recursive) ]"
            end
            CIO.pop
        end

        page.css("ul#content_listContainer li").each do |section|
            h3 = section.css("div.item h3")
            unless h3.empty?
                sectionName = h3.first.text.strip
                section.css("div.details div div ul.attachments li a")
                    .select { |x| x['href'].start_with?("/bbcswebdav") }
                    .each { |asset| addAsset(asset, sectionName) }

                section.css("div.item h3 a")
                    .select { |x| x['href'].start_with?("/bbcswebdav") }
                    .each { |asset| addAsset(asset, sectionName) }
            end
        end

        CIO.pop
    end

    def addAsset asset, sectionName
        title = asset.text.strip
        CIO.puts "-> Found Asset: #{asset.text} in #{sectionName}"
        title = sectionName + "_" + title if title != sectionName
        hash = Digest::MD5.hexdigest asset['href']
        @assets[hash] = BBAsset.new(@unit.session, hash, asset['href'], title, "#{path}/#{id}_#{friendly_filename(name)}")
    end

    def collectAssets
        assets = {}
        @assets.each { |k, asset| assets[k] = asset }
        @contents.each { |ck, cv| cv.assets.each { |k, asset| assets[k] = asset } }
        assets
    end

    def to_s
        "#{name} (#{@id})"
    end
end