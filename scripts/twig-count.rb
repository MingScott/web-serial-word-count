require "nokogiri"
require "open-uri"
require "csv"

class Chapter
	def initialize(url)
		@doc = Nokogiri::HTML URI.open url
		@url = url
	end
	def getrawtext
		article = @doc.search("#content article div.entry-content").first.clone
		article.search("div.sharedaddy").remove
		article.search("a").remove
		return article.content
	end
	def nextch
		begin
			puts @doc.search("h1.entry-title").first.content
			self.initialize @doc.search("div.nav-next a").first["href"]
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

chap = Chapter.new "https://twigserial.wordpress.com/2014/12/24/taking-root-1-1/"
data = {"date" => [], "wordcount" => [], "chapter" => []}
loop do
	data["date"] << chap.getdate
	data["wordcount"] << chap.getwordcount
	data["chapter"] << chap.gettitle
	if not chap.nextch
		break
	end
end
CSV.open("data/twig.csv","wb") do |csv|
	csv << ["date","wordcount","chapter","work"]
	for ii in 0..data["date"].length-1
		csv << [data["date"][ii],data["wordcount"][ii],data["chapter"][ii],"Twig"]
	end
end