require "nokogiri"
require "csv"
require "open-uri"

html = File.read("scplist.html")
datafile = "../../data/qntm/scp.csv"

@html = Nokogiri::HTML.parse(html)
links = []
@html.search("a").each{ |link| links << "http://scp-wiki.wikidot.com" + link["href"]}

class Chapter
	def initialize(url)
		@doc = Nokogiri::HTML URI.open url
		@url = url
	end
	def relative_url
		@url[27..@url.length]
	end
	def getrawtext
		article = @doc.search("div#page-content").first.clone
		article.search("a").remove
		return article.content
	end
	def gettitle
		@doc.search("div#page-title").first.content.gsub("\t","").gsub("\n","")
	end
	def getdate
		return Date.parse @doc.search("div.page__dateline").first.content.gsub(" by qntm","")
	end
	def getwordcount
		return self.getrawtext.scan(/[[:alpha:]]+/).count
	end
	def getwork
		return @doc.search("div. a").last.content.gsub("\t","").gsub("\n","")
	end
end

def getdate(chap)
	@html.search("//*[@href='#{chap.relative_url}']").first.parent.parent.previous_element.content
end

CSV.open("#{datafile}","wb") do |csv|
	csv << ["date","wordcount","chapter","work"]
	links.each do |link|
		chap = Chapter.new link
		puts [getdate(chap),chap.getwordcount,chap.gettitle,"SCP Foundation"]
		csv << [getdate(chap),chap.getwordcount,chap.gettitle,"SCP Foundation"]
	end
end