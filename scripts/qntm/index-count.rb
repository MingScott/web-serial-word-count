require "nokogiri"
require "csv"
require "open-uri"

html = File.read("list.html")
datafile = "../../data/qntm/blog.csv"

html = Nokogiri::HTML.parse(html)
links = []
html.search("a").each{ |link| links << "https://qntm.org" + link["href"]}

class Chapter
	def initialize(url)
		@doc = Nokogiri::HTML URI.open url
		@url = url
	end
	def getrawtext
		article = @doc.search("div.page__content").first.clone
		article.search("a").remove
		return article.content
	end
	def gettitle
		@doc.search("h2.page__h2").first.content.gsub("\t","").gsub("\n","")
	end
	def getdate
		return Date.parse @doc.search("div.page__dateline").first.content.gsub(" by qntm","")
	end
	def getwordcount
		return self.getrawtext.scan(/[[:alpha:]]+/).count
	end
	def getwork
		return @doc.search("div.page__breadcrumbs a").last.content.gsub("\t","").gsub("\n","")
	end
end

CSV.open("#{datafile}","wb") do |csv|
	csv << ["date","wordcount","chapter","work"]
	links.each do |link|
		chap = Chapter.new link
		puts [chap.getdate,chap.getwordcount,chap.gettitle,chap.getwork]
		csv << [chap.getdate,chap.getwordcount,chap.gettitle,chap.getwork]
	end
end