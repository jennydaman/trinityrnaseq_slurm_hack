#!/bin/bash
# TODO rewrite in racket, use YAML config file from stdin

bold=$(tput bold)
reset=$(tput sgr0)

fancy_subroutine_name="${bold}hpc_cmds_GridRunner.pl${reset}"


function show_help () {
  cat << HELP
usage: $0 [-i IMAGE_NAME] [-e COMMAND] \\
          [-o OPTIONS] [-J LOGIN_NODE] [-w WORKDIR] \\
          [-n MAX_NODES] [-c CMDS_PER_NODE] \\
          COMMANDS_FILE

A wrapper around $fancy_subroutine_name which schedules the commands
inside containers on SLURM using sbatch over ssh.

options:

  -h    show this help and exit
  -i    image name
  -e    container exec invocation command (default: "singularity exec")
  -p    preparatory command for loading GNU parallel and Singularity
  -o    sbatch options
  -J    SSH login node
  -n    max nodes
  -c    cmds per node
  -w    working directory (default: "./chorus-\$SLURM_JOB_ID")

example:

    $0 \\
        -p 'module load singularity/3.5.3 && module load /work/addres/local/scripts/loadconda && conda activate /work/addres/local/opt/conda/envs/datalad' \\
        -e 'singularity exec --cleanenv' \\
        -i '/work/addres/Singularity/trinityrnaseq.v2.13.2.simg' \\
        -o '--partition=express --time=01:00:00 --mem=21G --nodes=1 --ntasks=1 --cpus-per-task=20' \\
        -n 100 -c 100 \\
        -J 'login-01.discovery.neu.edu' \\
        recursive_trinity.cmds
HELP
}

workdir="chorus-$SLURM_JOB_ID"
singularity_exec='singularity exec'
sing_image=
sbatch_options=
login_node=
max_nodes=
cmds_per_node=
shell_header=

while getopts ":hi:e:w:o:J:n:c:p:" opt; do
  case $opt in
  h   ) show_help && exit 0 ;;
  i   ) sing_image="$OPTARG" ;;
  e   ) singularity_exec="$OPTARG" ;;
  w   ) workdir="$OPTARG" ;;
  J   ) login_node="$OPTARG" ;;
  o   ) sbatch_options="$OPTARG" ;;
  n   ) max_nodes="max_nodes=$OPTARG" ;;
  c   ) cmds_per_node="cmds_per_node=$OPTARG" ;;
  p   ) shell_header="shell_header=$OPTARG" ;;
  \?  ) >&2 printf "%s: -%s\n%s\n" "Invalid option" $OPTARG "Run $0 -h for help."
    exit 1 ;;
  esac
done
shift $((OPTIND-1))
commands_file="$(realpath $1)"


if [ -z "$sing_image" ]; then
  >&2 echo "option required: -i IMAGE_NAME"
  exit 1
fi
if [ -z "$login_node" ]; then
  >&2 echo "option required: -J LOGIN_NODE"
  exit 1
fi

if [ -z "$SLURM_JOB_ID" ]; then
  >&2 echo "SLURM_JOB_ID is undefined."
  >&2 echo "You must run me using sbatch."
  exit 1
fi

workdir="$(realpath "$workdir")"
mkdir -p $workdir
cd $workdir


function escape () {
  sed -E 's/(\/)|(\&)/\\&/g' <<< "$1"
}


wrapped_file="$(basename $commands_file)"
wrapped_file="${wrapped_file%.*}"
wrapped_file="${wrapped_file}.wrapped.cmds"

sed "s/^/$(escape "$singularity_exec $sing_image") /" "$commands_file" > "$wrapped_file"


gridrunner_conf="gridrunner-${SLURM_JOB_ID}.conf"
cat > $gridrunner_conf << EOF
[GRID]
gridtype=SLURM
cmd=ssh $login_node cd $workdir \&\& sbatch $sbatch_options
squeue=ssh $login_node squeue
$max_nodes
$cmds_per_node
$shell_header
EOF

exec /opt/HpcGridRunner/hpc_cmds_GridRunner.pl \
  --grid_conf "$gridrunner_conf" -c "$wrapped_file"

