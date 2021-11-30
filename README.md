# SLURM Scheduler for TrinityRNASeq inside Singularity

`chorus.sh` provides a script which wraps
[a fork of HpcGridRunner](https://github.com/jennydaman/HpcGridRunner)
for scheduling a containerized, parallel workload on SLURM
from within a Singularity container. It `ssh`es into the SLURM cluster's
login node to reach `sbatch`.

Here, a `Dockerfile` is provided which supplements the 
[`trinityrnaseq/trinityrnaseq:2.13.2`](https://hub.docker.com/r/trinityrnaseq/trinityrnaseq)
container image with OpenSSH and the code here.

## Tips and Tricks

#### Trinity Mini-Assembly Progress

```shell
printf "%d / %d\n" "$(find *trinity*/chorus-*/farmit.*/retvals/ -type f | wc -l)" "$(wc -l < *trinity*/partitioned_reads.files.list)"
```

