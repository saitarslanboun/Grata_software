import codecs, ast, sys, os

if __name__ == "__main__":
	regex_file = codecs.open("original_masks", encoding="utf-8").readlines()
	if len(sys.argv) > 1:
		ad_regex_file = codecs.open(sys.argv[1], encoding="utf-8").readlines()
	mask_covers = ['__xml_tag__', '__o_xml_tag__', '__c_xml_tag__', '__httpurl__']
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
	
	if len(sys.argv) > 1:
		ad_masks = ast.literal_eval(ad_regex_file[0])
	else:
		ad_masks = [[],[],[],[]]
	target = open("masked-classified-regexp.dat", "w")
	for a in range(len(mask_covers)):
		masks[mask_covers[a]] += ad_masks[a]
		masks[mask_covers[a]] = list(set(masks[mask_covers[a]]))
		m_list = masks[mask_covers[a]]
		for b in range(len(m_list)):
			line = m_list[b] + "\t" + mask_covers[a][2:-2] + "\n"
			target.write(line.encode("utf-8"))
	target.close()
