# encoding: utf-8
class Parsers::BioanalysisCsvParser
	def initialize(file)
		@file_path = file
	end

	def read_file(file)
		fd = File.open(file, "r:UTF-8")
		content = []
		while (line = fd.gets) 
			content.push line
		end
		fd.close

		# <ruby-1.9>content.join("").force_encoding("ISO-8859-1").encode("UTF-8")</ruby-1.9>
		content.join("")
	end

	def table_content_hash(content)
		lines = content.split(/\r/).select {|l| l.match(/,/)}
		content_hash = {}
		fields = lines[0].split(/,/)
		unless lines[1].nil?
			values = lines[1].split(/,/)
			fields.each_with_index do |field,pos|
				content_hash[field] = values[pos]
			end
		end
		content_hash
	end

	def parse_peak_table(content)
		table_content_hash((content.match(/Peak Table.*Region/m))[0])
	end

	def parse_region_table(content)
		table_content_hash((content.match(/Region Table.*Overall/m))[0])
	end

	def parse_overall(content)
		(content.match(/Overall.*/m))[0]
	end

	def parse_cell(content)
		@cell = (content.match (/[A-Z]\d+/))[0]
	end

	def parse_sample(sample_text)
		{
			parse_cell(sample_text) => {
			:peak_table => parse_peak_table(sample_text),
			:region_table => parse_region_table(sample_text),
			:overall => parse_overall(sample_text)
		    }
		}
	end

	def parse_samples(content)
		samples_content = content.split(/Sample Name,/).drop(1)
		samples_content.reduce({}) {|memo, obj| memo.merge(self.parse_sample obj) }
	end

	def parse
		content = read_file @file_path
		@parsed_content = parse_samples content
	end

	def parsed_content
		@parsed_content.nil? ? parse : @parsed_content
	end

	def concentration(plate_position)
		field = "Conc. [ng/µl]"
		field = parsed_content[plate_position][:peak_table].keys[1]
		parsed_content[plate_position][:peak_table][field]
	end

	def validates_content?
		@file_path.match(/\.csv$/i).length > 0
	end
end