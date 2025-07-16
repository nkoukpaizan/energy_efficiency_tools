#!/bin/bash
#SBATCH -J hpgmxp_freq_sweep
#SBATCH -A stf006          # EDIT: Use your project account 
#SBATCH --time=2:00:00     # EDIT: Time limit for the job
#SBATCH --nodes=1          # EDIT: Number of nodes for the job
# #SBATCH -q debug           # EDIT: Comment if you don't want to submit to the debug queue 
#SBATCH -e job_error.log
#SBATCH -o job_output.log

#### Global parameters
EE_TOOLS_PATH=/lustre/orion/scratch/nkouk/stf006/Codes/energy_efficiency_tools  # EDIT: location of the energy_efficiency_tools directory 
APP_PATH=/lustre/orion/scratch/nkouk/stf006/Codes/HPG-MxP                       # EDIT: application path
FREQUENCY_CAP_VALS=(1700 1600 1500 1400 1300 1200 1100 1000 900 800 700 600 500) 

#### Job parameters
WORK_DIR=${EE_TOOLS_PATH}/HPG-MxP      # EDIT: Work directory for the frequency sweep 
N_MPI_PER_NODE=8                       # EDIT: Number of MPI ranks per node 
HPCG_NX=320
HPCG_NY=320
HPCG_NZ=320
RUNTIME=60 #1800
EXEC="${APP_PATH}/_install/bin/xhpgmp --nx=$HPCG_NX --ny=$HPCG_NY --nz=$HPCG_NZ --rt=$RUNTIME" # EDIT: Application executable and parameters
AFFINITY="-c 7 --ntasks-per-node=${N_MPI_PER_NODE} --gpus-per-task=1 --gpu-bind=closest --exclusive"     # EDIT: Affinity config to run your application
N_NODES=${SLURM_JOB_NUM_NODES}
N_MPI=$((N_NODES*N_MPI_PER_NODE))
#NOTE: The srun command looks like follows: srun -n $N_MPI $AFFINITY $EXEC

#### Setup application environment  
# EDIT: Environment setup for your application
. /lustre/orion/scratch/nkouk/stf006/Codes/HPG-MxP/env.sh

# NOTHING ELSE TO EDIT BELOW
################################################################################

echo "EXEC: ${EXEC}"
echo "AFFINITY: ${AFFINITY}"
echo "N_NODES: ${N_NODES}"
echo "N_MPI_PER_NODE: ${N_MPI_PER_NODE}"
echo "N_MPI: ${N_MPI}"

#### Setup Omnistat
export OMNISTAT_VICTORIA_DATADIR=/tmp/omnistat/${SLURM_JOB_ID}
SAMPLING_INTERVAL=0.1
ml use /autofs/nccs-svm1_sw/crusher/amdsw/modules
ml omnistat-wrapper/1.6.0


#### Run the frequency sweep job
echo "SLUM_NODES=$SLURM_JOB_NUM_NODES  NODE_LIST:$SLURM_NODELIST"
echo "Starting SLURM job. $(date)"

# Loop over the frequency caps 
for MAX_SCLK in "${FREQUENCY_CAP_VALS[@]}"
do

  export FREQUENCY_CAP=$MAX_SCLK
  echo -e "\n###### Starting run with frequency cap: ${FREQUENCY_CAP} MHz"
  
  # Setup directory for this FREQUENCY_CAP
  RUN_DIR=${WORK_DIR}/maxsclk_${FREQUENCY_CAP}
  if [ ! -d "${RUN_DIR}" ]; then
    mkdir -p ${RUN_DIR}
  fi

  # Setup directory for energy counters
  export ENERGY_COUNTER_DIR=${RUN_DIR}

  # Start Omnistat
  ${OMNISTAT_WRAPPER} usermode --start --interval ${SAMPLING_INTERVAL}

  # Run the application
  echo "Starting application. $(date)"
  echo $(date +"%Y-%m-%d %H:%M:%S.%N") > ${RUN_DIR}/time_start.txt
  srun -n $N_MPI $AFFINITY ${EE_TOOLS_PATH}/tools/app_launcher.sh  $EXEC > ${RUN_DIR}/app_output.txt
  echo $(date +"%Y-%m-%d %H:%M:%S.%N") > ${RUN_DIR}/time_end.txt
  echo "Finished application. $(date)"

  # Finish Omnistat, generate summary pdf and copy database
  ${OMNISTAT_WRAPPER} usermode --stopexporters
  ${OMNISTAT_WRAPPER} query --interval ${SAMPLING_INTERVAL} --job ${SLURM_JOB_ID} --pdf ${RUN_DIR}/omnistat.${SLURM_JOB_ID}.pdf --export ${RUN_DIR}
  ${OMNISTAT_WRAPPER} usermode --stopserver
  mv /tmp/omnistat/${SLURM_JOB_ID} ${RUN_DIR}/data_omnistat.${SLURM_JOB_ID}

  echo "###### Finished run with frequency cap: ${FREQUENCY_CAP} MHz"
  
done

echo "Finished SLURM job. $(date)"
