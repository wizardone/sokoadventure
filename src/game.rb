require 'minigl'
require 'rbconfig'
require 'fileutils'
require_relative 'menu'

class Game
  class << self
    include MiniGL

    attr_reader :font, :big_font, :scores,
                :full_screen, :music_volume, :sound_volume, :last_level

    def load
      os = RbConfig::CONFIG['host_os']
      @save_dir =
        if /linux/ =~ os
          "#{Dir.home}/.vds-games/sokoadventure"
        else
          "#{Dir.home}/AppData/Local/VDS Games/SokoAdventure"
        end
      FileUtils.mkdir_p(@save_dir) unless File.exist?(@save_dir)

      scores_path = "#{@save_dir}/scores.soko"
      if File.exist?(scores_path)
        File.open(scores_path) do |f|
          @scores = f.read.split('|').map { |entry| entry.split(';').map(&:to_i) }
        end
      else
        @scores = []
        save_scores
      end

      config_path = "#{@save_dir}/config.soko"
      if File.exist?(config_path)
        File.open(config_path) do |f|
          data = f.read.split(';')
          @full_screen = data[0] == '+'
          @language = data[1].to_i
          @music_volume = data[2].to_i
          @sound_volume = data[3].to_i
          @last_level = data[4].to_i
        end
      else
        @full_screen = true
        @language = 0
        @music_volume = 10
        @sound_volume = 10
        @last_level = 1
        save_config
      end
    end

    def initialize
      @texts = []
      Dir["#{Res.prefix}/text/*.txt"].sort.each_with_index do |f_name, i|
        @texts[i] = {}
        File.open(f_name) do |f|
          f.read.each_line do |line|
            parts = line.split("\t")
            @texts[i][parts[0].to_sym] = parts[-1].chomp
          end
        end
      end

      @font = Res.font(:font, 20)
      @big_font = Res.font(:font, 32)

      @controller = Menu.new
    end

    def text(key)
      (@texts[@language][key] || '<!>').gsub('\\', "\n")
    end

    def play_song(id)
      Gosu::Song.current_song&.stop
      song = Res.song(id)
      song.volume = @music_volume * 0.1
      song.play(true)
    end

    def start(level)
      puts "starting level #{level}"
    end

    def save_scores
      File.open("#{@save_dir}/scores.soko", 'w+') do |f|
        f.write(@scores.map { |entry| entry.join(';') }.join('|'))
      end
    end

    def save_config
      File.open("#{@save_dir}/config.soko", 'w+') do |f|
        f.write([
          @full_screen ? '+' : '-',
          @language,
          @music_volume,
          @sound_volume,
          @last_level
        ].join(';'))
      end
    end

    def toggle_full_screen
      @full_screen = !@full_screen
      G.window.toggle_fullscreen
    end

    def next_language
      @language += 1
      @language = 0 if @language >= @texts.count
    end

    def change_music_volume(delta)
      @music_volume += delta
      @music_volume = 0 if @music_volume < 0
      @music_volume = 10 if @music_volume > 10
      Gosu::Song.current_song&.volume = @music_volume * 0.1
    end

    def change_sound_volume(delta)
      @sound_volume += delta
      @sound_volume = 0 if @sound_volume < 0
      @sound_volume = 10 if @sound_volume > 10
    end

    def update
      if KB.key_pressed?(Gosu::KB_RETURN) && (KB.key_down?(Gosu::KB_LEFT_ALT) || KB.key_down?(Gosu::KB_RIGHT_ALT))
        @full_screen = !@full_screen
      end

      @controller.update
    end

    def draw
      @controller.draw
    end
  end
end
