import codecs, numpy, sys

if __name__ == "__main__":
	f = codecs.open("detok", encoding="utf-8").readlines()
	masks = numpy.load("masks.npy").item()
	mask_covers = ['__o_xml_tag__', '__c_xml_tag__', '__xml_tag__', '__httpurl__']
	target = open("ltranslation", "w")
	for a in range(len(f)):
		line = f[a]
		mask = masks[a]
		vmask = []
		for b in range(len(mask.keys())):
			vmask += mask[mask.keys()[b]]
		vmask = list(set(vmask))
		for b in range(len(vmask)):		
			line = line.replace(vmask[b], "__"+str(b)+"__")
		line = line.replace(">", "&gt;")
		line = line.replace("<", "&lt;")
		line = line.replace("'", "&apos;")
		line = line.replace('"', "&quot;")
		line = line.replace("&", "&amp;")
		for b in range(len(vmask)):
			line = line.replace("__"+str(b)+"__", vmask[b])
		target.write(line.encode("utf-8"))
	target.close()
