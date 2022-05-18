module Curp
  class Generator
    attr_reader :curp, :name, :paternal_last_name, :maternal_last_name,
                :date_of_birth, :birthplace, :gender

    ACCENT_ORIGIN_DICT  = %w[Ã À Á Ä Â È É Ë Ê Ì Í Ï Î Ò Ó Ö Ô Ù Ú Ü Û ã à á ä â è é ë ê ì í ï î ò ó ö ô ù ú ü û Ç ç]
    ACCENT_DEST_DICT = %w[A A A A A E E E E I I I I O O O O U U U U a a a a a e e e e i i i i o o o o u u u u c c]
    COMMON_NAMES = %w[MARIA MA MA. JOSE J J.]
    VERIFICATION_DICT = %w[0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N Ñ O P Q R S T U V W X Y Z]
    CURP_WILDCARD = 'X'
    LAST_NAME_LETTER_EXCEPTION = 'Ñ'
    CONSONANT_REGEX = Regexp.new(/[BCDFGHJKLMNÑPQRSTVWXYZ]/)
    NON_ALPHABETICAL_REGEX = Regexp.new(/[\d_\-\.\/\\,]/)
    VOWELS_REGEX = Regexp.new(/[AEIOU]/i)
    COMPOUND_NAME_REGEX = [/\bDA\b/, /\bDAS\b/, /\bDE\b/, /\bDEL\b/, /\bDER\b/, /\bDI\b/,
                           /\bDIE\b/, /\bDD\b/, /\bEL\b/, /\bLA\b/, /\bLOS\b/, /\bLAS\b/, /\bLE\b/,
                           /\bLES\b/, /\bMAC\b/, /\bMC\b/, /\bVAN\b/, /\bVON\b/, /\bY\b/]
    NOT_ALLOWED_STRINGS = [ 'BACA', 'LOCO', 'BUEI', 'BUEY', 'MAME', 'CACA', 'MAMO',
                            'CACO', 'MEAR', 'CAGA', 'MEAS', 'CAGO', 'MEON', 'CAKA', 'MIAR', 'CAKO', 'MION',
                            'COGE', 'MOCO', 'COGI', 'MOKO', 'COJA', 'MULA', 'COJE', 'MULO', 'COJI', 'NACA',
                            'COJO', 'NACO', 'COLA', 'PEDA', 'CULO', 'PEDO', 'FALO', 'PENE', 'FETO', 'PIPI',
                            'GETA', 'PITO', 'GUEI', 'POPO', 'GUEY', 'PUTA', 'JETA', 'PUTO', 'JOTO', 'QULO',
                            'KACA', 'RATA', 'KACO', 'ROBA', 'KAGA', 'ROBE', 'KAGO', 'ROBO', 'KAKA', 'RUIN',
                            'KAKO', 'SENO', 'KOGE', 'TETA', 'KOGI', 'VACA', 'KOJA', 'VAGA', 'KOJE', 'VAGO',
                            'KOJI', 'VAKA', 'KOJO', 'VUEI', 'KOLA', 'VUEY', 'KULO', 'WUEI', 'LILO', 'WUEY',
                            'LOCA' ]

    def initialize(name: '', paternal_last_name: '', maternal_last_name: '',
                   date_of_birth: '', birthplace: '', gender: '')
      @name = name
      @paternal_last_name = paternal_last_name
      @maternal_last_name = maternal_last_name
      @date_of_birth = date_of_birth
      @birthplace = birthplace
      @gender = gender

      @curp = process_personal_data
    end

    def process_personal_data
      normalize_names

      curp = [
        get_first_curp_letters,
        get_year_digits,
        sprintf("%02d", @date_of_birth.month),
        sprintf("%02d", @date_of_birth.day),
        @gender.upcase,
        @birthplace.upcase,
        get_penultimate_letters,
        get_homonimia
      ].join

      get_verify_digit(curp)
    end

    private

      # We need to remove accent chars in name (á, à, â ä, ã...)
      def remove_accents(name_str)
        split_name = name_str.split('')
        clean_name = split_name.collect do |char|
          index = ACCENT_ORIGIN_DICT.find_index(char)
          index ? ACCENT_DEST_DICT[index] : char
        end
        clean_name.join
      end

      # Finds compounds in names and replaces it to empty string (De, De La, Y...)
      def remove_compounds(name_str)
        COMPOUND_NAME_REGEX.each do |regex|
          name_str.match?(regex) ? name_str.sub!(regex,'').squish! : name_str
        end
      end

      # TODO: This can be improved
      def normalize_names
        @name = remove_accents(@name.upcase.squish)
        @paternal_last_name = remove_accents(@paternal_last_name.upcase.squish)
        @maternal_last_name = remove_accents(@maternal_last_name.upcase.squish)

        remove_compounds(@name)
        remove_compounds(@paternal_last_name)
        remove_compounds(@maternal_last_name)
      end

      def get_name_initials(names)
        name_array = names.split(/\s+/)
        first_name_common = name_array.length > 1 && !COMMON_NAMES.include?(name_array.first)
        first_name_common ? name_array.first[0] : name_array.last[0]
      end

      def get_first_letter(last_name)
        first_letter = last_name[0]
        first_letter == LAST_NAME_LETTER_EXCEPTION ? CURP_WILDCARD : first_letter
      end

      def get_first_letter_maternal(last_name)
        last_name ? get_first_letter(last_name) : CURP_WILDCARD
      end

      def get_vowel_paternal(last_name)
        last_name[1..-1].gsub(CONSONANT_REGEX, '')[0] || CURP_WILDCARD
      end

      def filter_not_allowed_strings(first_four_letters)
        not_alphabetical_filter = first_four_letters.gsub(NON_ALPHABETICAL_REGEX, CURP_WILDCARD)
        return not_alphabetical_filter[0] + not_alphabetical_filter.sub(/^(\w)\w/, CURP_WILDCARD) if NOT_ALLOWED_STRINGS.include?(not_alphabetical_filter)
        not_alphabetical_filter
      end

      # Get letters for positions 14 - 16 returns X if not found
      def get_string_consonant(string)
        char = string[1..-1].gsub(VOWELS_REGEX, '')[0]
        !char || char == LAST_NAME_LETTER_EXCEPTION ? CURP_WILDCARD : char
      end

      def get_string_consonant_for_name(name)
        name_array = name.split(/\s+/)
        first_name_common = name_array.length > 1 && !COMMON_NAMES.include?(name_array.first)
        get_string_consonant(first_name_common ? name_array.first : name_array.last)
      end

      def get_first_curp_letters
        filter_not_allowed_strings([
                                     get_first_letter(@paternal_last_name),
                                     get_vowel_paternal(@paternal_last_name),
                                     get_first_letter_maternal(@maternal_last_name),
                                     get_name_initials(@name)
                                   ].join)
      end

      def get_penultimate_letters
        [
          get_string_consonant(@paternal_last_name),
          get_string_consonant(@maternal_last_name),
          get_string_consonant_for_name(@name)
        ].join
      end

      def get_verify_digit(curp)
        curp_array = curp.split('')
        numeric_curp = curp_array.collect {|c| VERIFICATION_DICT.index(c) }
        sum = numeric_curp.each.with_index.reduce(0) { |prev, value| prev + (value[0] * (18 - value[1])) }
        digit = (10 - (sum % 10))
        digit = 0 if digit == 10

        curp + digit.to_s
      end

      def get_homonimia
        @date_of_birth.year > 1999 ? 'A' : 0
      end

      def get_year_digits
        @date_of_birth.year.to_s[2..3]
      end
  end
end
