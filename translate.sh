model=models/model.npz
json=models/model.npz.json
trg_lang=et
src_test=preprocessing_scripts/fixed_bpe

output=preprocessing_scripts/translated
THEANO_FLAGS=mode=FAST_RUN,floatX=float32,device=cpu python nematus/translate_nematus.py        \
        -m $model                                                                            	\
        -i $src_test                                                                            \
        -o $output                                                                              \
        --constraints preprocessing_scripts/constraints.json                                    \
	-c $json

