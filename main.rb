require "nokogiri"
require "open-uri"

class MatchResult
  attr_accessor :first,:after
  def initialize(first_name,after_name,first_score,after_score)
    @first = Team.new(first_name,first_score)
    @after = Team.new(after_name,after_score)
  end
  def to_string()
    "*** #{first.name} vs #{after.name} ***\n#{@first.to_string}#{@after.to_string}"
  end
end

class Team
  attr_accessor :id,:name,:score
  def initialize(name,score)
    @name = name
    @score = score
  end
  def to_string()
    "team name :#{@name}\n\t score:#{score}\n"
  end
end

MAIN_URL = "https://baseball.yahoo.co.jp"

teams=[]
doc = Nokogiri::HTML(open("#{MAIN_URL}/npb/"))
doc.css("table.score a").each{|n|
  match_page = Nokogiri::HTML(open("#{MAIN_URL}#{n.attr("href")}"))
  titles = match_page.title.split(' ') # temaname is 1 3
  scores = match_page.css("td.sum").map{|s|
    s.text
  }
  teams = teams.push MatchResult.new(titles[1],titles[3],scores[0],scores[1])
  sleep(1)
}
#p teams
teams.each{|team|
  puts team.to_string
}
