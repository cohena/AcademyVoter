require 'find'

class Nominee
    attr_reader(:name)

    def initialize(name, trailer_url = "")
        @name = name
    end
end

class Ballot
    attr_reader(:voter_name)
    attr_accessor(:selections)

    def initialize(voter_name, ballot_box)
        @voter_name = voter_name
        @ballot_box = ballot_box
        @selections = {}
        @ballot_box.get_categories.each { |category| @selections.store(category.to_sym, nil) }
    end

    def self.from_hash(source_hash, ballot_box)
        ballot = self.new(source_hash[:voter_name], ballot_box)
        ballot.selections = source_hash[:selections]
        return ballot
    end

    def to_hash
        return {
            :voter_name => @voter_name,
            :selections => @selections
        }
    end

    def vote(category, nominee)
        @selections[category.to_sym] = nominee
        puts "#@voter_name voted - #{category.to_s}: #{nominee.name}"
    end

    def get_next_category_and_nominees
        @ballot_box.get_categories.each do |cat|
            if @selections[cat.to_sym].nil?
                return cat, @ballot_box.get_nominees_for_category(cat)
            end
        end

        #done voting
        return nil, nil
    end

    def cast_ballot
        @ballot_box.cast_ballot(self)
    end
end

class BallotBox
    attr_reader :ballot_dir, :nominees

    def initialize(ballot_dir, nominees_file)
        @ballot_dir = ballot_dir
        @ballots = {}
        @nominees = YAML.load(File.open(nominees_file))

        load_ballots
    end

    def blank_ballot(name)
        new_ballot = Ballot.new(name.to_s, self)
        @ballots[name.to_sym] = new_ballot
        return new_ballot
    end

    def load_ballots
        Find.find(@ballot_dir) do |f|
            if File.extname(f) == ".yaml"
                ballot = YAML.load(File.open(f))
                if ballot.is_a?(Hash)
                    @ballots[ballot[:voter_name].to_sym] = Ballot.from_hash(ballot, self)
                    puts "Loaded #{ballot[:voter_name]} from hash"
                elsif ballot.is_a?(Ballot)
                    @ballots[ballot.voter_name.to_sym] = ballot
                    puts "Loaded #{ballot.voter_name} from Ballot"
                end
            end
        end
    end

    def cast_ballot(ballot)
        File.open("./ballots/#{ballot.voter_name.gsub(" ", "_")}.yaml", "w+") { |f| f.puts(YAML.dump(ballot.to_hash)) }
    end

    def get_categories
        return @nominees.keys.sort { |a, b| a.to_s <=> b.to_s }
    end

    def get_nominee_by_cat_and_name(category, nom_name)
        @nominees[category.to_sym].each do |nominee|
            if nominee.name == nom_name
                return nominee
            end
        end
    end

    def get_nominees_for_category(category)
        return @nominees[category]
    end

    def get_correct_ballot
        return get_ballot_for_name("Correct")
    end

    def get_submitted_names
        return @ballots.keys.reject { |name| name.nil? || name.to_s == "Correct" }
    end

    def get_ballot_for_name(name)
        if @ballots.has_key?(name.to_sym)
            return @ballots[name.to_sym]
        else
            return blank_ballot(name)
        end
    end

    def score_ballot(ballot, correct_ballot = get_correct_ballot)
        score = 0
        return score if ballot == false or correct_ballot == false

        get_categories.each do |category|
            if correct_ballot.selections[category] != nil && ballot.selections[category] != nil
                if correct_ballot.selections[category].name == ballot.selections[category].name
                    score += get_nominees_for_category(category).length
                end
            end
        end
        return score
    end

    def get_all_scores
        scores = get_submitted_names.map do |name|
            [name, score_ballot(get_ballot_for_name(name))]
        end
        return scores.sort { |x, y| [y[1], x[0]] <=> [x[1], y[0]] }
    end
end

#def ballot_box
#  yaml_noms = YAML.load(File.open("./nominees.yaml"))
#  puts "What is your name? "
#  name = gets.chomp.strip
#  ballot = Ballot.new(name, yaml_noms)
#  ballot.get_categories.each do |category|
#    puts "Category - #{category.to_s}:\n"
#    nominees = ballot.get_nominees_for_category(category)
#    nominees.each_index do |index|
#      nominee = nominees[index]
#      puts "\t#{index+1}. #{nominee.name}"
#    end
#    puts  "\nWhat is your choice? "
#    choice = gets.chomp.strip.to_i - 1
#    ballot.vote(category, nominees[choice])
#  end
#
#  puts "Results:\n"
#  ballot.get_categories.each do |category|
#    puts "\t#{category.to_s}: #{ballot.selections[category].name}\n"
#  end
#
#  ballot.cast_ballot
#end
#
#
#
#ballot = YAML.load(File.open("./ballots/Aaron_Cohen.yaml"))
#correct_ballot = YAML.load(File.open("./ballots/Correct.yaml"))
#
#puts "Score: " + score_ballot(ballot, correct_ballot).to_s
#ballot_box