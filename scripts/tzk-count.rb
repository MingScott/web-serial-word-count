require "nokogiri"
require "open-uri"
require "csv"

starturl = "https://thezombieknight.blogspot.com/2013/04/page-1.html"
datafile = "tzk.csv"
workname = "The Zombie Knight"

class Chapter
	def initialize(url)
		@doc = Nokogiri::HTML URI.open url
		@url = url
	end
	def getrawtext
		article = @doc.search("div.entry-content").first.clone
		return article.content
	end
	def nextch
		begin
			puts self.gettitle
			self.initialize @doc.search("span#blog-pager-newer-link a").first["href"]
			return true
		rescue
			return false
		end
	end
	def gettitle
		@doc.search("h3.entry-title").first.content
	end
	def getdate
		return Date.parse @doc.search("h2.date-header span").first.content
	end
	def getwordcount
		return self.getrawtext.scan(/[[:alpha:]]+/).count
	end
end

chap = Chapter.new starturl
data = {"date" => [], "wordcount" => [], "chapter" => []}
loop do
	data["date"] << chap.getdate
	data["wordcount"] << chap.getwordcount
	data["chapter"] << chap.gettitle
	if not chap.nextch
		break
	end
end
CSV.open("data/#{datafile}","wb") do |csv|
	csv << ["date","wordcount","chapter","work"]
	for ii in 0..data["date"].length-1
		csv << [data["date"][ii],data["wordcount"][ii],data["chapter"][ii],workname]
	end
end