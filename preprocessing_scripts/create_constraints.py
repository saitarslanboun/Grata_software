import sys, string, codecs, json

if __name__ == "__main__":
	f = codecs.open("bpe", encoding="utf-8").readlines()
	edit_f = open("fixed_bpe", "w")
	punctuations = list(string.punctuation)
	masks = ["__xml_tag__", "__o_xml_tag__", "__c_xml_tag__", "__httpurl__"]
	constraint_variables = punctuations + masks
	constraints = []
	for a in range(len(f)):
		sentence = f[a].replace("\n", "")
		tokens = sentence.split()

		# putting flags before tags
		for b in range(len(masks)):
			cntr = 0
			for c in range(len(tokens)):
				if tokens[c] == masks[b]:
					tokens[c] = str(cntr) + " " + masks[b]
					cntr += 1
		
		tokens = " ".join(tokens).split()
		
		# adding punctuation at the end and writing the changes to the file
		if [i for i in tokens if i in masks]:
			if tokens[-1] not in punctuations:
				tokens.append(".")
			line = " ".join(tokens) + "\n"
			edit_f.write(line.encode("utf-8"))
		else:
			line = " ".join(tokens) + "\n"
                        edit_f.write(line.encode("utf-8"))
			constraints.append([])
			continue

		# creating constraints		
		sub_const = []
		for b in range(len(tokens)):
			token = tokens[b]
			if token in constraint_variables:
				if token in masks:
					sub_const.append([tokens[b-1]])
					sub_const.append([token])
				else:
					sub_const.append([token])
			else:
				if tokens[b+1] not in masks:
					sub_const.append(token)

		new_sub_const = []
		l = []
		for b in range(len(sub_const)):
			if type(sub_const[b]).__name__ == "list":
				l += sub_const[b]
				if b == len(sub_const) - 1:
					new_sub_const.append(l)
			else:
				if l != []:
					new_sub_const.append(l)
					l = []
		constraints.append(new_sub_const)

	edit_f.close()
	with open("constraints.json", 'wb') as outfile:
                json.dump(constraints, outfile)
