require "nokogiri"
require "open-uri"
require "csv"

starturl = "https://tiraas.net/2014/08/20/book-1-prologue/"
datafile = "../data/tgab.csv"
workname = "The Gods Are Bastards"

class Chapter
	def initialize(url)
		@doc = Nokogiri::HTML URI.open url
		@url = url
	end
	def getrawtext
		article = @doc.search("div.entry-content").first.clone
		article.search("div.sharedaddy").remove
		article.search("a").remove
		return article.content
	end
	def nextch
		begin
			puts self.gettitle
			self.initialize @doc.search("div.nav-links a[rel=next]").first["href"]
			return true
		rescue
			return false
		end
	end
	def gettitle
		@doc.search("h1.entry-title").first.content
	end
	def getdate
		return Date.parse @doc.search("time.entry-date").first["datetime"]
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
CSV.open("#{datafile}","wb") do |csv|
	csv << ["date","wordcount","chapter","work"]
	for ii in 0..data["date"].length-1
		csv << [data["date"][ii],data["wordcount"][ii],data["chapter"][ii],workname]
	end
end