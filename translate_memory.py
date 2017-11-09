import argparse, ast, codecs, os, sys

if __name__ == '__main__':
	parser = argparse.ArgumentParser()

	parser.add_argument("--memory_file", type=str, required=True, metavar="PATH",
				help="full path of translation memory file directory to be given as an input to translate")
	parser.add_argument('--mask_regexes', type=str, default=None, required=False,
                        help='(Optional) json file containing list of mask items in the form [[<__xml_tag__ regex>], [<__o_xml_tag__ regex>], [<__c_xml_tag__ regex>], [<__httpurl__ regex>]]')
	args = parser.parse_args()

	memory_file = vars(args)['memory_file']
	mask_file = vars(args)['mask_regexes']

	# extracting sentences from memory file
	cmd_line = "python preprocessing_scripts/extract_sentences.py " + os.getcwd()+"/memory/"+memory_file
	os.system(cmd_line)
	cmd_line = "mv " + os.getcwd() + "/memory/" + memory_file + ".s " + os.getcwd() + "/preprocessing_scripts/text"
	os.system(cmd_line)

	# fixing the text file before preprocessing
	cmd_line = "cd preprocessing_scripts && python fix_text.py"
	os.system(cmd_line)

	# tokenizing and masking the text file
	if mask_file == None:
		cmd_line = "cd preprocessing_scripts && python write_masks.py"
	else:
		cmd_line = "cd preprocessing_scripts && python write_masks.py " + os.getcwd()+"/"+mask_file
	os.system(cmd_line)
	cmd_line = "cd preprocessing_scripts && ./tokenizer.pl < fixed_text > tok"
	os.system(cmd_line)
	cmd_line = "cd preprocessing_scripts && recaser/truecase.perl --model ../models/tm < tok > true"
	os.system(cmd_line)
	cmd_line = "cd preprocessing_scripts && python apply_bpe.py -c  ../models/bpe_codes < true > bpe"
	os.system(cmd_line)
	cmd_line = "cd preprocessing_scripts && python create_constraints.py"
	os.system(cmd_line)	

	# translate text	
	cmd_line = "./translate.sh"
	os.system(cmd_line)

	# index mask covers
	cmd_line = "cd preprocessing_scripts && python index_masks.py"
	os.system(cmd_line)

	# recover translated file
	cmd_line = "cd preprocessing_scripts && python recover_translation.py"
	os.system(cmd_line)

	# merge bpes in translated file
	cmd_line = "cd preprocessing_scripts && python merge_bpes.py"
	os.system(cmd_line)

	# detruecase translated file
	cmd_line = "cd preprocessing_scripts && recaser/detruecase.perl < debpe > detrue"
	os.system(cmd_line)

	# detok translated file
	cmd_line = "cd preprocessing_scripts && tokenizer/detokenizer.perl < detrue > detok"
	os.system(cmd_line)

	# last fixes on translated file
	cmd_line = "cd preprocessing_scripts && python last_fix.py"
	os.system(cmd_line)

	# allocating translations back on translation memory file
	cmd_line = "cd preprocessing_scripts && python allocate_translations.py " + memory_file + " ltranslation"
	os.system(cmd_line)

	# remove unnecessary files
	cmd_line = "cd preprocessing_scripts && "
	cmd_line += "rm bpe constraints.json debpe detok detrue fixed_bpe fixed_text ltranslation masks.npy recovered "
	cmd_line += "masked-classified-regexp.dat text tok translated true"
	os.system(cmd_line)
