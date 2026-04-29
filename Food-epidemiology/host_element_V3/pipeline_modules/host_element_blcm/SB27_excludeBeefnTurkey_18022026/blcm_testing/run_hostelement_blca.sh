#!/bin/sh
#SBATCH --time 3-00:00:00
#SBATCH -J Bayesian_latent_class_modelling_testing
#SBATCH -p project
#SBATCH -o run_hostelement_blca_%j.out
#SBATCH -e run_hostelement_blca_%j.err
#SBATCH --cpus-per-task=6
#SBATCH --mem=32G

STARTTIMER="$(date +%s)"

#config
config_file_local="/dpssi/data/Projects/mtg_host_elements_files_and_output/proj/general_JonThesis/Food-epidemiology/host_element_V3/config/config.env"
config_file=${CONFIG_FILE:-$config_file_local}
#paths
project_root=$(grep '^GLOBAL__PROJECT_ROOT__=' "$config_file" | awk -F'__=' '{print $2}')
host_element_blcm_scripts="$project_root/pipeline_modules/host_element_blcm/SB27_excludeBeefnTurkey_18022026/blcm_testing"
#conda envs
conda_source=$(grep "^GLOBAL__CONDA_SH__=" "$config_file" | awk -F'__=' '{print $2}')
#for running latent class model
conda_env_blcm=$(grep "^BLCM__CONDA_ENV__=" "$config_file" | awk -F'__=' '{print $2}')
#for compiling input
conda_env_r_basics=$(grep "^BLCM__R_BASICS_ENV__=" "$config_file" | awk -F'__=' '{print $2}')

. "$conda_source"
conda activate "$conda_env_blcm"

# User Inputs
CSV_Input=$1
Folder_Output=$2

Rscript $host_element_blcm_scripts/testing_blca_model.R -i $CSV_Input -o $Folder_Output


# Script Timer
ENDTIMER="$(date +%s)"
DURATION=$[${ENDTIMER} - ${STARTTIMER}]
HOURS=$((${DURATION} / 3600))
MINUTES=$(((${DURATION} % 3600)/ 60))
SECONDS=$(((${DURATION} % 3600) % 60))
echo "RUNTIMER: $HOURS:$MINUTES:$SECONDS (hh:mm:ss)"
