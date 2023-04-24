require 'uri'
require 'net/http'
require 'json'

module DotaApi
    HOST = "https://api.opendota.com/api/"
    I64 = 76561197960265728
    class APIClient
        JSON_FILE = 'match.json'
        HEROES_FILE = 'heroes.json'
        MATCHES_FILE = 'matches.json'
    
        def initialize
            @heroes = {}
            parce_heroes()
        end
    
        def save_to_json(text, file=JSON_FILE)
            puts text
            File.open(file, 'w+') {|f| f.write text.force_encoding('utf-8') }
            puts 'File saved'
        end
    
        def download_to_json(path, file=JSON_FILE, to_save=false)
            uri = URI("#{HOST}#{path}")
            response = get uri
            save_to_json response, file if to_save
            return JSON.load response 
        end
    
        def download_match(match_serial)
            return download_to_json "matches/#{match_serial}"
        end
        
        def download_player(steam_id32)
            return download_to_json "players/#{steam_id32}"
        end

        def download_heroes
            return download_to_json "heroes", HEROES_FILE
        end
    
        def download_matches(steam_id32)
            return download_to_json "players/#{steam_id32}/refresh", MATCHES_FILE
        end
        
        def id32_to_id64(steam_id32)
            return steam_id32 + I64
        end

        def id64_to_id32(steam_id64)
            return steam_id64 - I64
        end

        def post_refresh(steam_id32)
            uri = URI("#{HOST}/players/#{steam_id32}/refresh")
            
            https = Net::HTTP.new(uri.host, uri.port)
            https.use_ssl = true
            
            request = Net::HTTP::Post.new(uri.path)
    
            response = https.request(request)
    
            puts response
        end
    
        def get(uri)
            response = Net::HTTP.get(uri)
            puts "Got response from #{uri}"
    
            return response
        end
    
        def parce_heroes
            file = File.open HEROES_FILE
            data = JSON.load file
            file.close
    
            if data.length != 0
                data.each { |hero| @heroes[hero['id']] = hero['localized_name'] }
            else
                puts 'NO HEROES INFO'
            end
        end
    
        def parce_match(match_serial)
            data = download_match(match_serial)
            return data
            # puts "Match ##{data['match_id']}"
            # puts '-----------------------------------'
            # puts "Score: #{data['radiant_score']} - #{data['dire_score']}"
            # puts data['radiant_win'] ? 'Radiant win' : 'Dire win'
            # puts '-----------------------------------'
            # puts "Game duration: #{data['duration'].to_f/60} mins"
            # puts "Competitive match" if data['game_mode'] == 22
            
            # puts '-----------------------------------'
            # data['players'].each do |player|
            #     puts @heroes[player['hero_id']]
            #     puts "KDA - #{player['kills']}/#{player['deaths']}/#{player['assists']}"
            #     puts "Creep Stat #{player['last_hits']}/#{player['denies']}"
            #     puts '-----------------------------------'
            # end 
        end
        def parce_matches
            parce_heroes
            file = File.open(MATCHES_FILE)
            data = JSON.load(file)
            file.close
    
            data.each do |match|
                load_match(match['match_id'])
                parce_match
                break
            end 
        end
        
        def parce_player(steam_id32)
            data = download_player(steam_id32)
            puts data
            return data['profile']
        end

        def get_hero_image_by_id(hero_id)
            hero_name = @heroes[hero_id].downcase
            hero_name.gsub!('-', '')
            hero_name.gsub!(' ', '_')
            url = "http://cdn.dota2.com/apps/dota2/images/heroes/#{hero_name}_lg.png"
            return url
        end
    
        def get_hero_images
            images = {}
            @heroes.keys.each do |hero_id|
                images[hero_id] = get_hero_image_by_id hero_id
            end
            return images
        end
    
        def get_heroes
            return @heroes
        end
    end

    API = APIClient.new
end

if __FILE__ == $0
    API.parce_match
end
