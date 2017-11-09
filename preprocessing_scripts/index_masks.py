import codecs, re, sys, numpy

if __name__ == "__main__":
	regex_file = codecs.open("masked-classified-regexp.dat", encoding="utf-8").readlines()
	text_file = codecs.open("fixed_text", encoding="utf-8").readlines()

	# creating mask dictionary
	masks = dict()
	for a in range(len(regex_file)):
		line = regex_file[a].replace("\n", "")
		lline = filter(lambda b: b != " ", list(line))
		if not lline:
			continue
		if lline[0] != "#":
			regex, mask = line.split("\t")
			mask = "__" + mask + "__"
			if mask in masks.keys():
				masks[mask].append(regex)
			else:
				masks[mask] = [regex]
			masks[mask] = list(set(masks[mask]))

	masked_substrings = dict()
	for a in range(len(text_file)):
		masked_substrings[a] = dict()
		line = text_file[a].replace("\n", "")
		for b in range(len(masks.keys())):
			mask = masks.keys()[b]
			r_list = masks[mask]
			reg = ""
			for c in range(len(r_list)):
				reg += "(" + r_list[c] + ")"
				if c != len(r_list) - 1:
					reg += "|"
			l = re.findall(reg, line)
			nl = []
			for c in range(len(l)):
				nl += filter(lambda b: b != '', l[c])	
			masked_substrings[a][mask] = nl 
	
	numpy.save("masks.npy", masked_substrings)
