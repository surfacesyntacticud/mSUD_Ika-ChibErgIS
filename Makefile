# Universal variables
GREW=grew
GRS_CONVERT=/Users/guillaum/github/surfacesyntacticud/tools/converter/grs
UD_TOOLS=/Users/guillaum/github/UniversalDependencies/tools

# Corpus specific variables
LANG=arh
CORPUS_NAME=ChibErgIS
LOWER_CORPUS_NAME = `echo ${CORPUS_NAME} | tr '[:upper:]' '[:lower:]'`
SUD_FOLDER=/Users/guillaum/github/surfacesyntacticud/DATA/mSUD_Ika-ChibErgIS/SUD_Ika-ChibErgIS
UD_FOLDER=/Users/guillaum/github/UniversalDependencies/UD_Ika-ChibErgIS
wSUD_FOLDER=/Users/guillaum/github/surfacesyntacticud/DATA/mSUD_Ika-ChibErgIS/wSUD_Ika-ChibErgIS

doc:
	@echo "make norm     ---> normalise with Grew"
	@echo "make sud      ---> convert to SUD"
	@echo "make ud       ---> convert to UD"
	@echo "make validate ---> UD validation of last conversion"

norm:
	for file in *.conllu ; do \
		${GREW} transform -i $$file -o tmp.conllu ; \
		mv -f tmp.conllu $$file ; \
	done

sud:
	mkdir -p ${SUD_FOLDER}
	for infile in *.conllu ; do \
		out=`echo $$infile | sed "s+mSUD+SUD+"` ; \
		outfile=${SUD_FOLDER}/$$out ; \
		echo "$$infile --> $$outfile" ; \
		${GREW} transform -config sud -grs ${GRS_CONVERT}/arh_mSUD_to_SUD.grs -strat arh_mSUD_to_SUD_main  -i $$infile -o $$outfile ; \
	done
	@make build_ud

wsud:
	mkdir -p ${wSUD_FOLDER}
	for infile in *.conllu ; do \
		out=`echo $$infile | sed "s+mSUD+${wSUD_FOLDER}+"` ; \
		outfile=${wSUD_FOLDER}/$$out ; \
		echo "$$infile --> $$outfile" ; \
		${GREW} transform -config sud -grs ${GRS_CONVERT}/mSUD_to_wSUD.grs -i $$infile -o $$outfile ; \
	done

ud: sud
	for infile in ${SUD_FOLDER}/*.conllu ; do \
		outfile=`echo $$infile | sed "s+${SUD_FOLDER}/+${UD_FOLDER}/not-to-release/+" | sed "s+-sud-+-ud-+"` ; \
		echo "$$infile --> $$outfile" ; \
		${GREW} transform -text_from_tokens -config sud -grs ${GRS_CONVERT}/${LANG}_SUD_to_UD.grs -strat ${LANG}_SUD_to_UD_main -i $$infile -o $$outfile ; \
	done

TEST += Ika_tree.conllu

build_ud:
	echo "# global.columns = ID FORM LEMMA UPOS XPOS FEATS HEAD DEPREL DEPS MISC" > ${UD_FOLDER}/${LANG}_${LOWER_CORPUS_NAME}-ud-test.conllu
	for file in ${TEST} ; do \
		cat ${UD_FOLDER}/not-to-release/$$file | grep -v "# global.columns" >> ${UD_FOLDER}/${LANG}_${LOWER_CORPUS_NAME}-ud-test.conllu ; \
	done

validate:
	for file in ${UD_FOLDER}/*.conllu ; do \
		${UD_TOOLS}/validate.py --lang=${LANG} --max-err=0 $$file || true ; \
	done

# ================================================================================
size:
	@echo "sentences:"
	@grep "# sent_id = " *.conllu | wc -l
	@echo "tokens:"
	@egrep "^[0-9]+\t" *.conllu | wc -l


filter:
	grep DEPREL validation | awk '{print $$11, $$1, $$2, $$3, $$4}' | sort > valid_DEPREL 
	grep auxiliary validation | awk '{print $$10, $$1, $$2, $$3, $$4}' | sort > valid_auxiliary 
	cat validation | grep -v DEPREL | grep -v auxiliary > valid_XXX