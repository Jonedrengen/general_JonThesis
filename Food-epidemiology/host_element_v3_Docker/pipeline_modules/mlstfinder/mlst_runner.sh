#!/bin/bash

#timer start
STARTTIMER="$(date +%s)"

#activate conda env (specified in dockerfile)
. "/opt/miniconda/etc/profile.d/conda.sh"
conda activate mlstfinder

usage() {
    echo
    echo "========================================"
    echo "           mlstfinder Runner"
    echo "========================================"
    echo
    mlst -v
    echo
    echo "Usage:"
    echo "  $0 -i <INPUT_FOLDER> -o <OUTPUT_FOLDER> [-s <SAMPLE_LIST>] [-c <CONFIG>] [-h]"
    echo
    echo "Options:"
    echo "  -i <INPUT_FOLDER>   (required) Path to folder containing .fasta sequence files"
    echo "  -o <OUTPUT_FOLDER>  (required) Folder for results"
    echo "  -s <SAMPLE_LIST>    (optional) TODO: File listing samples to process (default: all .fasta files in INPUT_FOLDER)"
    echo "  -c <CONFIG>         (optional) TODO: Config file with mlst options (scheme, coverage, identity) (default: hardcoded values)"
    echo "  -h                  Show this help message and exit"
    echo
    echo "Example (Docker):"
    echo "  docker run -v /path/to/data:/src/input -v /path/to/out:/src/out mlstfinder -i /src/input -o /src/out"
    echo "======================================="
    echo
}

#get inpput options
while getopts "i:s:o:c:h" opt; 
do
    case $opt in
        i) INPUT_FOLDER="$OPTARG" ;;
        s) SAMPLE_LIST="$OPTARG" ;;
        o) OUTPUT_FOLDER="$OPTARG" ;;
        c) CONFIG="$OPTARG" ;;
        h) usage; exit 0 ;;
        \?) usage; exit 1 ;; #handle non-existand opt
        :) usage; exit 1 ;;  #handle if opt is specified but not filled by user
    esac
done

#essential arg handling
if [ ! -d "$INPUT_FOLDER" ];
then
    echo "#######################"
    echo
    echo "      INPUR_FOLDER: $INPUT_FOLDER not a folder or does not exist!"
    echo "      or maybe you forgot to mount a volume with -v, if you're running via Docker!"
    echo "          -mount: docker run -v /path/to/data:/src/input -v /path/to/out:/src/out mlstfinder -i /src/input -o /src/out"
    echo 
    echo "#######################"
    exit 1
fi

#required args handling
if [ -z "$OUTPUT_FOLDER" ];
then
    echo
    echo "ERROR: -o <OUTPUT_FOLDER> is required."
    echo
    usage
    exit 1
fi

if [ -z "$SAMPLE_LIST" ];
then
    echo; echo "no sample list provided with option -s"; echo "generating sample list in /tmp"
    mkdir -p "$OUTPUT_FOLDER/tmp"
    for line in "$INPUT_FOLDER"/*.f*;
    do
        sample_name=$(basename "$line")
        echo "$sample_name" >> "$OUTPUT_FOLDER/tmp/SAMPLE_LIST"
    done
    SAMPLE_LIST="$OUTPUT_FOLDER/tmp/SAMPLE_LIST"
fi

#filesystem
mkdir -p "${OUTPUT_FOLDER}/processing_files"
mkdir -p "${OUTPUT_FOLDER}/combined_results"
mkdir -p "${OUTPUT_FOLDER}/tmp"

#unpack config if provided TODO
if [ -z "$CONFIG" ];
then
    scheme="ecoli_achtman_4"
    coverage=95
    identity=50
    
else
    echo "config provided: $CONFIG"
    scheme=$(grep "^scheme" "$CONFIG" | awk -F "=" '{print $2}' | xargs)
    coverage=$(( $(grep "^coverage" "$CONFIG" | awk -F "=" '{print $2}' | xargs) )) ## $(()) means to int
    identity=$(( $(grep "^identity" "$CONFIG" | awk -F "=" '{print $2}' | xargs) ))
fi

#run cmd
run_mlstfinder() {
    sequence="$1"
    sample_name="$2"
    project_root="$3"
    mlst "$sequence" \
    --mincov $(( "$coverage" )) \
    --minid $(( "$identity" )) \
    --scheme "$scheme" \
    --legacy \
    --label "$sample_name" \
    --quiet \
    --csv
}
#export function and variables for gnu parallel
export -f run_mlstfinder
export scheme coverage identity

#parallize with gnu parallel
parallel -j 0 run_mlstfinder "$INPUT_FOLDER/{}" "{.}" "$project_root" '>' "${OUTPUT_FOLDER}/processing_files/{.}.csv" :::: "$SAMPLE_LIST" 

#give specifics
echo 
echo "mincov    :   ${coverage}"
echo "minid     :   ${identity}"
echo

#combine results
echo "combining"
echo "FILE,SCHEME,ST,adk,fumC,gyrB,icd,mdh,purA,recA" > "${OUTPUT_FOLDER}/combined_results/combined_mlst_results.csv"
while read -r sample;
do
    sample_name=$(echo "$sample" | awk -F'.' '{print $1}')
    if [ -z "$(grep "^$sample_name" "${OUTPUT_FOLDER}/processing_files/${sample_name}.csv")" ];
    then
        echo "$sample_name,$scheme,NA,NA,NA,NA,NA,NA,NA" >> "${OUTPUT_FOLDER}/combined_results/combined_mlst_results.csv"
    else
        grep "^$sample_name" "${OUTPUT_FOLDER}/processing_files/${sample_name}.csv" >> "${OUTPUT_FOLDER}/combined_results/combined_mlst_results.csv"
    fi
    
done < "$SAMPLE_LIST"

conda deactivate

# timer end
ENDTIMER="$(date +%s)"
DURATION=$[${ENDTIMER} - ${STARTTIMER}]
HOURS=$((${DURATION} / 3600))
MINUTES=$(((${DURATION} % 3600)/ 60))
SECONDS=$(((${DURATION} % 3600) % 60))
echo "RUNTIMER: $HOURS:$MINUTES:$SECONDS (hh:mm:ss)"