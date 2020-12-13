require "nokogiri"
require "csv"
require "open-uri"

@authorpage = ARGV[0]
@datadir = "../../data"
@useragent = "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:83.0) Gecko/20100101 Firefox/83.0"

class Author
	def initialize(url)
		@doc = Nokogiri::HTML.parse URI.open(url + "/fictions", {'User-Agent' => @useragent})
		@links = @doc.search("div.fiction-description + a").clone.map do |link|
			link = "https://www.royalroad.com" + link["href"]
		end
		@name = @doc.search("h1").first.content.split(" ").join(" ")
		@fictions = []
		@stats = []
		@links.each do |link|
			@fictions << Fiction.new(link)
		end
	end
	def scrape
		puts "==Starting Author: #{self.getName}=="
		@fictions.each{ |fic| fic.scrape }
		puts "==Done=="
	end
	def getFictions
		@fictions
	end
	def getName
		@name
	end
	def to_s
		@name + ": " + @fictions.map{|fic| fic.getTitle}.join(", ")
	end
	def collate
		@fictions.each do |fic|
			fic.getChapters.each do |chap|
				@stats << {
					"date"		=> chap.getDate,
					"wordcount"	=> chap.getWordCount,
					"chapter"	=> chap.getTitle,
					"work"		=> fic.getTitle,
					"author"	=> self.getName
				}
			end
		end
	end
	def getStats
		@stats
	end

end

class Fiction
	def initialize(url)
		@cover = Nokogiri::HTML.parse URI.open(url, {'User-Agent' => @useragent})
		@nextch = "https://www.royalroad.com" + @cover.search("a.btn-primary.btn-lg").first["href"]
		@chapters = []
	end
	def scrape
		puts "+++Starting Fiction: #{self.getTitle}+++"
		loop do
			begin
				@chap = Chapter.new @nextch
				puts @chap.getTitle
			rescue
				sleep 60
				retry
			end
			@nextch = @chap.getNextCh
			@chapters << @chap
			unless @nextch
				puts "+++Done+++"
				break
			end
			sleep 6
		end
	end
	def getTitle
		@cover.css("h1[property=name]").inner_text
	end
	def to_s
		self.getTitle
	end
	def getChapters
		@chapters
	end
end

class Chapter
	def initialize(url)
		@chap = Nokogiri::HTML.parse URI.open(url, {'User-Agent' => @useragent})
		@wordcount = @chap.search("div.chapter-content").first.
			content.
			scan(/[[:alpha:]]+/).
			count
		@date = Date.parse @chap.search("time").first["datetime"]
		@title = @chap.search("h1.font-white").first.content
	end
	def getNextCh
		begin
			"https://www.royalroad.com" + @chap.search("a.btn.btn-primary").
				to_a.keep_if{ |link| link.content.include? "Next" }.first["href"]
		rescue
			false
		end
	end
	def getDate
		@date
	end
	def getWordCount
		@wordcount
	end
	def getTitle
		@title
	end
end

auth = Author.new @authorpage
puts auth.getName
auth.scrape
auth.collate
CSV.open("#{@datadir}/#{auth.getName}.csv","wb") do |csv|
	csv << ["date","wordcount","chapter","work","author"]
	auth.getStats.each do |chap|
		csv << chap.values_at("date","wordcount","chapter","work","author")
	end
end