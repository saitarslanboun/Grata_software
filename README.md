# Grata_translation_script

This script is intended to translate texts with tags in memory files by using masking and Grid Beam Search (GBS).

Translation models, dictionaries, truecasing model, and byte pair encoding model are located under "models/" directory.

In order to run translator, the command line is as the following.

python translate_memory.py  \
  --memory_file <full_path_of_memory_file>  \
  --mask_regexes <[['__xml_tag__'], ['__o_xml_tag__'], ['__c_xml_tag__'], ['__httpurl__']]>

There are 4 different mask covers ['__xml_tag__', '__o_xml_tag__', '__c_xml_tag__', '__httpurl__'] trained with the model. Respectively, mask covers list represent xml tags, opening xml tags, closing xml tags, httpurls. 

The file "original_masks" contains couple of mask regexes. But Since xml tags vary from file to file, the user can give mask regex list in the form shown above as a json file. For instance, 

[['<ph\s+x=".*?"\s+type=".*?"\s+\/>', '<ph\s+type=".*?"\s+\/>'], ['<ph\s+x=".*?">'], ['</ph>'], ['(?:http|https)(?::\/{2}[\w]+)(?:[\/|\.]?)(?:[^\s"]*)']].

In order to use different mask covers, you can train a new translation model which involves mask covers you want to use, and change it by updating the scripts. The original model is for German-Estonian translation involving sentence pairs with mask covers above.
