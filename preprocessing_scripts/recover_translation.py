import codecs, numpy

def RepresentsInt(s):
    try: 
        int(s)
        return True
    except ValueError:
        return False

if __name__ == "__main__":
	f = codecs.open("translated", encoding="utf-8").readlines()
	masks = numpy.load("masks.npy").item()
	mask_covers = ['__o_xml_tag__', '__c_xml_tag__', '__xml_tag__', '__httpurl__']
	recover = open("recovered", "w")
	for a in range(len(f)):
		mask_dict = masks[a]
		tokens = f[a].replace("\n", "").split()
		for b in range(len(tokens)):
			if tokens[b] in mask_covers:
				if b != 0 and RepresentsInt(tokens[b-1]):
					tokens[b] = mask_dict[tokens[b]][int(tokens[b-1])]
					tokens[b-1] = ""
				else:
					tokens[b] = ""
		#line = " ".join(tokens).replace("@@ ", "")
		#line = line.replace("@@", "")
		line = " ".join(tokens)
		line += "\n" 
		recover.write(line.encode("utf-8"))
	recover.close()
