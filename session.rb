require "net/http"
require "uri"
require "base64"
require "nokogiri"

require_relative 'unit.rb'
require_relative 'utils.rb'
require_relative 'cio.rb'

class BBSession
    require "base64"

    attr_accessor :units
    attr_accessor :http

    def initialize usr, pwd
        @user = usr
        @pwd = Base64.encode64(pwd)
        @pwd_unicode = Base64.encode64(pwd.split("").product(["\x00"]).flatten.join("").force_encoding("US-ASCII")).strip

        @loginPL = {
            user_id: @user,
            password: "",
            login: "Login",
            action: "login",
            'remote-user': "",
            new_loc: "",
            auth_type: "",
            one_time_token: "",
            encoded_pw: @pwd.strip,
            encoded_pw_unicode: @pwd_unicode
        }
        @cookies = {}

        @baseurl = "https://lms.curtin.edu.au"
        @uri = URI.parse(@baseurl)
        @http = Net::HTTP.new(@uri.host, @uri.port)
        @http.use_ssl = true

        @units = {}

        puts "Attempting Login...."
        response = doPost("webapps/login/", @loginPL)
        unless response.body.include?("You are being redirected to another page")
            puts "Invalid Login Details!"
            exit
        end
        puts "Login Successful!"
    end

    def doPost path, payload
        uri = makeURI(path)
        req = Net::HTTP::Post.new(uri.request_uri)
        req.set_form_data payload 
        req["Content-Length"] = req.body.length
        req["Cookie"] = @cookies.map { |k,v| "#{k}=#{v}" }.join(";")
        req['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36'

        res = @http.request req
        cookies = res.get_fields('set-cookie')
        cookies.each { |cookie|
            c = cookie.split(';')[0]
            @cookies[c.split('=')[0]] = c.split('=')[1]
        }
        res
    end

    def doGet path
        uri = makeURI(path)
        req = Net::HTTP::Get.new(uri.request_uri)
        req["Cookie"] = @cookies.map { |k,v| "#{k}=#{v}" }.join(";")
        req['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36'
        @http.request req
    end

    def doHead path
        uri = makeURI(path)
        req = Net::HTTP::Head.new(uri.request_uri)
        req["Cookie"] = @cookies.map { |k,v| "#{k}=#{v}" }.join(";")
        req['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36'
        @http.request req
    end

    def makeURI path
        URI.parse("#{@baseurl}/#{path}")
    end

    def fetchUnits
        puts "Fetching Units...."
        CIO.push

        html = doGet("webapps/portal/execute/tabs/tabAction?tab_tab_group_id=_3_1").body
        page = Nokogiri::HTML(html)
        @units = Hash[page.css('ul.courseListing li a').map do |el|
            courseid = el['href'].scan(/\&id=([-_0-9]+)\&/).last.first
            course = el.text
            CIO.puts "Found Unit -> #{courseid} (#{course})"
            [courseid, BBUnit.new(self, courseid, course, "")]
        end]

        CIO.pop
    end
end