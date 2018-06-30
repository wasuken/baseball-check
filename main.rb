# coding: utf-8
require "nokogiri"
require "open-uri"
require "slack"
require "parseconfig"
require "time"

MYCONF = ParseConfig.new('config')
BOT_CHANNEL=MYCONF['bot_channel']

SLACK_TOKEN = MYCONF['slack_token']

# 余計な文字が入るので
Slack.configure do |config|
  config.token = SLACK_TOKEN.gsub(/\n/,"")
end
# 対戦ペアクラス
class MatchPair
  attr_accessor :first,:after,:inning
  def initialize(first,after,inning)
    @first = first
    @after = after
    @inning = inning
  end
  def to_string()
    "*** #{first.name} vs #{after.name} #{inning}***\n#{@first.to_string}#{@after.to_string}"
  end
  def team_in_pair(name)
    @first.name == name || @after.name == name
  end
  def scores_equal(first_score,after_score)
    @first.score == first_score || @after.score == after_score
  end
  def scores_equal(mp)
    @first.score == mp.first.score || @after.score == mp.after.score
  end
  # 順番関係ないゆるい比較。
  def slack_scores_equal(scoreA,scoreB)
    score_equal(scoreA,scoreB) || score_equal(scoreB,scoreA)
  end
  def send_to_slack_to_string(channel)
    Slack.chat_postMessage(channel: channel,text: to_string)
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

mps=[]
loop do
  doc = Nokogiri::HTML(open("#{MAIN_URL}/npb/"))
  Slack.chat_postMessage(channel: BOT_CHANNEL,
                           text: "*****  #{Time.new.strftime("%Y-%m-%d %H:%M:%S")}  *****")
  doc.css("table.score a").each{|n|
    match_page = Nokogiri::HTML(open("#{MAIN_URL}#{n.attr("href")}"))
    titles = match_page.title.split(' ') # temaname is 1 3
    scores = match_page.css("td.sum").map{|s|
      s.text
    }
    if !scores.first.nil?
      cur_mp = mps.find{|m| m.team_in_pair(titles[1])}
      inning = n.text()
      if !cur_mp
        cur_mp = MatchPair.new(Team.new(titles[1],scores[0]),
                               Team.new(titles[3],scores[1]),
                               inning)
        mps = mps.push
        p cur_mp.send_to_slack_to_string(BOT_CHANNEL)
      elsif !cur_mp.slack_scores_equal(scores[0],scores[1])
        cur_mp.first.score = scores[0]
        cur_mp.after.score = scores[1]
        p cur_mp.send_to_slack_to_string(BOT_CHANNEL)
      end
      sleep(1)
    end
  }
  sleep(10 * 30)
end
